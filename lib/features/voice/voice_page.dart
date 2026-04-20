import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tools/client_tools.dart';

// ---------------------------------------------------------------------------
// Data model for a single transcript entry
// ---------------------------------------------------------------------------
class _TranscriptEntry {
  final bool isUser;
  String text;
  bool isTentative;

  _TranscriptEntry({
    required this.isUser,
    required this.text,
    this.isTentative = false,
  });
}

// ---------------------------------------------------------------------------
// VoicePage
// ---------------------------------------------------------------------------
class VoicePage extends StatefulWidget {
  final String conversationToken;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  /// Callback owned by AppShell — fetches a fresh token and swaps in a new
  /// ConversationIntroPage on the inner Navigator. Stays on same stage.
  final Future<void> Function() onStartNew;

  const VoicePage({
    super.key,
    required this.conversationToken,
    required this.stageBucket,
    required this.onStartNew,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late final ConversationClient _client;
  final List<_TranscriptEntry> _transcript = [];
  final ScrollController _scrollController = ScrollController();

  // Status shown below the AppBar
  String _statusText = 'Connecting…';
  // True once the session ends — stays on this page, shows restart banner.
  bool _conversationEnded = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _client = ConversationClient(
      clientTools: {
        'capture_need': CaptureNeedTool(prospectId: widget.prospectId),
        'search_products': SearchProductsTool(prospectId: widget.prospectId),
        'record_off_ramp': RecordOffRampTool(prospectId: widget.prospectId),
        'search_product_catalog': SearchProductCatalogTool(
          prospectId: widget.prospectId,
          stageBucket: widget.stageBucket,
        ),
        'advance_phase': AdvancePhaseTool(prospectId: widget.prospectId),
        'record_handoff': RecordHandoffTool(prospectId: widget.prospectId),
      },
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) {
          if (!mounted) return;
          setState(() => _statusText = 'Listening');
        },
        onDisconnect: (_) {
          if (!mounted) return;
          setState(() {
            _conversationEnded = true;
            _statusText = 'Conversation ended';
          });
        },
        onModeChange: ({required mode}) {
          if (!mounted) return;
          setState(() {
            _statusText = mode == ConversationMode.speaking
                ? '$_agentName is speaking…'
                : 'Listening';
          });
        },
        onError: (message, [context]) {
          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Error: $message'),
              backgroundColor: Theme.of(this.context).colorScheme.error,
            ),
          );
        },
        // ── Transcript callbacks ────────────────────────────────────────────
        onTentativeUserTranscript: ({required transcript, required eventId}) {
          if (!mounted) return;
          setState(() {
            // Update the last tentative user entry, or add one
            if (_transcript.isNotEmpty &&
                _transcript.last.isUser &&
                _transcript.last.isTentative) {
              _transcript.last.text = transcript;
            } else {
              _transcript.add(_TranscriptEntry(
                  isUser: true, text: transcript, isTentative: true));
            }
          });
          _scrollToBottom();
        },
        onUserTranscript: ({required transcript, required eventId}) {
          if (!mounted) return;
          setState(() {
            // Replace the tentative user entry with the finalized one
            if (_transcript.isNotEmpty &&
                _transcript.last.isUser &&
                _transcript.last.isTentative) {
              _transcript.last
                ..text = transcript
                ..isTentative = false;
            } else {
              _transcript.add(
                  _TranscriptEntry(isUser: true, text: transcript));
            }
          });
          _scrollToBottom();
        },
        onTentativeAgentResponse: ({required response}) {
          if (!mounted) return;
          setState(() {
            if (_transcript.isNotEmpty &&
                !_transcript.last.isUser &&
                _transcript.last.isTentative) {
              _transcript.last.text = response;
            } else {
              _transcript.add(_TranscriptEntry(
                  isUser: false, text: response, isTentative: true));
            }
          });
          _scrollToBottom();
        },
        onMessage: ({required message, required source}) {
          if (!mounted) return;
          if (source == Role.ai) {
            setState(() {
              if (_transcript.isNotEmpty &&
                  !_transcript.last.isUser &&
                  _transcript.last.isTentative) {
                _transcript.last
                  ..text = message
                  ..isTentative = false;
              } else {
                _transcript.add(
                    _TranscriptEntry(isUser: false, text: message));
              }
            });
            _scrollToBottom();
          }
        },
      ),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    // Start the session automatically once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _client
      ..endSession()
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _startSession() async {
    try {
      await _client.startSession(
        conversationToken: widget.conversationToken,
        dynamicVariables: widget.dynamicVariables.isNotEmpty
            ? widget.dynamicVariables
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _endSession() async {
    await _client.endSession();
    if (mounted) {
      setState(() {
        _conversationEnded = true;
        _statusText = 'Conversation ended';
      });
    }
  }

  void _startNewSession() {
    // Delegate to AppShell — it fetches a fresh token and replaces the inner
    // navigator stack with a new ConversationIntroPage for the same stage.
    widget.onStartNew();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _client.sendUserMessage(trimmed);
    setState(() {
      _transcript.add(_TranscriptEntry(isUser: true, text: trimmed));
    });
    _scrollToBottom();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String get _stageLabel {
    switch (widget.stageBucket) {
      case 'pre_seed':
        return 'Pre-seed';
      case 'seed':
        return 'Seed';
      case 'growth':
        return 'Growth';
      case 'early_stage':
        return 'Early Stage';
      case 'growth_stage':
        return 'Growth';
      case 'late_stage':
        return 'Late Stage';
      case 'ipo_beyond':
        return 'IPO & Beyond';
      default:
        return widget.stageBucket;
    }
  }

  String get _agentName {
    switch (widget.stageBucket) {
      case 'early_stage':
        return 'Earl';
      case 'growth_stage':
        return 'Gary';
      case 'late_stage':
        return 'Leena';
      case 'ipo_beyond':
        return 'Irma';
      default:
        return 'Alex';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = _client.status == ConversationStatus.connected;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '$_agentName · $_stageLabel',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          if (!_conversationEnded)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.call_end_rounded, size: 18),
                label: const Text('End'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Status strip ─────────────────────────────────────────────────
          _StatusStrip(
            statusText: _statusText,
            isSpeaking: _client.isSpeaking,
            colorScheme: colorScheme,
          ),
          // ── Transcript area ───────────────────────────────────────────────
          Expanded(
            child: _transcript.isEmpty
                ? Center(
                    child: Text(
                      _client.status == ConversationStatus.connecting
                          ? 'Connecting to $_agentName…'
                          : '$_agentName will start speaking shortly.\nBegin talking when you\'re ready.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _transcript.length,
                    itemBuilder: (context, index) =>
                        _BubbleRow(entry: _transcript[index]),
                  ),
          ),
          // ── Bottom controls ───────────────────────────────────────────────
          _BottomBar(
            isConnected: isConnected,
            isMuted: _client.isMuted,
            isEnded: _conversationEnded,
            prospectId: widget.prospectId,
            onToggleMute: () => _client.toggleMute(),
            onSend: _sendTextMessage,
            onStartNew: _startNewSession,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status strip
// ---------------------------------------------------------------------------
class _StatusStrip extends StatelessWidget {
  final String statusText;
  final bool isSpeaking;
  final ColorScheme colorScheme;

  const _StatusStrip({
    required this.statusText,
    required this.isSpeaking,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          // Animated dot
          _PulseDot(active: isSpeaking, colorScheme: colorScheme),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing dot indicator
// ---------------------------------------------------------------------------
class _PulseDot extends StatefulWidget {
  final bool active;
  final ColorScheme colorScheme;

  const _PulseDot({required this.active, required this.colorScheme});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.active ? _anim : const AlwaysStoppedAnimation(0.4),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              widget.active ? widget.colorScheme.primary : widget.colorScheme.outline,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat bubble row
// ---------------------------------------------------------------------------
class _BubbleRow extends StatelessWidget {
  final _TranscriptEntry entry;

  const _BubbleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = entry.isUser;

    final bubble = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
        ),
      ),
      child: Text(
        entry.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isUser
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontStyle:
                  entry.isTentative ? FontStyle.italic : FontStyle.normal,
            ),
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom control bar — mic toggle + text input
// ---------------------------------------------------------------------------
class _BottomBar extends StatefulWidget {
  final bool isConnected;
  final bool isMuted;
  final bool isEnded;
  final String? prospectId;
  final VoidCallback onToggleMute;
  final void Function(String) onSend;
  final VoidCallback onStartNew;

  const _BottomBar({
    required this.isConnected,
    required this.isMuted,
    required this.isEnded,
    required this.onToggleMute,
    required this.onSend,
    required this.onStartNew,
    this.prospectId,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty || !widget.isConnected) return;
    widget.onSend(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── "Start new session" banner (shown after conversation ends) ────
          if (widget.isEnded)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colorScheme.surfaceContainerLow,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conversation complete',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: widget.onStartNew,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    child: const Text('Start new session'),
                  ),
                ],
              ),
            ),
          // ── Return URL (shown after conversation ends, only when prospectId exists) ──
          if (widget.isEnded && widget.prospectId != null)
            _ReturnUrlBanner(prospectId: widget.prospectId!),
          // ── Text input row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: widget.isConnected && !widget.isEnded,
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.send,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.isConnected
                          ? 'Type a message…'
                          : 'Connecting…',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final canSend =
                        widget.isConnected && value.text.trim().isNotEmpty;
                    return IconButton.filled(
                      onPressed: canSend ? _submit : null,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: canSend
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHigh,
                        foregroundColor: canSend
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        minimumSize: const Size(44, 44),
                      ),
                      tooltip: 'Send message',
                    );
                  },
                ),
              ],
            ),
          ),
          // ── Mic toggle row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: widget.isConnected && !widget.isEnded
                      ? widget.onToggleMute
                      : null,
                  icon: Icon(
                    widget.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.isMuted
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    foregroundColor: widget.isMuted
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
                    minimumSize: const Size(48, 48),
                  ),
                  tooltip: widget.isMuted ? 'Unmute' : 'Mute',
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isMuted ? 'Microphone off' : 'Microphone on',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Return URL banner — shown post-conversation so the user can copy their link
// ---------------------------------------------------------------------------
class _ReturnUrlBanner extends StatelessWidget {
  final String prospectId;

  const _ReturnUrlBanner({required this.prospectId});

  String get _returnUrl {
    final uri = Uri.base;
    final origin = uri.origin;
    // Flutter Web defaults to hash routing: URLs look like http://host/#/...
    // uri.fragment is non-empty (e.g. "/") when hash routing is active.
    if (uri.fragment.isNotEmpty) {
      return '$origin/#/?p=$prospectId';
    }
    return '$origin/?p=$prospectId';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = _returnUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.4),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your return link — come back any time to continue',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Return link copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  width: 280,
                ),
              );
            },
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

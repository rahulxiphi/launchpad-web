import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/material.dart';

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

  const VoicePage({
    super.key,
    required this.conversationToken,
    required this.stageBucket,
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
  bool _isEnding = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _client = ConversationClient(
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) {
          if (!mounted) return;
          setState(() => _statusText = 'Listening');
        },
        onDisconnect: (_) {
          if (!mounted) return;
          if (!_isEnding) Navigator.of(context).pop();
        },
        onModeChange: ({required mode}) {
          if (!mounted) return;
          setState(() {
            _statusText = mode == ConversationMode.speaking
                ? 'Alex is speaking…'
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
    _isEnding = true;
    await _client.endSession();
    if (mounted) Navigator.of(context).pop();
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
      default:
        return widget.stageBucket;
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
          'Alex · $_stageLabel',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
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
                          ? 'Connecting to Alex…'
                          : 'Alex will start speaking shortly.\nBegin talking when you\'re ready.',
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
            onToggleMute: () => _client.toggleMute(),
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
// Bottom control bar
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final bool isConnected;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const _BottomBar({
    required this.isConnected,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filled(
            onPressed: isConnected ? onToggleMute : null,
            icon: Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isMuted
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              foregroundColor: isMuted
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              minimumSize: const Size(56, 56),
            ),
            tooltip: isMuted ? 'Unmute' : 'Mute',
          ),
          const SizedBox(width: 16),
          Text(
            isMuted ? 'Microphone off' : 'Microphone on',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}


class VoicePage extends StatefulWidget {
  final String agentId;
  final String stageBucket;

  const VoicePage({
    super.key,
    required this.agentId,
    required this.stageBucket,
  });

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'elevenlabs-convai-${widget.agentId}';
    try {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final el = html.document.createElement('elevenlabs-convai') as html.HtmlElement;
        el.setAttribute('agent-id', widget.agentId);
        el.style.width = '100%';
        el.style.height = '100%';
        return el;
      });
    } catch (_) {
      // Already registered on hot reload � safe to ignore.
    }
  }

  String get _stageLabel {
    switch (widget.stageBucket) {
      case 'pre_seed':
        return 'Pre-seed';
      case 'seed':
        return 'Seed';
      case 'growth':
        return 'Growth';
      default:
        return widget.stageBucket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Alex � $_stageLabel',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  'Click the orb in the bottom-right corner to start speaking',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: HtmlElementView(viewType: _viewType),
          ),
        ],
      ),
    );
  }
}

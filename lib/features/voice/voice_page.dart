import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
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

  // Track the current phase locally so we can update it via tool calls
  late int _activePhase;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    
    // Initialize active phase from dynamic variables
    final phaseStr = widget.dynamicVariables['conversation_phase']?.toString();
    _activePhase = int.tryParse(phaseStr ?? '1') ?? 1;

    _client = ConversationClient(
      clientTools: {
        'capture_need': CaptureNeedTool(prospectId: widget.prospectId),
        'search_products': SearchProductsTool(prospectId: widget.prospectId),
        'record_off_ramp': RecordOffRampTool(prospectId: widget.prospectId),
        'search_product_catalog': SearchProductCatalogTool(
          prospectId: widget.prospectId,
          stageBucket: widget.stageBucket,
        ),
        'advance_phase': AdvancePhaseTool(
          prospectId: widget.prospectId,
          onPhaseAdvanced: (newPhase) {
            if (mounted) {
              setState(() => _activePhase = newPhase);
            }
          },
        ),
        'record_handoff': RecordHandoffTool(prospectId: widget.prospectId),
      },
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) {
          if (!mounted) return;
          setState(() => _statusText = 'Listening');
        },
        onDisconnect: (_) {
          if (!mounted) return;
          // Inject the return link as the final AI message
          final uri = Uri.base;
          final origin = uri.origin;
          final returnUrl = widget.prospectId != null
              ? (uri.fragment.isNotEmpty
                  ? '$origin/#/?p=${widget.prospectId}'
                  : '$origin/?p=${widget.prospectId}')
              : null;
          setState(() {
            _conversationEnded = true;
            _statusText = 'Conversation ended';
            if (returnUrl != null) {
              final email = widget.dynamicVariables['userEmail']?.toString() ?? '';
              final emailNote = email.isNotEmpty
                  ? "We've also sent this link to $email"
                  : "Save this link to come back anytime";
              _transcript.add(_TranscriptEntry(
                isUser: false,
                text:
                    "Your return link — come back any time to continue:\n$returnUrl\n\n$emailNote",
                isTentative: false,
              ));

              if (email.isNotEmpty) {
                try {
                  Dio().post(
                    'http://localhost:8000/api/v1/conversations/send-return-link',
                    data: {
                      'email': email,
                      'return_url': returnUrl,
                    },
                  );
                } catch (e) {
                  // Silently ignore so as not to disrupt the UI if mail sending fails
                }
              }
            }
          });
          _scrollToBottom();
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
        // Convert snake_case to Title Case (e.g. 'super_agent_stage' → 'Super Agent Stage')
        return widget.stageBucket
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
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

  int get _currentPhase => _activePhase;

  Widget _buildSidebar() {
    final currentPhase = _currentPhase;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Text(
              'Phases',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF8d8578),
                letterSpacing: 0.8,
              ),
            ),
          ),
          _buildPhaseItem(phaseNumber: 1, title: 'Entry & Welcome',    subtitle: 'Identity & intent',       currentPhase: currentPhase),
          _buildPhaseItem(phaseNumber: 2, title: 'Discovery',          subtitle: 'Stage-tailored profiling', currentPhase: currentPhase),
          _buildPhaseItem(phaseNumber: 3, title: 'Deep Qualification', subtitle: 'Financial health',         currentPhase: currentPhase),
          _buildPhaseItem(phaseNumber: 4, title: 'Recommendations',    subtitle: 'Product match',           currentPhase: currentPhase),
          _buildPhaseItem(phaseNumber: 5, title: 'Next Actions',       subtitle: 'Facilitation',            currentPhase: currentPhase),
        ],
      ),
    );
  }

  Widget _buildPhaseItem({
    required int phaseNumber,
    required String title,
    required String subtitle,
    required int currentPhase,
  }) {
    final isCompleted = phaseNumber < currentPhase;
    final isCurrent = phaseNumber == currentPhase;
    const jpmcDarkNavy = Color(0xFF04213d);
    const jpmcGold = Color(0xFFe8cc7a);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Number badge
    final Widget numBadge = isCompleted
        ? Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1d9e75),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          )
        : Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0x2Ac9a84c) // gold tint on navy
                  : (isDark ? Colors.grey.shade800 : const Color(0xFFF3F0EA)),
              shape: BoxShape.circle,
            ),
            child: Text(
              '0$phaseNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCurrent
                    ? jpmcGold
                    : (isDark ? Colors.white70 : const Color(0xFF1a1a18)),
              ),
            ),
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent ? jpmcDarkNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              numBadge,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCurrent
                            ? Colors.white
                            : (isDark ? Colors.grey.shade300 : const Color(0xFF6f675b)),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrent
                            ? Colors.white.withOpacity(0.65)
                            : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = _client.status == ConversationStatus.connected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0f172a) : const Color(0xFFF4F1EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SizedBox.expand(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                height: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 848),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sidebar (phases) ──────────────────────────────────────
                  /*
                  if (MediaQuery.of(context).size.width >= 860)
                    _buildSidebar(),

                  // 12px gap between sidebar and chat card
                  if (MediaQuery.of(context).size.width >= 860)
                    const SizedBox(width: 12),
                  */

                  // ── Chat container ────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F3EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : const Color(0xFFE5E0D4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _JpmcMockHeader(
                            agentName: _agentName,
                            stageLabel: _stageLabel,
                            statusText: _statusText,
                            currentPhase: _activePhase,
                            isSpeaking: _client.isSpeaking,
                            isEnded: _conversationEnded,
                            onEnd: _endSession,
                            onStartNew: _startNewSession,
                            colorScheme: colorScheme,
                          ),
                          Expanded(
                            child: _transcript.isEmpty
                                ? Center(
                                    child: Text(
                                      _client.status ==
                                              ConversationStatus.connecting
                                          ? 'Connecting to $_agentName…'
                                          : '$_agentName will start speaking shortly.\nBegin talking when you\'re ready.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                            height: 1.6,
                                          ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                    itemCount: _transcript.length,
                                    itemBuilder: (context, index) {
                                      final entry = _transcript[index];
                                      final prevEntry = index > 0 ? _transcript[index - 1] : null;
                                      final nextEntry = index < _transcript.length - 1 ? _transcript[index + 1] : null;
                                      final isPrevSame = prevEntry != null && prevEntry.isUser == entry.isUser;
                                      final isNextSame = nextEntry != null && nextEntry.isUser == entry.isUser;
                                      
                                      return _BubbleRow(
                                        entry: entry,
                                        isPrevSame: isPrevSame,
                                        isNextSame: isNextSame,
                                        agentInitial: _agentName.isNotEmpty
                                            ? _agentName[0].toUpperCase()
                                            : 'A',
                                      );
                                    },
                                  ),
                          ),
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
                    ),
                  ),
                ],
              ),
            ),           // closes ConstrainedBox
          ),             // closes SizedBox(height)
        ),               // closes Padding
      ),                 // closes Center
    ),                   // closes SizedBox.expand
  ),                     // closes SafeArea
);
  }
}

// ---------------------------------------------------------------------------
// JPMC Mock Header — title bar that matches the HTML template's .mock-header
// ---------------------------------------------------------------------------
class _JpmcMockHeader extends StatelessWidget {
  final String agentName;
  final String stageLabel;
  final String statusText;
  final int currentPhase;
  final bool isSpeaking;
  final bool isEnded;
  final VoidCallback onEnd;
  final VoidCallback onStartNew;
  final ColorScheme colorScheme;

  const _JpmcMockHeader({
    required this.agentName,
    required this.stageLabel,
    required this.statusText,
    required this.currentPhase,
    required this.isSpeaking,
    required this.isEnded,
    required this.onEnd,
    required this.onStartNew,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const jpmcNavy = Color(0xFF04213d);
    const jpmcGold = Color(0xFFc9a84c);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E0D4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Wordmark
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'JPMC',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : jpmcNavy,
                        letterSpacing: 0.3,
                      ),
                    ),
                    TextSpan(
                      text: '  •  Innovation Economy Advisor',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFFe8cc7a)
                            : jpmcGold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : jpmcNavy,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: currentPhase / 5.0,
                        backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFE5E0D4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFFe8cc7a) : jpmcGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Prospect workspace  ·  $agentName  ·  $stageLabel',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF8d8578),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF0EAD8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade700
                    : const Color(0xFFD4C9AD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(active: isSpeaking, colorScheme: colorScheme),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF6f675b),
                  ),
                ),
              ],
            ),
          ),
          if (isEnded) ...[
            const SizedBox(width: 10),
            // ── Start new session button (coral, replaces End when conversation done)
            GestureDetector(
              onTap: onStartNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 5),
                    Text(
                      'Start new session',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 10),
            // ── End button
            GestureDetector(
              onTap: onEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.call_end_rounded, size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 5),
                    Text(
                      'End',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  final String agentInitial;
  final bool isPrevSame;
  final bool isNextSame;
  final bool isGrouped; // Restored just to appease hot-reload state constraints

  const _BubbleRow({
    required this.entry,
    this.agentInitial = 'A',
    this.isPrevSame = false,
    this.isNextSame = false,
    this.isGrouped = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = entry.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bubble colors
    const jpmcDarkNavy = Color(0xFF131F2E);
    final aiBubbleColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final aiTextColor = isDark ? Colors.white : const Color(0xFF1F2937);

    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 800 ? 800.0 : screenWidth;

    // Avatar colors: each avatar uses the OPPOSITE bubble's bg color
    final aiAvatarBg = jpmcDarkNavy;    // same as user bubble = dark navy
    final userAvatarBg = aiBubbleColor; // same as AI bubble = grey/light

    // ── Avatar widget ────────────────────────────────────────────────────────
    Widget avatar(Color bg, Widget child) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        );

    final aiAvatar = avatar(
      aiAvatarBg,
      Text(
        agentInitial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFc9a84c), // gold initial on dark bg
        ),
      ),
    );

    final userAvatar = avatar(
      userAvatarBg,
      Icon(
        Icons.person_rounded,
        size: 16,
        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      ),
    );

    // ── Bubble ───────────────────────────────────────────────────────────────
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: containerWidth * 0.68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? jpmcDarkNavy : aiBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
          topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
          bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
          bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
        ),
      ),
      child: Text(
        entry.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isUser ? Colors.white : aiTextColor,
              height: 1.5,
              fontSize: 15,
              fontWeight: FontWeight.w500, // same richness for both sides
              fontStyle:
                  entry.isTentative ? FontStyle.italic : FontStyle.normal,
            ),
      ),
    );

    // Estimate line count (~70 chars per line matches the actual bubble width)
    final estimatedLines =
        (entry.text.length / 70).ceil() + '\n'.allMatches(entry.text).length;
    final avatarAlign = estimatedLines <= 1
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.end;

    // ── Return link bubble (special formatting) ────────────────────────────
    final bool isReturnLink = !isUser && entry.text.contains('come back any time to continue');

    if (isReturnLink) {
      final parts = entry.text.split('\n');
      final label = parts.isNotEmpty ? parts[0] : '';
      final url = parts.length > 1 ? parts[1] : '';
      final note = parts.length > 3 ? parts.skip(3).join('\n') : '';
      return Padding(
        padding: EdgeInsets.only(top: isPrevSame ? 2 : 12, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            aiAvatar,
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: containerWidth * 0.75),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: aiBubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
                    topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
                    bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
                    bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      url,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF006CAD),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CopyLinkButton(url: url),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: isPrevSame ? 1 : 10, bottom: 1),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: avatarAlign,
        children: isUser
            ? [
                bubble,
                const SizedBox(width: 8),
                // Hide avatar for grouped messages unless it's the last one in the group
                if (isNextSame) const SizedBox(width: 28) else userAvatar,
              ]
            : [
                if (isNextSame) const SizedBox(width: 28) else aiAvatar,
                const SizedBox(width: 8),
                bubble,
              ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Copy link button used inside the return-link bubble
// ---------------------------------------------------------------------------
class _CopyLinkButton extends StatefulWidget {
  final String url;
  const _CopyLinkButton({required this.url});
  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF1d9e75)
              : const Color(0xFF04213d),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 14,
              color: _copied ? Colors.white : const Color(0xFFc9a84c),
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Copied!' : 'Copy link',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _copied ? Colors.white : const Color(0xFFc9a84c),
              ),
            ),
          ],
        ),
      ),
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
  bool _copied = false;

  // Compute the prospect return URL (mirrors _ReturnUrlBanner logic)
  String get _returnUrl {
    if (widget.prospectId == null) return '';
    final uri = Uri.base;
    final origin = uri.origin;
    if (uri.fragment.isNotEmpty) {
      return '$origin/#/?p=${widget.prospectId}';
    }
    return '$origin/?p=${widget.prospectId}';
  }

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

  void _copyReturnUrl() {
    final url = _returnUrl;
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Return link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        width: 260,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hardcoded suggestion chips (shown above input during active session)
    const chips = [
      'Pre-seed, pre-revenue',
      'Seed stage, early revenue',
      'Series A, growing revenue',
      'Profitable, bootstrapped',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E0D4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Suggestion chips (only when conversation is active) ───────────
          if (!widget.isEnded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: chips.map((chip) {
                  return GestureDetector(
                    onTap: () {
                      if (widget.isConnected) widget.onSend(chip);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : const Color(0xFFD4C9AD),
                        ),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Input area (Pill + Outside Mic) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFDFCF9),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        // ── Text area ─────────────────────────────────────────
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            enabled: widget.isConnected && !widget.isEnded,
                            onSubmitted: (_) => _submit(),
                            textInputAction: TextInputAction.send,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                            textAlignVertical: TextAlignVertical.center,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: widget.isEnded
                                  ? "You can't type now, Conversation Ended."
                                  : (widget.isConnected ? 'Type a message…' : 'Connecting…'),
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                          ),
                        ),
                        // ── Copy / Send button ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _textController,
                            builder: (context, value, _) {
                              final canSend = widget.isConnected && !widget.isEnded &&
                                  value.text.trim().isNotEmpty;
                              return GestureDetector(
                                onTap: canSend ? _submit : null,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: canSend
                                        ? const Color(0xFF131F2E)
                                        : colorScheme.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 20,
                                    color: canSend
                                        ? const Color(0xFFC8872A)
                                        : colorScheme.onSurfaceVariant
                                            .withOpacity(0.4),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Mic button (outside, to the right) ───────────────────────
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: (widget.isConnected && !widget.isEnded) ? widget.onToggleMute : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (widget.isMuted || widget.isEnded)
                          ? colorScheme.errorContainer
                          : const Color(0xFF006CAD),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      (widget.isMuted || widget.isEnded)
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      size: 22,
                      color: (widget.isMuted || widget.isEnded)
                          ? colorScheme.onErrorContainer
                          : Colors.white,
                    ),
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


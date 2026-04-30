import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../tools/client_tools.dart';
import '../../services/conversation_service.dart';
import 'widgets/voice_bubble_row.dart';
import 'widgets/voice_classification_panel.dart';
import 'widgets/voice_header.dart';

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

class _ResponseChipsState {
  final bool show;
  final List<String> chips;
  final DateTime? expiresAt;

  const _ResponseChipsState({
    required this.show,
    required this.chips,
    this.expiresAt,
  });

  static const empty = _ResponseChipsState(show: false, chips: <String>[]);
}

// ---------------------------------------------------------------------------
// VoicePage
// ---------------------------------------------------------------------------
class VoicePage extends StatefulWidget {
  final String conversationToken;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  final String initialMode; // 'voice' or 'chat'
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
    this.initialMode = 'voice',
  });

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late final ConversationClient _client;
  final ConversationService _conversationService = ConversationService();
  final List<_TranscriptEntry> _transcript = [];
  final ScrollController _scrollController = ScrollController();

  // Status shown below the AppBar
  String _statusText = 'Connecting…';
  // True once the session ends — stays on this page, shows restart banner.
  bool _conversationEnded = false;
  bool _isLoadingClassification = false;
  ProspectClassification? _classification;
  String? _classificationError;
  bool _showStageOverride = false;
  String? _selectedStageChoice;
  _ResponseChipsState _responseChips = _ResponseChipsState.empty;
  int _chipsEpoch = 0;
  int _disconnectClearEpoch = 0;
  late bool _isChatMode;

  // Track the current phase locally so we can update it via tool calls
  late int _activePhase;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    
    _isChatMode = widget.initialMode == 'chat';

    // Initialize active phase from dynamic variables
    final phaseStr = widget.dynamicVariables['conversation_phase']?.toString();
    _activePhase = int.tryParse(phaseStr ?? '1') ?? 1;

    final clientTools = <String, ClientTool>{
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
        'set_response_chips': SetResponseChipsTool(
          onUpdate: (payload) {
            if (!mounted) {
              print('[chips][ui] onUpdate ignored because widget is not mounted');
              return;
            }
            print(
              '[chips][ui] onUpdate received showChips=${payload.showChips} chips=${payload.chips} category=${payload.category} ttlMs=${payload.ttlMs}',
            );
            _applyResponseChips(payload);
          },
        ),
      };

    print('[chips][ui] registering client tools: ${clientTools.keys.toList()}');

    _client = ConversationClient(
      clientTools: clientTools,
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) {
          print('[chips][ui] onConnect conversationId=$conversationId mode=${_isChatMode ? 'chat' : 'voice'}');
          if (!mounted) return;
          setState(() => _statusText = _isChatMode ? 'Chatting' : 'Listening');
        },
        onDisconnect: (_) {
          if (!mounted || _conversationEnded) return;
          print(
            '[chips][ui] onDisconnect triggered; clearing chips and marking conversation ended',
          );
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
          // Keep chips briefly so late tool callbacks can render final options.
          _disconnectClearEpoch += 1;
          final scheduledEpoch = _disconnectClearEpoch;
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            if (scheduledEpoch != _disconnectClearEpoch) return;
            setState(() {
              _responseChips = _ResponseChipsState.empty;
            });
            print('[chips][ui] delayed disconnect clear executed');
          });
          _loadClassificationSummary();
          _scrollToBottom();
        },
        onModeChange: ({required mode}) {
          if (!mounted) return;
          setState(() {
            _statusText = mode == ConversationMode.speaking
                ? '$_agentName is speaking…'
                : (_isChatMode ? 'Chatting' : 'Listening');
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
          if (!mounted || transcript.trim().isEmpty) return;
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

  bool _isIdentityCategory(String? category) {
    if (category == null || category.isEmpty) return false;
    final normalized = category
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    const exactBlocked = <String>{
      'company_name',
      'founder_name',
      'email',
      'phone',
      'website',
      'location',
      'identity',
      'contact',
      'contact_info',
    };
    if (exactBlocked.contains(normalized)) return true;

    const keywordBlocked = <String>[
      'company_name',
      'founder_name',
      'email',
      'phone',
      'website',
      'location',
      'identity',
      'contact',
    ];
    return keywordBlocked.any(
      (keyword) => normalized == keyword || normalized.startsWith('${keyword}_'),
    );
  }

  void _applyResponseChips(SetResponseChipsPayload payload) {
    final now = DateTime.now();
    final expiresAt = payload.ttlMs != null && payload.ttlMs! > 0
        ? now.add(Duration(milliseconds: payload.ttlMs!))
        : null;

    final blockedByCategory = _isIdentityCategory(payload.category);

    final shouldShow = payload.showChips &&
        payload.chips.isNotEmpty &&
      !blockedByCategory;

    print(
      '[chips][ui] apply start show=${payload.showChips} chipsNotEmpty=${payload.chips.isNotEmpty} blockedByCategory=$blockedByCategory conversationEnded=$_conversationEnded => shouldShow=$shouldShow',
    );

    final next = _ResponseChipsState(
      show: shouldShow,
      chips: shouldShow ? payload.chips : const <String>[],
      expiresAt: expiresAt,
    );

    // Prevent redundant rebuilds when tool emits same payload repeatedly.
    if (_responseChips.show == next.show &&
        _responseChips.expiresAt == next.expiresAt &&
        _responseChips.chips.length == next.chips.length &&
        _responseChips.chips.join('|') == next.chips.join('|')) {
      print('[chips][ui] skip state update (no effective change)');
      return;
    }

    setState(() {
      _responseChips = next;
      _chipsEpoch += 1;
    });

    print(
      '[chips][ui] state applied show=${_responseChips.show} chips=${_responseChips.chips} expiresAt=${_responseChips.expiresAt} epoch=$_chipsEpoch',
    );

    if (next.expiresAt != null) {
      final int scheduledEpoch = _chipsEpoch;
      print('[chips][ui] expiry timer scheduled epoch=$scheduledEpoch expiresAt=${next.expiresAt}');
      Future<void>.delayed(next.expiresAt!.difference(now), () {
        if (!mounted) return;
        if (scheduledEpoch != _chipsEpoch) return;
        final expiry = _responseChips.expiresAt;
        if (expiry == null) return;
        if (DateTime.now().isBefore(expiry)) return;
        setState(() {
          _responseChips = _ResponseChipsState.empty;
          _chipsEpoch += 1;
        });
        print('[chips][ui] expiry timer cleared chips epoch=$_chipsEpoch');
      });
    }
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
      final dynamicVariables =
          Map<String, dynamic>.from(widget.dynamicVariables);
      dynamicVariables['initial_mode'] = widget.initialMode;

      await _client.startSession(
        conversationToken: widget.conversationToken,
        dynamicVariables: dynamicVariables,
        overrides: widget.initialMode == 'chat'
            ? ConversationOverrides(
                conversation: ConversationSettingsOverrides(
                  textOnly: true,
                ),
              )
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

  Future<void> _loadClassificationSummary() async {
    if (!_isStageChipsEnabled) return;
    if (widget.prospectId == null) return;
    if (!mounted) return;

    setState(() {
      _isLoadingClassification = true;
      _classificationError = null;
    });

    try {
      final prospect = await _conversationService.getProspect(widget.prospectId!);
      if (!mounted) return;
      setState(() {
        _classification = prospect.classification;
        _selectedStageChoice =
            prospect.classification?.confirmedStageBucket ??
            prospect.classification?.inferredStageBucket;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classificationError = 'Could not load classification summary';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingClassification = false;
      });
    }
  }

  bool get _isStageChipsEnabled {
    final raw = widget.dynamicVariables['show_stage_chips'];
    if (raw is bool) return raw;
    return raw?.toString().toLowerCase() != 'false';
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

  Future<void> _persistStageSelection(String selectedBucket) async {
    final prospectId = widget.prospectId;
    if (prospectId == null) return;

    try {
      final result = await _conversationService.updateProspectClassification(
        prospectId,
        selectedStageBucket: selectedBucket,
      );
      if (!mounted) return;
      setState(() {
        _classification = result.classification;
        _selectedStageChoice = selectedBucket;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save stage selection right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildClassificationSummary() {
    final inferredBucket = _classification?.inferredStageBucket;

    return VoiceClassificationPanel(
      enabled: _isStageChipsEnabled,
      isLoading: _isLoadingClassification,
      errorMessage: _classificationError,
      classification: _classification,
      showStageOverride: _showStageOverride,
      selectedStageChoice: _selectedStageChoice,
      onConfirmInferred: () {
        if (inferredBucket == null) return;
        setState(() {
          _showStageOverride = false;
          _selectedStageChoice = inferredBucket;
        });
        _persistStageSelection(inferredBucket);
      },
      onShowOverride: () {
        setState(() {
          _showStageOverride = true;
        });
      },
      onSelectOverride: (bucket) {
        setState(() {
          _selectedStageChoice = bucket;
        });
        _persistStageSelection(bucket);
      },
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
                          VoiceHeader(
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
                                      
                                      return VoiceBubbleRow(
                                        isUser: entry.isUser,
                                        text: entry.text,
                                        isTentative: entry.isTentative,
                                        isPrevSame: isPrevSame,
                                        isNextSame: isNextSame,
                                        agentInitial: _agentName.isNotEmpty
                                            ? _agentName[0].toUpperCase()
                                            : 'A',
                                      );
                                    },
                                  ),
                          ),
                                  if (_conversationEnded) _buildClassificationSummary(),
                          _BottomBar(
                            isConnected: isConnected,
                            isMuted: _client.isMuted,
                            isEnded: _conversationEnded,
                            isChatMode: _isChatMode,
                            prospectId: widget.prospectId,
                            suggestionChips: _responseChips.show
                                ? _responseChips.chips
                                : const <String>[],
                            onToggleMute: () => _client.toggleMute(),
                            onToggleMode: () async {
                              final newMode = !_isChatMode;
                              setState(() {
                                _isChatMode = newMode;
                                if (_statusText == 'Listening' || _statusText == 'Chatting') {
                                  _statusText = newMode ? 'Chatting' : 'Listening';
                                }
                              });
                              if (isConnected && !_conversationEnded) {
                                await _client.setMicMuted(newMode);
                              }
                            },
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
// Bottom control bar — mic toggle + text input
// ---------------------------------------------------------------------------
class _BottomBar extends StatefulWidget {
  final bool isConnected;
  final bool isMuted;
  final bool isEnded;
  final bool isChatMode;
  final String? prospectId;
  final List<String> suggestionChips;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleMode;
  final void Function(String) onSend;
  final VoidCallback onStartNew;

  const _BottomBar({
    required this.isConnected,
    required this.isMuted,
    required this.isEnded,
    required this.isChatMode,
    required this.onToggleMute,
    required this.onToggleMode,
    required this.onSend,
    required this.onStartNew,
    required this.suggestionChips,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chips = widget.suggestionChips;
    if (chips.isNotEmpty && widget.isEnded) {
      print(
        '[chips][ui] chips suppressed by render gate because isEnded=true chips=$chips',
      );
    }

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
          // ── Suggestion chips ───────────────────────────────────────────────
          if (chips.isNotEmpty)
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
                // ── Microphone button (voice mode only) ──────────────────
                if (!widget.isChatMode) ...[
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
              ],
            ),
          ),
        ],
      ),
    );

  }
}


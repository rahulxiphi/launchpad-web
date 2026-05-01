import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import '../../shared/widgets/app_shell.dart';

const _kSuperAgentBucket = 'super_agent';

class StageSelectorPage extends StatefulWidget {
  final String? invitationCode;
  final String? returnProspectId;

  const StageSelectorPage({
    super.key,
    this.invitationCode,
    this.returnProspectId,
  });

  @override
  State<StageSelectorPage> createState() => _StageSelectorPageState();
}

class _StageSelectorPageState extends State<StageSelectorPage> {
  final _service = ConversationService();
  bool _loading = false;
  String? _errorMessage;
  ProspectInitResult? _resolvedProspect;
  bool _startAtModeSelection = false;

  @override
  void initState() {
    super.initState();
    final returnProspectId =
        widget.returnProspectId ?? Uri.base.queryParameters['p'];
    final invitationCode =
        widget.invitationCode ?? Uri.base.queryParameters['invite'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (returnProspectId != null && returnProspectId.isNotEmpty) {
        _handleReturnVisit(returnProspectId);
      } else if (invitationCode != null && invitationCode.isNotEmpty) {
        _handleInviteCode(invitationCode);
      }
    });
  }

  Future<void> _handleReturnVisit(String prospectId) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final prospect = await _service.getProspect(prospectId);
      if (!mounted) return;
      setState(() {
        _resolvedProspect = prospect;
        _startAtModeSelection = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not resume your session. Tap below to start fresh.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleInviteCode(String invitationCode) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final initResult = await _service.initProspect(invitationCode);
      if (!mounted) return;
      setState(() {
        _resolvedProspect = initResult;
        _startAtModeSelection = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Invalid or expired invitation link. Tap below to continue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final prospectId = await _service.createProspect(_kSuperAgentBucket);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AppShell(
          stageBucket: _kSuperAgentBucket,
          prospectId: prospectId,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to start session: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedProspect != null) {
      final resolved = _resolvedProspect!;
      return AppShell(
        stageBucket: resolved.stageBucket,
        prospectId: resolved.prospectId,
        dynamicVariables: resolved.toDynamicVariables(
          lockProfileFields: _startAtModeSelection,
        ),
        startAtModeSelection: _startAtModeSelection,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // While handling invite/return URL, show full-screen loader
    if (_loading && (widget.invitationCode != null || widget.returnProspectId != null)) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / wordmark
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome,
                          color: colorScheme.onPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'JPMC LaunchPad',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 56),

                // Headline
                Text(
                  'Hi, I\'m Nova.',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your JPMC Innovation Economy AI advisor.\n'
                  'I\'ll learn about your startup and recommend the right banking solutions for your stage.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Single CTA card
                _NovaCard(
                  isLoading: _loading,
                  onTap: _loading ? null : _startSession,
                ),

                // Error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                Text(
                  'Demo build - auth not required',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Nova CTA card

class _NovaCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _NovaCard({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.record_voice_over_outlined,
                    color: colorScheme.onPrimary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talk to Nova',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10-15 min | personalized for your stage',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : Icon(Icons.arrow_forward_ios_rounded,
                      size: 18, color: colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import '../voice/conversation_intro_page.dart';

class _StageOption {
  final String bucket;
  final String label;
  final String description;
  final IconData icon;

  const _StageOption({
    required this.bucket,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _stages = [
  _StageOption(
    bucket: 'pre_seed',
    label: 'Pre-seed',
    description: 'Idea stage · no revenue yet · building MVP',
    icon: Icons.rocket_launch_outlined,
  ),
  _StageOption(
    bucket: 'seed',
    label: 'Seed',
    description: 'Early revenue · scaling team · first funding round',
    icon: Icons.trending_up_outlined,
  ),
  _StageOption(
    bucket: 'growth',
    label: 'Growth',
    description: 'Significant revenue · multi-market · Series A+',
    icon: Icons.account_balance_outlined,
  ),
];

class StageSelectorPage extends StatefulWidget {
  const StageSelectorPage({super.key});

  @override
  State<StageSelectorPage> createState() => _StageSelectorPageState();
}

class _StageSelectorPageState extends State<StageSelectorPage> {
  final _service = ConversationService();
  String? _loadingBucket;
  String? _errorMessage;

  Future<void> _startSession(String stageBucket) async {
    setState(() {
      _loadingBucket = stageBucket;
      _errorMessage = null;
    });

    try {
      // 1. Create prospect identity
      final prospectId = await _service.createProspect(stageBucket);

      // 2. Get voice token with prospect context
      final result = await _service.getVoiceToken(
        stageBucket,
        prospectId: prospectId,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationIntroPage(
            conversationToken: result.conversationToken,
            stageBucket: stageBucket,
            prospectId: prospectId,
            dynamicVariables: result.dynamicVariables,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to start session: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _loadingBucket = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, I\'m Alex',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your LaunchPad financial advisor. Select your startup stage to begin.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 40),
                ..._stages.map((stage) => _StageCard(
                      stage: stage,
                      isLoading: _loadingBucket == stage.bucket,
                      isDisabled: _loadingBucket != null,
                      onTap: () => _startSession(stage.bucket),
                    )),
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
                const SizedBox(height: 32),
                Text(
                  'Demo build — auth not required',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final _StageOption stage;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stage.icon, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stage.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDisabled
                        ? colorScheme.outline
                        : colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

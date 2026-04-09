import 'package:flutter/material.dart';
import 'voice_page.dart';

class _StageContent {
  final String heading;
  final String description;
  final List<String> topics;
  final String duration;

  const _StageContent({
    required this.heading,
    required this.description,
    required this.topics,
    required this.duration,
  });
}

const _stageContent = {
  'pre_seed': _StageContent(
    heading: 'Early-stage financial advisory',
    description:
        'Our advisor will get to know your startup and help identify what financial support and tools make sense at your stage.',
    topics: [
      'Your vision, business model, and current progress',
      'Banking basics, payments infrastructure, and operational tools',
      'Compliance essentials and early funding options',
    ],
    duration: '5–8 min',
  ),
  'seed': _StageContent(
    heading: 'Scaling-stage financial advisory',
    description:
        'Our advisor will discuss your current financials, funding history, and the financial infrastructure you need to grow.',
    topics: [
      'Revenue metrics, burn rate, and runway',
      'Funding stack — equity, credit, and venture debt',
      'Payments, FX basics, and treasury foundations',
    ],
    duration: '7–10 min',
  ),
  'growth': _StageContent(
    heading: 'Growth-stage financial advisory',
    description:
        'Our advisor will explore your strategic financial priorities, global expansion plans, and enterprise-grade infrastructure needs.',
    topics: [
      'Debt structuring, treasury management, and cash optimisation',
      'Cross-border payments, FX strategy, and multi-currency operations',
      'ERP, forecasting maturity, and board-level reporting',
    ],
    duration: '8–12 min',
  ),
};

class ConversationIntroPage extends StatelessWidget {
  final String conversationToken;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  /// Called when the user taps "Start new session" after a conversation ends.
  /// Handled by AppShell — fetches a fresh token and replaces the inner nav.
  final Future<void> Function() onStartNew;

  const ConversationIntroPage({
    super.key,
    required this.conversationToken,
    required this.stageBucket,
    required this.onStartNew,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  Widget build(BuildContext context) {
    final content = _stageContent[stageBucket]!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pop the AppShell from the root navigator → back to StageSelectorPage.
          // ConversationIntroPage is the initial route of the inner navigator,
          // so a plain pop() would be a no-op here.
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.headset_mic_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'You\'re about to start a\nvoice session',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'What we\'ll cover',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...content.topics.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Microphone access required',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Your browser will ask for microphone permission when the session starts. This is required for the voice conversation.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Estimated duration: ${content.duration}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => VoicePage(
                              conversationToken: conversationToken,
                              stageBucket: stageBucket,
                              prospectId: prospectId,
                              dynamicVariables: dynamicVariables,
                              onStartNew: onStartNew,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mic_rounded, size: 20),
                      label: const Text('Begin conversation'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

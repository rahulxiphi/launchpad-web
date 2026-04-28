import 'package:flutter/material.dart';

import '../../../services/conversation_service.dart';

class VoiceClassificationPanel extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final String? errorMessage;
  final ProspectClassification? classification;
  final bool showStageOverride;
  final String? selectedStageChoice;
  final VoidCallback onConfirmInferred;
  final VoidCallback onShowOverride;
  final ValueChanged<String> onSelectOverride;

  const VoiceClassificationPanel({
    super.key,
    required this.enabled,
    required this.isLoading,
    required this.errorMessage,
    required this.classification,
    required this.showStageOverride,
    required this.selectedStageChoice,
    required this.onConfirmInferred,
    required this.onShowOverride,
    required this.onSelectOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentClassification = classification;

    if (isLoading) {
      return _buildInfoContainer(
        isDark: isDark,
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Generating stage summary...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          errorMessage!,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
          ),
        ),
      );
    }

    if (currentClassification == null || !currentClassification.hasClassification) {
      return const SizedBox.shrink();
    }

    final inferredBucket = currentClassification.inferredStageBucket!;
    final selectedBucket = currentClassification.confirmedStageBucket ?? inferredBucket;
    final selectedLabel = _bucketLabel(selectedBucket);
    final confidence = (currentClassification.inferredStageConfidenceLabel ??
            (currentClassification.inferredStageConfidence != null
                ? (currentClassification.inferredStageConfidence! >= 0.85
                    ? 'high'
                    : currentClassification.inferredStageConfidence! >= 0.70
                        ? 'medium'
                        : 'low')
                : 'low'))
        .toLowerCase();

    final reasons = currentClassification.inferredStageReasons;
    final confidenceColor = switch (confidence) {
      'high' => const Color(0xFF1D9E75),
      'medium' => const Color(0xFFB7791F),
      _ => const Color(0xFF6B7280),
    };

    const stageOptions = [
      'early_stage',
      'growth_stage',
      'late_stage',
      'ipo_beyond',
    ];

    return _buildInfoContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stage summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade600 : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: confidenceColor.withOpacity(0.35)),
                ),
                child: Text(
                  '${confidence[0].toUpperCase()}${confidence.substring(1)} confidence',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Why this stage:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons
                  .map(
                    (reason) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8F5EE),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade700 : const Color(0xFFE5E0D4),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Is this stage accurate?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Confirm inferred stage'),
                selected: !showStageOverride,
                onSelected: (_) => onConfirmInferred(),
              ),
              ChoiceChip(
                label: const Text('Not accurate'),
                selected: showStageOverride,
                onSelected: (_) => onShowOverride(),
              ),
            ],
          ),
          if (showStageOverride) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stageOptions
                  .map(
                    (bucket) => ChoiceChip(
                      label: Text(_bucketLabel(bucket)),
                      selected: selectedStageChoice == bucket,
                      onSelected: (_) => onSelectOverride(bucket),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoContainer({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : const Color(0xFFE5D8B3),
        ),
      ),
      child: child,
    );
  }

  String _bucketLabel(String bucket) {
    switch (bucket) {
      case 'pre_seed':
        return 'Pre-seed';
      case 'seed':
        return 'Seed';
      case 'growth':
        return 'Growth';
      case 'early_stage':
        return 'Early Stage';
      case 'growth_stage':
        return 'Growth Stage';
      case 'late_stage':
        return 'Late Stage';
      case 'ipo_beyond':
        return 'IPO & Beyond';
      default:
        return bucket
            .split('_')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }
}

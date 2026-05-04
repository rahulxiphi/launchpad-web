import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class VoiceHeader extends StatelessWidget {
  final String agentName;
  final String stageLabel;
  final String statusText;
  final int currentPhase;
  final bool isSpeaking;
  final bool isEnded;
  final VoidCallback onEnd;
  final VoidCallback onStartNew;
  final VoidCallback onGoToRelationshipHub;
  final ColorScheme colorScheme;
  final bool isChatMode;

  const VoiceHeader({
    super.key,
    required this.agentName,
    required this.stageLabel,
    required this.statusText,
    required this.currentPhase,
    required this.isSpeaking,
    required this.isEnded,
    required this.onEnd,
    required this.onStartNew,
    required this.onGoToRelationshipHub,
    required this.colorScheme,
    required this.isChatMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : AppThemeTokens.modalHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'JPMC',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    TextSpan(
                      text: '  •  Innovation Economy Advisor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppThemeTokens.goldAccent,
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
                      color: isDark ? Colors.grey.shade300 : Colors.white,
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
                        backgroundColor:
                            isDark ? Colors.grey.shade800 : const Color(0xFFE5E0D4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppThemeTokens.goldAccent,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF0EAD8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFD4C9AD),
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
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF6f675b),
                  ),
                ),
              ],
            ),
          ),
          if (isEnded) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onGoToRelationshipHub,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF4FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBEE3F8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.dashboard_rounded,
                      size: 14,
                      color: AppThemeTokens.buttonPrimary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Go to Relationship Hub',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppThemeTokens.buttonPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 10),
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
                  children: [
                    const Icon(Icons.call_end_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 5),
                    Text(
                      isChatMode ? 'End chat' : 'End',
                      style: const TextStyle(
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
          color: widget.active ? widget.colorScheme.primary : widget.colorScheme.outline,
        ),
      ),
    );
  }
}

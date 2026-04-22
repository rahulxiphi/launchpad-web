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
  // ── Legacy stages (kept for backward compat) ──────────────────────────────
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
  // ── JPMC stages ───────────────────────────────────────────────────────────
  'early_stage': _StageContent(
    heading: 'Earl — Early-stage advisor',
    description:
        'Earl will explore your startup\'s vision, business model, and early financial needs to recommend the right JPMC products.',
    topics: [
      'Your founding story, business model, and current traction',
      'Banking basics, payment infrastructure, and operational tools',
      'Early compliance, funding options, and financial planning',
    ],
    duration: '5–8 min',
  ),
  'growth_stage': _StageContent(
    heading: 'Gary — Growth-stage advisor',
    description:
        'Gary will discuss your scaling priorities, revenue metrics, and the financial infrastructure you need for Series A/B growth.',
    topics: [
      'Revenue metrics, burn rate, and runway planning',
      'Treasury foundations, credit facilities, and venture debt',
      'Payments, FX strategy, and multi-currency operations',
    ],
    duration: '7–10 min',
  ),
  'late_stage': _StageContent(
    heading: 'Leena — Late-stage advisor',
    description:
        'Leena will explore your strategic financial priorities, capital structure, and enterprise-grade infrastructure for Series C and beyond.',
    topics: [
      'Debt structuring, treasury management, and cash optimisation',
      'Cross-border payments, FX strategy, and global operations',
      'Capital markets readiness and board-level reporting',
    ],
    duration: '8–12 min',
  ),
  'ipo_beyond': _StageContent(
    heading: 'Irma — IPO & Beyond advisor',
    description:
        'Irma will discuss your capital markets strategy, public-market readiness, and institutional-grade financial infrastructure.',
    topics: [
      'IPO readiness, capital markets access, and investor relations',
      'Enterprise treasury, cash concentration, and yield optimisation',
      'Compliance, regulatory infrastructure, and global operations',
    ],
    duration: '10–15 min',
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
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Core aesthetic colors for JPMC
    const jpmcNavy = Color(0xFF0A2744);
    const jpmcBgDk = Color(0xFF0F3460);
    const jpmcBlue = Color(0xFF006CAD);
    const jpmcGold = Color(0xFFC8872A);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 200,
        leading: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: InkWell(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: jpmcGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: jpmcGold,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [jpmcNavy, jpmcBgDk],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 640;
              
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Container(
                      width: isMobile ? double.infinity : 600,
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0 : 24, 
                        vertical: isMobile ? 0 : 40
                      ),
                      padding: EdgeInsets.all(isMobile ? 24 : 36),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
                        boxShadow: isMobile ? null : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated / glowing modern AI icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEBF4FF), Color(0xFFBBE0FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: jpmcBlue.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ]
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              color: jpmcBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Heading
                          Text(
                            content.heading,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : jpmcNavy,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Description
                          Text(
                            content.description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Topics "What we'll cover"
                          Text(
                            'WHAT WE\'LL COVER',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: jpmcGold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...content.topics.map((topic) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: jpmcBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: jpmcBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                                      height: 1.4,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 28),
                          
                          // Microphone permission banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: jpmcBlue.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: jpmcBlue.withOpacity(0.12)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mic_none_rounded, size: 18, color: jpmcBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Microphone access required',
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : jpmcNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your browser will request permission when the session starts.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                          height: 1.4,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Action footer
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 16, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Est. ${content.duration}',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
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
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('GET STARTED'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: jpmcNavy,
                                    foregroundColor: jpmcGold,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Match the squared look of JPMC
                                    elevation: 8,
                                    shadowColor: jpmcNavy.withOpacity(0.5),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

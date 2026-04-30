import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';
import 'manual_form_page.dart';

class ModeSelectionPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  final Future<void> Function() onStartNew;

  const ModeSelectionPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage> with SingleTickerProviderStateMixin {
  bool _isFetchingToken = false;
  bool _preferManual = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const jpmcNavy = Color(0xFF0A2744);
  static const jpmcBlue = Color(0xFF006CAD);
  static const jpmcGold = Color(0xFFC8872A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSession({required bool isChatMode}) async {
    setState(() => _isFetchingToken = true);
    try {
      final tokenResult = await ConversationService().getVoiceToken(
        widget.stageBucket,
        prospectId: widget.prospectId,
      );
      
      final vars = Map<String, dynamic>.from(widget.dynamicVariables);
      vars.addAll(tokenResult.dynamicVariables);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoicePage(
            conversationToken: tokenResult.conversationToken,
            stageBucket: widget.stageBucket,
            prospectId: widget.prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
            initialMode: isChatMode ? 'chat' : 'voice',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start session: $e')),
      );
      setState(() => _isFetchingToken = false);
    }
  }

  void _goToManualForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualFormPage(
          stageBucket: widget.stageBucket,
          prospectId: widget.prospectId,
          dynamicVariables: widget.dynamicVariables,
          onStartNew: widget.onStartNew,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1556761175-b413da4baf72?q=80&w=2000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 640;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Container(
                      width: isMobile ? double.infinity : 840,
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0 : 24,
                        vertical: isMobile ? 0 : 32,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
                        boxShadow: isMobile ? null : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 48,
                            offset: const Offset(0, 16),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header bar ──────────────────────────────────
                          _buildTopHeader(context, isDark, textTheme),
                          _buildStepHeader(context, isDark, textTheme),

                          // ── Body ────────────────────────────────────────
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 24 : 36,
                              16,
                              isMobile ? 24 : 36,
                              32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Central Pulse Button
                                if (_isFetchingToken)
                                  const SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: CircularProgressIndicator(color: jpmcBlue),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => _startSession(isChatMode: false),
                                    behavior: HitTestBehavior.opaque,
                                    child: SizedBox(
                                      height: 180,
                                      width: 180,
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Outer rings
                                              for (int i = 0; i < 3; i++)
                                                Container(
                                                  width: 60 + (120 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                                                  height: 60 + (120 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: jpmcGold.withOpacity(0.4 * (1.0 - ((_pulseAnimation.value + (i * 0.33)) % 1.0))),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              // Inner button
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: jpmcNavy,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: jpmcNavy.withOpacity(0.3),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    )
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.graphic_eq_rounded,
                                                  color: jpmcGold,
                                                  size: 28,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to start conversation',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : jpmcNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '~10 min · Nova asks, you answer',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                // Checkbox for Manual form
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C261A) : const Color(0xFFFDF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF423C2B) : const Color(0xFFF0E6C5)),
                                  ),
                                  child: _buildCheckbox(
                                    _preferManual,
                                    (val) => setState(() => _preferManual = val ?? false),
                                    'I prefer to fill in the form manually — I understand this may result in slower matching and less tailored recommendations',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Footer row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _preferManual ? _goToManualForm : null,
                                      icon: Icon(
                                        Icons.description_outlined,
                                        size: 18,
                                        color: _preferManual ? jpmcBlue : Colors.grey,
                                      ),
                                      label: const Text(
                                        'Fill Manual Form',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        foregroundColor: jpmcBlue,
                                        disabledForegroundColor: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 22),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 12,
                                          width: 1,
                                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            'OR',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 12,
                                          width: 1,
                                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 32),
                                    ElevatedButton(
                                      onPressed: _isFetchingToken ? null : () => _startSession(isChatMode: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: jpmcGold,
                                        foregroundColor: jpmcNavy,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                      ),
                                      child: const Text(
                                        "Let's Chat",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 20),
      decoration: const BoxDecoration(
        color: jpmcNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: jpmcGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: jpmcGold.withOpacity(0.3)),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFFD4AD46), size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova — Your JPMC AI Advisor',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFD4AD46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Gets to know your company, then connects you to the right banking team and resources.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT WE\'LL COVER',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: jpmcGold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildCoverItem(context, isDark, textTheme, 'Your startup stage, business model, and key priorities'),
          _buildCoverItem(context, isDark, textTheme, 'Banking, payments, treasury, and credit options for your stage'),
          _buildCoverItem(context, isDark, textTheme, 'Personalised JPMC product recommendations and next steps'),
        ],
      ),
    );
  }

  Widget _buildCoverItem(BuildContext context, bool isDark, TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: jpmcGold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
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
    );
  }

  Widget _buildCheckbox(bool value, ValueChanged<bool?> onChanged, String label, bool isDark) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? jpmcBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value ? jpmcBlue : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

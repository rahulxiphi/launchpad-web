import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';
import 'manual_form_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../theme/app_theme.dart';

class ModeSelectionPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  final Future<void> Function() onStartNew;
  final Future<void> Function() onGoToRelationshipHub;

  const ModeSelectionPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
    required this.onGoToRelationshipHub,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage>
    with SingleTickerProviderStateMixin {
  bool _isFetchingToken = false;
  bool _preferManual = false;
  bool _isVoiceTriggerHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isReturnVisit => widget.dynamicVariables['is_return_visit'] == true;

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

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _startSession({required bool isChatMode}) async {
    setState(() => _isFetchingToken = true);
    try {
      final tokenResult = await ConversationService().getVoiceToken(
        widget.stageBucket,
        prospectId: widget.prospectId ?? ProspectIdProvider.of(context),
      );

      final vars = Map<String, dynamic>.from(widget.dynamicVariables);
      vars.addAll(tokenResult.dynamicVariables);
      vars['initial_mode'] = isChatMode ? 'chat' : 'voice';

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        NoTransitionPageRoute(
          builder: (_) => VoicePage(
            conversationToken: tokenResult.conversationToken,
            stageBucket: widget.stageBucket,
            prospectId: widget.prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
            onGoToRelationshipHub: widget.onGoToRelationshipHub,
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
      NoTransitionPageRoute(
        builder: (_) => ManualFormPage(
          stageBucket: widget.stageBucket,
          prospectId: widget.prospectId ?? ProspectIdProvider.of(context),
          dynamicVariables: widget.dynamicVariables,
          onStartNew: widget.onStartNew,
          onGoToRelationshipHub: widget.onGoToRelationshipHub,
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
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Container(
                        width: isMobile ? double.infinity : 840,
                        height: isMobile ? null : 680.0,
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 0 : 24,
                          vertical: isMobile ? 0 : 32,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(isMobile ? 0 : 20),
                          boxShadow: isMobile
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.22),
                                    blurRadius: 48,
                                    offset: const Offset(0, 16),
                                  )
                                ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // ── Header bar ──────────────────────────────────
                          _buildTopHeader(context, isDark, textTheme),
                          _buildStepHeader(context, isDark, textTheme),

                          // ── Body ────────────────────────────────────────
                          Expanded(
                            child: SingleChildScrollView(
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
                                      child: CircularProgressIndicator(
                                          color: AppThemeTokens.buttonPrimary),
                                    ),
                                  )
                                else
                                  MouseRegion(
                                    cursor: _isFetchingToken
                                        ? SystemMouseCursors.basic
                                        : SystemMouseCursors.click,
                                    onEnter: (_) => setState(
                                        () => _isVoiceTriggerHovered = true),
                                    onExit: (_) => setState(
                                        () => _isVoiceTriggerHovered = false),
                                    child: GestureDetector(
                                      onTap: _isFetchingToken
                                          ? null
                                          : () =>
                                              _startSession(isChatMode: false),
                                      behavior: HitTestBehavior.opaque,
                                      child: SizedBox(
                                        height: 180,
                                        width: 180,
                                        child: AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (context, child) {
                                            final triggerColor =
                                                _isVoiceTriggerHovered
                                                    ? AppThemeTokens
                                                        .buttonPrimaryHover
                                                    : AppThemeTokens
                                                        .buttonPrimary;
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                for (int i = 0; i < 3; i++)
                                                  Container(
                                                    width: 104 +
                                                        (92 *
                                                            ((_pulseAnimation
                                                                        .value +
                                                                    (i *
                                                                        0.33)) %
                                                                1.0)),
                                                    height: 104 +
                                                        (92 *
                                                            ((_pulseAnimation
                                                                        .value +
                                                                    (i *
                                                                        0.33)) %
                                                                1.0)),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppThemeTokens
                                                            .buttonPrimary
                                                            .withOpacity(0.35 *
                                                                (1.0 -
                                                                    ((_pulseAnimation.value +
                                                                            (i * 0.33)) %
                                                                        1.0))),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 140),
                                                  width: 104,
                                                  height: 104,
                                                  decoration: BoxDecoration(
                                                    color: triggerColor,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: triggerColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4),
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.graphic_eq_rounded,
                                                    color: Colors.white,
                                                    size: 46,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  _isReturnVisit
                                      ? 'Tap the Orb to continue conversation'
                                      : 'Tap the Orb to start conversation',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppThemeTokens.brandInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isReturnVisit
                                      ? 'Continue where Nova left off'
                                      : '~10 min · Nova asks, you answer',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Checkbox for Manual form
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2C261A)
                                        : const Color(0xFFFDF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF423C2B)
                                            : const Color(0xFFF0E6C5)),
                                  ),
                                  child: _buildCheckbox(
                                    _preferManual,
                                    (val) => setState(
                                        () => _preferManual = val ?? false),
                                    'I prefer to fill in the form manually — I understand this may result in slower matching and less tailored recommendations',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Footer row
                                SizedBox(
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child:
                                            _buildBottomBackButton(context),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton.icon(
                                            onPressed: _preferManual
                                                ? _goToManualForm
                                                : null,
                                            icon: Icon(
                                              Icons.description_outlined,
                                              size: 18,
                                              color: _preferManual
                                                  ? AppThemeTokens
                                                      .buttonPrimary
                                                  : Colors.grey,
                                            ),
                                            label: const Text(
                                              'Fill Manual Form',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 14),
                                              foregroundColor:
                                                  AppThemeTokens
                                                      .buttonPrimary,
                                              disabledForegroundColor:
                                                  Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 22),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 12,
                                                width: 1,
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.grey.shade300,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: Text(
                                                  'OR',
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey.shade500,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 10,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 12,
                                                width: 1,
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.grey.shade300,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 32),
                                          ElevatedButton(
                                            onPressed: _isFetchingToken
                                                ? null
                                                : () => _startSession(
                                                    isChatMode: true),
                                            style: Theme.of(context)
                                                .elevatedButtonTheme
                                                .style
                                                ?.copyWith(
                                                  padding:
                                                      WidgetStateProperty.all(
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 18),
                                                  ),
                                                  shape:
                                                      WidgetStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(13),
                                                    ),
                                                  ),
                                                ),
                                            child: Text(
                                              _isReturnVisit
                                                  ? 'Continue Chat'
                                                  : "Let's Chat",
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold),
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
                          ],
                        ),
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

  Widget _buildTopHeader(
      BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 20),
      decoration: const BoxDecoration(
        color: AppThemeTokens.modalHeader,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          _buildHeaderAiBadge(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova — Your JPMC AI Advisor',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppThemeTokens.goldAccent,
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

  Widget _buildHeaderAiBadge() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.22),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBottomBackButton(BuildContext context) {
    return TextButton(
      onPressed: _handleBack,
      child: const Icon(Icons.chevron_left_rounded, size: 22),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4B5563),
        backgroundColor: const Color(0xFFF3F4F6),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFD1D5DB),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(
      BuildContext context, bool isDark, TextTheme textTheme) {
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
              color: AppThemeTokens.goldAccent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildCoverItem(context, isDark, textTheme,
              'Your startup stage, business model, and key priorities'),
          _buildCoverItem(context, isDark, textTheme,
              'Banking, payments, treasury, and credit options for your stage'),
          _buildCoverItem(context, isDark, textTheme,
              'Personalised JPMC product recommendations and next steps'),
        ],
      ),
    );
  }

  Widget _buildCoverItem(
      BuildContext context, bool isDark, TextTheme textTheme, String text) {
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
              color: Colors.white,
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

  Widget _buildCheckbox(
      bool value, ValueChanged<bool?> onChanged, String label, bool isDark) {
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
              color: value ? AppThemeTokens.buttonPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value
                    ? AppThemeTokens.buttonPrimary
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
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

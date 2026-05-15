import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';
import 'manual_form_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/prospect_id_provider.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

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

                Widget buildContent(double? bodyHeight) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80), // Balanced spacing
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
                      
                      const SizedBox(height: 12),
                      _buildOrSeparator(isDark),
                      const SizedBox(height: 12),

                      // Continue Chat Button
                      SizedBox(
                        width: 280,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isFetchingToken
                              ? null
                              : () => _startSession(isChatMode: true),
                          style: Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.copyWith(
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                      horizontal: 48, vertical: 18),
                                ),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                          child: Text(
                            _isReturnVisit
                                ? 'Continue Chat'
                                : "Let's Chat",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOrSeparator(isDark),
                    ],
                  );
                }

                return Center(
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
                    child: isMobile
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildTopHeader(context, isDark, textTheme),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: buildContent(null),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: _buildBottomBackButton(context),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopHeader(context, isDark, textTheme),
                              Expanded(
                                child: Center(
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.zero,
                                      child: buildContent(null),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: _buildBottomBackButton(context),
                                    ),
                                    TextButton.icon(
                                      onPressed: _isFetchingToken ? null : _goToManualForm,
                                      icon: const Icon(Icons.description_outlined, size: 18),
                                      label: const Text(
                                        'Fill Manual Form',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppThemeTokens.buttonPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                  style: const TextStyle(
                    color: AppThemeTokens.goldAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nova will get to know your startup — stage, priorities, and financial needs — and route you to the right specialist',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.22),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 22,
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

  Widget _buildOrSeparator(bool isDark) {
    final color = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    return SizedBox(
      width: 200, // Shorter lines
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: color)),
        ],
      ),
    );
  }
}

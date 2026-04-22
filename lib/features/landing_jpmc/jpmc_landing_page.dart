import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import '../../shared/widgets/app_shell.dart';

class JpmcLandingPage extends StatefulWidget {
  final String? invitationCode;
  final String? returnProspectId;

  const JpmcLandingPage({
    super.key,
    this.invitationCode,
    this.returnProspectId,
  });

  @override
  State<JpmcLandingPage> createState() => _JpmcLandingPageState();
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _JpmcLandingPageState extends State<JpmcLandingPage> {
  final _service = ConversationService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.returnProspectId != null) {
      _handleReturnVisit(widget.returnProspectId!);
    } else if (widget.invitationCode != null) {
      _handleInviteCode(widget.invitationCode!);
    }
  }

  Future<void> _handleReturnVisit(String prospectId) async {
    setState(() => _isLoading = true);
    try {
      final prospect = await _service.getProspect(prospectId);
      final tokenResult = await _service.getVoiceToken(
        prospect.stageBucket,
        prospectId: prospectId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AppShell(
          conversationToken: tokenResult.conversationToken,
          stageBucket: prospect.stageBucket,
          prospectId: prospectId,
          dynamicVariables: tokenResult.dynamicVariables,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not resume session.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleInviteCode(String invitationCode) async {
    setState(() => _isLoading = true);
    try {
      final initResult = await _service.initProspect(invitationCode);
      final tokenResult = await _service.getVoiceToken(
        initResult.stageBucket,
        prospectId: initResult.prospectId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AppShell(
          conversationToken: tokenResult.conversationToken,
          stageBucket: initResult.stageBucket,
          prospectId: initResult.prospectId,
          dynamicVariables: tokenResult.dynamicVariables,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Invalid link.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const stageBucket = 'super_agent';
      final prospectId = await _service.createProspect(stageBucket);
      final result = await _service.getVoiceToken(
        stageBucket,
        prospectId: prospectId,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppShell(
            conversationToken: result.conversationToken,
            stageBucket: stageBucket,
            prospectId: prospectId,
            dynamicVariables: result.dynamicVariables,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to start session: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0A2744);
    const gold = Color(0xFFC8872A);
    const textGray = Color(0xFF6B6B6B);
    const lpIndigo = Color(0xFF4F46E5);
    const lpIndigoDk = Color(0xFF3730A3);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFF1E1B4B),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    '🔵 Demo mockup — LaunchPad simulation${isMobile ? '' : ' of the J.P. Morgan startups page.'}',
                    style: const TextStyle(
                      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                      fontSize: 12,
                      color: Color(0xD9C8CDFF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  height: 104,
                  child: Container(
                    color: navy,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontFamily: 'Georgia, serif', fontSize: 22, color: Colors.white, letterSpacing: 0.5),
                                  children: [
                                    TextSpan(text: 'J.P. '),
                                    TextSpan(text: 'Morgan', style: TextStyle(color: gold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (!isMobile) ...[
                                    _navLink('Commercial Banking'),
                                    if (isDesktop) ...[
                                      _navLink('Solutions'),
                                      _navLink('Industries'),
                                      _navLink('Insights'),
                                      _navLink('About Us'),
                                    ],
                                    const SizedBox(width: 16),
                                  ],
                                  ElevatedButton(
                                    onPressed: _startSession,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006CAD),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      elevation: 0,
                                    ),
                                    child: const Text('GET IN TOUCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.9)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(height: 1, color: Colors.white.withOpacity(0.08)),
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: () {
                                  final allSubItems = [
                                    'Overview',
                                    'Startups',
                                    'Growth Companies',
                                    'Industries',
                                    'Chase Connect®',
                                    'Startup Offers'
                                  ];
                                  
                                  int visibleCount = isMobile ? 2 : (isTablet ? 4 : 6);
                                  List<Widget> subNavWidgets = [];
                                  
                                  for (int i = 0; i < visibleCount; i++) {
                                    subNavWidgets.add(_subNavLink(allSubItems[i], isActive: allSubItems[i] == 'Startups'));
                                  }
                                  
                                  if (visibleCount < allSubItems.length) {
                                    subNavWidgets.add(
                                      Theme(
                                        data: Theme.of(context).copyWith(
                                          popupMenuTheme: const PopupMenuThemeData(
                                            color: Color(0xFF0F3460), 
                                          ),
                                        ),
                                        child: PopupMenuButton<String>(
                                          offset: const Offset(0, 40),
                                          child: _subNavLink('More', hasDropdown: true),
                                          itemBuilder: (BuildContext context) {
                                            return allSubItems.skip(visibleCount).map((String choice) {
                                              return PopupMenuItem<String>(
                                                value: choice,
                                                height: 40,
                                                child: Text(choice, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      )
                                    );
                                  }
                                  return subNavWidgets;
                                }(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // Hero Section
                      Container(
                        padding: EdgeInsets.only(top: isMobile ? 48 : 88, bottom: isMobile ? 48 : 64, left: isMobile ? 24 : 40, right: isMobile ? 24 : 40),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [navy, Color(0xFF0F3460)],
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('INNOVATION ECONOMY BANKING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.2, color: gold)),
                                  const SizedBox(height: 18),
                                  Text('Banking the Innovation\nEconomy', style: TextStyle(fontFamily: 'Georgia, serif', fontSize: isMobile ? 38 : 52, fontWeight: FontWeight.w400, color: Colors.white, height: 1.12)),
                                  const SizedBox(height: 22),
                                  Text('Streamlined financial solutions and expert guidance to support your\nstartup from seed to IPO and beyond.', style: TextStyle(fontSize: isMobile ? 15 : 17, color: const Color(0xB7FFFFFF), height: 1.7)),
                                  const SizedBox(height: 38),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _startSession,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF006CAD),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                                          elevation: 0,
                                        ),
                                        child: const Text('GET IN TOUCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                                        ),
                                        child: const Text('OUR SOLUTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Stats Bar
                      Container(
                        color: const Color(0xFF081E36),
                        padding: EdgeInsets.symmetric(vertical: 30, horizontal: isMobile ? 24 : 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: isMobile
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _statItemResponsive('11K', 'Innovation economy banking clients globally'),
                                        _statItemResponsive('40+', 'Countries where we support innovative companies'),
                                        _statItemResponsive('550+', 'Innovation economy bankers globally'),
                                        _statItemResponsive('\$18B', 'Invested in technology'),
                                      ],
                                    )
                                  : isTablet
                                    ? Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _statItem('11K', 'Innovation economy banking clients globally', isLast: false)),
                                              Expanded(child: _statItem('40+', 'Countries where we support innovative companies', isLast: true)),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(child: _statItem('550+', 'Innovation economy bankers globally', isLast: false)),
                                              Expanded(child: _statItem('\$18B', 'Invested in technology', isLast: true)),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: _statItem('11K', 'Innovation economy banking clients globally', isLast: false)),
                                          Expanded(child: _statItem('40+', 'Countries where we support innovative companies', isLast: false)),
                                          Expanded(child: _statItem('550+', 'Innovation economy bankers globally', isLast: false)),
                                          Expanded(child: _statItem('\$18B', 'Invested in technology', isLast: true)),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),

                      // Solutions Grid Section
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 48 : 72, horizontal: isMobile ? 24 : 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('BANKING SOLUTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0xFF006CAD))),
                                  const SizedBox(height: 12),
                                  Text('Banking solutions to match your scale and needs', style: TextStyle(fontFamily: 'Georgia, serif', fontSize: isMobile ? 26 : 34, fontWeight: FontWeight.w400, color: navy)),
                                  const SizedBox(height: 16),
                                  Text('Our products help you reduce costs, save time and make more\ninformed decisions — so you can focus on growing your business.', style: TextStyle(fontSize: 16, color: textGray, height: 1.65)),
                                  const SizedBox(height: 48),
                                  
                                  // Responsive Cards Building
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFDDE1E6)),
                                      color: const Color(0xFFDDE1E6),
                                    ),
                                    child: isDesktop 
                                        ? IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(child: _buildSolCard1(isLast: false)),
                                                Expanded(child: _buildSolCard2(isLast: false)),
                                                Expanded(child: _buildSolCard3(isLast: false)),
                                                Expanded(child: _buildSolCard4(isLast: true)),
                                              ],
                                            ))
                                        : isTablet
                                            ? Column(
                                                children: [
                                                  IntrinsicHeight(
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Expanded(child: _buildSolCard1(isLast: false, isBottom: false)),
                                                        Expanded(child: _buildSolCard2(isLast: true, isBottom: false)),
                                                      ],
                                                    ),
                                                  ),
                                                  IntrinsicHeight(
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Expanded(child: _buildSolCard3(isLast: false)),
                                                        Expanded(child: _buildSolCard4(isLast: true)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  _buildSolCard1(isLast: true, isBottom: false),
                                                  _buildSolCard2(isLast: true, isBottom: false),
                                                  _buildSolCard3(isLast: true, isBottom: false),
                                                  _buildSolCard4(isLast: true, isBottom: true),
                                                ],
                                              )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Stages Section
                      Container(
                        color: const Color(0xFFF4F6F8),
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 48 : 72, horizontal: isMobile ? 24 : 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('YOUR STAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0xFF006CAD))),
                                  const SizedBox(height: 12),
                                  Text('Expertise supporting your growth at every stage', style: TextStyle(fontFamily: 'Georgia, serif', fontSize: isMobile ? 26 : 34, fontWeight: FontWeight.w400, color: navy)),
                                  const SizedBox(height: 48),

                                  // Stage Tabs
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFDDE1E6), width: 2))),
                                      child: Row(
                                        children: [
                                          _stageTab('Early Stage', isActive: true),
                                          _stageTab('Growth Stage'),
                                          _stageTab('Late Stage'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),

                                  // Stage Content
                                  Flex(
                                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                                    crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: isMobile ? 0 : 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('From pre-seed to seed', style: TextStyle(fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: FontWeight.w400, color: navy)),
                                            const SizedBox(height: 16),
                                            const Text('We offer comprehensive support including operating accounts, liquidity management, card and merchant processing, cap table management, Startup Offers, and financing alternatives to help you grow.', style: TextStyle(fontSize: 15, color: textGray, height: 1.72)),
                                            const SizedBox(height: 28),
                                            ElevatedButton(
                                              onPressed: _startSession,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF006CAD),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                                elevation: 0,
                                              ),
                                              child: const Text('EARLY STAGE STARTUPS →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 48 : 0, width: isMobile ? 0 : 64),
                                      Expanded(
                                        flex: isMobile ? 0 : 1,
                                        child: Container(
                                          height: 260,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navy, Color(0xFF1A4A7A)]),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Center(child: Text('🌱', style: TextStyle(fontSize: 80))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // LaunchPad CTA Band
                      Container(
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 48 : 80, horizontal: isMobile ? 24 : 40),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [lpIndigo, lpIndigoDk],
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: Flex(
                                direction: isMobile || isTablet ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: isMobile || isTablet ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: isMobile || isTablet ? 0 : 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.13),
                                            border: Border.all(color: Colors.white.withOpacity(0.22)),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle)),
                                              const SizedBox(width: 8),
                                              Text('NEW · PARTNER PROGRAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), letterSpacing: 1.2))
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        Text('Meet LaunchPad — your startup intelligence partner', style: TextStyle(fontFamily: 'Georgia, serif', fontSize: isMobile ? 28 : 40, color: Colors.white, height: 1.18)),
                                        const SizedBox(height: 18),
                                        Text('We\'ve partnered with LaunchPad to give J.P. Morgan startup clients access to a personalised AI advisor that understands your business and maps your needs to exactly the right financial products — no forms, no waiting.', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.72), height: 1.68)),
                                        const SizedBox(height: 28),
                                        _lpBullet('Voice + text AI that adapts to your startup\'s stage and goals'),
                                        _lpBullet('Instant matching to relevant J.P. Morgan products and services'),
                                        _lpBullet('Direct handoff to a J.P. Morgan advisor when you\'re ready to move forward'),
                                        _lpBullet('Private learn hub: webinars, 1:1 sessions, and personalised resources'),
                                        const SizedBox(height: 32),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            Text('POWERED BY', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 0.8)),
                                            _lpChip('LaunchPad'),
                                            Text('×', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.2))),
                                            _lpChip('J.P. Morgan'),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isMobile || isTablet ? 48 : 0, width: isMobile || isTablet ? 0 : 64),
                                  Expanded(
                                    flex: isMobile || isTablet ? 0 : 1,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(isMobile ? 0 : 16),
                                      child: Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: _startSession,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: lpIndigo,
                                              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 32),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              elevation: 10,
                                              minimumSize: const Size(double.infinity, 50),
                                            ),
                                            child: const Text('Get Started with LaunchPad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Free for J.P. Morgan startup clients', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                                          const SizedBox(height: 20),
                                          Text('You\'ll be redirected to LaunchPad with your J.P. Morgan partnership credentials pre-applied.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer
                      Container(
                        color: navy,
                        padding: EdgeInsets.only(top: 52, bottom: 24, left: isMobile ? 24 : 40, right: isMobile ? 24 : 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Column(
                              children: [
                                Wrap(
                                  spacing: 48,
                                  runSpacing: 48,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  children: [
                                    _footerCol('SOLUTIONS', ['Commercial Banking', 'Credit & Financing', 'Investment Banking', 'Payments', 'Asset Management']),
                                    _footerCol('STARTUPS', ['Early Stage Banking', 'Growth Stage Banking', 'Startup Offers', 'Cap Table Management', 'Sectors Served']),
                                    _footerCol('INSIGHTS', ['Innovation Economy Hub', 'Business Planning', 'Markets & Economy', 'Sustainability', 'H2 2025 Outlook']),
                                    _footerCol('COMPANY', ['About J.P. Morgan', 'Careers', 'Contact Us', 'Media Center', 'Investor Relations']),
                                  ],
                                ),
                                const SizedBox(height: 44),
                                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                                const SizedBox(height: 24),
                                Flex(
                                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                                  mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Text('© 2026 JPMorgan Chase & Co. All rights reserved.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                    ),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 20,
                                      runSpacing: 12,
                                      children: [
                                        Text('Privacy Policy', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                        Text('Terms of Use', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                        Text('Accessibility', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                        Text('Cookie Policy', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                        Text('Global Regulatory Disclosures', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Extracted card widgets to build easily
  Widget _buildSolCard1({required bool isLast, bool isBottom = true}) => _solutionCard(icon: '💳', iconColor: const Color(0xFFEBF4FF), title: 'Chase Connect®', points: ['Automate invoicing, manage cash flow and streamline reporting', 'Send wires in nearly 70 currencies', 'No fees for up to three years on included services'], isLast: isLast, isBottom: isBottom);
  Widget _buildSolCard2({required bool isLast, bool isBottom = true}) => _solutionCard(icon: '📲', iconColor: const Color(0xFFFFF4EB), title: 'Chase Cashflow360℠', points: ['2× faster payments with ACH vs. traditional check', 'Spend 50% less time paying and approving bills', 'Automatically sync with your accounting software'], isLast: isLast, isBottom: isBottom);
  Widget _buildSolCard3({required bool isLast, bool isBottom = true}) => _solutionCard(icon: '📈', iconColor: const Color(0xFFEDFAF1), title: 'Yield & Cash Management', points: ['Instant access to liquidity with no limit on deposits', 'No period trades, rollover or administration required', 'Integrated with treasury tools for efficient capital management'], isLast: isLast, isBottom: isBottom);
  Widget _buildSolCard4({required bool isLast, bool isBottom = true}) => _solutionCard(icon: '💰', iconColor: const Color(0xFFF3EBFF), title: 'Commercial Cards', points: ['Choose from physical and virtual cards', 'Enable spend for travel, procurement and more', '24/7 customer support and fraud protection'], isLast: isLast, isBottom: isBottom);


  Widget _navLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.75), letterSpacing: 0.2)),
    );
  }

  Widget _subNavLink(String text, {bool isActive = false, bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFC8872A) : Colors.transparent, width: 2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.white.withOpacity(0.65))),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white.withOpacity(0.65)),
          ]
        ]
      )
    );
  }

  Widget _statItemResponsive(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, letterSpacing: 1, color: Colors.white.withOpacity(0.45), height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _statItem(String number, String label, {required bool isLast}) {
    return Container(
      decoration: BoxDecoration(border: Border(right: BorderSide(color: isLast ? Colors.transparent : Colors.white.withOpacity(0.08)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -1)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 11, letterSpacing: 1, color: Colors.white.withOpacity(0.45), height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _stageTab(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFC8872A) : Colors.transparent, width: 2))),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0A2744) : const Color(0xFF6B6B6B))),
    );
  }

  Widget _solutionCard({required String icon, required Color iconColor, required String title, required List<String> points, required bool isLast, required bool isBottom}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFDDE1E6)),
          bottom: BorderSide(color: isBottom ? Colors.transparent : const Color(0xFFDDE1E6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle), alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 20))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A2744))),
          const SizedBox(height: 14),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF006CAD))),
                Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.5)))
              ]
            )
          )),
          const SizedBox(height: 24),
          const Text('LEARN MORE →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006CAD), letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _lpBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓', style: TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.82))))
        ],
      )
    );
  }

  Widget _lpChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
    );
  }

  Widget _footerCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.38))),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(link, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.58))),
        )),
      ]
    );
  }
}

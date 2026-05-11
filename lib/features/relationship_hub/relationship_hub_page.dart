import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:async';


import '../../services/conversation_service.dart';
import '../../theme/app_theme.dart';

class _GuideMessage {
  final bool isUser;
  final String text;
  final bool isMarkdown;

  const _GuideMessage({
    required this.isUser,
    required this.text,
    this.isMarkdown = false,
  });
}

class RelationshipHubPage extends StatefulWidget {
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;

  const RelationshipHubPage({
    super.key,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<RelationshipHubPage> createState() => _RelationshipHubPageState();
}

class _RelationshipHubPageState extends State<RelationshipHubPage> {
  final ConversationService _service = ConversationService();
  ProspectInitResult? _prospect;
  bool _loading = false;

  static const _defaultCompany = 'Launchpad';
  static const _defaultFounder = 'Aditya Kumar';

  @override
  void initState() {
    super.initState();
    _hydrateProspect();
  }

  Future<void> _hydrateProspect() async {
    if (widget.prospectId == null) return;
    setState(() => _loading = true);
    try {
      final prospect = await _service.getProspect(widget.prospectId!);
      if (!mounted) return;
      setState(() => _prospect = prospect);
    } catch (_) {
      if (!mounted) return;
      setState(() => _prospect = null);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _companyName =>
      _prospect?.companyName ??
      widget.dynamicVariables['companyName']?.toString() ??
      _defaultCompany;

  String get _founderName =>
      _prospect?.fullName ??
      widget.dynamicVariables['userName']?.toString() ??
      _defaultFounder;

  String get _userEmail =>
      _prospect?.email ??
      widget.dynamicVariables['userEmail']?.toString() ??
      '';

  String get _industry =>
      _prospect?.industry ??
      widget.dynamicVariables['industry']?.toString() ??
      'Innovation Economy';

  List<String> get _priorities {
    final selected = _prospect?.selectedPrioritiesJson ??
        (widget.dynamicVariables['selectedPriorities'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value == true)) ??
        const <String, bool>{};
    final enabled = selected.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    return enabled.isEmpty
        ? const [
            'Payments & operations',
            'Credit & lending',
            'International expansion',
          ]
        : enabled;
  }

  String get _stageLabel {
    const map = {
      'pre_seed': 'Pre-seed',
      'seed': 'Seed',
      'series_a': 'Series A',
      'series_b_plus': 'Series B+',
      'revenue_generating_no_vc': 'Revenue-generating, no VC',
    };
    final raw =
        _prospect?.companyStage ?? widget.dynamicVariables['stage']?.toString();
    return map[raw] ?? 'Founder workspace';
  }

  String get _initials {
    final source = _founderName.trim().isNotEmpty ? _founderName : _companyName;
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty
        ? 'AL'
        : parts.map((part) => part[0].toUpperCase()).join();
  }

  void _showProfileModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ProspectProfileModal(
        prospectId: widget.prospectId,
        founderName: _founderName,
        companyName: _companyName,
        initials: _initials,
        stageBucket: _prospect?.stageBucket,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1180;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Column(
          children: [
            _HubNavBar(
              companyName: _companyName,
              initials: _initials,
              founderName: _founderName,
              onProfileTap: () => _showProfileModal(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : isDesktop
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _NotificationsSection(),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      child: _HubMainColumn(
                                    companyName: _companyName,
                                    founderName: _founderName,
                                    industry: _industry,
                                    stageLabel: _stageLabel,
                                    priorities: _priorities,
                                    prospectId: widget.prospectId,
                                    email: _userEmail,
                                    onTapProduct: _showProductModal,
                                  )),
                                  SizedBox(
                                    width: 404,
                                    child: _AiGuidePanel(
                                      prospectId: widget.prospectId,
                                      founderName: _founderName,
                                      companyName: _companyName,
                                      industry: _industry,
                                      stageLabel: _stageLabel,
                                      priorities: _priorities,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _HubMainColumn(
                          companyName: _companyName,
                          founderName: _founderName,
                          industry: _industry,
                          stageLabel: _stageLabel,
                          priorities: _priorities,
                          prospectId: widget.prospectId,
                          email: _userEmail,
                          trailingPanel: _AiGuidePanel(
                            prospectId: widget.prospectId,
                            founderName: _founderName,
                            companyName: _companyName,
                            industry: _industry,
                            stageLabel: _stageLabel,
                            priorities: _priorities,
                          ),
                          onTapProduct: _showProductModal,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubNavBar extends StatelessWidget {
  final String companyName;
  final String founderName;
  final String initials;
  final VoidCallback? onProfileTap;

  const _HubNavBar({
    required this.companyName,
    required this.founderName,
    required this.initials,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AppThemeTokens.modalHeader,
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppThemeTokens.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'JPMorgan '),
                TextSpan(
                  text: 'Innovation Economy',
                  style: TextStyle(color: AppThemeTokens.goldAccent),
                ),
              ],
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: const [
              _NavPill(label: 'Hub', active: true),
              _NavPill(label: 'My profile'),
              _NavPill(label: 'Events'),
              _NavPill(label: 'Resources'),
            ],
          ),
          const Spacer(),
          _NavbarNotificationIcon(),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onProfileTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF223A56),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFB99C4C), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppThemeTokens.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            companyName.isNotEmpty && companyName != 'Launchpad'
                ? companyName
                : founderName.split(' ').first,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final bool active;

  const _NavPill({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF28486C) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFFB6C2D2),
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final List<bool> _visibleCards = [true, true, true];

  void _dismissCard(int index) {
    setState(() {
      _visibleCards[index] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visibleCards.contains(true)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: Text(
            'NOTIFICATIONS',
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              color: Color(0xFF8D8578),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...() {
                final List<Widget> activeCards = [];
                if (_visibleCards[0]) {
                  activeCards.add(
                    Expanded(
                      child: _NotificationCard(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF7C5410),
                        iconBg: const Color(0xFFFBEAD5),
                        title: 'Meeting confirmed',
                        message:
                            'Intro call with Sarah on May 6 at 2:00 PM ET. Tap to prep.',
                        footer: 'Apr 28 · Click to prepare',
                        onDismiss: () => _dismissCard(0),
                      ),
                    ),
                  );
                }
                if (_visibleCards[1]) {
                  activeCards.add(
                    Expanded(
                      child: _NotificationCard(
                        icon: Icons.call_outlined,
                        iconColor: const Color(0xFF0F6E56),
                        iconBg: const Color(0xFFE1F5EE),
                        title: 'Call summary available',
                        message:
                            'Apr 29 call with Sarah. Topics, next steps, and new material added.',
                        footer: 'Apr 29 · Click to view',
                        onDismiss: () => _dismissCard(1),
                      ),
                    ),
                  );
                }
                if (_visibleCards[2]) {
                  activeCards.add(
                    Expanded(
                      child: _NotificationCard(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF5B55D9),
                        iconBg: const Color(0xFFEEEDFE),
                        title: 'New guide added by Sarah',
                        message:
                            'Preparing for your first credit facility, based on your call.',
                        footer: 'Apr 29 · In your learning path',
                        onDismiss: () => _dismissCard(2),
                      ),
                    ),
                  );
                }

                while (activeCards.length < 3) {
                  activeCards.add(const Expanded(child: SizedBox.shrink()));
                }

                final List<Widget> finalRow = [];
                for (int i = 0; i < activeCards.length; i++) {
                  finalRow.add(activeCards[i]);
                  if (i < activeCards.length - 1) {
                    finalRow.add(const SizedBox(width: 12));
                  }
                }
                return finalRow;
              }(),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE7DCC8)),
      ],
    );
  }
}

class _HubMainColumn extends StatelessWidget {
  final String companyName;
  final String founderName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;
  final String? prospectId;
  final String email;
  final Widget? trailingPanel;
  final void Function(BuildContext context, String title, String description, IconData icon, Color tint, Color iconColor)? onTapProduct;

  const _HubMainColumn({
    required this.companyName,
    required this.founderName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    this.prospectId,
    this.email = '',
    this.trailingPanel,
    this.onTapProduct,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On mobile, show notifications inside the scroll view
          if (trailingPanel != null) const _NotificationsSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your banker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Georgia',
                        color: AppThemeTokens.modalHeader,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppThemeTokens.modalHeader,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF213E5B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF314C68)),
                                ),
                                child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppThemeTokens.goldAccent,
                                    size: 18),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'UPCOMING MEETING',
                                      style: TextStyle(
                                        color: AppThemeTokens.goldAccent,
                                        fontSize: 10,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Intro call with Sarah Chen',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tuesday, May 6 · 2:00 PM ET · 30 min',
                                      style: TextStyle(
                                        color: Color(0xFFB8C3D1),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE2E8F0),
                                  side: const BorderSide(
                                      color: Color(0xFF3E5B79)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(999)),
                                ),
                                child: const Text('Add to calendar'),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppThemeTokens.goldAccent,
                                  foregroundColor: AppThemeTokens.modalHeader,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(999)),
                                ),
                                child: const Text('Prep for call'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 260,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE0D7C8)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        AppThemeTokens.modalHeader,
                                    child: Text(
                                      'SC',
                                      style: TextStyle(
                                        color: AppThemeTokens.goldAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sarah Chen',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Innovation Banking',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniActionButton(
                                      label: 'Contact',
                                      dark: true,
                                      icon: Icons.forum_outlined,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniActionButton(
                                      label: 'Schedule',
                                      dark: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
            child: Row(
              children: [
                Text(
                  'SHARED DOCUMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppThemeTokens.modalHeader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const _AddDocChip(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _DocChip('Investor overview deck.pdf', 'Shared'),
                _DocChip('Product one-pager.docx', 'Needs review'),
                _DocChip('Financial statements Q1.xlsx', 'Requested'),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore what's available to you",
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Georgia',
                            color: AppThemeTokens.modalHeader,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Products relevant to your stage${stageLabel.isNotEmpty ? ' — $stageLabel' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F675B),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 320,
                  child: _ProductCard(
                    icon: Icons.account_balance_wallet_outlined,
                    tint: const Color(0xFF1A7B99),
                    iconColor: AppThemeTokens.buttonPrimary,
                    title: 'Business checking & operating accounts',
                    description:
                        'Accounts built for startups — multi-user access, sweep options, and no minimum balance.',
                    cta: 'Learn more',
                    onTap: () => onTapProduct?.call(context, 'Business checking & operating accounts',
                        'Accounts built for startups — multi-user access, sweep options, and no minimum balance. Ideal for separating operating cash, reserves, and payroll across multiple entities.',
                        Icons.account_balance_wallet_outlined, const Color(0xFF1A7B99), AppThemeTokens.buttonPrimary),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _ProductCard(
                    icon: Icons.monitor_heart_outlined,
                    tint: const Color(0xFF1D9E75),
                    iconColor: const Color(0xFF1D9E75),
                    title: 'Treasury & cash management',
                    description:
                        'Automated sweep structures, money market access, and yield optimization tuned for your operating rhythm.',
                    cta: 'Learn more',
                    onTap: () => onTapProduct?.call(context, 'Treasury & cash management',
                        'Automated sweep structures, money market access, and yield optimization. Maximize returns on idle cash with minimal operational overhead.',
                        Icons.monitor_heart_outlined, const Color(0xFF1D9E75), const Color(0xFF1D9E75)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _ProductCard(
                    icon: Icons.attach_money_rounded,
                    tint: const Color(0xFF996715),
                    iconColor: const Color(0xFF996715),
                    title: 'Venture debt & credit facilities',
                    description:
                        'Pre-approved borrowing for growth capital, bridge financing, and optionality before your next equity round.',
                    cta: 'Ask Sarah about this',
                    onTap: () => onTapProduct?.call(context, 'Venture debt & credit facilities',
                        'Pre-approved borrowing for growth capital, bridge financing, and optionality before your next equity round. Flexible terms tailored to your stage.',
                        Icons.attach_money_rounded, const Color(0xFF996715), const Color(0xFF996715)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _ProductCard(
                    icon: Icons.payments_outlined,
                    tint: const Color(0xFF7C3AED),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Payments & operations',
                    description:
                        'Vendor payments, payroll integration, and multi-currency operations for global-ready startups.',
                    cta: 'Learn more',
                    onTap: () => onTapProduct?.call(context, 'Payments & operations',
                        'Streamlined vendor payments, payroll integration, and multi-currency operations. Built for startups operating across borders.',
                        Icons.payments_outlined, const Color(0xFF7C3AED), const Color(0xFF7C3AED)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _ProductCard(
                    icon: Icons.public_outlined,
                    tint: const Color(0xFF0891B2),
                    iconColor: const Color(0xFF0891B2),
                    title: 'International expansion',
                    description:
                        'New market entry support, FX strategy, and cross-border payment infrastructure.',
                    cta: 'Learn more',
                    onTap: () => onTapProduct?.call(context, 'International expansion',
                        'New market entry support, FX strategy, and cross-border payment infrastructure. Navigate multi-currency operations with confidence.',
                        Icons.public_outlined, const Color(0xFF0891B2), const Color(0xFF0891B2)),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'Learning material',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: AppThemeTokens.modalHeader,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    _TinyBadge('New'),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Curated guides and events to support your next stage of growth.',
                  style: TextStyle(
                    color: Color(0xFF6F675B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisExtent: 140,
              children: [
                _LearningCard(
                  stripe: AppThemeTokens.goldAccent,
                  tag: 'Guide',
                  title: 'Setting up efficient banking early',
                  description:
                      'Shared by Sarah to help streamline your initial operations.',
                  meta: '8 min read · Seed · Operations',
                ),
                _LearningCard(
                  stripe: const Color(0xFF378ADD),
                  tag: 'Event',
                  title: 'Treasury habits that scale with you',
                  description:
                      'Added by Sarah based on your discussion about cash management.',
                  meta: 'May 7 · 1:00 PM ET · 45 min',
                ),
                _LearningCard(
                  stripe: const Color(0xFF1D9E75),
                  tag: 'Explainer',
                  title: 'How early-stage treasury accounts work',
                  description:
                      'A brief explainer shared by Sarah to clarify treasury basics.',
                  meta: '5 min read · Finance leads',
                ),
                _LearningCard(
                  stripe: const Color(0xFF7F77DD),
                  tag: 'Guide',
                  title: 'Preparing for your first credit facility',
                  description:
                      'Recommended reading by Sarah ahead of your Series A raise.',
                  meta: '10 min read · Series A · Capital structure',
                ),
              ],
            ),
          ),
          if (trailingPanel != null) ...[
            Container(height: 1, color: const Color(0xFFE7DCC8)),
            trailingPanel!,
          ],
        ],
      ),
    );
  }
}

class _AiGuidePanel extends StatefulWidget {
  final String? prospectId;
  final String founderName;
  final String companyName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;

  const _AiGuidePanel({
    this.prospectId,
    required this.founderName,
    required this.companyName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
  });

  @override
  State<_AiGuidePanel> createState() => _AiGuidePanelState();
}

class _AiGuidePanelState extends State<_AiGuidePanel> {
  final ConversationService _service = ConversationService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  bool _sending = false;
  late final List<_GuideMessage> _messages = [
    _GuideMessage(
      isUser: false,
      text:
          "I have context from ${widget.founderName}'s profile and the materials in ${widget.companyName}'s learning path. Ask me anything about the next meeting, Sarah's notes, or what matters most right now.",
    ),
  ];

  bool _viewingHistory = false;
  List<_GuideMessage> _historyMessages = [];
  bool _loadingHistory = false;
  bool _historyHasMore = false;
  int _historyEarliestId = 0;
  bool _hasHistory = false;

  @override
  void initState() {
    super.initState();
    _checkHistory();
  }

  Future<void> _checkHistory() async {
    if (widget.prospectId == null) return;
    try {
      final result = await _service.getChatHistory(
        widget.prospectId!,
        limit: 1,
      );
      if (!mounted) return;
      setState(() => _hasHistory = result.messages.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_GuideMessage(isUser: true, text: trimmed));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _service.sendRelationshipHubChat(
        trimmed,
        prospectId: widget.prospectId,
        context: {
          'founder_name': widget.founderName,
          'company_name': widget.companyName,
          'industry': widget.industry,
          'stage_label': widget.stageLabel,
          'priorities': widget.priorities,
        },
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          _GuideMessage(
            isUser: false,
            text: result.replyMarkdown,
            isMarkdown: true,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _GuideMessage(
            isUser: false,
            text:
                'I could not reach the guide right now. Please try again in a moment.',
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (_loadingHistory) return;
    if (loadMore && !_historyHasMore) return;

    setState(() => _loadingHistory = true);

    try {
      final result = await _service.getChatHistory(
        widget.prospectId!,
        limit: 30,
        beforeId: loadMore ? _historyEarliestId : 0,
      );

      if (!mounted) return;

      final newMessages = result.messages.map((m) {
        final isUser = m.type == 'human';
        return _GuideMessage(isUser: isUser, text: m.content);
      }).toList();

      if (loadMore) {
        _historyMessages = [...newMessages, ..._historyMessages];
      } else {
        _historyMessages = newMessages;
      }

      _historyHasMore = result.hasMore;
      _historyEarliestId = result.messages.isNotEmpty ? result.messages.first.id : 0;
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _openReturnLink() {
    final pid = widget.prospectId;
    if (pid == null) return;
    final uri = Uri.base;
    final url = uri.fragment.isNotEmpty
        ? '${uri.origin}/#/?p=$pid'
        : '${uri.origin}/?p=$pid';
    html.window.open(url, '_blank');
  }

  void _openHistory() {
    _loadHistory();
    setState(() => _viewingHistory = true);
  }

  void _closeHistory() {
    setState(() {
      _viewingHistory = false;
      _historyMessages = [];
      _historyEarliestId = 0;
      _historyHasMore = false;
    });
  }

  void _onHistoryScroll() {
    if (!_historyScrollController.hasClients || _loadingHistory || !_historyHasMore) return;
    if (_historyScrollController.offset <= 50) {
      _loadHistory(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _viewingHistory ? _buildHistoryBody() : _buildChatBody(),
          ),
          if (!_viewingHistory) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Row(
        children: [
          Icon(
            _viewingHistory ? Icons.history_rounded : Icons.auto_awesome_rounded,
            color: _viewingHistory ? const Color(0xFF6B7280) : AppThemeTokens.buttonPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _viewingHistory ? 'Chat History' : 'Nova',
            style: const TextStyle(
              color: AppThemeTokens.modalHeader,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_viewingHistory)
            GestureDetector(
              onTap: _closeHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 13, color: AppThemeTokens.buttonPrimary),
                    SizedBox(width: 5),
                    Text(
                      'Back to Chat',
                      style: TextStyle(
                        color: AppThemeTokens.buttonPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _openReturnLink,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppThemeTokens.modalHeader,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Talk to Nova',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(_messages.length, (i) {
              final msg = _messages[i];
              final isPrevSame = i > 0 && _messages[i - 1].isUser == msg.isUser;
              final isNextSame = i < _messages.length - 1 && _messages[i + 1].isUser == msg.isUser;
              return Padding(
                padding: EdgeInsets.only(top: isPrevSame ? 2 : 10, bottom: 1),
                child: _GuideMessageBubble(
                  message: msg,
                  isPrevSame: isPrevSame,
                  isNextSame: isNextSame,
                ),
              );
            }),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: _GuideTypingBubble(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBody() {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _onHistoryScroll();
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _historyScrollController,
          padding: const EdgeInsets.all(16),
          child: _historyMessages.isEmpty && _loadingHistory
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingHistory)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      ),
                    if (_historyMessages.isEmpty && !_loadingHistory)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No chat history yet.',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_historyMessages.length, (i) {
                        final msg = _historyMessages[i];
                        final isPrevSame = i > 0 && _historyMessages[i - 1].isUser == msg.isUser;
                        final isNextSame = i < _historyMessages.length - 1 && _historyMessages[i + 1].isUser == msg.isUser;
                        return Padding(
                          padding: EdgeInsets.only(top: isPrevSame ? 2 : 10, bottom: 1),
                          child: _GuideMessageBubble(
                            message: msg,
                            isPrevSame: isPrevSame,
                            isNextSame: isNextSame,
                          ),
                        );
                      }),
                    if (_historyHasMore && !_loadingHistory)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _loadHistory(loadMore: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFE1D9CB)),
                              ),
                              child: const Text(
                                'Load more',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCF9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFD1D5DB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your materials…',
                        hintStyle: TextStyle(color: Color(0xFF8D8578)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        final canSend =
                            !_sending && value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: canSend
                              ? () => _sendMessage(value.text)
                              : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? AppThemeTokens.modalHeader
                                  : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: canSend
                                  ? AppThemeTokens.goldAccent
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideMessageBubble extends StatelessWidget {
  final _GuideMessage message;
  final bool isPrevSame;
  final bool isNextSame;

  const _GuideMessageBubble({
    required this.message,
    this.isPrevSame = false,
    this.isNextSame = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    Widget avatar(Color bg, Widget child) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        );

    final aiAvatar = avatar(
      AppThemeTokens.modalHeader,
      const Text(
        'A',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppThemeTokens.goldAccent,
        ),
      ),
    );

    final userAvatar = avatar(
      const Color(0xFFE5E7EB),
      const Icon(Icons.person_rounded, size: 16, color: Color(0xFF6B7280)),
    );

    final bubbleContent = message.isMarkdown && !isUser
        ? MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              strong: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
              ),
              a: const TextStyle(
                color: AppThemeTokens.buttonPrimary,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w600,
              ),
              listBullet: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
              code: const TextStyle(
                fontSize: 12,
                color: AppThemeTokens.modalHeader,
                backgroundColor: Color(0xFFE5E7EB),
              ),
            ),
          )
        : Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              color: isUser ? Colors.white : const Color(0xFF1F2937),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          );

    // Grouped corner radii — same logic as VoiceBubbleRow
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? AppThemeTokens.buttonPrimary : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
          topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
          bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
          bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
        ),
      ),
      child: bubbleContent,
    );

    final estimatedLines =
        (message.text.length / 55).ceil() + '\n'.allMatches(message.text).length;
    final avatarAlign =
        estimatedLines <= 1 ? CrossAxisAlignment.center : CrossAxisAlignment.end;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: avatarAlign,
      children: isUser
          ? [
              Flexible(child: bubble),
              const SizedBox(width: 8),
              if (isNextSame) const SizedBox(width: 28) else userAvatar,
            ]
          : [
              if (isNextSame) const SizedBox(width: 28) else aiAvatar,
              const SizedBox(width: 8),
              Flexible(child: bubble),
            ],
    );
  }
}

class _GuideTypingBubble extends StatelessWidget {
  const _GuideTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppThemeTokens.modalHeader,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppThemeTokens.goldAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Thinking…',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final String footer;
  final VoidCallback? onDismiss;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.footer,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A7B99).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB6D4F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 14,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: '$title ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '— $message'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      footer,
                      style: const TextStyle(
                        color: Color(0xFF8D8578),
                        fontSize: 12,
                      ),
                    ),
                    if (onDismiss != null)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onDismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A7B99).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFF1A7B99).withValues(alpha: 0.2)),
                            ),
                            child: const Text(
                              'Mark as read',
                              style: TextStyle(
                                color: Color(0xFF1A7B99),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final bool dark;
  final IconData? icon;

  const _MiniActionButton({
    required this.label,
    required this.dark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? AppThemeTokens.modalHeader : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? AppThemeTokens.modalHeader : const Color(0xFFE1D9CB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 15, color: dark ? Colors.white : const Color(0xFF1F2937)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyLinkButton extends StatefulWidget {
  final String url;
  const _CopyLinkButton({required this.url});

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.url));
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF1D9E75).withOpacity(0.1)
              : AppThemeTokens.modalHeader.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _copied ? 'Copied' : 'Copy link',
          style: TextStyle(
            color: _copied ? const Color(0xFF1D9E75) : AppThemeTokens.modalHeader,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final String label;
  final String status;

  const _DocChip(this.label, this.status);

  @override
  Widget build(BuildContext context) {
    final isShared = status == 'Shared';
    final isReview = status == 'Needs review';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1D9CB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 16, color: Color(0xFF8D8578)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isShared
                  ? const Color(0xFFE1F5EE)
                  : isReview
                      ? const Color(0xFFFBEAD5)
                      : const Color(0xFFFBEAD5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: isShared
                    ? const Color(0xFF0F6E56)
                    : const Color(0xFF7C5410),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddDocChip extends StatelessWidget {
  const _AddDocChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1D9CB)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16, color: Color(0xFF1F2937)),
          SizedBox(width: 6),
          Text(
            'Add document',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;
  final String cta;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cta,
    this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 240,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isHovered ? AppThemeTokens.modalHeader : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? AppThemeTokens.modalHeader : const Color(0xFFE1D9CB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHovered ? Colors.white.withOpacity(0.12) : widget.tint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: _isHovered ? Colors.white : widget.iconColor, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isHovered ? Colors.white : const Color(0xFF1A1A18),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFF6F675B),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.cta} →',
                style: TextStyle(
                  color: _isHovered ? const Color(0xFF93C5FD) : AppThemeTokens.buttonPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatefulWidget {
  final Color stripe;
  final String tag;
  final String title;
  final String meta;
  final String? description;

  const _LearningCard({
    required this.stripe,
    required this.tag,
    required this.title,
    required this.meta,
    this.description,
  });

  @override
  State<_LearningCard> createState() => _LearningCardState();
}

class _LearningCardState extends State<_LearningCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isHovered ? const Color(0xFF1F2937) : const Color(0xFFE1D9CB)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: widget.stripe,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isHovered ? Colors.white.withOpacity(0.12) : const Color(0xFFFBEAD5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.tag,
                          style: TextStyle(
                            color: _isHovered ? Colors.white : const Color(0xFF7C5410),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _isHovered ? Colors.white : const Color(0xFF1A1A18),
                        ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFF6F675B),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        widget.meta,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isHovered ? const Color(0xFF9CA3AF) : const Color(0xFF8D8578),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _isHovered ? Colors.white70 : const Color(0xFF8D8578),
                    size: 22,
                  ),
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

class _TinyBadge extends StatelessWidget {
  final String text;

  const _TinyBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF0F6E56),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

  void _showProductModal(BuildContext context, String title, String description, IconData icon, Color tint, Color iconColor) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailModal(
        icon: icon,
        tint: tint,
        iconColor: iconColor,
        title: title,
        description: description,
      ),
    );
  }
// ─────────────────────────────────────────────────────────────────────────────
// Profile Modal
// ─────────────────────────────────────────────────────────────────────────────

class _ProspectProfileModal extends StatefulWidget {
  final String? prospectId;
  final String founderName;
  final String companyName;
  final String initials;
  final String? stageBucket;

  const _ProspectProfileModal({
    required this.prospectId,
    required this.founderName,
    required this.companyName,
    required this.initials,
    this.stageBucket,
  });

  @override
  State<_ProspectProfileModal> createState() => _ProspectProfileModalState();
}

class _ProspectProfileModalState extends State<_ProspectProfileModal> {
  final ConversationService _service = ConversationService();
  ProspectFullProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.prospectId == null) {
      setState(() {
        _loading = false;
        _error = 'No prospect ID available.';
      });
      return;
    }
    try {
      final profile = await _service.getProspectFullProfile(widget.prospectId!);
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load profile.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 840,
        height: 680,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                color: AppThemeTokens.modalHeader,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFB99C4C), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials,
                        style: const TextStyle(
                          color: AppThemeTokens.goldAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.founderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.companyName.isNotEmpty && widget.companyName != 'Launchpad') ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.companyName,
                              style: const TextStyle(
                                color: AppThemeTokens.goldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_loading && _profile != null && _profile!.aiAttributes.isEmpty) ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.prospectId != null) {
                            GoRouter.of(context).go('/?p=${Uri.encodeComponent(widget.prospectId!)}');
                          } else {
                            GoRouter.of(context).go('/');
                          }
                        },
                        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        child: const Text('Start Conversation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 14),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── Body ───────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppThemeTokens.buttonPrimary),
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                sliver: SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Builder(builder: (ctx) {
                                    final manualFormRows = [
                                      _buildRow('Industry', _profile!.industry),
                                      _buildRow('Stage', _profile!.companyStage),
                                      _buildRow('Headcount', _profile!.headcount),
                                      _buildRow(
                                          'Incorporated', _profile!.incorporated ? 'Yes' : 'No'),
                                      if (_profile!.selectedPrioritiesJson.isNotEmpty)
                                        _buildRow(
                                          'Priorities',
                                          _profile!.selectedPrioritiesJson.entries
                                              .where((e) => e.value)
                                              .map((e) => e.key)
                                              .join(', '),
                                        ),
                                    ];
                                    final hasManualFormRows =
                                        manualFormRows.any((r) => r != null);

                                    final firstFormRows = [
                                      _buildRow('Email', _profile!.email),
                                      _buildRow('Phone', _profile!.phoneNumber),
                                      _buildRow('Company', _profile!.companyName),
                                      _buildRow('Conversations',
                                          '${_profile!.conversationCount}'),
                                      if (_profile!.invitationCode != null)
                                        _buildRow('Invite code', _profile!.invitationCode),
                                    ];
                                    final hasFirstFormRows =
                                        firstFormRows.any((r) => r != null);

                                    final insightRows = _profile!.aiAttributes.isNotEmpty
                                        ? _profile!.aiAttributes.entries
                                            .map((e) => _buildRow(
                                                  e.key
                                                      .replaceAll('_', ' ')
                                                      .split(' ')
                                                      .map((w) => w.isEmpty
                                                          ? ''
                                                          : '${w[0].toUpperCase()}${w.substring(1)}')
                                                      .join(' '),
                                                  e.value?.toString(),
                                                ))
                                            .toList()
                                        : null;

                                    final companyLabel = widget.companyName.isNotEmpty
                                        ? '${widget.companyName.toUpperCase()} DETAILS'
                                        : 'COMPANY DETAILS';

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (hasManualFormRows)
                                                Expanded(
                                                  child:
                                                      _buildSection(companyLabel, manualFormRows),
                                                ),
                                              if (hasManualFormRows && hasFirstFormRows)
                                                const SizedBox(width: 32),
                                              if (hasFirstFormRows)
                                                Expanded(
                                                  child:
                                                      _buildSection('YOUR DETAILS', firstFormRows),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (insightRows != null && insightRows.isNotEmpty) ...[
                                          const SizedBox(height: 32),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24),
                                            child: _buildSentenceSection(
                                                'What We\'ve Collected', insightRows),
                                          ),
                                        ],
                                        const Spacer(),
                                        const SizedBox(height: 48),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: _buildSectionTitle('TEAM MEMBERS'),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 80,
                                          child: ListView.separated(
                                            padding: const EdgeInsets.symmetric(horizontal: 24),
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _mockTeam.length,
                                            separatorBuilder: (context, index) =>
                                                const SizedBox(width: 16),
                                            itemBuilder: (context, index) {
                                              return _TeamMemberCard(
                                                  member: _mockTeam[index]);
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  }),
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
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: Color(0xFF8D8578),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSectionSentenceTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }

  Widget _buildSentenceSection(String label, List<Widget?> rows) {
    final nonNullRows = rows.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionSentenceTitle(label),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7DCC8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: nonNullRows
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < nonNullRows.length - 1)
                          const Divider(height: 1, color: Color(0xFFEDE7DB), indent: 14, endIndent: 14),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String label, List<Widget?> rows) {
    final nonNullRows = rows.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7DCC8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: nonNullRows
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < nonNullRows.length - 1)
                          const Divider(height: 1, color: Color(0xFFEDE7DB), indent: 14, endIndent: 14),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget? _buildRow(String label, String? value) {
    if (value == null || value.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Detail Modal
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDetailModal extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;

  const _ProductDetailModal({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white.withOpacity(0.96),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                  color: AppThemeTokens.modalHeader,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // ── Body ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.auto_awesome, size: 18, color: AppThemeTokens.goldAccent),
                          label: const Text('Learn More', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _NavbarNotificationIcon extends StatefulWidget {
  const _NavbarNotificationIcon();

  @override
  State<_NavbarNotificationIcon> createState() => _NavbarNotificationIconState();
}

class _NavbarNotificationIconState extends State<_NavbarNotificationIcon> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  bool _isExpanded = false;
  Timer? _hideTimer;

  List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Sarah reviewed your guide',
      'time': '2 hours ago',
      'icon': Icons.description_outlined,
      'bg': const Color(0xFFEEEDFE),
      'iconColor': const Color(0xFF5B55D9)
    },
    {
      'title': 'New message from Alex',
      'time': '5 hours ago',
      'icon': Icons.message_outlined,
      'bg': const Color(0xFFE1F5EE),
      'iconColor': const Color(0xFF0F6E56)
    },
    {
      'title': 'Upcoming meeting: Q3 Review',
      'time': '1 day ago',
      'icon': Icons.calendar_today_rounded,
      'bg': const Color(0xFFFBEAD5),
      'iconColor': const Color(0xFF7C5410)
    },
  ];

  final List<Map<String, dynamic>> _extraNotifications = [
    {
      'title': 'New document shared: Pitch deck',
      'time': '2 days ago',
      'icon': Icons.file_present_rounded,
      'bg': const Color(0xFFE1F5EE),
      'iconColor': const Color(0xFF0F6E56)
    },
    {
      'title': 'Your account was verified',
      'time': '3 days ago',
      'icon': Icons.verified_user_outlined,
      'bg': const Color(0xFFEEEDFE),
      'iconColor': const Color(0xFF5B55D9)
    },
    {
      'title': 'Welcome to Innovation Economy',
      'time': '4 days ago',
      'icon': Icons.auto_awesome_outlined,
      'bg': const Color(0xFFFBEAD5),
      'iconColor': const Color(0xFF7C5410)
    },
    {
      'title': 'Weekly insight report ready',
      'time': '1 week ago',
      'icon': Icons.bar_chart_rounded,
      'bg': const Color(0xFFE1F5EE),
      'iconColor': const Color(0xFF0F6E56)
    },
    {
      'title': 'Security alert: New login',
      'time': '1 week ago',
      'icon': Icons.security_rounded,
      'bg': const Color(0xFFFEE2E2),
      'iconColor': const Color(0xFFB91C1C)
    },
  ];

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(-250, 40),
              child: MouseRegion(
                onEnter: (_) {
                  _hideTimer?.cancel();
                  setState(() {
                    _isHovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHovered = false;
                    _startHideTimer();
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF202020),
                                ),
                              ),
                              const Spacer(),
                              if (_notifications.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _notifications = [];
                                      _isExpanded = false;
                                      _hideOverlay();
                                      _showOverlay();
                                    });
                                  },
                                  child: const Text(
                                    'Mark all as read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1A7B99),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_notifications.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No notifications now',
                                style: TextStyle(color: Color(0xFF8D8578), fontSize: 13),
                              ),
                            ),
                          )
                        else ...[
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 400),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: [
                                  ..._notifications
                                      .map((n) => _buildDropdownItem(n['title'],
                                          n['time'], n['icon'], n['bg'], n['iconColor']))
                                      .toList(),
                                  if (_isExpanded)
                                    ..._extraNotifications
                                        .map((n) => _buildDropdownItem(n['title'],
                                            n['time'], n['icon'], n['bg'], n['iconColor']))
                                        .toList(),
                                ],
                              ),
                            ),
                          ),
                          if (!_isExpanded)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = true;
                                  _hideOverlay();
                                  _showOverlay();
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                child: const Center(
                                  child: Text(
                                    'View all notifications',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1A7B99),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownItem(String title, String time, IconData icon, Color bg, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF202020)),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8D8578)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), () {
      if (!_isHovered) {
        _hideOverlay();
      }
    });
  }

  void _hideOverlay() {
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          _hideTimer?.cancel();
          setState(() {
            _isHovered = true;
            _showOverlay();
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _startHideTimer();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFF3F4F6).withOpacity(0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Color(0xFFE2E8F0), size: 20),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF87171),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String email;
  final String initials;

  _TeamMember(this.name, this.role, this.email, this.initials);
}

final List<_TeamMember> _mockTeam = [
  _TeamMember('Alex Chen', 'Co-Founder & CTO', 'alex@xphi.ai', 'AC'),
  _TeamMember('Sarah Johnson', 'Head of Product', 'sarah@xphi.ai', 'SJ'),
  _TeamMember('Michael Brown', 'Lead Engineer', 'michael@xphi.ai', 'MB'),
  _TeamMember('Emily Davis', 'Marketing Director', 'emily@xphi.ai', 'ED'),
  _TeamMember('David Wilson', 'Operations Lead', 'david@xphi.ai', 'DW'),
];

class _TeamMemberCard extends StatefulWidget {
  final _TeamMember member;
  const _TeamMemberCard({required this.member});

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _TeamMemberProfileModal(member: widget.member),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFFE7DCC8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF223A56),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.member.initials,
                      style: const TextStyle(
                        color: AppThemeTokens.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A18),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.member.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMemberProfileModal extends StatelessWidget {
  final _TeamMember member;
  const _TeamMemberProfileModal({required this.member});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppThemeTokens.modalHeader,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF223A56),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppThemeTokens.goldAccent, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: AppThemeTokens.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.role,
                          style: const TextStyle(color: AppThemeTokens.goldAccent, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.email_outlined, 'Email', member.email),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.business_center_outlined, 'Department', 'Core Team'),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on_outlined, 'Location', 'Remote'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

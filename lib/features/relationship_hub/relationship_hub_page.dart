import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

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
                          trailingPanel: _AiGuidePanel(
                            prospectId: widget.prospectId,
                            founderName: _founderName,
                            companyName: _companyName,
                            industry: _industry,
                            stageLabel: _stageLabel,
                            priorities: _priorities,
                          ),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: Color(0xFFE2E8F0), size: 20),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
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

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
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
            children: const [
              Expanded(
                child: _NotificationCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: Color(0xFF7C5410),
                  iconBg: Color(0xFFFBEAD5),
                  title: 'Meeting confirmed',
                  message:
                      'Intro call with Sarah on May 6 at 2:00 PM ET. Tap to prep.',
                  footer: 'Apr 28 · Click to prepare',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _NotificationCard(
                  icon: Icons.call_outlined,
                  iconColor: Color(0xFF0F6E56),
                  iconBg: Color(0xFFE1F5EE),
                  title: 'Call summary available',
                  message:
                      'Apr 29 call with Sarah. Topics, next steps, and new material added.',
                  footer: 'Apr 29 · Click to view',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _NotificationCard(
                  icon: Icons.description_outlined,
                  iconColor: Color(0xFF5B55D9),
                  iconBg: Color(0xFFEEEDFE),
                  title: 'New guide added by Sarah',
                  message:
                      'Preparing for your first credit facility, based on your call.',
                  footer: 'Apr 29 · In your learning path',
                ),
              ),
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
  final Widget? trailingPanel;

  const _HubMainColumn({
    required this.companyName,
    required this.founderName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    this.trailingPanel,
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
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Color(0xFF8D8578),
                    fontWeight: FontWeight.w600,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
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
                        'Products relevant to your stage — no commitment required',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6F675B),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$stageLabel · $industry',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D8578),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ProductCard(
                      icon: Icons.account_balance_wallet_outlined,
                      tint: Color(0xFF1A7B99).withValues(alpha: 0.1),
                      iconColor: AppThemeTokens.buttonPrimary,
                      title: 'Business checking & operating accounts',
                      description:
                          'Accounts built for startups — multi-user access, sweep options, and no minimum balance at ${_stageCopy(stageLabel)}.',
                      cta: 'Learn more',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ProductCard(
                      icon: Icons.monitor_heart_outlined,
                      tint: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF1D9E75),
                      title: 'Treasury & cash management',
                      description:
                          'Automated sweep structures, money market access, and yield optimization tuned for ${companyName.trim()}\'s operating rhythm.',
                      cta: 'Learn more',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ProductCard(
                      icon: Icons.attach_money_rounded,
                      tint: const Color(0xFFFBEAD5),
                      iconColor: const Color(0xFF996715),
                      title: 'Venture debt & credit facilities',
                      description:
                          'Pre-approved borrowing for growth capital, bridge financing, and optionality before your next equity round.',
                      cta: 'Ask Sarah about this',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Row(
              children: const [
                Text(
                  'ADDED BY SARAH AFTER YOUR APR 29 CALL',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Color(0xFF8D8578),
                  ),
                ),
                SizedBox(width: 10),
                _TinyBadge('New'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                _LearningCard(
                  stripe: AppThemeTokens.goldAccent,
                  tag: 'Guide',
                  title: 'Setting up efficient banking early',
                  meta: '8 min read · Seed · Operations',
                ),
                _LearningCard(
                  stripe: const Color(0xFF378ADD),
                  tag: 'Event',
                  title: 'Treasury habits that scale with you',
                  meta: 'May 7 · 1:00 PM ET · 45 min',
                ),
                _LearningCard(
                  stripe: const Color(0xFF1D9E75),
                  tag: 'Explainer',
                  title: 'How early-stage treasury accounts work',
                  meta: '5 min read · Finance leads',
                ),
                _LearningCard(
                  stripe: const Color(0xFF7F77DD),
                  tag: 'Guide',
                  title: 'Preparing for your first credit facility',
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
  bool _sending = false;
  late final List<_GuideMessage> _messages = [
    _GuideMessage(
      isUser: false,
      text:
          "I have context from ${widget.founderName}'s profile and the materials in ${widget.companyName}'s learning path. Ask me anything about the next meeting, Sarah's notes, or what matters most right now.",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7DCC8))),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppThemeTokens.buttonPrimary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'AI guide',
                  style: TextStyle(
                    color: AppThemeTokens.modalHeader,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Ask about your materials',
                    style: TextStyle(
                      color: AppThemeTokens.buttonPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
            ),
          ),
          Container(
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

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A7B99).withValues(alpha: 0.1),
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
                Text(
                  footer,
                  style: const TextStyle(
                    color: Color(0xFF8D8578),
                    fontSize: 12,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD7CFBF),
          style: BorderStyle.solid,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16, color: Color(0xFF8D8578)),
          SizedBox(width: 6),
          Text(
            'Add document',
            style: TextStyle(fontSize: 13, color: Color(0xFF6F675B)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;
  final String cta;

  const _ProductCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6F675B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$cta →',
            style: const TextStyle(
              color: AppThemeTokens.buttonPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final Color stripe;
  final String tag;
  final String title;
  final String meta;

  const _LearningCard({
    required this.stripe,
    required this.tag,
    required this.title,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1D9CB)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBEAD5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFF7C5410),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A18),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D8578),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF8D8578), size: 22),
            ),
          ],
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

String _stageCopy(String stageLabel) {
  switch (stageLabel) {
    case 'Pre-seed':
      return 'pre-seed';
    case 'Seed':
      return 'seed';
    case 'Series A':
      return 'Series A';
    case 'Series B+':
      return 'Series B+';
    default:
      return 'your current stage';
  }
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── Body ───────────────────────────────────────────────────────
              Container(
                color: Colors.white,
                constraints: const BoxConstraints(maxHeight: 520),
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
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                            child: Builder(builder: (ctx) {
                              final profileRows = [
                                _buildRow('Email', _profile!.email),
                                _buildRow('Phone', _profile!.phoneNumber),
                                _buildRow('Company', _profile!.companyName),
                                _buildRow('Industry', _profile!.industry),
                                _buildRow('Stage', _profile!.companyStage),
                                _buildRow('Headcount', _profile!.headcount),
                                _buildRow('Incorporated', _profile!.incorporated ? 'Yes' : 'No'),
                                if (_profile!.selectedPrioritiesJson.isNotEmpty)
                                  _buildRow(
                                    'Priorities',
                                    _profile!.selectedPrioritiesJson.entries
                                        .where((e) => e.value)
                                        .map((e) => e.key)
                                        .join(', '),
                                  ),
                                _buildRow('Conversations', '${_profile!.conversationCount}'),
                                if (_profile!.invitationCode != null)
                                  _buildRow('Invite code', _profile!.invitationCode),
                              ];
                              final hasProfileData = profileRows.any((r) => r != null);

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

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasProfileData)
                                    Expanded(
                                      child: _buildSection('PROFILE', profileRows),
                                    ),
                                  if (hasProfileData && insightRows != null)
                                    const SizedBox(width: 24),
                                  if (insightRows != null)
                                    Expanded(
                                      child: _buildSection('AI-COLLECTED INSIGHTS', insightRows),
                                    )
                                  else
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'AI-COLLECTED INSIGHTS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              letterSpacing: 1.2,
                                              color: Color(0xFF8D8578),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFFE7DCC8)),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome_rounded,
                                                  size: 16,
                                                  color: Color(0xFF8D8578),
                                                ),
                                                const SizedBox(width: 10),
                                                const Expanded(
                                                  child: Text(
                                                    'No attributes collected yet.',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
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
                                                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                                    ),
                                                    shape: WidgetStateProperty.all(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(13),
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Text('Start Conversation', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, List<Widget?> rows) {
    final nonNullRows = rows.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Color(0xFF8D8578),
            fontWeight: FontWeight.w600,
          ),
        ),
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

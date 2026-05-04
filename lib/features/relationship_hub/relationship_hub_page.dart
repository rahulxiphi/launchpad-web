import 'package:flutter/material.dart';

import '../../services/conversation_service.dart';
import '../../theme/app_theme.dart';

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

  static const _defaultCompany = 'Aster Labs';
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
    final raw = _prospect?.companyStage ??
        widget.dynamicVariables['stage']?.toString();
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
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _HubMainColumn(
                              companyName: _companyName,
                              founderName: _founderName,
                              industry: _industry,
                              stageLabel: _stageLabel,
                              priorities: _priorities,
                            )),
                            SizedBox(
                              width: 320,
                              child: _AiGuidePanel(
                                founderName: _founderName,
                                companyName: _companyName,
                                priorities: _priorities,
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
                            founderName: _founderName,
                            companyName: _companyName,
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

  const _HubNavBar({
    required this.companyName,
    required this.founderName,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: const Color(0xFF0A2C4E),
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
                  style: TextStyle(color: Color(0xFFE8CC7A)),
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
          Container(
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
                color: Color(0xFFE8CC7A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            companyName,
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
          _SectionLabel('Notifications'),
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
                    message: 'Intro call with Sarah on May 6 at 2:00 PM ET. Tap to prep.',
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
                    message: 'Apr 29 call with Sarah. Topics, next steps, and new material added.',
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
                    message: 'Preparing for your first credit facility, based on your call.',
                    footer: 'Apr 29 · In your learning path',
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Your banker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    color: const Color(0xFF0A2C4E),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2C4E),
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
                            border: Border.all(color: const Color(0xFF314C68)),
                          ),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFFE8CC7A), size: 18),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPCOMING MEETING',
                                style: TextStyle(
                                  color: Color(0xFFE8CC7A),
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Intro call with Sarah Chen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tuesday, May 6 · 2:00 PM ET · 30 min',
                                style: TextStyle(
                                  color: Color(0xFFB8C3D1),
                                  fontSize: 13,
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
                            side: const BorderSide(color: Color(0xFF3E5B79)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('Add to calendar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDBB549),
                            foregroundColor: const Color(0xFF0A2C4E),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('Prep for call'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0D7C8)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF0A2C4E),
                            child: Text(
                              'SC',
                              style: TextStyle(
                                color: Color(0xFFE8CC7A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sarah Chen',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Innovation Banking',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8, color: Color(0xFF1D9E75)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Available this week',
                                      style: TextStyle(
                                        color: Color(0xFF1D9E75),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          const _SectionLabel('Shared documents'),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _DocChip('Investor overview deck.pdf', 'Shared'),
                _DocChip('Product one-pager.docx', 'Needs review'),
                _DocChip('Financial statements Q1.xlsx', 'Requested'),
                _AddDocChip(),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: 'Georgia',
                              color: const Color(0xFF0A2C4E),
                              fontWeight: FontWeight.w700,
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
            child: Row(
              children: [
                Expanded(
                  child: _ProductCard(
                    icon: Icons.account_balance_wallet_outlined,
                    tint: const Color(0xFFE6F1FB),
                    iconColor: const Color(0xFF2366B3),
                    title: 'Business checking & operating accounts',
                    description:
                        'Accounts built for startups — multi-user access, sweep options, and no minimum balance at $_stageCopy(stageLabel).',
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
                  stripe: const Color(0xFFDBB549),
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

class _AiGuidePanel extends StatelessWidget {
  final String founderName;
  final String companyName;
  final List<String> priorities;

  const _AiGuidePanel({
    required this.founderName,
    required this.companyName,
    required this.priorities,
  });

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
                    color: Color(0xFF0A5CA5), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'AI guide',
                  style: TextStyle(
                    color: Color(0xFF0A2C4E),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBCD6F4)),
                  ),
                  child: const Text(
                    'Ask about your materials',
                    style: TextStyle(
                      color: Color(0xFF0A5CA5),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE1D9CB)),
                      ),
                      child: Text(
                        'I have context from $founderName\'s profile and all materials in your learning path — including the new guide Sarah added after your call. Ask me anything.',
                        style: const TextStyle(
                          color: Color(0xFF35302A),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AiBubble(
                      text:
                          'Want a quick summary of what matters most for $companyName right now?',
                    ),
                    const SizedBox(height: 10),
                    ...priorities.take(3).map(
                      (chip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0xFFE1D9CB)),
                            ),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _AiBubble(
                      text:
                          'I can also explain what Sarah added, help you prep for the next call, or point you to the most relevant product path.',
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
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask about your materials…',
                      hintStyle: const TextStyle(color: Color(0xFF8D8578)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE1D9CB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE1D9CB)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2C4E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;

  const _AiBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1D9CB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF35302A),
          height: 1.6,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          color: Color(0xFF8D8578),
          fontWeight: FontWeight.w600,
        ),
      ),
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
        color: const Color(0xFFE6F1FB),
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
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF378ADD),
              borderRadius: BorderRadius.circular(999),
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
        color: dark ? const Color(0xFF0A2C4E) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? const Color(0xFF0A2C4E) : const Color(0xFFE1D9CB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: dark ? Colors.white : const Color(0xFF1F2937)),
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
        color: const Color(0xFFFAF7F0),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
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
              color: Color(0xFF0A5CA5),
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
      child: Row(
        children: [
          Container(
            width: 4,
            height: 100,
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

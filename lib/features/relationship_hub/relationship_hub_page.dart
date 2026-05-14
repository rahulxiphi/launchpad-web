import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:async';


import '../../services/conversation_service.dart';
import '../../theme/app_theme.dart';
import '../voice/voice_page.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/hub_nav_bar.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../shared/widgets/prospect_id_provider.dart';

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
  List<ProductPublic> _products = [];
  bool _loadingProducts = false;

  static const _defaultCompany = 'Launchpad';
  static const _defaultFounder = 'Aditya Kumar';

  @override
  void initState() {
    super.initState();
    _hydrateProspect();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final products = await _service.listProducts(prospectId: widget.prospectId);
      if (mounted) setState(() => _products = products);
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
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

  void _showProductModal(BuildContext context, ProductPublic product) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailModal(
        product: product,
        prospectId: widget.prospectId,
      ),
    );
  }

  void _showLearningModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => _LearningMaterialModal(
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1180;
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Column(
          children: [
            HubNavBar(
              companyName: _companyName,
              initials: _initials,
              founderName: _founderName,
              activeLabel: 'Relationship Hub',
              isHubEnabled: true,
              onProfileTap: () => _showProfileModal(context),
              onInteractionsTap: () {
                final pid = widget.prospectId;
                final path = pid != null ? '/?p=$pid' : '/';
                context.go(path);
              },
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
                                    onTapLearning: _showLearningModal,
                                    products: _products,
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
                          products: _products,
                          trailingPanel: _AiGuidePanel(
                            prospectId: widget.prospectId,
                            founderName: _founderName,
                            companyName: _companyName,
                            industry: _industry,
                            stageLabel: _stageLabel,
                            priorities: _priorities,
                          ),
                          onTapProduct: _showProductModal,
                          onTapLearning: _showLearningModal,
                        ),
            ),
          ],
        ),
      ),
    );

    return ProspectIdProvider(
      prospectId: widget.prospectId,
      child: scaffold,
    );
  }
}


class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _notifService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _dismissCard(int index) {
    _notifService.markAsRead(index);
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = _notifService.activeHubNotifications;
    if (activeItems.isEmpty) {
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
                for (int i = 0; i < activeItems.length; i++) {
                  final item = activeItems[i];
                  activeCards.add(
                    Expanded(
                      child: _NotificationCard(
                        icon: item.icon,
                        iconColor: item.iconColor,
                        iconBg: item.bg,
                        title: item.title,
                        message: item.message,
                        footer: item.footer,
                        onDismiss: () => _dismissCard(i),
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

class _HubMainColumn extends StatefulWidget {
  final String companyName;
  final String founderName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;
  final String? prospectId;
  final String email;
  final Widget? trailingPanel;
  final void Function(BuildContext context, ProductPublic product)? onTapProduct;

  final List<ProductPublic> products;

  const _HubMainColumn({
    required this.companyName,
    required this.founderName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    required this.products,
    this.prospectId,
    this.email = '',
    this.trailingPanel,
    this.onTapProduct,
    this.onTapLearning,
  });

  final void Function(BuildContext context, String title)? onTapLearning;

  @override
  State<_HubMainColumn> createState() => _HubMainColumnState();
}

class _HubMainColumnState extends State<_HubMainColumn> {
  bool _hasInteractedProducts = false;
  bool _hasInteractedLearning = false;
  bool _showAllProducts = false;

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return Icons.payments_outlined;
    if (c.contains('treasury')) return Icons.monitor_heart_outlined;
    if (c.contains('card')) return Icons.credit_card_outlined;
    if (c.contains('international') || c.contains('cross-currency'))
      return Icons.public_outlined;
    if (c.contains('banking')) return Icons.account_balance_wallet_outlined;
    if (c.contains('credit') || c.contains('lending'))
      return Icons.attach_money_rounded;
    return Icons.category_outlined;
  }

  Color _getTintForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return const Color(0xFF7C3AED);
    if (c.contains('treasury')) return const Color(0xFF1D9E75);
    if (c.contains('card')) return const Color(0xFF1A7B99);
    if (c.contains('international') || c.contains('cross-currency'))
      return const Color(0xFF0891B2);
    if (c.contains('banking')) return const Color(0xFF1A7B99);
    if (c.contains('credit') || c.contains('lending'))
      return const Color(0xFF996715);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On mobile, show notifications inside the scroll view
          if (widget.trailingPanel != null) const _NotificationsSection(),
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
                  'Products relevant to your stage${widget.stageLabel.isNotEmpty ? ' — ${widget.stageLabel}' : ''}',
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
                ...(() {
                  final sorted = List<ProductPublic>.from(widget.products)
                    ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
                  return sorted.take(_showAllProducts ? sorted.length : 5);
                })().map((product) {
                  final icon = _getIconForCategory(product.category);
                  final tint = _getTintForCategory(product.category);

                  return SizedBox(
                    width: 320,
                    child: _ProductCard(
                      icon: icon,
                      tint: tint,
                      iconColor: tint,
                      title: product.name,
                      description: product.shortDescription ?? product.description,
                      cta: 'By ${product.provider?.companyName ?? 'J.P. Morgan'}',
                      matchScore: product.matchScore,
                      matchReasoning: product.matchReasoning,
                      productId: product.productId,
                      prospectId: widget.prospectId,
                      onInteraction: () =>
                          setState(() => _hasInteractedProducts = true),
                      onTap: () => widget.onTapProduct?.call(context, product),
                    ),
                  );
                }).toList(),
                if (!_showAllProducts && widget.products.length > 5)
                  SizedBox(
                    width: 320,
                    height: 240,
                    child: Center(
                      child: TextButton(
                        onPressed: () => setState(() => _showAllProducts = true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppThemeTokens.buttonPrimary,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Show more"),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          ],
                        ),
                      ),
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
                Text(
                  'Learning material',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: AppThemeTokens.modalHeader,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 16.0;
                const targetItemHeight = 140.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                final childAspectRatio = itemWidth / targetItemHeight;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: childAspectRatio,
                  children: [
                    _LearningCard(
                      stripe: AppThemeTokens.goldAccent,
                      tag: 'Guide',
                      title: 'Setting up efficient banking early',
                      description:
                          'Shared by Sarah to help streamline your initial operations.',
                      meta: '8 min read · Seed · Operations',
                      defaultHover: !_hasInteractedLearning,
                      showNewBadge: true,
                      onInteraction:
                          () => setState(() => _hasInteractedLearning = true),
                      onTap: () => widget.onTapLearning?.call(context, 'Setting up efficient banking early'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF378ADD),
                      tag: 'Event',
                      title: 'Treasury habits that scale with you',
                      description:
                          'Added by Sarah based on your discussion about cash management.',
                      meta: 'May 7 · 1:00 PM ET · 45 min',
                      onInteraction:
                          () => setState(() => _hasInteractedLearning = true),
                      onTap: () => widget.onTapLearning?.call(context, 'Treasury habits that scale with you'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF1D9E75),
                      tag: 'Explainer',
                      title: 'How early-stage treasury accounts work',
                      description:
                          'A brief explainer shared by Sarah to clarify treasury basics.',
                      meta: '5 min read · Finance leads',
                      onTap: () => widget.onTapLearning?.call(context, 'How early-stage treasury accounts work'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF7F77DD),
                      tag: 'Guide',
                      title: 'Preparing for your first credit facility',
                      description:
                          'Recommended reading by Sarah ahead of your Series A raise.',
                      meta: '10 min read · Series A · Capital structure',
                      onTap: () => widget.onTapLearning?.call(context, 'Preparing for your first credit facility'),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.trailingPanel != null) ...[
            Container(height: 1, color: const Color(0xFFE7DCC8)),
            widget.trailingPanel!,
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
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.dispose();
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
        // Keep focus on the input after sending
        _focusNode.requestFocus();
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Only prefill if input is empty
      if (_controller.text.isEmpty && !_sending) {
        try {
          final lastUserMessage = _messages.lastWhere(
            (m) => m.isUser,
          );
          if (lastUserMessage.text.isNotEmpty) {
            _controller.text = lastUserMessage.text;
            // Set cursor at the end
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          }
        } catch (_) {
          // No user messages yet
        }
      }
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
            _viewingHistory
                ? Icons.history_rounded
                : Icons.auto_awesome_rounded,
            color: _viewingHistory
                ? const Color(0xFF6B7280)
                : AppThemeTokens.buttonPrimary,
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
          GestureDetector(
            onTap: _viewingHistory
                ? _closeHistory
                : (widget.prospectId == null ? null : _openHistory),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _viewingHistory
                        ? Icons.arrow_back_rounded
                        : Icons.history_rounded,
                    size: 13,
                    color: AppThemeTokens.buttonPrimary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _viewingHistory ? 'Back to Chat' : 'History',
                    style: const TextStyle(
                      color: AppThemeTokens.buttonPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_viewingHistory) ...[
            const SizedBox(width: 12),
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
                    child: KeyboardListener(
                      focusNode: _focusNode,
                      onKeyEvent: _handleKeyEvent,
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
  final double? matchScore;
  final String? matchReasoning;
  final String productId;
  final String? prospectId;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cta,
    this.matchScore,
    this.matchReasoning,
    required this.productId,
    this.prospectId,
    this.onTap,
    this.defaultHover = false,
    this.onInteraction,
  });

  final bool defaultHover;
  final VoidCallback? onInteraction;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool? _localHovered;
  bool _isMatchHovered = false;
  bool _showReasoning = false;
  final _overlayController = OverlayPortalController();
  final GlobalKey _cardChipKey = GlobalKey();
  
  String? _paraphrasedReasoning;
  bool _isLoadingReasoning = false;
  final _conversationService = ConversationService();

  Future<void> _fetchParaphrasedReasoning() async {
    if (widget.prospectId == null) return;

    // 1. Check shared static cache first to see if we already have this for the current raw reasoning
    final cached = ConversationService.getCachedReasoning(widget.prospectId!, widget.productId, widget.matchReasoning);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = cached.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
      return;
    }

    if (_isLoadingReasoning) return;
    
    setState(() => _isLoadingReasoning = true);
    try {
      final result = await _conversationService.getMatchReasoning(
        prospectId: widget.prospectId!,
        productId: widget.productId,
        currentRaw: widget.matchReasoning,
      );
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = result.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReasoning = false;
          _paraphrasedReasoning = widget.matchReasoning; // Fallback
        });
      }
    }
  }
  
  bool get _isHovered => _localHovered ?? widget.defaultHover;

  void _toggleReasoning() {
    setState(() {
      _showReasoning = !_showReasoning;
      if (_showReasoning) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    });
  }

  void _showOverlay() {
    _fetchParaphrasedReasoning();
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.show();
        }
      });
    }
  }

  void _hideOverlay() {
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.hide();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return MouseRegion(
      onEnter: (_) {
        widget.onInteraction?.call();
        setState(() => _localHovered = true);
      },
      onExit: (_) {
        setState(() {
          _localHovered = false;
          _isMatchHovered = false;
        });
        _hideOverlay();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 320,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? Colors.white.withOpacity(0.12)
                              : widget.tint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon,
                            color: _isHovered ? Colors.white : widget.iconColor,
                            size: 20),
                      ),
                      if (widget.matchScore != null)
                        OverlayPortal(
                          controller: _overlayController,
                          overlayChildBuilder: (context) {
                            return _buildReasoningOverlay(context);
                          },
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() => _isMatchHovered = true);
                              _showOverlay();
                            },
                            onExit: (_) {
                              setState(() => _isMatchHovered = false);
                              _hideOverlay();
                            },
                            child: GestureDetector(
                              onTap: isMobile ? _toggleReasoning : null,
                              child: Container(
                                key: _cardChipKey,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(widget.matchScore! * 100).toInt()}% match',
                                  style: const TextStyle(
                                    color: Color(0xFF1D9E75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                  const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningOverlay(BuildContext context) {
    if (widget.matchReasoning == null) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // We need the chip's position to show the overlay near it
        final renderBox = _cardChipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        
        final offset = renderBox.localToGlobal(Offset.zero);
        final chipSize = renderBox.size;
        
        return Stack(
          children: [
            Positioned(
              left: offset.dx - (280 - chipSize.width),
              top: offset.dy + chipSize.height + 8,
              width: 280,
              child: IgnorePointer(
                child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: Color(0xFF1D9E75),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reasoning',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D9E75),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          if (_showReasoning)
                            GestureDetector(
                              onTap: _toggleReasoning,
                              child: const Icon(Icons.close, color: Color(0xFF1D9E75), size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isLoadingReasoning)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                        ))
                      else if (_paraphrasedReasoning != null)
                        MarkdownBody(
                          data: _paraphrasedReasoning!,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                              height: 1.5,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        )
                      else
                        Text(
                          widget.matchReasoning ?? "Reasoning unavailable",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F766E),
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }
}

class _LearningCard extends StatefulWidget {
  final Color stripe;
  final String tag;
  final String title;
  final String meta;
  final String? description;

  final bool defaultHover;
  final bool showNewBadge;
  final VoidCallback? onInteraction;
  final VoidCallback? onTap;

  const _LearningCard({
    required this.stripe,
    required this.tag,
    required this.title,
    required this.meta,
    this.description,
    this.defaultHover = false,
    this.showNewBadge = false,
    this.onInteraction,
    this.onTap,
  });

  @override
  State<_LearningCard> createState() => _LearningCardState();
}

class _LearningCardState extends State<_LearningCard> {
  bool? _localHovered;
  bool get _isHovered => _localHovered ?? widget.defaultHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        widget.onInteraction?.call();
        setState(() => _localHovered = true);
      },
      onExit: (_) => setState(() => _localHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
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
    if (widget.showNewBadge)
      Positioned(
        top: 12,
        right: 12,
        child: _TinyBadge('New'),
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

class _ProspectProfileModalState extends State<_ProspectProfileModal> with SingleTickerProviderStateMixin {
  final ConversationService _service = ConversationService();
  ProspectFullProfile? _profile;
  bool _loading = true;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isVoiceTriggerHovered = false;
  bool _isFetchingToken = false;

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
    _loadProfile();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSession({required bool isChatMode}) async {
    if (widget.prospectId == null) return;
    setState(() => _isFetchingToken = true);
    try {
      // In the hub, we might need a specific stage or use the current bucket
      final stage = widget.stageBucket ?? 'super_agent';
      final tokenResult = await _service.getVoiceToken(
        stage,
        prospectId: widget.prospectId!,
      );

      final Map<String, dynamic> vars = {
        'companyName': widget.companyName,
        'userName': widget.founderName,
        'initial_mode': isChatMode ? 'chat' : 'voice',
      };
      vars.addAll(tokenResult.dynamicVariables);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close modal
      
      Navigator.of(context).push(
        NoTransitionPageRoute(
          builder: (_) => VoicePage(
            conversationToken: tokenResult.conversationToken,
            stageBucket: stage,
            prospectId: widget.prospectId,
            dynamicVariables: vars,
            initialMode: isChatMode ? 'chat' : 'voice',
            onStartNew: () async => GoRouter.of(context).go('/'),
            onGoToRelationshipHub: () async => GoRouter.of(context).go('/relationship-hub?p=${widget.prospectId}'),
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
                color: const Color(0xFF131F2E),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFB99C4C), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials,
                        style: const TextStyle(
                          color: Color(0xFFB99C4C),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.founderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.companyName,
                            style: const TextStyle(
                              color: Color(0xFFB99C4C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 24),
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
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Left: Details Form ──────────────────────
                                    Expanded(
                                      flex: 5,
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                        child: _buildDetailsList(),
                                      ),
                                    ),
                                    // ── Right: Voice/Chat Orb ───────────────────
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: _buildVoiceInteractionArea(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ── Bottom: Team Members (Full Width) ────────
                              _buildTeamSection(),
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

  Widget _buildDetailsList() {
    if (_profile == null) return const SizedBox.shrink();
    
    final companyLabel = widget.companyName.isNotEmpty
        ? '${widget.companyName.toUpperCase()} DETAILS'
        : 'COMPANY DETAILS';

    final manualFormRows = [
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
    ];

    final firstFormRows = [
      _buildRow('Email', _profile!.email),
      _buildRow('Phone', _profile!.phoneNumber),
      _buildRow('Company', _profile!.companyName),
      _buildRow('Conversations', '${_profile!.conversationCount}'),
    ];

    final insightRows = _profile!.aiAttributes.isNotEmpty
        ? _profile!.aiAttributes.entries
            .map((e) => _buildRow(
                  _formatAttributeLabel(e.key),
                  _formatAttributeValue(e.value),
                ))
            .toList()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(companyLabel, manualFormRows),
        const SizedBox(height: 32),
        _buildSection('YOUR DETAILS', firstFormRows),
        if (insightRows != null && insightRows.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSentenceSection('What We Have Collected', insightRows),
        ],
      ],
    );
  }

  String _formatAttributeLabel(String key) {
    final spaced = key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );
    return spaced
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String? _formatAttributeValue(dynamic value) {
    if (value == null || value == '') return null;
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Iterable) {
      final values = value.where((item) => item != null && item.toString().isNotEmpty);
      return values.isEmpty ? null : values.join(', ');
    }
    if (value is Map) {
      final values = value.entries
          .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
          .map((entry) => '${_formatAttributeLabel(entry.key.toString())}: ${entry.value}');
      return values.isEmpty ? null : values.join(', ');
    }
    return value.toString();
  }

  Widget _buildVoiceInteractionArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: _isFetchingToken ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isVoiceTriggerHovered = true),
          onExit: (_) => setState(() => _isVoiceTriggerHovered = false),
          child: GestureDetector(
            onTap: _isFetchingToken ? null : () => _startSession(isChatMode: false),
            child: SizedBox(
              height: 200,
              width: 200,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, child) {
                  final color = _isVoiceTriggerHovered ? AppThemeTokens.buttonPrimaryHover : AppThemeTokens.buttonPrimary;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 110 + (100 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                          height: 110 + (100 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppThemeTokens.buttonPrimary.withOpacity(0.3 * (1.0 - ((_pulseAnimation.value + (i * 0.33)) % 1.0))),
                              width: 1.5,
                            ),
                          ),
                        ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 48),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tap the Orb to start conversation',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppThemeTokens.brandInk),
        ),
        const SizedBox(height: 8),
        const Text(
          '~10 min · Nova asks, you answer',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 48),
        if (_isFetchingToken)
          const CircularProgressIndicator(color: AppThemeTokens.buttonPrimary)
        else
          ElevatedButton(
            onPressed: () => _startSession(isChatMode: true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Let's Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              separatorBuilder: (ctx, i) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) => _TeamMemberCard(member: _mockTeam[i]),
            ),
          ),
        ],
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

class _ProductDetailModal extends StatefulWidget {
  final ProductPublic product;
  final String? prospectId;

  _ProductDetailModal({
    required this.product,
    this.prospectId,
  });

  @override
  State<_ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<_ProductDetailModal> {
  final _overlayController = OverlayPortalController();
  final GlobalKey _modalChipKey = GlobalKey();
  bool _isMatchHovered = false;
  bool _showReasoning = false;

  String? _paraphrasedReasoning;
  bool _isLoadingReasoning = false;
  final _conversationService = ConversationService();

  Future<void> _fetchParaphrasedReasoning() async {
    if (widget.prospectId == null) return;

    // 1. Check shared static cache first
    final cached = ConversationService.getCachedReasoning(widget.prospectId!, widget.product.productId, widget.product.matchReasoning);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = cached.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
      return;
    }

    if (_isLoadingReasoning) return;
    
    setState(() => _isLoadingReasoning = true);
    try {
      final result = await _conversationService.getMatchReasoning(
        prospectId: widget.prospectId!,
        productId: widget.product.productId,
        currentRaw: widget.product.matchReasoning,
      );
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = result.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReasoning = false;
          _paraphrasedReasoning = widget.product.matchReasoning; // Fallback
        });
      }
    }
  }

  void _toggleReasoning() {
    setState(() {
      _showReasoning = !_showReasoning;
      if (_showReasoning) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    });
  }

  void _showOverlay() {
    _fetchParaphrasedReasoning();
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.show();
        }
      });
    }
  }

  void _hideOverlay() {
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.hide();
        }
      });
    }
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return Icons.payments_outlined;
    if (c.contains('treasury')) return Icons.monitor_heart_outlined;
    if (c.contains('card')) return Icons.credit_card_outlined;
    if (c.contains('international') || c.contains('cross-currency'))
      return Icons.public_outlined;
    if (c.contains('banking')) return Icons.account_balance_wallet_outlined;
    if (c.contains('credit') || c.contains('lending'))
      return Icons.attach_money_rounded;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final icon = _getIconForCategory(product.category);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 840,
        height: 680,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (product.provider != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${product.provider!.companyName}${product.provider!.hqLocation != null ? ' • ${product.provider!.hqLocation}' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xFFB99C4C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (product.provider!.websiteUrl != null) ...[
                                    const SizedBox(width: 8),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          html.window.open(product.provider!.websiteUrl!, '_blank');
                                        },
                                        child: const Icon(
                                          Icons.open_in_new_rounded,
                                          color: Color(0xFFB99C4C),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (product.matchScore != null) ...[
                        const SizedBox(width: 16),
                        (() {
                          final bool isMobile = MediaQuery.of(context).size.width < 768;
                          return OverlayPortal(
                            controller: _overlayController,
                            overlayChildBuilder: (context) => _buildReasoningOverlay(context),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) {
                                setState(() => _isMatchHovered = true);
                                _showOverlay();
                              },
                              onExit: (_) {
                                setState(() => _isMatchHovered = false);
                                _hideOverlay();
                              },
                              child: GestureDetector(
                                onTap: _toggleReasoning,
                                child: Container(
                                  key: _modalChipKey,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D9E75).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${(product.matchScore! * 100).toInt()}% match',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        })(),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white60, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // ── Body ───────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownSection(
                          title: 'OVERVIEW',
                          initiallyExpanded: true,
                          content: Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        if (product.features.isNotEmpty)
                          _buildDropdownSection(
                            title: 'KEY FEATURES',
                            content: _buildColumnList(product.features.map((f) => f.toString()).toList()),
                          ),
                        
                        if (product.benefits.isNotEmpty)
                          _buildDropdownSection(
                            title: 'BENEFITS',
                            content: _buildColumnList(product.benefits),
                          ),
                        
                        if (product.pricingDetails != null)
                          _buildDropdownSection(
                            title: 'PRICING',
                            content: Text(
                              product.pricingDetails!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        
                        if (product.eligibilityCriteria.isNotEmpty)
                          _buildDropdownSection(
                            title: 'ELIGIBILITY',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: product.eligibilityCriteria.entries.map((e) =>
                                  _buildBulletPoint('${e.key}: ${e.value}')).toList(),
                            ),
                          ),

                        _buildDropdownSection(
                          title: 'CLASSIFICATION',
                          content: Text(
                            '${product.category}${product.subcategory != null ? ' • ${product.subcategory}' : ''}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF334155),
                            ),
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
  }

  Widget _buildColumnList(List<String> items) {
    if (items.length <= 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((i) => _buildBulletPoint(i)).toList(),
      );
    } else {
      int mid = (items.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.sublist(0, mid).map((i) => _buildBulletPoint(i)).toList(),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.sublist(mid).map((i) => _buildBulletPoint(i)).toList(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReasoningOverlay(BuildContext context) {
    if (widget.product.matchReasoning == null) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderBox = _modalChipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        
        final offset = renderBox.localToGlobal(Offset.zero);
        final chipSize = renderBox.size;
        
        return Stack(
          children: [
            Positioned(
              left: offset.dx - (280 - chipSize.width),
              top: offset.dy + chipSize.height + 8,
              width: 280,
              child: IgnorePointer(
                ignoring: _showReasoning ? false : true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              size: 16,
                              color: Color(0xFF1D9E75),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reasoning',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D9E75),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (_showReasoning)
                              GestureDetector(
                                onTap: _toggleReasoning,
                                child: const Icon(Icons.close, color: Color(0xFF1D9E75), size: 14),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingReasoning)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                          ))
                        else if (_paraphrasedReasoning != null)
                          MarkdownBody(
                            data: _paraphrasedReasoning!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F766E),
                                height: 1.5,
                              ),
                              strong: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          )
                        else
                          Text(
                            widget.product.matchReasoning ?? "Reasoning unavailable",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required Widget content,
    bool initiallyExpanded = false,
  }) {
    return _ModalDropdownSection(
      title: title,
      content: content,
      initiallyExpanded: initiallyExpanded,
    );
  }
}

class _ModalDropdownSection extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const _ModalDropdownSection({
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<_ModalDropdownSection> createState() => _ModalDropdownSectionState();
}

class _ModalDropdownSectionState extends State<_ModalDropdownSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: widget.content,
          ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Learning Material Modal
// ─────────────────────────────────────────────────────────────────────────────

class _LearningMaterialModal extends StatelessWidget {
  final String title;

  const _LearningMaterialModal({
    required this.title,
  });

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
          child: Container(
            color: Colors.white,
            child: Column(
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
                          color: const Color(0xFFB99C4C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFFB99C4C), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'CURATED GUIDE • 8 MIN READ',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white60, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // ── Body ───────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('INTRODUCTION', 
                          'For early-stage startups, the foundation of your financial operations can dictate your speed of growth. This guide outlines how to establish a robust banking setup that automates manual tasks, ensures compliance, and prepares you for your first institutional funding round.'),
                        
                        const SizedBox(height: 32),
                        
                        _buildSection('WHY BANKING ARCHITECTURE MATTERS', 
                          'Many founders treat banking as a utility, but it’s actually your most critical financial infrastructure. A well-designed setup helps you:\n\n• Maintain clean books for future audits\n• Automate vendor payments without manual oversight\n• Safeguard investor capital through multi-layered security\n• Leverage treasury solutions to extend your runway'),
                        
                        const SizedBox(height: 40),
                        
                        const Text(
                          'KEY STEPS TO GETTING STARTED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppThemeTokens.modalHeader,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildStepCard(
                          '1', 
                          'Choose the Right Entity Bank Account', 
                          'Ensure your bank supports C-Corp structures and has specialized startup teams who understand VC-backed growth models.'
                        ),
                        _buildStepCard(
                          '2', 
                          'Implement Proper Segregation of Duties', 
                          'Set up secondary approvers for large transfers to prevent fraud and internal errors from day one.'
                        ),
                        _buildStepCard(
                          '3', 
                          'Link Your Accounting Stack', 
                          'Connect your bank feeds directly to QuickBooks or Xero to eliminate manual data entry and minimize reconciliation lag.'
                        ),
                        
                        const SizedBox(height: 40),
                        
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB99C4C), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'PRO TIP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB99C4C),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Consider opening a secondary "Reserve" account. Move 80% of your venture capital into this account and only pull into your "Operating" account what is needed for the month\'s burn. This reduces risk and improves interest yield management.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade800,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 20),
                        const Text(
                          'Ready to optimize your treasury?\nSchedule a 1:1 consultation with Sarah to review your current setup.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeTokens.buttonPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Book Consultation', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppThemeTokens.modalHeader.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppThemeTokens.modalHeader,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
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
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
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
                        fontSize: 20,
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
                          member.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.role,
                          style: const TextStyle(color: AppThemeTokens.goldAccent, fontSize: 13, fontWeight: FontWeight.w600),
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

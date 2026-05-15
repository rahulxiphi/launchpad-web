import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';
import 'mode_selection_page.dart';
import 'manual_form_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/prospect_id_provider.dart';

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
  // ── Super agent ───────────────────────────────────────────────────────────
  'super_agent': _StageContent(
    heading: 'Nova — Your JPMC AI Advisor',
    description:
        'Nova will get to know your startup — stage, priorities, and financial needs — and route you to the right specialist',
    topics: [
      'Calibrate your startup stage — from Pre-seed to IPO & Beyond',
      'Identify immediate financial priorities like Fundraising or Treasury',
      'Surface personalized JPMC product recommendations for your needs',
    ],
    duration: '4-7 min',
  ),
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

enum _EmailLookupAction {
  resume,
  startFresh,
}

class ConversationIntroPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  /// Called when the user taps "Start new session" after a conversation ends.
  /// Handled by AppShell — fetches a fresh token and replaces the inner nav.
  final Future<void> Function() onStartNew;
  final Future<void> Function() onGoToRelationshipHub;
  final VoidCallback? onFormFilled;
  final Function(ProspectInitResult)? onProspectFound;

  const ConversationIntroPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
    required this.onGoToRelationshipHub,
    this.onFormFilled,
    this.onProspectFound,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<ConversationIntroPage> createState() => _ConversationIntroPageState();
}

class _ConversationIntroPageState extends State<ConversationIntroPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ConversationService();
  bool _isPostIncorporated = false;
  bool _isSavingProfile = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  bool _preferManual = false;
  bool _disclaimerAccepted = false;

  Timer? _debounce;
  String? _lastCheckedEmail;
  bool _isCheckingEmail = false;
  bool _emailLookupDialogOpen = false;
  ProspectInitResult? _pendingResumeProspect;

  // Core JPMC aesthetic colors
  static const jpmcDarkNavy = Color(0xFF131F2E);

  bool get _isReadOnly =>
      widget.dynamicVariables['lock_profile_fields'] == true;

  bool get _isProfileLocked => _isReadOnly || _pendingResumeProspect != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.dynamicVariables['userName']?.toString() ?? '';
    _emailController.text =
        widget.dynamicVariables['userEmail']?.toString() ?? '';
    _phoneController.text =
        widget.dynamicVariables['userPhone']?.toString() ?? '';
    _companyController.text =
        widget.dynamicVariables['companyName']?.toString() ?? '';
    _isPostIncorporated =
        widget.dynamicVariables['isPostIncorporated'] == true;
    _preferManual = widget.dynamicVariables['preferManual'] == true;
    _disclaimerAccepted = _isReadOnly;
    _emailController.addListener(_onEmailChanged);
    _companyController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _companyController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    setState(() {
      if (_pendingResumeProspect?.email != null &&
          _pendingResumeProspect!.email != email) {
        _pendingResumeProspect = null;
      }
    });
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      final settledEmail = _emailController.text.trim();
      if (_isValidEmail(settledEmail)) {
        _lookupEmail(settledEmail);
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _lookupEmail(String email) async {
    if (email == _lastCheckedEmail ||
        _isCheckingEmail ||
        _emailLookupDialogOpen ||
        _isReadOnly) {
      return;
    }

    _lastCheckedEmail = email;
    _isCheckingEmail = true;

    try {
      final result = await _service.lookupProspectByEmail(email);
      if (!mounted) return;

      // If we found a different prospect than the current one
      if (result.prospectId != widget.prospectId &&
          result.prospectId != _pendingResumeProspect?.prospectId) {
        await _showWelcomeBackModal(result);
      }
    } catch (e) {
      // Not found or error, ignore
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _showWelcomeBackModal(ProspectInitResult result) async {
    if (_emailLookupDialogOpen) return;
    setState(() => _emailLookupDialogOpen = true);

    final action = await showDialog<_EmailLookupAction>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppThemeTokens.modalHeader,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: AppThemeTokens.goldAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      (() {
                        final firstName = result.fullName?.trim().split(RegExp(r'\s+')).first ?? '';
                        return Expanded(
                          child: Text(
                            firstName.isNotEmpty ? 'Welcome back, $firstName!' : 'Welcome back!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      })(),
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.email ?? lastCheckedEmail ?? 'This email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: jpmcDarkNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Let's continue where you left off.",
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                _EmailLookupAction.startFresh,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'START FRESH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                _EmailLookupAction.resume,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeTokens.buttonPrimary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'RESUME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
          ),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _emailLookupDialogOpen = false);

    switch (action) {
      case _EmailLookupAction.resume:
        _hydrateFromLookup(result);
        break;
      case _EmailLookupAction.startFresh:
        await _startFreshFromLookup();
        break;
      case null:
        setState(() => _lastCheckedEmail = null);
    }
  }

  void _hydrateFromLookup(ProspectInitResult result) {
    setState(() {
      _pendingResumeProspect = result;
      _emailController.text = result.email ?? _emailController.text.trim();
      _nameController.text = result.fullName ?? '';
      _phoneController.text = result.phoneNumber ?? '';
      _companyController.text = result.companyName ?? '';
      _isPostIncorporated = result.incorporated;
      _disclaimerAccepted = true;
    });

    if (result.conversationPhase > 1) {
      widget.onProspectFound?.call(result);
      widget.onGoToRelationshipHub();
    }
  }

  Future<void> _startFreshFromLookup() async {
    setState(() {
      _pendingResumeProspect = null;
      _lastCheckedEmail = null;
      _nameController.clear();
      _phoneController.clear();
      _companyController.clear();
      _isPostIncorporated = false;
      _disclaimerAccepted = false;
    });
    await widget.onStartNew();
  }

  String? get lastCheckedEmail => _lastCheckedEmail;

  void _onFormChanged() {
    setState(() {});
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _submitProfileAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final pendingResume = _pendingResumeProspect;
    final prospectId = pendingResume?.prospectId ??
        widget.prospectId ??
        ProspectIdProvider.of(context);
    debugPrint('IntroPage: Submitting with prospectId=$prospectId (from widget=${widget.prospectId}, from provider=${ProspectIdProvider.of(context)})');
    if (prospectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prospect session is not ready yet.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final bool isResuming = pendingResume != null;
      await _service.updateProspectProfile(
        prospectId,
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        companyName: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        incorporated: _isPostIncorporated,
      );

      final hydratedResume =
          isResuming ? await _service.getProspect(prospectId) : null;
      final vars = hydratedResume?.toDynamicVariables(lockProfileFields: true) ??
          Map<String, dynamic>.from(widget.dynamicVariables);
      if (_nameController.text.trim().isNotEmpty) {
        vars['userName'] = _nameController.text.trim();
      }
      vars['userEmail'] = _emailController.text.trim();
      if (_phoneController.text.trim().isNotEmpty) {
        vars['userPhone'] = _phoneController.text.trim();
      }
      if (_companyController.text.trim().isNotEmpty) {
        vars['companyName'] = _companyController.text.trim();
      }
      vars['isPostIncorporated'] = _isPostIncorporated;
      vars['preferManual'] = _preferManual;

      if (!mounted) return;
      if (hydratedResume != null) {
        widget.onProspectFound?.call(hydratedResume);
      }
      widget.onFormFilled?.call();
      
      if (hydratedResume != null && hydratedResume.conversationPhase > 1) {
        widget.onGoToRelationshipHub();
        return;
      }
      
      Navigator.of(context).push(
        NoTransitionPageRoute(
          builder: (_) => ModeSelectionPage(
            stageBucket: hydratedResume?.stageBucket ??
                pendingResume?.stageBucket ??
                widget.stageBucket,
            prospectId: prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
            onGoToRelationshipHub: widget.onGoToRelationshipHub,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save your details: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  bool get _canSubmit {
    if (_isProfileLocked) return true;
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return false;
    if (_isPostIncorporated && _companyController.text.trim().isEmpty) return false;
    if (!_disclaimerAccepted) return false;
    return true;
  }

  void _showDisclaimerModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppThemeTokens.goldAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Important Disclaimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to JPMC Innovation Economy Chat!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppThemeTokens.brandInk),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'We may retain and review our conversations to provide better service and ensure security. For more details, please see our Privacy and Security guidelines under Profile > Important Information.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Service Availability:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppThemeTokens.brandInk),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This chat feature is designed specifically for JPMC Innovation Economy banking products. It is not available for servicing other JPMC lines of business or specific investment accounts. For non-IE inquiries, please contact your dedicated Relationship Manager or our Service Desk at (800) JPMC-HELP.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Important Notice:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppThemeTokens.brandInk),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If your conversation is related to an account that is currently past due, please be advised: this is an attempt to collect a debt and any information obtained will be used for that purpose.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _disclaimerAccepted = true);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeTokens.buttonPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFB3D8E5), // Faded light blue
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('GET STARTED'),
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

  @override
  Widget build(BuildContext context) {
    final content = _stageContent[widget.stageBucket]!;
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
                    Colors.black.withOpacity(0.6),
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
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Container(
                        width: isMobile ? double.infinity : 840,
                        height: isMobile ? null : 680.0,
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 0 : 24, 
                          vertical: isMobile ? 0 : 32
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
                          boxShadow: isMobile ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 48,
                              offset: const Offset(0, 16),
                            )
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(
                                context,
                                isDark,
                                textTheme,
                                content.heading,
                                content.description,
                              ),
                              
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, bodyConstraints) {
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(
                                        isMobile ? 24 : 36,
                                        20,
                                        isMobile ? 24 : 36,
                                        32,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minHeight: bodyConstraints.maxHeight - 44),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 40),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildTextField('Name', _nameController, false, hint: 'Alex Rivera', onChanged: (_) => _onFormChanged(), readOnly: _isProfileLocked),
                                                      _buildTextField('Email', _emailController, true, hint: 'alex@yourcompany.com', onChanged: (_) => _onFormChanged(), readOnly: _isProfileLocked),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 48),
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildTextField('Phone number', _phoneController, false, hint: '+1 (555) 000-0000', onChanged: (_) => _onFormChanged(), readOnly: _isProfileLocked),
                                                      _buildTextField(
                                                        'Company',
                                                        _companyController,
                                                        _isPostIncorporated,
                                                        hint: 'e.g. Northline AI',
                                                        onChanged: (_) => _onFormChanged(),
                                                        readOnly: _isProfileLocked,
                                                        trailingLabelWidget: GestureDetector(
                                                          onTap: _isProfileLocked ? null : () {
                                                            setState(() => _isPostIncorporated = !_isPostIncorporated);
                                                            _onFormChanged();
                                                          },
                                                          behavior: HitTestBehavior.opaque,
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                width: 16,
                                                                height: 16,
                                                                decoration: BoxDecoration(
                                                                  color: _isPostIncorporated ? AppThemeTokens.buttonPrimary : Colors.transparent,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(
                                                                    color: _isPostIncorporated ? AppThemeTokens.buttonPrimary : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                                child: _isPostIncorporated ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                'Incorporated',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: isDark ? Colors.white70 : Colors.grey.shade800,
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
                                            const SizedBox(height: 36),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1A202C) : Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: isDark ? Colors.grey.shade700 : const Color(0xFFE5E0D4)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      Text(
                                                        'A few basics so Nova can make the conversation immediately useful.',
                                                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.70) : const Color(0xFF6B7280), height: 1.5),
                                                      ),
                                                      Icon(Icons.timer_outlined, size: 13, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                                                      Text(content.duration, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Column(
                                                    children: content.topics.take(3).map((topic) {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 10),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 6),
                                                              child: Container(
                                                                width: 5,
                                                                height: 5,
                                                                decoration: BoxDecoration(color: AppThemeTokens.goldAccent, shape: BoxShape.circle),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Text(
                                                                topic,
                                                                style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.80) : const Color(0xFF4B5563), height: 1.4),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF2C261A) : const Color(0xFFFDF8E1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: isDark ? const Color(0xFF423C2B) : const Color(0xFFF0E6C5)),
                                                    ),
                                                    child: _buildCheckbox(
                                                      _disclaimerAccepted,
                                                      (val) {
                                                        if (_isProfileLocked) return;
                                                        setState(() => _disclaimerAccepted = val ?? false);
                                                      },
                                                      '',
                                                      isDark,
                                                      customLabel: Text.rich(
                                                        TextSpan(
                                                          text: 'I understand and agree to the ',
                                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                                                          children: [
                                                            WidgetSpan(
                                                              alignment: PlaceholderAlignment.middle,
                                                              child: GestureDetector(
                                                                onTap: _showDisclaimerModal,
                                                                child: Container(
                                                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                                                  decoration: BoxDecoration(
                                                                    border: Border(bottom: BorderSide(color: isDark ? Colors.white70 : const Color(0xFF6B7280), width: 1.0)),
                                                                  ),
                                                                  padding: const EdgeInsets.only(bottom: 1),
                                                                  child: Text('Disclaimer', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                                                                ),
                                                              ),
                                                            ),
                                                            TextSpan(text: ' and the terms of this advisory session.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 32),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: _buildBottomBackButton(context),
                                                  ),
                                                  SizedBox(
                                                    height: 52,
                                                    width: isMobile ? double.infinity : 320,
                                                    child: ElevatedButton(
                                                      onPressed: _canSubmit && !_isSavingProfile ? _submitProfileAndContinue : null,
                                                      style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                                            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 18)),
                                                            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                                                            elevation: WidgetStateProperty.all(0),
                                                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                                                              if (states.contains(WidgetState.disabled)) {
                                                                return const Color(0xFFB3D8E5);
                                                              }
                                                              return AppThemeTokens.buttonPrimary;
                                                            }),
                                                            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                                          ),
                                                      child: _isSavingProfile
                                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                          : Text(
                                                              _isSavingProfile
                                                                  ? "SAVING..."
                                                                  : (_isProfileLocked
                                                                      ? "CONTINUE"
                                                                      : "GET STARTED"),
                                                            ),
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

  Widget _buildHeader(
      BuildContext context, bool isDark, TextTheme textTheme, String title, String description) {
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
                  title,
                  style: const TextStyle(
                    color: AppThemeTokens.goldAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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

  Widget _buildTextField(String label, TextEditingController controller, bool isMandatory, {String? hint, void Function(String)? onChanged, Widget? trailingLabelWidget, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(text: label),
                    if (isMandatory) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                  ]
                )
              ),
              if (trailingLabelWidget != null) ...[
                const Spacer(),
                trailingLabelWidget,
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            onChanged: readOnly ? null : onChanged,
            readOnly: readOnly,
            validator: (value) {
              if (isMandatory && (value == null || value.trim().isEmpty)) {
                return 'This field is mandatory';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppThemeTokens.buttonPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool value, ValueChanged<bool?> onChanged, String label, bool isDark, {bool isMultiLine = false, Widget? customLabel}) {
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
            child: customLabel ?? Text(
              label,
              style: TextStyle(
                fontSize: isMultiLine ? 12 : 13,
                fontWeight: isMultiLine ? FontWeight.normal : FontWeight.w600,
                color: isDark ? Colors.white70 : (isMultiLine ? const Color(0xFF6B7280) : Colors.grey.shade800),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

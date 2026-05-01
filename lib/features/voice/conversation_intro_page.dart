import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';
import 'mode_selection_page.dart';
import 'manual_form_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../theme/app_theme.dart';

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
        'Nova will get to know your startup — stage, priorities, and financial needs — then route you to the right specialist and surface personalised JPMC product recommendations.',
    topics: [
      'Your startup stage, business model, and key priorities',
      'Banking, payments, treasury, and credit options for your stage',
      'Personalised JPMC product recommendations and next steps',
    ],
    duration: '10–15 min',
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

class ConversationIntroPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  /// Called when the user taps "Start new session" after a conversation ends.
  /// Handled by AppShell — fetches a fresh token and replaces the inner nav.
  final Future<void> Function() onStartNew;

  const ConversationIntroPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
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

  // Core JPMC aesthetic colors
  static const jpmcDarkNavy = Color(0xFF131F2E);

  bool get _isReadOnly =>
      widget.dynamicVariables['lock_profile_fields'] == true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.dynamicVariables['userName']?.toString() ?? '';
    _emailController.text = widget.dynamicVariables['userEmail']?.toString() ?? '';
    _phoneController.text = widget.dynamicVariables['userPhone']?.toString() ?? '';
    _companyController.text = widget.dynamicVariables['companyName']?.toString() ?? '';
    _isPostIncorporated =
        widget.dynamicVariables['isPostIncorporated'] == true;
    _preferManual = widget.dynamicVariables['preferManual'] == true;
    _emailController.addListener(_onFormChanged);
    _companyController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _submitProfileAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final prospectId = widget.prospectId ?? ProspectIdProvider.of(context);
    if (prospectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prospect session is not ready yet.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
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

      final vars = Map<String, dynamic>.from(widget.dynamicVariables);
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
      Navigator.of(context).push(
        NoTransitionPageRoute(
          builder: (_) => ModeSelectionPage(
            stageBucket: widget.stageBucket,
            prospectId: prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
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
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return false;
    if (_isPostIncorporated && _companyController.text.trim().isEmpty) return false;
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
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
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1556761175-b413da4baf72?q=80&w=2000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay for readability
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header bar ──────────────────────────────────
                              _buildHeader(context, isDark, textTheme, content.heading, content.description),
                              
                              // ── Body ────────────────────────────────────────
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isMobile ? 24 : 36,
                                  16,
                                  isMobile ? 24 : 36,
                                  24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Let\'s start with you',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppThemeTokens.brandInk,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'A few basics so Nova can make the conversation immediately useful.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Lower Section: Balanced Form Fields
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left Form Fields: Name, Email
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildTextField('Name', _nameController, false, hint: 'Alex Rivera', onChanged: (_) => _onFormChanged(), readOnly: _isReadOnly),
                                              _buildTextField('Email', _emailController, true, hint: 'alex@yourcompany.com', onChanged: (_) => _onFormChanged(), readOnly: _isReadOnly),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 48),
                                        // Right Form Fields: Phone, Checkbox, Company
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildTextField('Phone number', _phoneController, false, hint: '+1 (555) 000-0000', onChanged: (_) => _onFormChanged(), readOnly: _isReadOnly),
                                              _buildTextField(
                                                'Company',
                                                _companyController,
                                                _isPostIncorporated,
                                                hint: 'e.g. Northline AI',
                                                onChanged: (_) => _onFormChanged(),
                                                readOnly: _isReadOnly,
                                                trailingLabelWidget: GestureDetector(
                                                  onTap: _isReadOnly ? null : () {
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
                                                          color: _isPostIncorporated
                                                              ? AppThemeTokens.buttonPrimary
                                                              : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: _isPostIncorporated
                                                                ? AppThemeTokens.buttonPrimary
                                                                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: _isPostIncorporated
                                                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                                                            : null,
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
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildBottomBackButton(
                                                context),
                                          ),
                                          SizedBox(
                                            height: 48,
                                            width: isMobile
                                                ? double.infinity
                                                : 320,
                                            child: ElevatedButton.icon(
                                              onPressed: _canSubmit &&
                                                      !_isSavingProfile
                                                  ? _submitProfileAndContinue
                                                  : null,
                                              icon: _isSavingProfile
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.auto_awesome,
                                                      size: 18,
                                                      color: _canSubmit
                                                          ? AppThemeTokens
                                                              .goldAccent
                                                          : Colors.white,
                                                    ),
                                              label: Text(_isSavingProfile
                                                  ? 'SAVING...'
                                                  : (_isReadOnly
                                                      ? 'CONTINUE'
                                                      : 'GET STARTED')),
                                              style: Theme.of(context)
                                                  .elevatedButtonTheme
                                                  .style
                                                  ?.copyWith(
                                                    padding:
                                                        WidgetStateProperty.all(
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 32),
                                                    ),
                                                    shape:
                                                        WidgetStateProperty.all(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                    elevation:
                                                        WidgetStateProperty.all(
                                                      _canSubmit ? 4 : 0,
                                                    ),
                                                    shadowColor:
                                                        WidgetStateProperty.all(
                                                      AppThemeTokens
                                                          .buttonPrimary
                                                          .withOpacity(0.4),
                                                    ),
                                                    textStyle:
                                                        WidgetStateProperty.all(
                                                      const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1.0,
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
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppThemeTokens.goldAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
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

  Widget _buildCheckbox(bool value, ValueChanged<bool?> onChanged, String label, bool isDark, {bool isMultiLine = false}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: EdgeInsets.only(top: isMultiLine ? 2 : 0),
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
                fontSize: isMultiLine ? 12 : 13,
                fontWeight: isMultiLine ? FontWeight.normal : FontWeight.w600,
                color: isDark ? Colors.white70 : (isMultiLine ? const Color(0xFF6B7280) : Colors.grey.shade800),
                height: isMultiLine ? 1.4 : 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

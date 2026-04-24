import 'package:flutter/material.dart';
import 'voice_page.dart';

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
  final String conversationToken;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  /// Called when the user taps "Start new session" after a conversation ends.
  /// Handled by AppShell — fetches a fresh token and replaces the inner nav.
  final Future<void> Function() onStartNew;

  const ConversationIntroPage({
    super.key,
    required this.conversationToken,
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
  bool _isPostIncorporated = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  bool _preferManual = false;

  // Core JPMC aesthetic colors
  static const jpmcNavy = Color(0xFF0A2744);
  static const jpmcDarkNavy = Color(0xFF131F2E);
  static const jpmcBlue = Color(0xFF006CAD);
  static const jpmcGold = Color(0xFFC8872A);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
    _companyController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _canSubmit {
    if (_emailController.text.trim().isEmpty) return false;
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
    
    // Core aesthetic colors for JPMC
    const jpmcBgDk = Color(0xFF0F3460);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
                        width: isMobile ? double.infinity : 1000,
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 0 : 24, 
                          vertical: isMobile ? 0 : 24
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 24 : 36),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
                                boxShadow: isMobile ? null : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                  )
                                ],
                              ),
                              child: Flex(
                                direction: isMobile ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: isMobile ? 0 : 5,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Animated / glowing modern AI icon
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFEBF4FF), Color(0xFFBBE0FF)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: jpmcBlue.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              )
                                            ]
                                          ),
                                          child: const Icon(
                                            Icons.task_alt_rounded,
                                            color: jpmcBlue,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Heading
                                        Text(
                                          content.heading,
                                          style: textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : jpmcNavy,
                                            height: 1.15,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Description
                                        Text(
                                          content.description,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                                            height: 1.5,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        
                                        // Topics "What we'll cover"
                                        Text(
                                          'WHAT WE\'LL COVER',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: jpmcGold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        ...content.topics.map((topic) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 2),
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: jpmcBlue.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, size: 12, color: jpmcBlue),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  topic,
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
                                        )),
                                        const SizedBox(height: 28),
                                        
                                        // Microphone permission banner
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: jpmcBlue.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: jpmcBlue.withOpacity(0.12)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.mic_none_rounded, size: 18, color: jpmcBlue),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Microphone access required',
                                                      style: textTheme.labelLarge?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : jpmcNavy,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Your browser will request permission when the session starts.',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                                        height: 1.4,
                                                        fontSize: 12,
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
                                  if (!isMobile) const SizedBox(width: 48),
                                  if (isMobile) const SizedBox(height: 48),
                                  Expanded(
                                    flex: isMobile ? 0 : 4,
                                    child: _buildForm(textTheme, isDark, content.duration),
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
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildForm(TextTheme textTheme, bool isDark, String duration) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your startup',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : jpmcNavy,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField('Name', _nameController, false, hint: 'Alex Rivera', onChanged: (_) => _onFormChanged()),
          _buildTextField('Email', _emailController, true, hint: 'alex@yourcompany.com', onChanged: (_) => _onFormChanged()),
          _buildTextField('Phone number', _phoneController, false, hint: '+1 (555) 000-0000', onChanged: (_) => _onFormChanged()),
          
          // Post-incorporated checkbox
          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 12),
            child: _buildCheckbox(
              _isPostIncorporated,
              (val) {
                setState(() => _isPostIncorporated = val ?? false);
                _onFormChanged();
              },
              'Post-incorporated',
              isDark,
            ),
          ),
          _buildTextField('Company', _companyController, _isPostIncorporated, hint: 'e.g. Northline AI', onChanged: (_) => _onFormChanged()),
          const SizedBox(height: 8),
          // Manual fill disclaimer box
          Container(
            padding: const EdgeInsets.all(16),
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
              isMultiLine: true,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                'Est. $duration',
                style: textTheme.labelLarge?.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit ? () {
                if (_formKey.currentState!.validate()) {
                  final vars = Map<String, dynamic>.from(widget.dynamicVariables);
                  if (_nameController.text.trim().isNotEmpty) vars['userName'] = _nameController.text.trim();
                  if (_emailController.text.trim().isNotEmpty) vars['userEmail'] = _emailController.text.trim();
                  if (_phoneController.text.trim().isNotEmpty) vars['userPhone'] = _phoneController.text.trim();
                  if (_companyController.text.trim().isNotEmpty) vars['companyName'] = _companyController.text.trim();
                  vars['isPostIncorporated'] = _isPostIncorporated;
                  vars['preferManual'] = _preferManual;
                  
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => VoicePage(
                        conversationToken: widget.conversationToken,
                        stageBucket: widget.stageBucket,
                        prospectId: widget.prospectId,
                        dynamicVariables: vars,
                        onStartNew: widget.onStartNew,
                      ),
                    ),
                  );
                }
              } : null,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('GET STARTED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSubmit ? jpmcBlue : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _canSubmit ? 4 : 0,
                shadowColor: jpmcBlue.withOpacity(0.4),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isMandatory, {String? hint, void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
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
                borderSide: const BorderSide(color: jpmcBlue, width: 1.5),
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
              color: value ? jpmcBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value ? jpmcBlue : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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

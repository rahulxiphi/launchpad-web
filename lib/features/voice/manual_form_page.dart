import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';

class ManualFormPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  final Future<void> Function() onStartNew;

  const ManualFormPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<ManualFormPage> createState() => _ManualFormPageState();
}

class _ManualFormPageState extends State<ManualFormPage> {
  // JPMC Colors
  static const jpmcNavy = Color(0xFF0A2744);
  static const jpmcBlue = Color(0xFF006CAD);
  static const jpmcGold = Color(0xFFC8872A);

  bool _isFetchingToken = false;

  // Stage
  String? _selectedStage;
  final _stages = ['Pre-seed', 'Seed', 'Series A', 'Series B+', 'Revenue-generating, no VC'];

  // Company fields
  final _industryController = TextEditingController();
  String? _headcount;
  final _headcounts = ['1–5', '6–15', '16–50', '51–200', '200+'];

  // Priorities
  final _priorityOptions = [
    ('International expansion', 'New markets, FX, cross-border payments'),
    ('Fundraising & investor relations', 'Preparing for a round, cap table, wire management'),
    ('Credit & lending', 'Venture debt, credit lines, equipment financing'),
    ('Payments & operations', 'Vendor payments, payroll, multi-currency'),
    ('Banking & treasury setup', 'Account structure, cash management, yield on reserves'),
  ];
  final Set<String> _selectedPriorities = {};

  bool get _canSubmit =>
      _selectedStage != null && _selectedPriorities.isNotEmpty;

  void _togglePriority(String title) {
    setState(() {
      if (_selectedPriorities.contains(title)) {
        _selectedPriorities.remove(title);
      } else if (_selectedPriorities.length < 3) {
        _selectedPriorities.add(title);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isFetchingToken = true);
    try {
      final tokenResult = await ConversationService().getVoiceToken(
        widget.stageBucket,
        prospectId: widget.prospectId,
      );

      final vars = Map<String, dynamic>.from(widget.dynamicVariables);
      vars.addAll(tokenResult.dynamicVariables);
      vars['stage'] = _selectedStage;
      vars['industry'] = _industryController.text.trim();
      vars['headcount'] = _headcount;
      vars['priorities'] = _selectedPriorities.toList();
      vars['preferManual'] = true;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoicePage(
            conversationToken: tokenResult.conversationToken,
            stageBucket: widget.stageBucket,
            prospectId: widget.prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
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

  @override
  void dispose() {
    _industryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1556761175-b413da4baf72?q=80&w=2000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
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
                  child: Center(
                    child: Container(
                      width: isMobile ? double.infinity : 840,
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0 : 24,
                        vertical: isMobile ? 0 : 32,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header bar ──────────────────────────────────
                          _buildHeader(context, isDark, textTheme),

                          // ── Body ────────────────────────────────────────
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 24 : 36,
                              16,
                              isMobile ? 24 : 36,
                              20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stage pills
                                Text(
                                  'Company stage',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.70)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _stages.map((stage) {
                                    final selected = _selectedStage == stage;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedStage = stage),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? jpmcNavy
                                              : (isDark
                                                  ? const Color(0xFF2C2C2C)
                                                  : Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: selected
                                                ? jpmcNavy
                                                : (isDark
                                                    ? Colors.white.withOpacity(0.24)
                                                    : const Color(0xFFD1D5DB)),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          stage,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: selected
                                                ? jpmcGold
                                                : (isDark
                                                    ? Colors.white.withOpacity(0.60)
                                                    : const Color(0xFF374151)),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),

                                // Industry + Headcount row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        label: 'Industry / sector',
                                        optional: true,
                                        isDark: isDark,
                                        controller: _industryController,
                                        hint: 'e.g. B2B SaaS, Fintech…',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Headcount',
                                        isDark: isDark,
                                        value: _headcount,
                                        items: _headcounts,
                                        onChanged: (v) =>
                                            setState(() => _headcount = v),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // ── Section 2: Priorities ──────────────────
                                _sectionLabel(
                                    "WHAT'S MOST PRESSING RIGHT NOW?", isDark),
                                const SizedBox(height: 6),
                                Text(
                                  'Pick up to 3. Nova focuses the conversation on what actually matters today.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.54)
                                        : const Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final cardWidth = (boxConstraints.maxWidth - 16) / 2;
                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: _priorityOptions.map((entry) {
                                        final title = entry.$1;
                                        final subtitle = entry.$2;
                                        final isSelected =
                                            _selectedPriorities.contains(title);
                                        final isDisabled =
                                            !isSelected && _selectedPriorities.length >= 3;
                                        return SizedBox(
                                          width: isMobile ? double.infinity : cardWidth,
                                          child: GestureDetector(
                                            onTap: isDisabled
                                                ? null
                                                : () => _togglePriority(title),
                                        child: AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          opacity: isDisabled ? 0.45 : 1.0,
                                          child: AnimatedContainer(
                                            duration:
                                                const Duration(milliseconds: 180),
                                            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isDark
                                                      ? const Color(0xFF0A2744)
                                                          .withOpacity(0.5)
                                                      : const Color(0xFFEBF4FF))
                                                  : (isDark
                                                      ? const Color(0xFF2C2C2C)
                                                      : Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? jpmcBlue
                                                    : (isDark
                                                        ? Colors.white.withOpacity(0.12)
                                                        : const Color(0xFFE5E7EB)),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Checkbox
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 180),
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? jpmcBlue
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? jpmcBlue
                                                          : (isDark
                                                              ? Colors.white.withOpacity(0.38)
                                                              : const Color(
                                                                  0xFFD1D5DB)),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(Icons.check,
                                                          size: 13,
                                                          color: Colors.white)
                                                      : null,
                                                ),
                                                const SizedBox(width: 14),
                                                // Text
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? Colors.white.withOpacity(0.87)
                                                              : jpmcNavy,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        subtitle,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? Colors.white.withOpacity(0.38)
                                                              : const Color(
                                                                  0xFF6B7280),
                                                          height: 1.4,
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
                                      }).toList(),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // ── Footer: Submit ─────────────────────────
                                Center(
                                  child: SizedBox(
                                    height: 52,
                                    width: isMobile ? double.infinity : 360,
                                    child: ElevatedButton.icon(
                                      onPressed: _canSubmit && !_isFetchingToken ? _submit : null,
                                      icon: _isFetchingToken
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : Icon(
                                              Icons.auto_awesome,
                                              size: 18,
                                              color: _canSubmit
                                                  ? jpmcGold
                                                  : Colors.white,
                                            ),
                                      label: const Text('GO TO RELATIONSHIP HUB'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: jpmcBlue,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: jpmcBlue,
                                        disabledForegroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: _canSubmit ? 4 : 0,
                                        shadowColor:
                                            jpmcBlue.withOpacity(0.4),
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
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
      BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 20),
      decoration: BoxDecoration(
        color: jpmcNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: jpmcGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: jpmcGold.withOpacity(0.3)),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFFD4AD46), size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABOUT YOUR COMPANY',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFD4AD46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Helps Nova calibrate every recommendation to your actual situation — not a generic playbook.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.38),
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

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: jpmcGold,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required bool isDark,
    required TextEditingController controller,
    String? hint,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.70) : const Color(0xFF374151),
            ),
            children: [
              TextSpan(text: label),
              if (optional)
                const TextSpan(
                  text: '  (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
    );
  }

  Widget _buildDropdownField({
    required String label,
    required bool isDark,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final key = GlobalKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.70) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark ? Colors.white.withOpacity(0.54) : Colors.grey.shade500),
          dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            hintText: 'Select…',
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
          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

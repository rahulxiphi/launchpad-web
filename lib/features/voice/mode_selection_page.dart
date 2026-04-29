import 'package:flutter/material.dart';
import '../../services/conversation_service.dart';
import 'voice_page.dart';

class ModeSelectionPage extends StatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;
  final Future<void> Function() onStartNew;

  const ModeSelectionPage({
    super.key,
    required this.stageBucket,
    required this.onStartNew,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage> {
  bool _isFetchingToken = false;

  static const jpmcNavy = Color(0xFF0A2744);
  static const jpmcBlue = Color(0xFF006CAD);
  static const jpmcGold = Color(0xFFC8872A);

  Future<void> _startSession({required bool isChatMode}) async {
    setState(() => _isFetchingToken = true);
    try {
      final tokenResult = await ConversationService().getVoiceToken(
        widget.stageBucket,
        prospectId: widget.prospectId,
      );
      
      final vars = Map<String, dynamic>.from(widget.dynamicVariables);
      vars.addAll(tokenResult.dynamicVariables);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoicePage(
            conversationToken: tokenResult.conversationToken,
            stageBucket: widget.stageBucket,
            prospectId: widget.prospectId,
            dynamicVariables: vars,
            onStartNew: widget.onStartNew,
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.connect_without_contact_rounded,
                        size: 48,
                        color: isDark ? jpmcGold : jpmcBlue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'How would you like to proceed?',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : jpmcNavy,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose between a hands-free voice conversation or a text-based chat experience.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      if (_isFetchingToken)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: jpmcBlue),
                        )
                      else ...[
                        _buildModeOption(
                          context: context,
                          title: 'Start voice conversation',
                          subtitle: 'Talk naturally with our AI advisor',
                          icon: Icons.mic_rounded,
                          isDark: isDark,
                          onTap: () => _startSession(isChatMode: false),
                        ),
                        const SizedBox(height: 16),
                        _buildModeOption(
                          context: context,
                          title: 'Or let\'s chat instead',
                          subtitle: 'Type your responses',
                          icon: Icons.chat_bubble_outline_rounded,
                          isDark: isDark,
                          onTap: () => _startSession(isChatMode: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white : jpmcNavy, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

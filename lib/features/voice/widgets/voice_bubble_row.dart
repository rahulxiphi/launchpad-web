import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

class VoiceBubbleRow extends StatelessWidget {
  final bool isUser;
  final String text;
  final bool isTentative;
  final String agentInitial;
  final bool isPrevSame;
  final bool isNextSame;

  const VoiceBubbleRow({
    super.key,
    required this.isUser,
    required this.text,
    required this.isTentative,
    this.agentInitial = 'A',
    this.isPrevSame = false,
    this.isNextSame = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final aiBubbleColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final aiTextColor = isDark ? Colors.white : const Color(0xFF1F2937);

    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 800 ? 800.0 : screenWidth;

    final aiAvatarBg = AppThemeTokens.modalHeader;
    final userBubbleBg = AppThemeTokens.buttonPrimary;
    final userAvatarBg = aiBubbleColor;

    Widget avatar(Color bg, Widget child) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        );

    final aiAvatar = avatar(
      aiAvatarBg,
      Text(
        agentInitial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppThemeTokens.goldAccent,
        ),
      ),
    );

    final userAvatar = avatar(
      userAvatarBg,
      Icon(
        Icons.person_rounded,
        size: 16,
        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      ),
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: containerWidth * 0.68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? userBubbleBg : aiBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
          topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
          bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
          bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isUser ? Colors.white : aiTextColor,
              height: 1.5,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: isTentative ? FontStyle.italic : FontStyle.normal,
            ),
      ),
    );

    final estimatedLines =
        (text.length / 70).ceil() + '\n'.allMatches(text).length;
    final avatarAlign = estimatedLines <= 1
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.end;

    final isReturnLink = !isUser && text.contains('come back any time to continue');

    if (isReturnLink) {
      final parts = text.split('\n');
      final label = parts.isNotEmpty ? parts[0] : '';
      final url = parts.length > 1 ? parts[1] : '';
      final note = parts.length > 3 ? parts.skip(3).join('\n') : '';
      return Padding(
        padding: EdgeInsets.only(top: isPrevSame ? 2 : 12, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            aiAvatar,
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: containerWidth * 0.75),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: aiBubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
                    topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
                    bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
                    bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      url,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : AppThemeTokens.buttonPrimary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CopyLinkButton(url: url),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: isPrevSame ? 1 : 10, bottom: 1),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: avatarAlign,
        children: isUser
            ? [
                bubble,
                const SizedBox(width: 8),
                if (isNextSame) const SizedBox(width: 28) else userAvatar,
              ]
            : [
                if (isNextSame) const SizedBox(width: 28) else aiAvatar,
                const SizedBox(width: 8),
                bubble,
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

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF1d9e75)
              : AppThemeTokens.modalHeader,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 14,
              color: _copied ? Colors.white : AppThemeTokens.goldAccent,
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Copied!' : 'Copy link',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _copied ? Colors.white : AppThemeTokens.goldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

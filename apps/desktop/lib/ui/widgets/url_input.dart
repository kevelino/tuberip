import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme_tokens.dart';

class UrlInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool enabled;
  final VoidCallback onSubmit;

  const UrlInput({
    super.key,
    required this.controller,
    this.hint = AppStrings.urlPlaceholder,
    this.label = AppStrings.pasteHint,
    this.enabled = true,
    required this.onSubmit,
  });

  @override
  State<UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends State<UrlInput> {
  late FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.controller.text = data.text!;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    final focused = _isHovered || _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: tokens.textMuted,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.text,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                widget.onSubmit();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(
                  color: focused ? tokens.primary : tokens.border,
                  width: 2,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: tokens.primary.withValues(alpha: 0.3),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.link_outlined,
                    size: 16,
                    color: widget.enabled
                        ? tokens.primary
                        : tokens.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      onSubmitted: (_) => widget.onSubmit(),
                    ),
                  ),
                  if (widget.controller.text.isNotEmpty)
                    _CircleButton(
                      icon: Icons.close,
                      color: tokens.textSecondary,
                      onTap: () {
                        widget.controller.clear();
                        setState(() {});
                      },
                    ),
                  _CircleButton(
                    icon: Icons.content_paste_outlined,
                    color: tokens.textSecondary,
                    onTap: _paste,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanDim,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: AppColors.background),
        ),
      ),
    );
  }
}

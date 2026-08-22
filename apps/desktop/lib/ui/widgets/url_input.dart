import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class UrlInput extends StatefulWidget {
  const UrlInput({
    super.key,
    required this.controller,
    this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback? onSubmit;

  @override
  State<UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends State<UrlInput> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      widget.controller.text = text;
      widget.controller.selection =
          TextSelection.collapsed(offset: text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste YouTube Video URL or ID',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.gray400,
              ),
        ),
        SizedBox(height: tokens.spacingSm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                onSubmitted: (_) => widget.onSubmit?.call(),
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=…',
                  suffixIcon: widget.controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            widget.controller.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            OutlinedButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Paste'),
            ),
          ],
        ),
      ],
    );
  }
}

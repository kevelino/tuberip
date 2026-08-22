import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help'),
      content: const SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TubeRip downloads YouTube videos and audio via yt-dlp.',
              ),
              SizedBox(height: 12),
              Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• yt-dlp — installed and on PATH\n'
                  '• ffmpeg — required for merge / audio extract'),
              SizedBox(height: 12),
              Text('Quick start', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('1. Paste a YouTube URL or video ID\n'
                  '2. Choose Video or Audio and quality\n'
                  '3. Click Download\n'
                  '4. Files go to ~/Downloads/YouTube by default'),
              SizedBox(height: 12),
              Text('Cookies', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                'Some videos need browser cookies. Pick Firefox/Chrome '
                'in Settings, or provide a cookies.txt file.',
              ),
              SizedBox(height: 12),
              Text('Shortcuts', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Enter — start download\n'
                  'Ctrl+S — settings\n'
                  'Ctrl+/ — help'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

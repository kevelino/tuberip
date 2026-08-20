import 'package:flutter/material.dart';

// ── TubeRip Cyber-Cyan Theme ────────────────────────────────────

class AppColors {
  static const background = Color(0xFF111113);
  static const surface = Color(0xFF18181B);
  static const surfaceAlt = Color(0xFF1F1F23);
  static const border = Color(0xFF2D2D31);
  static const borderAlt = Color(0xFF3F3F46);

  static const cyan = Color(0xFF11EEF9);
  static const cyanAlt = Color(0xFF0DD4DE);
  static const cyanDim = Color(0xFF0891B2);

  static const textPrimary = Color(0xFFE4E4E7);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);

  static const yellow = Color(0xFFEAB308);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);

  static const titleBarBg = Color(0xFF0D0D0F);
}

class AppSizes {
  static const titleBarHeight = 50.0;
  static const sidebarWidth = 240.0;
  static const borderRadius = 8.0;
  static const borderRadiusLg = 12.0;
  static const borderRadiusXl = 16.0;
  static const borderWidth = 1.5;
  static const borderWidthThin = 1.0;
}

class AppStrings {
  static const appName = 'TubeRip';
  static const appLogo = 'TR';
  static const pasteHint = 'Paste YouTube Video URL or ID';
  static const urlPlaceholder = 'https://www.youtube.com/watch?v=...';

  // Button labels
  static const downloadVideo = 'Download Video';
  static const downloadAudio = 'Download Audio';
  static const saveToLabel = 'Save to:';

  // Status
  static const statusQueued = 'Queued';
  static const statusDownloading = 'Downloading';
  static const statusPaused = 'Paused';
  static const statusCompleted = 'Completed';
  static const statusError = 'Error';
  static const statusCancelled = 'Cancelled';

  // Settings
  static const settingsTitle = 'Advanced Settings';
  static const settingsSubtitle = 'Configure download behaviour and metadata options.';
  static const audioQualityTitle = 'Audio Quality (VBR 0 = best, 9 = smallest)';
  static const subtitlesTitle = 'Subtitles';
  static const metadataTitle = 'Metadata & Extras';
  static const networkTitle = 'Network';
  static const applyButton = 'Apply';

  // Help
  static const helpTitle = 'Help';
  static const helpSummary = 'Download YouTube videos or extract audio with a clean,\nintuitive desktop application.';

  // Feature list
  static const featureVideoAudio = 'Video & Audio Modes';
  static const featureVideoDesc = 'Download full resolution videos or extract audio\nin popular formats.';
  static const featureQuality = 'Quality Presets';
  static const featureQualityDesc = 'Choose from best, 1080p, 720p, 480p\nfor video, or high-quality audio.';
  static const featureAudioQuality = 'Audio Quality';
  static const featureAudioQualityDesc = 'Fine-tune your audio downloads with\nvariable bitrate settings.';
  static const featureSubtitles = 'Subtitles';
  static const featureSubtitlesDesc = 'Download subtitles with language\nselection support.';
  static const featurePauseResume = 'Pause & Resume';
  static const featurePauseDesc = 'Suspend downloads on the fly and\nresume them when ready.';
  static const featureFolder = 'Custom Output Folder';
  static const featureFolderDesc = 'Set your preferred download location\nusing a native folder picker.';
  static const featureQueue = 'Live Queue Progress';
  static const featureQueueDesc = 'Monitor downloads with real-time\nstatus, progress, and speed.';
  static const featureSettings = 'Advanced Settings';
  static const featureSettingsDesc = 'Configure subtitles, metadata\nembedding, and rate limiting.';

  // Shortcuts
  static const shortcutEnter = 'Enter';
  static const shortcutEnterAction = 'Start download';
  static const shortcutSettings = 'Ctrl + S';
  static const shortcutSettingsAction = 'Open settings';
  static const shortcutQuit = 'Ctrl + Q';
  static const shortcutQuitAction = 'Quit application';
  static const shortcutHelp = 'Ctrl + /';
  static const shortcutHelpAction = 'Open help';
}

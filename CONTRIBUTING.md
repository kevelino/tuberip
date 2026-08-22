# Contributing to TubeRip

Thank you for your interest in contributing. This document describes the development workflow, code style, and review process.

## Code of Conduct

Be respectful and constructive. We are building this together.

## How to Contribute

1. Fork the repo and clone your fork.
2. Create a feature branch from `master` (or `main`):
   ```bash
   git checkout -b feat/my-new-feature
   ```
3. Make your changes under `apps/desktop/`.
4. Run analyze and tests:
   ```bash
   cd apps/desktop
   flutter analyze
   flutter test
   ```
5. Commit with a clear message:
   ```bash
   git commit -m "feat: add playlist support"
   ```
6. Push and open a pull request.

## Development Setup

```bash
git clone https://github.com/kevelino/tuberip.git
cd tuberip/apps/desktop
./scripts/install-deps.sh   # yt-dlp + ffmpeg if needed
flutter pub get
flutter run -d linux
```

## Code Style

- Dart / Flutter for the desktop app
- Prefer small, focused widgets and services under `lib/`
- Keep yt-dlp CLI construction in `lib/backend/`; process lifecycle in `lib/services/`
- Do not add comments unless necessary
- Follow existing naming conventions
- Brand accent is cyan `#0FE5F4` only (no purple Material defaults)

## Commit Messages

Use Conventional Commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` code change that neither fixes a bug nor adds a feature
- `test:` adding or updating tests
- `chore:` tooling, CI, dependencies

## Pull Request Checklist

- [ ] `flutter analyze` passes in `apps/desktop`
- [ ] `flutter test` passes in `apps/desktop`
- [ ] README or docs updated if behavior changed
- [ ] `CHANGELOG.md` updated if applicable

## Reporting Bugs

Open an issue with:
- OS and version
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behavior
- Logs or terminal output if available

## Questions

Open an issue with the `question` label.

# Contributing to TubeRip

Thank you for your interest in contributing. This document describes the development workflow, code style, and review process.

## Code of Conduct

Be respectful and constructive. We are building this together.

## How to Contribute

1. Fork the repo and clone your fork.
2. Create a feature branch from `master`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
3. Make your changes.
4. Run the linter and tests:
   ```bash
   PYTHONPATH=src pytest tests/
   ```
5. Commit with a clear message:
   ```bash
   git commit -m "feat: add playlist support"
   ```
6. Push and open a pull request.

## Development Setup

```bash
git clone https://github.com/kevelino/tuberip.git
cd tuberip
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
```

## Code Style

- Python 3.9+ syntax
- 4 spaces, no tabs
- Type hints on public functions and dataclasses
- Keep UI code in `src/tuberip/ui/`, backend in `src/tuberip/backend/`
- Do not add comments unless necessary
- Follow existing naming conventions

## Commit Messages

Use Conventional Commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` code change that neither fixes a bug nor adds a feature
- `test:` adding or updating tests
- `chore:` tooling, CI, dependencies

## Pull Request Checklist

- [ ] `PYTHONPATH=src pytest tests/` passes
- [ ] `python3 -m py_compile` passes on changed files
- [ ] README or docs updated if behavior changed
- [ ] `CHANGELOG.md` updated if applicable

## Reporting Bugs

Open an issue with:
- OS and version
- Python version
- Steps to reproduce
- Expected vs actual behavior
- Logs or terminal output if available

## Questions

Open an issue with the `question` label.

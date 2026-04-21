#!/bin/sh
# Opt in to the project's git hooks (kept under .githooks/).
# After running this once, git will run pre-commit and pre-push checks
# automatically. Undo with: git config --unset core.hooksPath
set -e

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

chmod +x .githooks/*
git config core.hooksPath .githooks
echo "Git hooks installed (core.hooksPath=.githooks)"
echo "Active hooks:"
ls -1 .githooks/ | grep -v '^\.' | sed 's/^/  - /'

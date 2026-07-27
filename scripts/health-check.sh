#!/usr/bin/env bash
#
# health-check.sh -- verify that init.el loads cleanly under batch Emacs.
#
# This is the same check described in README.org: load the full config in a
# throwaway batch session and fail if initialization raises any error.
#
# Usage:
#   scripts/health-check.sh            Load init.el and report pass/fail.
#   scripts/health-check.sh --refresh  Refresh package archives, then check.
#
# Use --refresh when installation fails with "file-error ... Not found":
# MELPA rebuilds its index daily and drops old tarballs, so a stale local
# archive can point at package versions that no longer exist on the server.
# The plain check never refreshes on its own (it would slow every run).

set -euo pipefail

# Resolve the repo root (parent of this script's directory) so the check
# works regardless of the caller's current directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ "${1:-}" == "--refresh" ]]; then
  echo "Refreshing package archives..."
  # Mirror the archive list from init.el so a refresh works even when the
  # full config cannot load yet. Keep this in sync with init.el.
  emacs --batch --eval "(progn
    (require 'package)
    (setq package-archives '((\"melpa\"  . \"https://melpa.org/packages/\")
                             (\"gnu\"    . \"https://elpa.gnu.org/packages/\")
                             (\"nongnu\" . \"https://elpa.nongnu.org/nongnu/\")))
    (package-initialize)
    (package-refresh-contents))"
fi

echo "Loading init.el under batch Emacs..."
if emacs --batch -l init.el; then
  echo "PASS: init.el loaded with no errors (exit 0)."
else
  status=$?
  echo "FAIL: init.el raised an error (exit ${status})." >&2
  exit "${status}"
fi

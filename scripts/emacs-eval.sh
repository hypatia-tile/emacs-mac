#!/usr/bin/env bash
#
# emacs-eval.sh -- evaluate an Elisp expression in a batch Emacs that has the
# package archives initialized (but does NOT load init.el). Handy for probing
# available packages/themes, checking key bindings, or any quick inspection.
#
# Usage:
#   scripts/emacs-eval.sh 'ELISP'
#   scripts/emacs-eval.sh --install PKG 'ELISP'   # ensure PKG is installed first
#
# Examples:
#   scripts/emacs-eval.sh '(princ (emacs-version))'
#   scripts/emacs-eval.sh --install tokyo-night \
#     "(dolist (th (custom-available-themes)) (princ (format \"%s\\n\" th)))"

set -euo pipefail

INSTALL_PKG=""
if [[ "${1:-}" == "--install" ]]; then
  INSTALL_PKG="${2:-}"
  shift 2 || true
fi

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: scripts/emacs-eval.sh [--install PKG] 'ELISP'" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Pass inputs via the environment so they are never mistaken for files to load.
export EMACS_EVAL_EXPR="$1"
export EMACS_EVAL_INSTALL="$INSTALL_PKG"

# Mirror the archive list from init.el so this works on its own. Keep in sync.
emacs --batch --eval "(progn
  (require 'package)
  (setq package-archives '((\"melpa\"  . \"https://melpa.org/packages/\")
                           (\"gnu\"    . \"https://elpa.gnu.org/packages/\")
                           (\"nongnu\" . \"https://elpa.nongnu.org/nongnu/\")))
  (package-initialize)
  (let ((pkg (getenv \"EMACS_EVAL_INSTALL\")))
    (when (and pkg (> (length pkg) 0))
      (let ((sym (intern pkg)))
        (unless (package-installed-p sym)
          (unless package-archive-contents (package-refresh-contents))
          (package-install sym)))))
  (eval (car (read-from-string (getenv \"EMACS_EVAL_EXPR\"))) t))"

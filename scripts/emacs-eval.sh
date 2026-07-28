#!/usr/bin/env bash
#
# emacs-eval.sh -- evaluate an Elisp expression in a batch Emacs, for probing
# the configuration or the available packages without opening an editor.
#
# Two modes:
#   (default) archives ready, init.el NOT loaded -- for probing available
#             packages/themes. Supports --install PKG.
#   --init    load the full init.el first -- for probing the LIVE config
#             (key bindings, active modes, completion-at-point-functions, ...).
#
# Usage:
#   scripts/emacs-eval.sh 'ELISP'
#   scripts/emacs-eval.sh --install PKG 'ELISP'
#   scripts/emacs-eval.sh --init 'ELISP'
#
# Examples:
#   scripts/emacs-eval.sh '(princ (emacs-version))'
#   scripts/emacs-eval.sh --install tokyo-night \
#     "(dolist (th (custom-available-themes)) (princ (format \"%s\\n\" th)))"
#   scripts/emacs-eval.sh --init "(princ (key-binding (kbd \"M-/\")))"

set -euo pipefail

LOAD_INIT=0
INSTALL_PKG=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --init)    LOAD_INIT=1; shift ;;
    --install) INSTALL_PKG="${2:-}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: scripts/emacs-eval.sh [--init | --install PKG] 'ELISP'" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Pass the expression via the environment so it is never mistaken for a file.
export EMACS_EVAL_EXPR="$1"

if [[ "$LOAD_INIT" == 1 ]]; then
  # Probe the live config: load init.el, then evaluate the expression.
  emacs --batch -l init.el \
    --eval "(eval (car (read-from-string (getenv \"EMACS_EVAL_EXPR\"))) t)"
else
  # Probe packages: initialize archives (optionally install PKG), then eval.
  # Mirror the archive list from init.el so this works on its own. Keep in sync.
  export EMACS_EVAL_INSTALL="$INSTALL_PKG"
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
fi

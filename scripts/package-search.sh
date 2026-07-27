#!/usr/bin/env bash
#
# package-search.sh -- search available ELPA/MELPA packages by name or summary.
#
# Usage:
#   scripts/package-search.sh REGEXP
#
# Prints "name  summary" for every package in the configured archives whose
# name or summary matches REGEXP (case-insensitive). This reads the local
# archive cache; if results look stale or empty, refresh it first with:
#   scripts/health-check.sh --refresh

set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: scripts/package-search.sh REGEXP" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Pass the query via the environment so it is not mistaken for a file to load.
export PKG_SEARCH_QUERY="$1"

# Mirror the archive list from init.el so search works on its own. Keep in sync.
emacs --batch --eval "(progn
  (require 'package)
  (setq package-archives '((\"melpa\"  . \"https://melpa.org/packages/\")
                           (\"gnu\"    . \"https://elpa.gnu.org/packages/\")
                           (\"nongnu\" . \"https://elpa.nongnu.org/nongnu/\")))
  (package-initialize)
  (let ((re (getenv \"PKG_SEARCH_QUERY\")) (n 0))
    (dolist (p (sort (copy-sequence package-archive-contents)
                     (lambda (a b) (string< (symbol-name (car a))
                                            (symbol-name (car b))))))
      (let* ((name (symbol-name (car p)))
             (desc (cadr p))
             (summary (if desc (package-desc-summary desc) \"\")))
        (when (or (string-match-p re name) (string-match-p re summary))
          (setq n (1+ n))
          (princ (format \"%-28s %s\\n\" name summary)))))
    (princ (format \"\\n%d package(s) matched \\\"%s\\\".\\n\" n re))))"

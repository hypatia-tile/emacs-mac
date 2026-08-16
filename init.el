;;; Package bootstrap

;; Since I'm in the learning stage, show all errors.
(setq debug-on-error t)

;; Use package manager
(require 'package)

;; Declare the source of package archives, "gnu", "nongnu", and "melpa".
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"  . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;; Isolate the write destination for saving customizations, never load it.
(setq custom-file (expand-file-name "emacs-custom-garbage.el" temporary-file-directory))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))


;;; Environment: PATH & direnv

;; exec-path-from-shell: a GUI Emacs on macOS starts with a minimal PATH and
;; does not see tools installed via nix / homebrew / direnv. Import the login
;; shell's PATH (and friends) so `direnv', compilers, etc. are found. Run only
;; under a window system; in batch (health-check) this is skipped.
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; envrc: apply each directory's .envrc (direnv) as a buffer-local environment,
;; so Emacs-native commands (compile, eglot, executable lookup) pick up the
;; per-directory nix flake dev shell. A new .envrc must be approved once with
;; `envrc-allow' (C-c e a). Needs `direnv' on PATH (exec-path-from-shell above).
;; vterm gets direnv for free via the zsh hook, so this covers the Emacs side.
(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode)
  :bind-keymap ("C-c e" . envrc-command-map))


;;; Japanese input & notes

;; ddskk
;; To set the variable `skk-large-jisyo`, it is better to use `:custom`
;; block rather than `setq` in `:config` block.
;; See: (info "(use-package)User options")
(use-package ddskk
  :ensure t
  :custom
  (skk-large-jisyo "~/.local/share/skk/SKK-JISYO.L" "Path to the standard large dictionary file (SKK-JISYO.L).")
  :bind (("C-x C-j" . skk-mode)
         ("C-x j" . skk-auto-fill-mode)))

;; Org-mode
;; TODO: For now, I put in anything that sounds useful, since I need to
;; take some notes for my task management and the behavior seems good.
;; Although I should restructure this and add more comments for
;; reasoning, I use the current style for the time being.
(use-package org
  ;; Since Org-mode is a built-in package in Emacs, setting `:ensure t`
  ;; will cause Emacs to search for and try to install it from external
  ;; repositories. To prevent this, omit `:ensure t` or explicitly set
  ;; `:ensure nil` for built-in packages.
  :ensure nil
  :defer t
  :bind
  ("C-c l" . org-store-link)
  ("C-c a" . org-agenda)
  ("C-c c" . org-capture)
  :custom
  (org-agenda-files '("~/org-notes-proto/todo.org" "~/org-notes-proto/now.org") "Tentative agenda file I am currently using.")
  (org-startup-indented t)
  (org-log-done 'time)
  (org-startup-folded t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  :hook
  (org-mode . visual-line-mode))


;;; Completion

;; Vertico: vertical interactive completion UI for the minibuffer.
;; It enhances the built-in `completing-read', so all commands that
;; read from the minibuffer (M-x, C-x C-f, C-x b, ...) get a vertical,
;; incrementally-filtered candidate list.
(use-package vertico
  :ensure t
  :init
  (vertico-mode))

;; Orderless: a completion style that matches space-separated components
;; in any order, anywhere in the candidate. Pairs with vertico, which only
;; handles how candidates are displayed, not how they are filtered.
(use-package orderless
  :ensure t
  :custom
  ;; Try `orderless' first, fall back to the built-in `basic' style so that
  ;; exact/prefix matching (and TAB completion) still works as expected.
  (completion-styles '(orderless basic))
  ;; For file paths, keep `partial-completion' so "/u/s/l" can expand to
  ;; "/usr/share/lib"; `orderless' is not ideal for path segments.
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Marginalia: add annotations (docstrings, file metadata, key bindings, ...)
;; in the right margin of minibuffer candidates. Display only -- it does not
;; affect how vertico lists or how orderless filters.
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

;; Consult: a collection of practical search/navigation commands built on top
;; of the minibuffer completion (vertico). Many commands show a live preview.
;; These upgrade the standard keys in place (C-x b, M-y, C-s, M-g g); plain
;; isearch-forward moves to M-s s (see the Keybindings section).
(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)    ; replaces switch-to-buffer (+ recent, bookmarks)
         ("M-y"   . consult-yank-pop)   ; replaces yank-pop (preview the kill-ring)
         ("C-s"   . consult-line)       ; replaces isearch-forward (now on M-s s)
         ("M-g g" . consult-goto-line)  ; replaces goto-line (with preview)
         ("M-g i" . consult-imenu)      ; jump to a function/heading
         ("M-s g" . consult-grep)       ; grep across files
         ("M-s r" . consult-ripgrep)    ; ripgrep across the project
         ;; Upgrade the standard bookmark jump (C-x r b): consult-bookmark adds
         ;; a preview and can create a bookmark on the fly. C-x r m (set) and
         ;; C-x r l (list) stay as the built-in bookmark commands.
         ("C-x r b" . consult-bookmark)))

;; Corfu: in-buffer completion popup at point -- the buffer-local counterpart
;; to vertico (which handles the minibuffer). It displays whatever
;; `completion-at-point' offers, including eglot's LSP candidates.
(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)               ; pop up automatically while typing
  ;; Let TAB do indentation first and completion when already indented, so
  ;; TAB is a natural trigger for the corfu popup.
  (tab-always-indent 'complete))

;; Cape: extra completion-at-point sources for corfu. Add buffer-word
;; completion (cape-dabbrev) and file-path completion (cape-file) to the global
;; capf list, so corfu offers them in ordinary buffers. Note: in eglot (LSP)
;; buffers eglot sets its own buffer-local capf, so LSP completion stays primary
;; there; merging buffer words into LSP buffers (cape-capf-super) is deferred.
(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;; Which-key: after starting a key sequence, pop up the available follow-up
;; keys (e.g. press C-x and pause to see every C-x binding). Built into
;; Emacs 30, so no installation is needed (:ensure nil, like org).
(use-package which-key
  :ensure nil
  :init
  (which-key-mode))


;;; Tools

;; Magit: a full-featured git interface. `C-x g' opens the status buffer,
;; from which staging, committing, pushing, branching, log browsing, etc. are
;; all a few keys away. Press `?' inside any magit buffer for a menu.
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; Vterm: a fast terminal emulator backed by libvterm, for day-to-day shell
;; work inside Emacs. `C-c t' opens one. It runs $SHELL (zsh), whose direnv
;; hook loads each directory's .envrc automatically. The native module is
;; compiled on first use (needs cmake + libtool, both installed).
(use-package vterm
  :ensure t
  :bind ("C-c t" . vterm))


;;; Languages & LSP

;; Eglot (built-in): a minimal LSP client. Auto-start the server for C/C++
;; (clangd), Rust (rust-analyzer), and LaTeX (texlab; AUCTeX's LaTeX-mode is
;; recognized as a tex-mode derivative by eglot's built-in server table).
;; Servers are found via PATH
;; (exec-path-from-shell) or, inside a project, via the flake toolchain that
;; envrc applies; clangd reads compile_commands.json. Standard Emacs facilities
;; do the rest: eldoc (hover), flymake (diagnostics, see below), xref (M-. ;
;; go-back on C-c ,), completion-at-point (shown by corfu). Rename:
;; M-x eglot-rename. Format the buffer with C-c f (eglot-format-buffer), which
;; drives the server's formatter (e.g. rust-analyzer -> rustfmt); M-x
;; eglot-format handles a region. The key lives in eglot-mode-map, so it is
;; active only in LSP-managed buffers.
(use-package eglot
  :ensure nil
  :hook ((c-mode c++-mode rust-ts-mode LaTeX-mode) . eglot-ensure)
  :bind (:map eglot-mode-map
              ("C-c f" . eglot-format-buffer))
  :config
  ;; eglot's built-in tex entry offers a choice between digestif and texlab and
  ;; picks digestif -- which has no formatting -- when both are present (the TeX
  ;; Live flake ships both). Pin tex modes (incl. AUCTeX's LaTeX-mode, a
  ;; tex-mode derivative) to texlab so completion, diagnostics and C-c f all
  ;; come from one server. texlab formats out of the box via latexindent, so no
  ;; extra workspace configuration is needed.
  (add-to-list 'eglot-server-programs '((tex-mode) . ("texlab"))))

;; Rust: use the built-in tree-sitter mode. It needs the Rust grammar, so
;; record its source and install it once if missing -- but only under a window
;; system, to keep the batch health-check offline and fast. `.rs' maps to
;; rust-ts-mode; eglot (rust-analyzer) is started via the shared hook above.
(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :init
  (require 'treesit)
  (add-to-list 'treesit-language-source-alist
               '(rust "https://github.com/tree-sitter/tree-sitter-rust"))
  (when (and (memq window-system '(mac ns x))
             (not (treesit-language-available-p 'rust)))
    (treesit-install-language-grammar 'rust)))

;; Flymake diagnostics navigation. Modern flymake ships no default keys and
;; next-error (M-g n / M-g p) is not wired to flymake here, so bind the flymake
;; jumpers under the classic C-c ! prefix (Ctrl-based; M-n would be a dead key
;; on macOS). Active only where flymake-mode is on (e.g. eglot buffers).
(use-package flymake
  :ensure nil
  :bind (:map flymake-mode-map
              ("C-c ! n" . flymake-goto-next-error)
              ("C-c ! p" . flymake-goto-prev-error)
              ("C-c ! l" . flymake-show-buffer-diagnostics)))

;; AUCTeX: a full LaTeX editing environment (LaTeX-mode, compilation, math
;; input, folding). The package exposes no `auctex' feature to require, so the
;; use-package is named after a real feature it ships (`tex') while
;; `:ensure auctex' installs the package. LaTeX-mode is AUCTeX's enhanced
;; replacement for the built-in latex-mode. Skim/SyncTeX viewing and the texlab
;; LSP layer are added in later steps; this block is editing + compilation.
;; The TeX toolchain lives in a per-project nix flake, applied buffer-locally
;; by envrc -- approve it once per document tree with C-c e a (envrc-allow).
(use-package tex
  :ensure auctex
  :custom
  ;; Parse the document (and cache the parse) so completion of macros, labels,
  ;; \ref/\cite targets and environments is context-aware.
  (TeX-auto-save t)
  (TeX-parse-self t)
  ;; Ask for the master file in multi-file documents instead of guessing.
  (TeX-master nil)
  ;; Produce PDF via pdflatex, not DVI.
  (TeX-PDF-mode t)
  ;; SyncTeX forward search: correlate source -> PDF so C-c C-v jumps Skim to
  ;; the line at point. Enabling this also makes AUCTeX pass --synctex=1 to the
  ;; TeX run. (Inverse search, PDF -> source, is intentionally skipped: it would
  ;; need TeX-source-correlate-start-server plus a viewer hotkey, and the
  ;; PDF->editor click collides with the window manager.)
  (TeX-source-correlate-mode t)
  ;; View PDFs in Skim (macOS, solid SyncTeX support).
  (TeX-view-program-selection '((output-pdf "Skim")))
  :config
  ;; Skim's `displayline' does SyncTeX forward search: -b draws a reading bar
  ;; at the target line, -g keeps Skim in the background (drop -g to raise Skim
  ;; on each jump). %n line, %o output PDF, %b the source .tex.
  (add-to-list 'TeX-view-program-list
               '("Skim"
                 "/Applications/Skim.app/Contents/SharedSupport/displayline -b -g %n %o %b")))


;;; Appearance

;; Tokyo Night theme, matching the kitty terminal (bg #1a1b26 / fg #c0caf5).
(use-package tokyo-night
  :ensure t
  :config
  (load-theme 'tokyo-night :no-confirm))

;; Background transparency: deferred. On macOS Tahoe (26) the built-in
;; `alpha-background' is not rendered even under emacs-plus (setting it to 50
;; still showed no transparency), so it is left out for now. To revisit, use
;; the emacs-plus `window-blur' community patch (blur + configurable alpha) or
;; the `emacs-liquid-glass' package (NSGlassEffectView, needs emacs-plus@31).

;; Hide the Start Screen (Splash Screen)
(setq inhibit-startup-screen t)

;; Disable menu bar, tool bar, and scroll bar.
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Display line number
(global-display-line-numbers-mode t)

;; Hilite current cursor line
(global-hl-line-mode t)


;;; Files & editing

;; Auto-revert: keep file-visiting buffers in sync with on-disk changes made
;; by external processes -- agents (claude/codex) editing files, magit branch
;; switches, etc. Emacs otherwise only notices at the next save and warns;
;; auto-revert reloads *unmodified* buffers automatically. A buffer with unsaved
;; edits is never clobbered -- that conflict is left for manual resolution. On
;; macOS this rides kqueue file notifications, with a 5s polling fallback.
(use-package autorevert
  :ensure nil
  ;; Parked: also auto-refresh non-file buffers (Dired listings, Buffer Menu)
  ;; so a directory view reflects files an agent adds/removes. Beyond the
  ;; current need (file-buffer sync); enable if Dired staleness starts to bite.
  ;; :custom
  ;; (global-auto-revert-non-file-buffers t)
  :init
  (global-auto-revert-mode))

(add-to-list 'auto-mode-alist '("\\.foo\\'" . c-mode))
(add-to-list 'auto-mode-alist '("\\.notes\\'" . org-mode))

;; Set the default directory for auto-save files
(setq auto-save-file-name-transforms
      `((".*" , (expand-file-name "auto-save/" user-emacs-directory) t)))

;; If the auto-save directory does not exist, create it
;; since Emacs does not create it automatically unlike the backup directory.
(let ((dir (expand-file-name "auto-save/" user-emacs-directory)))
  (unless (file-exists-p dir)
    (make-directory dir t)))

;; Set the default directory for backup files
(setq backup-directory-alist
      `((".*" . ,(expand-file-name "backup/" user-emacs-directory))))

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)


;;; Keybindings (global)

;; Global key tweaks for built-in commands, kept in one place. Package-specific
;; bindings live in their own use-package blocks (:bind). List every personal
;; binding with M-x describe-personal-keybindings.
(use-package emacs
  :ensure nil
  :bind (;; Plain isearch-forward, relocated from C-s (now consult-line). C-r
         ;; keeps the default isearch-backward.
         ("M-s s" . isearch-forward)
         ;; xref navigation on the default keys: M-. definitions (default,
         ;; unbound here), M-, go-back, M-? find-references. M-? had been
         ;; rebound to help-command (a pre-GUI leftover; help stays on C-h), and
         ;; M-, had been shadowed by AeroSpace's alt-comma binding -- now freed.
         ("M-," . xref-go-back)
         ("M-?" . xref-find-references)))

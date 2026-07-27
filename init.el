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

;; Package installations.

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
  (org-agenda-files '("~/org-notes-proto/todo.org") "Tentative agenda file I am currently using.")
  (org-startup-indented t)
  (org-log-done 'time)
  (org-startup-folded t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  :hook
  (org-mode . visual-line-mode))


;; Hide the Start Screen (Splash Screen)
(setq inhibit-startup-screen t)

(menu-bar-mode -1) ; Hide menu bar

;; Disable toolbar, menu bar, and scroll bar
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Display line number
(global-display-line-numbers-mode t)

;; Hilite current cursor line
(global-hl-line-mode t)

;; Re-bind help command
(global-set-key (kbd "M-?") 'help-command)
(global-set-key (kbd "C-x ?") 'help-command)

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

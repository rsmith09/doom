;; -*- lexical-binding: t; -*-
(setq user-full-name "Russell Smith"
      user-mail-address "russell.smith7502@gmail.com")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono"
                           :size 13
                           :weight 'normal))

(setq doom-theme 'zenburn)

(setq display-line-numbers-type t)

(map! "C-s" 'consult-line)       ; rebind Isearch to use Consult

(setq avy-all-windows t)

(map! :after avy
      "C-." 'avy-goto-char-timer)

(define-advice pop-global-mark (:around (pgm) use-display-buffer)
  "Make `pop-to-buffer' jump buffers via `display-buffer'."
  (cl-letf (((symbol-function 'switch-to-buffer)
                         #'pop-to-buffer))
                (funcall pgm)))

(use-package! cc-mode
  :bind
  (("C-x DEL" . c-hungry-delete-backwards)
   ("C-x C-d" . c-hungry-delete-forward)))

(setq global-hl-line-modes nil)

(setq next-line-add-newlines t)

(setq scroll-conservatively 10
      scroll-margin 0)

(defun my-set-whitespace-defaults ()
  ;; Only save the values the first time we get here
  (unless (boundp 'my-default-whitespace-style)
    (setq my-default-whitespace-style                (default-value 'whitespace-style)
          my-default-whitespace-display-mappings     (default-value 'whitespace-display-mappings)
          my-doom-whitespace-style                   whitespace-style
          my-doom-whitespace-display-mappings        whitespace-display-mappings
          my-whitespace-mode                         "doom")))

;; whitespace-style etc is set up with default-values in whitespace.el and then
;; modified in doom-highlight-non-default-indentation-h (in core/core-ui.el).
;; This is added to after-change-major-mode-hook in doom-init-ui-h (in
;; core/core-ui.el) and called a LOT: so I need to capture doom's modified
;; settings after that. The trouble is, this file (config.el) is called before
;; doom-init-ui-h which is called in window-setup-hook.
(add-hook 'find-file-hook #'my-set-whitespace-defaults 'append)

(defun my-toggle-whitespace ()
  (interactive)
  (cond ((equal my-whitespace-mode "doom")
         (setq whitespace-style my-default-whitespace-style
               whitespace-display-mappings my-default-whitespace-display-mappings
               my-whitespace-mode "default")
         (prin1 (concat "whitespace-mode is whitespace default"))
         (whitespace-mode))
        ((equal my-whitespace-mode "default")
         (setq my-whitespace-mode "off")
         (prin1 (concat "whitespace-mode is off"))
         (whitespace-mode -1))
        (t ; (equal bh:whitespace-mode "off")
         (setq whitespace-style my-doom-whitespace-style
               whitespace-display-mappings my-doom-whitespace-display-mappings
               my-whitespace-mode "doom")
         (prin1 (concat "whitespace-mode is doom default"))
         (whitespace-mode))))

(global-set-key (kbd "C-<f4>") #'my-toggle-whitespace)

(after! company
  (setq company-idle-delay 0.21
        company-show-quick-access t
        company-tooltip-limit 20
        company-tooltip-align-annotations t)
  (map! :map company-active-map
        "C-n" nil
        "C-p" nil))

(setq org-directory "~/org/")

(add-hook! 'org-mode-hook (auto-fill-mode +1))

(add-hook! 'prog-mode-hook
  (rainbow-delimiters-mode-enable)
  (display-fill-column-indicator-mode))

(add-hook! 'prog-mode-hook (setq-local tab-always-indent t))

(setq-hook! '(c-ts-mode-hook c++-ts-mode-hook)
  c-ts-mode-indent-style 'linux
  c-ts-mode-indent-offset 4)

(add-to-list '+format-on-save-disabled-modes 'c++-ts-mode)
(add-to-list '+format-on-save-disabled-modes 'c-ts-mode)

(add-hook! 'lisp-mode-hook (setq-local company-idle-delay nil))

(map! :map smartparens-mode-map
      "C-<right>" 'sp-forward-slurp-sexp
      "M-<right>" 'sp-forward-barf-sexp
      "C-<left>" 'sp-backward-slurp-sexp
      "M-<left>" 'sp-backward-barf-sexp)

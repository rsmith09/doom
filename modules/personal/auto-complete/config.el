;;; config.el -*- lexical-binding: t; -*-

;; Completion candidate frontend
(use-package! corfu
  :hook (((prog-mode text-mode) . corfu-mode))
  :bind
  (:map corfu-map
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous))
  :config
  (setq corfu-auto t
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-count 16
        corfu-max-width 120
        corfu-quit-no-match t)

  (add-to-list 'completion-category-overrides `(lsp-capf (styles ,@completion-styles)))
  ;; HACK: If your dictionaries aren't set up in text-mode buffers, ispell will
  ;;   continuously pester you about errors. This ensures it only happens once
  ;;   per session.
  (defadvice! +corfu--auto-disable-ispell-capf-a (fn &rest args)
    "If ispell isn't properly set up, only complain once per session."
    :around #'ispell-completion-at-point
    (condition-case-unless-debug e
        (apply fn args)
      ('error
       (message "Error: %s" (error-message-string e))
       (message "Auto-disabling `text-mode-ispell-word-completion'")
       (setq text-mode-ispell-word-completion nil)
       (remove-hook 'completion-at-point-functions #'ispell-completion-at-point t)))))

(use-package! nerd-icons-corfu
  :when (modulep! +icons)
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;;; Backend completion-at-point functions.
(defcustom +cape-buffer-scanning-size-limit (* 1 1024 1024) ; 1 MB
  "Size limit in bytes for a buffer to be scanned by `cape-dabbrev'."
  :type 'integer
  :group '+cape)

(use-package! cape
  :commands (+cape-dabbrev-friend-buffer-p
             +cape--add-cape-file-h
             +cape--add-cape-dabbrev-h)
  :hook ((prog-mode . +cape--add-cape-file-h)
         ((prog-mode-hook
           text-mode-hook
           conf-mode-hook
           comint-mode-hook
           minibuffer-setup-hook
           eshell-mode-hook) . +cape--add-cape-dabbrev-h))
  :config
  (defun +cape-dabbrev-friend-buffer-p (other-buffer)
    (< (buffer-size other-buffer) +cape-buffer-scanning-size-limit))

  (defun +cape--add-cape-file-h ()
    (add-hook 'completion-at-point-functions #'cape-file -10 t))

  (defun +cape--add-cape-dabbrev-h ()
    (add-hook 'completion-at-point-functions #'cape-dabbrev 20 t))

  (setq cape-dabbrev-check-other-buffers t)
  ;; From the `cape' readme. Without this, Eshell autocompletion is broken on
  ;; Emacs28.
  (when (< emacs-major-version 29)
    (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-silent)
    (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-purify))

  (when (modulep! :lang latex)
    ;; Allow file completion on latex directives.
    (setq-hook! '(tex-mode-local-vars-hook
                  latex-mode-local-vars-hook
                  LaTeX-mode-local-vars-hook)
      cape-file-prefix "{"))

  (after! dabbrev
    (setq dabbrev-friend-buffer-function #'+cape-dabbrev-friend-buffer-p
          dabbrev-ignored-buffer-regexps
          '("\\` "
            "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
          dabbrev-upcase-means-case-search t)
    (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
    (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
    (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))
  ;; Make these capfs composable.
  (advice-add #'lsp-completion-at-point :around #'cape-wrap-noninterruptible)
  (advice-add #'lsp-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))

(use-package! yasnippet-capf
  :when (modulep! :editor snippets)
  :commands (+cape--add-yasnippet-capf-h)
  :hook ((yas-minor-mode . +cape--add-yasnippet-capf-h))
  :config
  (defun +cape--add-yasnippet-capf-h ()
    (add-hook 'completion-at-point-functions #'yasnippet-capf 30 t)))

;; If vertico is not enabled, orderless will be installed but not configured.
;; That may break smart separator behavior, so we conditionally configure it.
(use-package! orderless
  :when (not (modulep! :completion vertico))
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles orderless partial-completion)))
        orderless-component-separator #'orderless-escapable-split-on-space))

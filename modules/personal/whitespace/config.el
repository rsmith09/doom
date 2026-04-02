;;; editor/whitespace/config.el -*- lexical-binding: t; -*-

(defvar +whitespace-guess-excluded-modes
  '(pascal-mode
    so-long-mode
    ;; Variable-width indentation is superior in elisp. Otherwise, `dtrt-indent'
    ;; and `editorconfig' would force fixed indentation on elisp.
    emacs-lisp-mode
    ;; See #5823: indent detection is slow and inconclusive in these major modes
    ;; so they are disabled there.
    coq-mode
    ;; Automatic indent detection in org files is meaningless. Not to mention, a
    ;; non-standard `tab-width' causes an error in org-mode.
    org-mode)
  "A list of major modes where indentation shouldn't be auto-detected.")

(defvar +whitespace-guess-in-projects nil
  "If non-nil, indentation settings will be guessed in project files.

This is off by default because, generally, indent-guessing is less useful for
projects, which have many options for configuring editors (editorconfig,
.dir-locals.el, global settings, etc). While single files have fewer options and
are more likely to use varied styles (and would be a pain to accommodate on a
per-file basis).")

(defvar-local +whitespace-guess-inhibit nil
  "A buffer-local flag that indicates whether `dtrt-indent' should try to guess
indentation settings or not. This should be set by editorconfig if it
successfully sets indent_style/indent_size.")

(defvar +whitespace-styles
  `(("check-indentation" . +whitespace-check-indent-style)
    ("default" . ((face
                   tabs spaces trailing lines space-before-tab newline
                   indentation empty space-after-tab
                   space-mark tab-mark newline-mark
                   missing-newline-at-eof)
                  ((space-mark   ?\     [?·]      [?.])
                   (space-mark   ?\xA0  [?¤]      [?_])
                   (newline-mark ?\n    [?$ ?\n])
                   (tab-mark     ?\t    [?» ?\t]  [?\\ ?\t])))))
  "Alist of style defintions available to toggle.

The alist keys are strings that name the style. There are two valid
types for the alist values: a list containing valid values for the
`whitespace-style' and `whitespace-display-mappings' variables, or a
function taking no arguments that returns the same type of list.")

(defvar-local +whitespace-default-style (when +whitespace-styles
                                          (caar +whitespace-styles))
  "Default style enabled when `+whitespace-mode' is enabled.

This variable can contain the name of any style listed in
`+whitespace-styles' or nil, which uses the current `whitespace-mode'
values as the default style.")

(defvar-local +whitespace-active-style nil
  "Name of the currently activated style.")

(defvar-local +whitespace-saved-state ()
  "List containing saved `whitespace-style' and
`whitespace-display-mappings' variable values.

These values are restored when `+whitespace-mode' is disabled.")

(defvar +whitespace-watched-variables '(indent-tabs-mode)
  "Variables watched by `+whitespace-mode' to update highlighting.

Any dynamic variables read by style functions should be listed here so
that highlighting is updated when those variables are changed.")

;;
;;; Packages

(use-package! whitespace
  :hook ((prog-mode text-mode) . +whitespace-mode)
  :init
  (defun +whitespace-check-indent-style ()
    "Highlight whitespace at odds with `indent-tabs-mode'.

That is, highlight tabs if `indent-tabs-mode' is `nil', and highlight
spaces at the beginnings of lines if `indent-tabs-mode' is `t'. The
purpose is to make incorrect indentation in the current buffer obvious
to you, so it can be noticed and corrected."
    (let ((style (append '(face)
                         (if indent-tabs-mode
                             '(indentation)
                           '(tabs tab-mark))))
          (mappings '((tab-mark ?\t [?› ?\t])
                      (newline-mark ?\n [?¬ ?\n])
                      (space-mark ?\  [?·] [?.]))))
      (list style mappings)))
  :config
  (setq whitespace-line-column nil)
  ;; HACK: `whitespace-mode' inundates child frames with whitespace markers, so
  ;; disable it to fix all that visual noise.
  (defun +whitespace--in-parent-frame-p () (null (frame-parameter nil 'parent-frame)))
  (add-function :before-while whitespace-enable-predicate #'+whitespace--in-parent-frame-p))


(use-package! dtrt-indent
  :when (modulep! +guess)
  ;; Automatic detection of indent settings
  :unless noninteractive
  ;; I'm not using `global-dtrt-indent-mode' because it has hard-coded and rigid
  ;; major mode checks, so I implement it in `+whitespace-guess-indentation-h'.
  :hook ((change-major-mode-after-body read-only-mode) . +whitespace-guess-indentation-h)
  :config
  (defun +whitespace-guess-indentation-h ()
    (unless (or (not after-init-time)
                (bound-and-true-p so-long-detected-p)
                +whitespace-guess-inhibit
                (eq major-mode 'fundamental-mode)
                (member (substring (buffer-name) 0 1) '(" " "*"))
                (apply #'derived-mode-p +whitespace-guess-excluded-modes)
                buffer-read-only
                (and (not +whitespace-guess-in-projects)
                     (doom-project-root)))
      ;; Don't display messages in the echo area, but still log them
      (let ((inhibit-message (not init-file-debug)))
        (dtrt-indent-mode +1))))

  ;; Enable dtrt-indent even in smie modes so that it can update `tab-width',
  ;; `standard-indent' and `evil-shift-width' there as well.
  (setq dtrt-indent-run-after-smie t)
  ;; Reduced from the default of 5000 for slightly faster analysis
  (setq dtrt-indent-max-lines 2000)

  ;; Always keep tab-width up-to-date
  (add-to-list 'dtrt-indent-hook-generic-mapping-list '(t tab-width))

  ;; Add missing language support
  ;; REVIEW: PR these upstream.
  (add-to-list 'dtrt-indent-hook-mapping-list '(gdscript-mode default gdscript-indent-offset))
  (add-to-list 'dtrt-indent-hook-mapping-list '(graphviz-mode graphviz-dot-indent-width))
  (add-to-list 'dtrt-indent-hook-mapping-list '(janet-mode janet janet-indent))

  (defadvice! +whitespace--guess-smie-modes-a (fn &optional arg)
    "Some smie modes throw errors when trying to guess their indentation, like
`nim-mode'. This prevents them from leaving Emacs in a broken state."
    :around #'dtrt-indent-mode
    (let ((dtrt-indent-run-after-smie dtrt-indent-run-after-smie))
      (letf! ((defun symbol-config--guess (beg end)
                (funcall symbol-config--guess beg (min end 10000)))
              (defun smie-config-guess ()
                (condition-case e (funcall smie-config-guess)
                  (error (setq dtrt-indent-run-after-smie t)
                         (message "[WARNING] Indent detection: %s"
                                  (error-message-string e))
                         (message ""))))) ; warn silently
        (funcall fn arg)))))


;; a less intrusive `delete-trailing-whitespaces' on save
(use-package! ws-butler
  :when (modulep! +trim)
  :hook (doom-first-buffer . ws-butler-global-mode)
  :config
  (pushnew! ws-butler-global-exempt-modes
            'special-mode
            'comint-mode
            'term-mode
            'eshell-mode
            'diff-mode))

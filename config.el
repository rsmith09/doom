;;;; -*- lexical-binding: t; -*-

(setq user-full-name "Russell Smith"
      user-mail-address "russell.smith7502@gmail.com")

(setq doom-theme 'doom-zenburn)

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono"
                           :size 13
                           :weight 'normal))

(setq display-line-numbers-type t)

(setq +word-wrap-fill-style 'soft)

(defun visual-line-range ()
  (save-excursion
    (cons (progn (vertical-motion 0) (point))
          (progn (vertical-motion 1) (point)))))

(setq hl-line-range-function #'visual-line-range)

(when (modulep! :personal whitespace)
  (map! :map doom-leader-toggle-map
        :desc "Whitespace Style" "W" #'+whitespace/toggle-style))

(setq next-line-add-newlines t)

(map! "C-." 'avy-goto-char-timer)

(setq avy-all-windows t)

(define-advice pop-global-mark (:around (pgm) use-display-buffer)
  "Make `pop-to-buffer' jump buffers via `display-buffer'."
  (cl-letf (((symbol-function 'switch-to-buffer) #'pop-to-buffer))
    (funcall pgm)))

(defun avy-action-embark (pt)
  (unwind-protect
      (save-excursion
        (goto-char pt)
        (embark-act))
    (select-window
     (cdr (ring-ref avy-ring 0))))
  t)

(after! avy
  (setf (alist-get ?o avy-dispatch-alist) 'avy-action-embark))

(defun my-isearch-consult-line ()
  "Invoke `consult-line' from isearch."
  (interactive)
  (let ((query (if isearch-regexp
                   isearch-string
                 (regexp-quote isearch-string))))
    (isearch-update-ring isearch-string isearch-regexp)
    (let (search-nonincremental-instead)
      (ignore-errors (isearch-done t t)))
    (consult-line query)))

(after! isearch
  (setq search-nonincremental-instead nil) ; disable nonincremental search when input is empty on RET
  (map! :map isearch-mode-map
        "C-h" #'isearch-describe-bindings
        "C-d" #'isearch-forward-symbol-at-point ; often quicker than M-s .
        "C-l" #'my-isearch-consult-line
        "C-." #'avy-isearch
        "M-@" #'anzu-isearch-query-replace ; M-% is too much of a stretch
        [remap isearch-query-replace]         #'anzu-isearch-query-replace
        [remap isearch-query-replace-regexp]  #'anzu-isearch-query-replace-regexp))

(map! :after smartparens
      :map smartparens-mode-map
      "C-<right>" 'sp-forward-slurp-sexp
      "M-<right>" 'sp-forward-barf-sexp
      "C-<left>" 'sp-backward-slurp-sexp
      "M-<left>" 'sp-backward-barf-sexp)

(defun empty-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

(defun my-fill-paragraph (&optional region empty)
  (interactive (progn (barf-if-buffer-read-only)
                      (list t current-prefix-arg)))
  (let ((empty (or empty 1)))
    (if (or (eq empty '-)
            (cl-minusp empty))
        (empty-paragraph region)
      (fill-paragraph t region))))

(map! "M-q" 'my-fill-paragraph)

(setq +workspaces-on-switch-project-behavior t)

(after! corfu
  (setq corfu-auto nil
        corfu-cycle t
        corfu-on-exact-match 'insert))

(setq-default tab-always-indent 'complete) ; indent line or complete

(after! spell-fu
  (unless (file-exists-p ispell-personal-dictionary)
    (make-directory (file-name-directory ispell-personal-dictionary) t)
    (with-temp-file ispell-personal-dictionary
      (insert (format "personal_ws-1.1 %s 0\n" ispell-dictionary)))))

(setq org-directory "~/Documents/Org/"
      org-startup-indented t)

(setq-hook! org-mode fill-column 120)

(cl-defmacro my-set-org-header-style ((top-level-height height-diff) &rest args)
  "Set the height of Org head lines with evenly spaced height differences."
  (declare (indent defun))
  `(progn
     ,@(cl-loop for height = top-level-height then (- height height-diff)
                for level from 1
                while (>= height 1)
                collect (let ((level-name (intern (format "org-level-%d" level))))
                          `(set-face-attribute ',level-name nil
                            :height ,height
                            ,@args)))))

(after! org
  (my-set-org-header-style (1.6 0.2)
    :weight 'bold))

(when (modulep! :personal auto-complete)
  (setq-hook! org-mode
    completion-at-point-functions
    (list #'cape-elisp-block
          (cape-capf-super #'cape-dabbrev
                           #'cape-dict))))

(add-hook! prog-mode '(rainbow-delimiters-mode display-fill-column-indicator-mode))

(setq lsp-headerline-breadcrumb-enable t)

(after! sly
  (put 'iter 'common-lisp-indent-function 0))

(setq-hook! '(c-ts-mode-hook c++-ts-mode-hook)
  c-ts-mode-indent-style 'linux
  c-ts-mode-indent-offset 4)

(add-to-list '+format-on-save-disabled-modes 'c++-ts-mode)
(add-to-list '+format-on-save-disabled-modes 'c-ts-mode)

(use-package! cc-mode
  :bind (("C-x DEL" . c-hungry-delete-backwards)
         ("C-x C-d" . c-hungry-delete-forward)))

;;; editor/whitespace/autoload.el -*- lexical-binding: t; -*-

(defun +whitespace--watcher (symbol newval _op buffer)
  "`+whitespace-mode' variable watcher that reactivates styles."
  (when buffer
    (with-current-buffer buffer
      (when +whitespace-mode
        ;;Style functions are going to expect the value to already be updated.
        (set symbol newval)
        (+whitespace/toggle-style +whitespace-active-style)))))

;;;###autoload
(define-minor-mode +whitespace-mode
  "Allows toggling predefined dynamic `whitespace-mode' styles."
  :init-value nil
  :lighter "+ws"
  (require 'whitespace)
  (cond (+whitespace-mode
         (setq-local +whitespace-saved-state
                     (list whitespace-style whitespace-display-mappings))
         (+whitespace/toggle-style +whitespace-default-style)
         (dolist (var +whitespace-watched-variables)
           (add-variable-watcher var #'+whitespace--watcher)))
        (t (cl-destructuring-bind (style mappings) +whitespace-saved-state
             (setq-local whitespace-style style
                         whitespace-display-mappings mappings
                         +whitespace-active-style nil))
           (whitespace-mode -1)
           (dolist (var +whitespace-watched-variables)
             (remove-variable-watcher var #'+whitespace--watcher)))))

;;;###autoload
(defun +whitespace/toggle-style (name &optional print-msg-p)
  "Toggle `+whitespace-mode''s active style.

If `+whitespace-mode' is not already enabled, enables it. If NAME is
nil, this function does nothing."
  (interactive (list (if +whitespace-styles
                         (completing-read "Style: " +whitespace-styles nil t)
                       (message "no +whitespace-mode styles defined")
                       nil)
                     t))
  (when name
    (let ((+ws-style (alist-get name +whitespace-styles nil nil #'equal)))
      (cl-destructuring-bind (style mappings)
          (cl-typecase +ws-style
            (cons +ws-style)
            (symbol (funcall +ws-style))
            (otherwise (error "malformed +whitespace-mode style: %s" +ws-style)))
        (setq-local whitespace-style style
                    whitespace-display-mappings mappings
                    +whitespace-active-style name)))
    ;; Refresh `whitespace-mode''s overlays
    (whitespace-mode -1)
    (whitespace-mode)
    (when print-msg-p
      (message "activated +whitespace-mode style: %s" name))
    name))

;;;; autoload.el -*- lexical-binding: t; -*-

;;;###autoload
(define-minor-mode ++word-wrap-mode
  "Toggle word wrapping.

This mode enables word wrapping at the `fill-column' via
`visual-line-mode' and `visual-fill-column-mode'. If the word-wrap
module is enabled, `+word-wrap-mode' is used as the backend."
  :init-value nil
  (cond (++word-wrap-mode
         (++word-wrap--turn-on))
        (t (++word-wrap--turn-off))))

(defun ++word-wrap--turn-on ()
  "Turn on `++word-wrap-mode' locally."
  (if (modulep! word-wrap)
      (+word-wrap-mode)
    (visual-line-mode)
    (visual-fill-column-mode)))

(defun ++word-wrap--turn-off ()
  "Turn on `++word-wrap-mode' locally."
  (when (modulep! word-wrap)
    (+word-wrap-mode -1))
  (visual-line-mode -1)
  (visual-fill-column-mode -1))

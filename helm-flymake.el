;;; helm-flymake.el --- Some extensions and enhancements for Helm -*- lexical-binding: t; -*-

;; Author: zbelial
;; Maintainer: zbelial
;; Version: 0.1.0
;; Package-Requires: ((helm "3.9.4") (emacs "28.1"))
;; Homepage: https://github.com/zbelial/helm
;; Keywords: helm Emacs


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;;; Code:

(require 'flymake)
(require 'helm)

(defcustom helm-flymake-actions
  '(("Goto flymake diagnostic" . helm-flymake-action-goto))
  "Actions for helm-flymake."
  :type '(alist :key-type string :value-type function))

(defun helm-flymake-action-goto (x)
  "Goto where there is any diagnostic."
  (goto-char (plist-get x :beg))
  (recenter))

(defvar helm-flymake-source-name "Helm Flymake"
  "Source name of helm flymake.")

(defvar helm-flymake-buffer-name " *Helm Flymake*"
  "Buffer name of helm flymake.")

(defun helm-flymake--format-type (type)
  (let (face
	display-type
	(type (symbol-name type)))
    (cond
     ((string-suffix-p "note" type)
      (setq display-type "note")
      (setq face 'success))
     ((string-suffix-p "warning" type)
      (setq display-type "warning")
      (setq face 'warning))
     ((string-suffix-p "error" type)
      (setq display-type "error")
      (setq face 'error))
     (t
      (setq display-type "note")
      (setq face 'warning)))
    (propertize (format "%s" display-type) 'face face)))

(defun helm-flymake--transformer (diag)
  (let* (msg
	 (beg (flymake--diag-beg diag))
	 (end (flymake--diag-end diag))
	 (type (flymake--diag-type diag))
	 (text (flymake--diag-text diag))
	 (line (line-number-at-pos beg)))
    (setq msg (format "%-8d  %-12s    %s" line (helm-flymake--format-type type) text))
    (cons msg (list :line line :type type :text text :beg beg :end end))))

;;;###autoload
(defun helm-flymake ()
  "Helm interface for flymake."
  (interactive)
  (helm :sources (helm-build-sync-source helm-flymake-source-name
                   :candidates (mapcar #'helm-flymake--transformer (flymake-diagnostics))
                   :action 'helm-flymake-actions)
        :buffer helm-flymake-buffer-name))

(provide 'helm-flymake)

;;; helm-flymakes.el ends here

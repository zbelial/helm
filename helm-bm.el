;;; helm-bm.el --- Some extensions and enhancements for Helm -*- lexical-binding: t; -*-

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

(require 'bm)
(require 'helm)

(defface helm-bm-annotation-face nil
  "Face used for annotation."
  :group 'helm-bm)

(defcustom helm-bm-actions
  '(("Jump to bm" . helm-bm-jump))
  "Actions for helm-bm."
  :type '(alist :key-type string :value-type function))

(defvar helm-bm-source-name "Helm Bm"
  "Source name of helm bm.")

(defvar helm-bm-buffer-name " *Helm Bm*"
  "Buffer name of helm bm.")

(defun helm-bm-bookmarks-all()
  (let (all bms)
    (dolist (buf (buffer-list))
      (setq bms (helm-bm-bookmarks-in-buffer buf))
      (when bms
        (setq all (append all bms))))
    all))

(defun helm-bm-bookmarks-in-buffer (&optional buf)
  "Gets a list of bookmarks in BUF, which can be a string or a buffer."
  (let ((buf (or buf (buffer-name)))
        (mklist (lambda (x) (if (listp x) x (list x)))))
    (funcall mklist
             (with-current-buffer buf
               (apply 'append
                      (mapcar mklist (remove nil (bm-lists))))))))

(defun helm-bm-candidate-transformer (bm)
  "Return a string displayed in helm buffer."
  (let ((bufname (plist-get bm :bufname))
        (lineno (plist-get bm :lineno))
        (content (plist-get bm :content))
        (annotation (plist-get bm :annotation)))
    (format "%s:%s:%s%s"
            (propertize bufname 'face compilation-info-face)
            (propertize lineno 'face compilation-line-face)
            content
            (if (length= annotation 0) ""
              (concat "\n  "
                      (propertize annotation 'face
                                  'helm-bm-annotation-face))))))

(defun helm-bm-transform-to-candicate (bm)
  "Convert a BM to a CANDICATE."
  (let ((current-buf (overlay-buffer bm)))
    (with-current-buffer current-buf
      (let* ((start (overlay-start bm))
             (end (overlay-end bm))
             (bufname (buffer-name current-buf))
             (annotation (overlay-get bm 'annotation))
             (lineno (line-number-at-pos start)))
        (unless (< (- end start) 1)
          (list 
           :bufname bufname
           :lineno (int-to-string lineno)
           :content (buffer-substring-no-properties start (1- end))
           :annotation annotation))))))


(defun helm-bm-candidates (&optional all)
  (let ((bms (mapcar #'helm-bm-transform-to-candicate
                     (if all
                         (helm-bm-bookmarks-all)
                       (helm-bm-bookmarks-in-buffer)))))
    (delq nil (mapcar #'(lambda (bm)
                          (cons (helm-bm-candidate-transformer bm) bm))
                      bms))))

(defun helm-bm-goto-line (linum &optional buf)
  (let ((buf (or buf (current-buffer))))
    (with-current-buffer buf
      (goto-char (point-min))
      (forward-line (1- linum)))))

(defun helm-bm-jump (cand)
  (let* ((bm cand)
         (bufname (plist-get bm :bufname))
         (lineno (plist-get bm :lineno)))
    (switch-to-buffer bufname)
    (helm-bm-goto-line (string-to-number lineno))
    (recenter)))

;;;###autoload
(defun helm-bm ()
  "Jump to an bm with completion."
  (interactive)
  (let* ((all (if (equal current-prefix-arg nil)
                  nil
                t))
         (bms (helm-bm-candidates all)))
    (helm :sources (helm-build-sync-source helm-bm-source-name
                     :candidates bms
                     :action 'helm-bm-actions)
          :buffer helm-bm-buffer-name)))


(provide 'helm-bm)

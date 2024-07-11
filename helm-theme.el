;;; helm-theme.el --- Some extensions and enhancements for Helm -*- lexical-binding: t; -*-

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

(defcustom helm-theme-actions
  '(("Load theme" . helm-load-theme-action))
  "Actions for helm-theme."
  :type '(alist :key-type string :value-type function))

(declare-function powerline-reset "ext:powerline")

(defun helm-load-theme-action (x)
  "Disable current themes and load theme X."
  (condition-case nil
      (progn
        (mapc #'disable-theme custom-enabled-themes)
        (load-theme (intern x) t)
        (when (fboundp 'powerline-reset)
          (powerline-reset)))
    (error "Problem loading theme %s" x)))

(defvar helm-theme-source-name "Helm Theme"
  "Source name of helm theme.")

(defvar helm-theme-buffer-name " *Helm Theme*"
  "Buffer name of helm theme.")

;;;###autoload
(defun helm-load-theme ()
  "Load theme from helm."
  (interactive)
  (helm :sources (helm-build-sync-source helm-theme-source-name
                   :candidates (mapcar #'symbol-name
                                       (custom-available-themes))
                   :action 'helm-theme-actions)
        :buffer helm-theme-buffer-name))

(provide 'helm-theme)

;;; helm-themes.el ends here

;;; helm-outline.el --- Some extensions and enhancements for Helm -*- lexical-binding: t; -*-

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

(require 'outline)

(defface helm-outline-1
  '((t :inherit org-level-1))
  "Face for displaying level 1 headings."
  :group 'helm-faces)

(defface helm-outline-2
  '((t :inherit org-level-2))
  "Face for displaying level 2 headings."
  :group 'helm-faces)

(defface helm-outline-3
  '((t :inherit org-level-3))
  "Face for displaying level 3 headings."
  :group 'helm-faces)

(defface helm-outline-4
  '((t :inherit org-level-4))
  "Face for displaying level 4 headings."
  :group 'helm-faces)

(defface helm-outline-5
  '((t :inherit org-level-5))
  "Face for displaying level 5 headings."
  :group 'helm-faces)

(defface helm-outline-6
  '((t :inherit org-level-6))
  "Face for displaying level 6 headings."
  :group 'helm-faces)

(defface helm-outline-7
  '((t :inherit org-level-7))
  "Face for displaying level 7 headings."
  :group 'helm-faces)

(defface helm-outline-8
  '((t :inherit org-level-8))
  "Face for displaying level 8 headings."
  :group 'helm-faces)

(defface helm-outline-default
  '((t :inherit minibuffer-prompt))
  "Face for displaying headings."
  :group 'helm-faces)

(defvar helm-outline-settings
  '((emacs-lisp-mode
     :outline-regexp ";;[;*]+[\s\t]+"
     :outline-level helm-outline-level-emacs-lisp)
    (org-mode
     :outline-title helm-outline-title-org
     :action helm-org-goto-action
     :history helm-org-goto-history
     :caller helm-org-goto)
    ;; markdown-mode package
    (markdown-mode
     :outline-title helm-outline-title-markdown)
    ;; Built-in mode or AUCTeX package
    (latex-mode
     :outline-title helm-outline-title-latex))
  "Alist mapping major modes to their `helm-outline' settings.

Each entry is a pair (MAJOR-MODE . PLIST).  `helm-outline'
checks whether an entry exists for the current buffer's
MAJOR-MODE and, if so, loads the settings specified by PLIST
instead of the default settings.  The following settings are
recognized:

- `:outline-regexp' is a regexp to match the beginning of an
  outline heading.  It is only checked at the start of a line and
  so need not start with \"^\".
  Defaults to the value of the variable `outline-regexp'.

- `:outline-level' is a function of no arguments which computes
  the level of an outline heading.  It is called with point at
  the beginning of `outline-regexp' and with the match data
  corresponding to `outline-regexp'.
  Defaults to the value of the variable `outline-level'.

- `:outline-title' is a function of no arguments which returns
  the title of an outline heading.  It is called with point at
  the end of `outline-regexp' and with the match data
  corresponding to `outline-regexp'.
  Defaults to the function `helm-outline-title'.

- `:action' is a function of one argument, the selected outline
  heading to jump to.  This setting corresponds directly to its
  eponymous `helm-source' keyword, as used by `helm-outline', so
  the type of the function's argument depends on the value
  returned by `helm-outline-candidates'.
  Defaults to the function `helm-outline-action'.

- `:history' is a history list, usually a symbol representing a
  history list variable.  It corresponds directly to its
  eponymous `helm-source' keyword, as used by `helm-outline'.
  Defaults to the symbol `helm-outline-history'.

- `:display-style' overrides the variable
  `helm-outline-display-style'.

- `:path-separator' overrides the variable
  `helm-outline-path-separator'.

- `:face-style' overrides the variable
  `helm-outline-face-style'.

- `:custom-faces' overrides the variable
  `helm-outline-custom-faces'.")

(defcustom helm-outline-display-style 'path
  "The style used when displaying matched outline headings.

If `headline', the title is displayed with leading stars
indicating the outline level.

If `path', the path hierarchy is displayed.  For each entry the
title is shown.  Entries are separated with
`helm-outline-path-separator'.

If `title' or any other value, only the title of the heading is
displayed.

For displaying tags and TODO keywords in `org-mode' buffers, see
`helm-org-headline-display-tags' and
`helm-org-headline-display-todo', respectively."
  :type '(choice
          (const :tag "Title only" title)
          (const :tag "Headline" headline)
          (const :tag "Path" path)))

(defcustom helm-outline-path-separator "/"
  "String separating path entries in matched outline headings.
This variable has no effect unless
`helm-outline-display-style' is set to `path'."
  :type 'string)

(declare-function org-get-outline-path "org")


;;** `helm-outline'
(declare-function org-trim "org-macs")

(defcustom helm-outline-face-style nil
  "Determines how to style outline headings during completion.

If `org', the faces `helm-outline-1' through
`helm-outline-8' are applied in a similar way to Org.
Note that no cycling is performed, so headings on levels 9 and
higher are not styled.

If `verbatim', the faces used in the buffer are applied.  For
simple headlines in `org-mode' buffers, this is usually the same
as the `org' setting, except that it depends on how much of the
buffer has been completely fontified.  If your buffer exceeds a
certain size, headlines are styled lazily depending on which
parts of the tree are visible.  Headlines which are not yet
styled in the buffer will appear unstyled in the minibuffer as
well.  If your headlines contain parts which are fontified
differently than the headline itself (e.g. TODO keywords, tags,
links) and you want these parts to be styled properly, verbatim
is the way to go; otherwise you are probably better off using the
`org' setting instead.

If `custom', the faces defined in `helm-outline-custom-faces'
are applied.  Note that no cycling is performed, so if there is
no face defined for a certain level, headlines on that level will
not be styled.

If `nil', all headlines are highlighted using
`helm-outline-default'.

For displaying tags and TODO keywords in `org-mode' buffers, see
`helm-org-headline-display-tags' and
`helm-org-headline-display-todo', respectively."
  :type '(choice
          (const :tag "Same as org-mode" org)
          (const :tag "Verbatim" verbatim)
          (const :tag "Custom" custom)
          (const :tag "No style" nil)))

(defcustom helm-outline-custom-faces nil
  "List of faces for custom display of outline headings.

Headlines on level N are fontified with the Nth entry of this
list, starting with N = 1.  Headline levels with no corresponding
entry in this list will not be styled.

This variable has no effect unless `helm-outline-face-style'
is set to `custom'."
  :type '(repeat face))

(defun helm-outline-title ()
  "Return title of current outline heading.
Intended as a value for the `:outline-title' setting in
`helm-outline-settings', which see."
  (buffer-substring (point) (line-end-position)))

(defun helm-outline-title-org ()
  "Return title of current outline heading.
Like `helm-outline-title' (which see), but for `org-mode'
buffers."
  (let ((statistics-re "\\[[0-9]*\\(?:%\\|/[0-9]*\\)]")
        (heading (apply #'org-get-heading (helm--org-get-heading-args))))
    (cond (helm-org-headline-display-statistics
           heading)
          (heading
           (org-trim (replace-regexp-in-string statistics-re " " heading))))))

(defun helm-outline-title-markdown ()
  "Return title of current outline heading.
Like `helm-outline-title' (which see), but for
`markdown-mode' (from the eponymous package) buffers."
  ;; `outline-regexp' is set by `markdown-mode' to match both setext
  ;; (underline) and atx (hash) headings (see
  ;; `markdown-regex-header').
  (or (match-string 1)                  ; setext heading title
      (match-string 5)))                ; atx heading title

(defun helm-outline-title-latex ()
  "Return title of current outline heading.
Like `helm-outline-title' (which see), but for `latex-mode'
buffers."
  ;; `outline-regexp' is set by `latex-mode' (see variable
  ;; `latex-section-alist' for the built-in mode or function
  ;; `LaTeX-outline-regexp' for the AUCTeX package) to match section
  ;; macros, in which case we get the section name, as well as
  ;; `\appendix', `\documentclass', `\begin{document}', and
  ;; `\end{document}', in which case we simply return that.
  (if (and (assoc (match-string 1)                             ; Macro name
                  (or (bound-and-true-p LaTeX-section-list)    ; AUCTeX
                      (bound-and-true-p latex-section-alist))) ; Built-in
           (progn
             ;; Point is at end of macro name, skip stars and optional args
             (skip-chars-forward "*")
             (while (looking-at-p "\\[")
               (forward-list))
             ;; First mandatory arg should be section title
             (looking-at-p "{")))
      (buffer-substring (1+ (point)) (1- (progn (forward-list) (point))))
    (buffer-substring (line-beginning-position) (point))))

(defun helm-outline-level-emacs-lisp ()
  "Return level of current outline heading.
Like `lisp-outline-level', but adapted for the `:outline-level'
setting in `helm-outline-settings', which see."
  (if (looking-at ";;\\([;*]+\\)")
      (- (match-end 1) (match-beginning 1))
    (funcall outline-level)))

(defvar helm-outline--preselect 0
  "Index of the preselected candidate in `helm-outline'.")

(defun helm-outline-candidates (&optional settings prefix)
  "Return an alist of outline heading completion candidates.
Each element is a pair (HEADING . MARKER), where the string
HEADING is located at the position of MARKER.  SETTINGS is a
plist entry from `helm-outline-settings', which see.
PREFIX is a string prepended to all candidates."
  (let* ((bol-regex (concat "^\\(?:"
                            (or (plist-get settings :outline-regexp)
                                outline-regexp)
                            "\\)"))
         (outline-title-fn (or (plist-get settings :outline-title)
                               #'helm-outline-title))
         (outline-level-fn (or (plist-get settings :outline-level)
                               outline-level))
         (display-style (or (plist-get settings :display-style)
                            helm-outline-display-style))
         (path-separator (or (plist-get settings :path-separator)
                             helm-outline-path-separator))
         (face-style (or (plist-get settings :face-style)
                         helm-outline-face-style))
         (custom-faces (or (plist-get settings :custom-faces)
                           helm-outline-custom-faces))
         (stack-level 0)
         (orig-point (point))
         (stack (and prefix (list (helm-outline--add-face
                                   prefix 0 face-style custom-faces))))
         cands name level marker)
    (save-excursion
      (setq helm-outline--preselect 0)
      (goto-char (point-min))
      (while (re-search-forward bol-regex nil t)
        (save-excursion
          (setq name (or (save-match-data
                           (funcall outline-title-fn))
                         ""))
          (goto-char (match-beginning 0))
          (setq marker (point-marker))
          (setq level (funcall outline-level-fn))
          (cond ((eq display-style 'path)
                 ;; Update stack.  The empty entry guards against incorrect
                 ;; headline hierarchies, e.g. a level 3 headline
                 ;; immediately following a level 1 entry.
                 (while (<= level stack-level)
                   (pop stack)
                   (cl-decf stack-level))
                 (while (> level stack-level)
                   (push "" stack)
                   (cl-incf stack-level))
                 (setf (car stack)
                       (helm-outline--add-face
                        name level face-style custom-faces))
                 (setq name (mapconcat #'identity
                                       (reverse stack)
                                       path-separator)))
                (t
                 (when (eq display-style 'headline)
                   (setq name (concat (make-string level ?*) " " name)))
                 (setq name (helm-outline--add-face
                             name level face-style custom-faces))))
          (push (cons name marker) cands))
        (unless (or (string= name "")
                    (< orig-point marker))
          (cl-incf helm-outline--preselect))))
    (nreverse cands)))

(defun helm-outline--add-face (name level &optional face-style custom-faces)
  "Set the `face' property on headline NAME according to LEVEL.
FACE-STYLE and CUSTOM-FACES override `helm-outline-face-style'
and `helm-outline-custom-faces', respectively, which determine
the face to apply."
  (let ((face (cl-case (or face-style helm-outline-face-style)
                (verbatim)
                (custom (nth (1- level)
                             (or custom-faces helm-outline-custom-faces)))
                (org (format "helm-outline-%d" level))
                (t 'helm-outline-default))))
    (when face
      (put-text-property 0 (length name) 'face face name)))
  name)


(defcustom helm-outline-actions
  '(("Go to Line" . helm-outline-action))
  "Actions for helm-outline."
  :type '(alist :key-type string :value-type function))

(defun helm-outline-action (x)
  (let ((settings (cdr (assq major-mode helm-outline-settings)))
        action)
    (setq action (or (plist-get settings :action)
                     'helm-outline-goto-line))
    (funcall action x)))

(defun helm-outline-goto-line (x)
  "Go to outline X."
  (goto-char x)
  (recenter))

(defvar helm-outline-source-name "Helm Outline"
  "Source name of helm outline.")

;;;###autoload
(defun helm-outline ()
  "Jump to an outline heading with completion."
  (interactive)
  (let ((settings (cdr (assq major-mode helm-outline-settings))))
    (helm :sources (helm-build-sync-source helm-outline-source-name
                     :candidates (helm-outline-candidates settings)
                     :action 'helm-outline-actions)
          :buffer " *helm outline*")))

(defcustom helm-org-headline-display-tags nil
  "If non-nil, display tags in matched `org-mode' headlines."
  :type 'boolean)

(defcustom helm-org-headline-display-todo nil
  "If non-nil, display todo keywords in matched `org-mode' headlines."
  :type 'boolean)

(defcustom helm-org-headline-display-priority nil
  "If non-nil, display priorities in matched `org-mode' headlines."
  :type 'boolean)

(defcustom helm-org-headline-display-comment nil
  "If non-nil, display COMMENT string in matched `org-mode' headlines."
  :type 'boolean)

(defcustom helm-org-headline-display-statistics nil
  "If non-nil, display statistics cookie in matched `org-mode' headlines."
  :type 'boolean)

(defun helm-org-goto-action (x)
  "Go to headline in candidate X."
  (org-goto-marker-or-bmk x))

(defun helm--org-get-heading-args ()
  "Return list of arguments for `org-get-heading'.
Try to return the right number of arguments for the current Org
version.  Argument values are based on the
`helm-org-headline-display-*' user options."
  (nbutlast (mapcar #'not (list helm-org-headline-display-tags
                                helm-org-headline-display-todo
                                helm-org-headline-display-priority
                                helm-org-headline-display-comment))
            ;; Added in Emacs 26.1.
            (if (if (fboundp 'func-arity)
                    (< (cdr (func-arity #'org-get-heading)) 3)
                  (version< org-version "9.1.1"))
                2 0)))

(defcustom helm-org-goto-all-outline-path-prefix nil
  "Prefix for outline candidates in `helm-org-goto-all'."
  :type '(choice
          (const :tag "None" nil)
          (const :tag "File name" file-name)
          (const :tag "File name (nondirectory part)" file-name-nondirectory)
          (const :tag "Buffer name" buffer-name)))

(defun helm-org-goto-all--outline-path-prefix ()
  (cl-case helm-org-goto-all-outline-path-prefix
    (file-name buffer-file-name)
    (file-name-nondirectory (file-name-nondirectory buffer-file-name))
    (buffer-name (buffer-name))))

(provide 'helm-outline)

;;; helm-outline.el ends here

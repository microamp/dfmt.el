;;; dfmt.el --- Format D source code using dfmt

;; Copyright (C) 2017 Sangho Na <microamp@protonmail.com>

;; Author: Sangho Na
;; Version: 0.0.1

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of Emacs.

;;; Commentary:

;;; Code:

(defgroup dfmt nil
  "Frontend for dfmt."
  :group 'languages)

(defcustom dfmt-executable "dfmt"
  "The default executable for dfmt."
  :type 'string
  :group 'dfmt)

(defun dfmt--check-executable ()
  (unless (executable-find dfmt-executable)
    (error (format "%s not installed" dfmt-executable))))

(defun dfmt--error-if-unsaved ()
  (when (buffer-modified-p)
    (error (format "Please save the current buffer before invoking %s" dfmt-executable))))

(defun dfmt--build-command (filename)
  (list dfmt-executable nil t nil filename "--inplace"))

(defun dfmt--execute-command (compilation-buffer cmd)
  (with-current-buffer (get-buffer-create compilation-buffer)
    (setq buffer-read-only nil)
    (erase-buffer)
    (message (format "Running %s..." dfmt-executable))
    (let* ((win (display-buffer (current-buffer)))
           (proc (apply #'call-process cmd))
           (successful (zerop proc)))
      (compilation-mode)
      (if successful
          ;; If successful, quit the window immediately
          (progn (quit-restore-window win)
                 (revert-buffer t t t))
        ;; Otherwise, keep it displayed with errors or diffs
        (shrink-window-if-larger-than-buffer win)
        (set-window-point win (point-min)))
      (message (if successful
                   (format "%s completed" dfmt-executable)
                 (format "%s exited with %d" dfmt-executable proc))))))

;;;###autoload
(defun dfmt ()
  (interactive)
  (dfmt--check-executable)
  (dfmt--error-if-unsaved)
  (let ((compilation-buffer "*dfmt*")
        (dfmt-command (dfmt--build-command (buffer-file-name))))
    (message "buffer: %s, command: %s" compilation-buffer dfmt-command)
    (dfmt--execute-command compilation-buffer dfmt-command)))

;;;###autoload
(defun dfmt-after-save ()
  (interactive)
  (when (eq major-mode 'd-mode) (dfmt)))

(provide 'dfmt)
;;; dfmt.el ends here

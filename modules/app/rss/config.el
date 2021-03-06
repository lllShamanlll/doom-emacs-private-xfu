;;; app/rss/config.el -*- lexical-binding: t; -*-

;; This is an opinionated workflow that turns Emacs into an RSS reader, inspired
;; by apps Reeder and Readkit. It can be invoked via `=rss'. Otherwise, if you
;; don't care for the UI you can invoke elfeed directly with `elfeed'.

(defvar +rss-split-direction 'below
  "What direction to pop up the entry buffer in elfeed.")


;;
;; Packages
;;

(def-package! elfeed
  :commands elfeed
  :config
  (setq elfeed-search-filter "@1-week-ago +unread"
        elfeed-db-directory (concat doom-local-dir "elfeed/db/")
        elfeed-enclosure-default-dir (concat doom-local-dir "elfeed/enclosures/")
        elfeed-search-print-entry-function '+rss/elfeed-search-print-entry
        elfeed-search-title-min-width 80
        elfeed-show-entry-switch #'pop-to-buffer
        elfeed-show-entry-delete #'+rss/delete-pane
        shr-max-image-proportion 0.6)
  (make-directory elfeed-db-directory t)

  ;; Ensure elfeed buffers are treated as real
  (push (lambda (buf) (string-match-p "^\\*elfeed" (buffer-name buf)))
        doom-real-buffer-functions)

  (set! :popup "\\*elfeed-xwidget-webkit*" '((side . bottom) (window-height . 40)) '((select . t) (transient) (quit)))
  ;; Enhance readability of a post
  (add-hook 'elfeed-show-mode-hook #'+rss|elfeed-wrap)

  (after! elfeed-search
    (after! evil-snipe
      (push 'elfeed-search-mode evil-snipe-disabled-modes))
    (set! :evil-state 'elfeed-search-mode 'normal)
    ;; avoid ligature hang
    (advice-add #'elfeed-search--header-1         :override #'+rss/elfeed-search--header-1)
    (advice-add #'elfeed-show-next                :override #'+rss/elfeed-show-next)
    (advice-add #'elfeed-show-prev                :override #'+rss/elfeed-show-prev))

  (after! elfeed-show
    (after! evil-snipe
      (push 'elfeed-show-mode evil-snipe-disabled-modes))
    (set! :evil-state 'elfeed-show-mode 'normal)
    (advice-add #'elfeed-show-entry        :override #'+rss/elfeed-show-entry))

  (elfeed-org)
  (def-package! elfeed-link)
  (map! (:after elfeed-search
          (:map elfeed-search-mode-map
            [remap kill-this-buffer]      "q"
            [remap kill-buffer]           "q"
            :n doom-leader-key nil
            :n "q"   #'+rss/quit
            :n "e"   #'elfeed-update
            :n "r"   #'elfeed-search-untag-all-unread
            :n "u"   #'elfeed-search-tag-all-unread
            :n "s"   #'elfeed-search-live-filter
            :n "RET" #'elfeed-search-show-entry
            :n "+"   #'elfeed-search-tag-all
            :n "-"   #'elfeed-search-untag-all
            :n "S"   #'elfeed-search-set-filter
            :n "o"   #'elfeed-search-browse-url
            :n "y"   #'elfeed-search-yank))
        (:after elfeed-show
          (:map elfeed-show-mode-map
            [remap kill-this-buffer]      "q"
            [remap kill-buffer]           "q"
            :n doom-leader-key nil
            :nm "q"   #'quit-window
            :nm "o"   #'ace-link-elfeed
            :nm "RET" #'+reference/elfeed-add
            :nm "n"   #'elfeed-show-next
            :nm "p"   #'elfeed-show-prev
            :nm "+"   #'elfeed-show-tag
            :nm "-"   #'elfeed-show-untag
            :nm "s"   #'elfeed-show-new-live-search
            :nm "y" #'elfeed-show-yank))))

;;;; Elfeed-org
(def-package! elfeed-org
  :commands (elfeed-org)
  :config
  (setq rmh-elfeed-org-files '("~/.doom.d/modules/app/rss/elfeed.org")))

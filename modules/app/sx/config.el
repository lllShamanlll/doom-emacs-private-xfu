;;; app/sx/config.el -*- lexical-binding: t; -*-

(def-package! sx
  :config
  (load "sx-autoloads.el" nil t t)
  (setq sx-tab-default-order 'creation
        sx-search-default-order 'creation
        sx-question-mode-display-buffer-function 'display-buffer
        sx-default-site "stackoverflow")

  (set! :evil-state 'sx-question-mode 'insert)
  (set! :evil-state 'sx-question-list-mode 'insert)
  (map!
   (:after sx-question-list
     :map sx-question-list-mode-map
     :ni "q" #'quit-window
     :ni "RET" #'sx-display
     :ni "j" #'sx-question-list-next
     :ni "k" #'sx-question-list-previous
     :ni "n" #'sx-question-list-view-next
     :ni "p" #'sx-question-list-view-previous)
   (:after sx-question-mode
     :map sx-question-mode-map
     :i "j" #'sx-question-mode-next-section
     :i "k" #'sx-question-mode-previous-section
     :i "n" #'sx-question-list-view-next
     :i "p" #'sx-question-list-view-previous
     :ni "q" #'quit-window))
  (set! :popup "\\*sx-search-result\\*"
    '((slot . -1) (side . right) (size . 100))
    '((select . t) (quit . nil) (transient . t)))
  (set! :popup "\\*sx-question\\*"
    '((slot . 0) (side . right) (window-height . 0.6))
    '((select . t) (quit . nil) (transient . t)))
  (advice-add 'sx-search :override #'*sx-search)
  (advice-add 'sx-question-list--create-question-window :override #'*sx-question-list--create-question-window)
  (advice-add 'sx-question-list-view-previous :before #'*goto-sx-question-list)
  (advice-add 'sx-question-list-view-next :before #'*goto-sx-question-list)
  (defhydra sx-hydra (:color red :hint nil)
    "
┌^^───────────────┐
│ _a_: questions  │
│ _i_: inbox      │
│ _o_: open-link  │
│ _u_: unanswered │
│ _n_: ask        │
│ _s_: search     │
│ _r_: sort       │
└^^───────────────┘
"
    ("a" sx-tab-newest)
    ("A" sx-tab-all-questions)
    ("i" sx-inbox)
    ("o" sx-open-link)
    ("u" sx-tab-unanswered-my-tags)
    ("n" sx-ask)
    ("s" sx-search)
    ("r" sx-question-list-order-by)))

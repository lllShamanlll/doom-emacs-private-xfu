;;; lang/python/config.el -*- lexical-binding: t; -*-

(defvar +python-pyenv-root nil
  "The path to pyenv's root directory. This is automatically set when `python'
is loaded.")

(defvar +python-pyenv-versions nil
  "Available versions of python in pyenv.")

(defvar +python-conda-home nil
  "A list of host pattern and corresponding anaconda home.")

(defvar +python/set-conda-home--history nil)

(defvar-local +python-current-version nil
  "The currently active pyenv version.")


;;
;; Plugins
;;

(def-package! python
  :defer t
  :init
  (setq python-environment-directory doom-cache-dir
        python-indent-guess-indent-offset-verbose nil
        python-shell-interpreter "python")
  :config
  (add-hook! 'python-mode-hook #'(flycheck-mode highlight-numbers-mode))

  (set! :env "PYTHONPATH" "PYENV_ROOT")
  (set! :company-backend 'python-mode '(company-anaconda))
  (set! :electric 'python-mode :chars '(?:))
  (set! :repl 'python-mode #'+python/repl)

  (map! (:map python-mode-map
          (:localleader
            :desc "Conda Enable" :n "c" #'conda-env-activate-for-buffer
            :desc "LSP Enable"   :n "l" #'lsp-python-enable)
          :v "s-<return>" #'python-shell-send-region
          :ni "s-<return>" #'+python/repl-send-dwim)
        (:map inferior-python-mode-map
          :nv "C-d" #'evil-scroll-down))
  (when (executable-find "ipython")
    (setq python-shell-interpreter "ipython"
          python-shell-prompt-detect-enabled nil
          python-shell-completion-native-disabled-interpreters '("pypy" "jupyter" "ipython")
          python-shell-interpreter-args "--simple-prompt --pylab"
          python-shell-prompt-regexp "In \\[[0-9]+\\]: "
          python-shell-prompt-block-regexp "\\.\\.\\.\\.: "
          python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "))

  (define-key python-mode-map (kbd "DEL") nil) ; interferes with smartparens
  (sp-with-modes 'python-mode
    (sp-local-pair "'" nil :unless '(sp-point-before-word-p sp-point-after-word-p sp-point-before-same-p)))

  (def-package! conda
    :when (featurep! +conda)
    :config
    (setq conda-anaconda-home "/usr/local/anaconda3")
    (setq +python-conda-home
          '("/usr/local/anaconda3"
            "/ssh:xfu@hpc10.cse.cuhk.edu.hk:/research/kevinyip10/xfu/miniconda3"
            "/ssh:xfu@hpc11.cse.cuhk.edu.hk:/research/kevinyip10/xfu/miniconda3"))
    (advice-add 'anaconda-mode-bootstrap :override #'*anaconda-mode-bootstrap)
    (conda-env-autoactivate-mode -1)
    ;; (add-hook 'python-mode-hook #'conda-env-activate-for-buffer)
    (conda-env-initialize-interactive-shells)
    (conda-env-initialize-eshell)
    ;; Version management with pyenv
    (add-hook 'conda-postactivate-hook #'+python|add-version-to-modeline)
    (add-hook 'conda-postdeactivate-hook #'+python|add-version-to-modeline)))

(def-package! lpy
  :when (featurep! +lpy)
  :hook ((python-mode . lpy-mode))
  :config
  (require 'le-python)
  (require 'zoutline)
  (define-minor-mode lpy-mode "Minor mode for navigating Python code similarly to LISP."
    :keymap lpy-mode-map
    :lighter " LPY"
    (if lpy-mode
        (progn
          (setq lispy-outline-header "# ")
          (setq-local outline-regexp "# \\*+")
          (setq-local lispy-outline (concat "^" outline-regexp))
          (setq-local outline-heading-end-regexp "\n")
          (setq-local outline-level 'lpy-outline-level)
          (setq-local fill-paragraph-function 'lpy-fill-paragraph)
          (setq-local fill-forward-paragraph-function 'lpy-fill-forward-paragraph-function)
          (setq-local completion-at-point-functions '(lispy-python-completion-at-point t))
          ;; (setq-local forward-sexp-function 'lpy-forward-sexp-function)
          )
      (setq-local forward-sexp-function nil)))
  (map! :map lpy-mode-map
        "n" nil
        :i "C-p" #'previous-line
        :i "C-n" #'next-line)
  (advice-add 'lispy--python-proc :override #'*lispy--python-proc)
  (advice-add 'lispy-short-process-name :override #'*lispy-short-process-name)
  (advice-add 'lispy-set-python-process-action :override #'*lispy-set-python-process-action))

(def-package! anaconda-mode
  :hook python-mode
  :init
  (setq anaconda-mode-installation-directory (concat doom-etc-dir "anaconda/")
        anaconda-mode-eldoc-as-single-line t
        anaconda-mode-server-command "
import sys, site
site.addsitedir('.')
import anaconda_mode
anaconda_mode.main(sys.argv[-2:])
")
  :config
  (add-hook 'anaconda-mode-hook #'anaconda-eldoc-mode)

  (set! :popup "^\\*anaconda-mode" nil '((select)))
  (set! :popup "^\\*Anaconda\\*" '((side . right) (size . 80)) '((select) (quit . t) (transient . t)))

  (set! :lookup 'python-mode
    :definition #'anaconda-mode-find-definitions
    :references #'anaconda-mode-find-references
    :documentation #'anaconda-mode-show-doc)
  (advice-add #'anaconda-mode-doc-buffer :after #'doom*anaconda-mode-doc-buffer)

  (defun +python|auto-kill-anaconda-processes ()
    "Kill anaconda processes if this buffer is the last python buffer."
    (when (and (eq major-mode 'python-mode)
               (not (delq (current-buffer)
                          (doom-buffers-in-mode 'python-mode (buffer-list)))))
      (anaconda-mode-stop)))
  (add-hook! 'python-mode-hook
    (add-hook 'kill-buffer-hook #'+python|auto-kill-anaconda-processes nil t)))

(def-package! company-anaconda
  :when (featurep! :completion company)
  :after anaconda-mode
  :config
  (set! :company-backend 'python-mode '(company-anaconda company-files company-yasnippet company-dabbrev-code))
  (map! :map python-mode-map
        :localleader
        :prefix "f"
        :nv "d" #'anaconda-mode-find-definitions
        :nv "h" #'anaconda-mode-show-doc
        :nv "a" #'anaconda-mode-find-assignments
        :nv "f" #'anaconda-mode-find-file
        :nv "u" #'anaconda-mode-find-references
        :map anaconda-view-mode-map
        :nv "q" #'quit-window))

(def-package! py-isort
  :after python
  :config
  (map! :map python-mode-map
        :localleader
        :n "s" #'py-isort-buffer
        :v "s" #'py-isort-region))

(def-package! yapfify
  :after python
  :hook (python-mode . yapf-mode)
  :config
  (map! :map python-mode-map
        :localleader
        :nv "=" #'yapfify-buffer))

(def-package! nose
  :commands nose-mode
  :preface
  (defvar nose-mode-map (make-sparse-keymap))
  :init
  ;; (associate! nose-mode :match "/test_.+\\.py$" :modes (python-mode))
  :config

  (set! :popup "^\\*nosetests" '((size . 0.4)) '((select)))
  (set! :yas-minor-mode 'nose-mode)
  (map! :map nose-mode-map
        :localleader
        :prefix "t"
        :n "r" #'nosetests-again
        :n "a" #'nosetests-all
        :n "s" #'nosetests-one
        :n "v" #'nosetests-module
        :n "A" #'nosetests-pdb-all
        :n "O" #'nosetests-pdb-one
        :n "V" #'nosetests-pdb-module))


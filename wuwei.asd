(in-package :asdf)

#+ALLEGRO
(require :aserve)

(defsystem :wuwei
    :name "Ajax and other tools for web development."
    :serial t
    :depends-on (#-ALLEGRO :aserve :cl-json :mtlisp)
    :components 
    (
     (:file "package")
     ;; Patches to existing systems
     #-ALLEGRO (:file "aserve-patch")
     #-ALLEGRO (:file "htmlgen-patch")
     (:file "cl-json-patches")
     ;; Config
     (:file "config")
     (:file "net-utils")
     (:file "bigstring")
     (:file "web")
     (:file "ajax-render")
     (:file "session")
     (:file "debug-utils")
     (:file "error")
     (:file "async")
     (:file "autocomplete")
     (:file "dom-objects")
     ))

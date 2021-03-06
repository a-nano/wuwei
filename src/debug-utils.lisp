(in-package :wuwei)

#|
Borrowed from BioBike 
|#

;;; This also works: (top-level.debug:zoom *standard-output*)

;;; Used to use functions in debug: package, appears to have changed
#+:allegro
(defun get-frames-list ()
  (let ((*terminal-io* excl::*null-stream*)
        prev cur lis old frames-before-error)
    ;; This isn't supposed to be able to error out, but in
    ;; a weird case that seems like every other error to us, but
    ;; must be different somehow, this function errors out
    ;; calling DEBUG:FRAME-EXPRESSION on CUR in the second loop,
    ;; generating a `NIL' is not of the expected type `REAL' error.
    ;; This unexpected signaling of an error was masking the real
    ;; error we are trying to get information on and report.
    ;; The only solution I could come up with was to trap this
    ;; bizarre error signal and ignore it.  The only effect doing this
    ;; has is that when this bizarre error occurs, typing (explain)
    ;; at the weblistener won't get you any stack listing.
    (handler-case
        (progn
          (setq prev (excl::int-newest-frame))
          (setq old (excl::int-oldest-frame))
          (loop
           (setq cur (excl::int-next-older-frame prev))
           (when (null cur)
             (return-from get-frames-list (nreverse frames-before-error)))
           (push (debug:frame-expression cur) frames-before-error)
           (when (eq 'error (car (debug:frame-expression cur)))
             (setq prev cur) (return))
           (setq prev cur))
          (loop
           (setq cur (excl::int-next-older-frame prev))
           ;; We want to see every frame and make a decision ourselves.
           (if t ;(excl::int-frame-visible-p cur)
               (push (debug:frame-expression cur) lis))
           (if (excl::int-frame-reference-eq cur old)
               (return))
           (setq prev cur))
          )
      (error () (setq lis nil))
      )
    (nreverse lis)))


(defparameter *stack-frame-limit* 30)

#+:ccl
(defun get-frames-list ()
  ;; discard uninteresting get-frames-list frame
  (cdr (ccl::backtrace-as-list :count *stack-frame-limit*)))

#+:sbcl
(defun get-frames-list ()
  (sb-debug::backtrace-as-list *stack-frame-limit*))

#-(or :ccl :sbcl :allegro)
(defun get-frames-list ()
  nil)

(defun dump-stack (&optional (stream *standard-output*))
  (loop for frame in (get-frames-list) do
       (format stream " ~a~%" frame)))

(defun stack-trace ()
  (with-output-to-string (s)
    (dump-stack s)))

(defmacro logging-errors (&body body)
  `(restart-case
       (handler-bind
           ((condition #'(lambda (c)
                           (invoke-restart 'total-lossage c (stack-trace)))))
         ,@body
         )
     (total-lossage (c trace)
       (format t "~%Pretending to log ~a~%~a~%" c trace)
       )
     )
  )


(defmacro without-unwinding-restart ((restart &rest args) &body body)
  `(restart-case
       (handler-bind
           ((serious-condition
	     #'(lambda (c)
		 (if *developer-mode*
		     (signal c)		;rethrow if dev mode
		     (progn
		       (ignore-errors (format t "~a ~a~%" (net.aserve::universal-time-to-date (get-universal-time)) c))
		       (dump-stack)
		       (invoke-restart 'total-lossage c (stack-trace)))))))
         ,@body
         )
     (total-lossage (c stack-trace)
       (ignore-errors (,restart ,@args :error c :stack-trace stack-trace))
       )
     )
  )


#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(print (dynamic-space-size))

(quicklisp:quickload "woo")

(defun start-it ()
  (declare (optimize speed safety))
  (let ((max 250000)
        (cnt 0)
        (ht (make-hash-table :size 250000 :synchronized nil))
        (mutex (sb-thread:make-mutex)))
    (declare (type fixnum cnt max))
    (woo:run
     (lambda (env)
       (declare (ignore env))
       (let ((data (make-array 1024 :element-type '(unsigned-byte 8))))
         (sb-thread:with-mutex (mutex)
           (setf (gethash cnt ht) data)
           (when (>= cnt max)
             (remhash (- cnt max) ht))
           (incf cnt)))
       '(200 (:content-type "text/plain") ("OK")))
     :worker-num 4 :debug nil
     :port 8080)))

(start-it)

;; warmup
;; wrk2/wrk --latency -c 99 -t 3 -d 60 -R9000 'http://localhost:8080' | head -n17
;; then
;; wrk2/wrk --latency -c 99 -t 3 -d 180 -R9000 'http://localhost:8080'

;;   Latency Distribution (HdrHistogram - Recorded Latency)
;;  50.000%    1.24ms
;;  75.000%    1.75ms
;;  90.000%    2.24ms
;;  99.000%   44.86ms
;;  99.900%  103.74ms
;;  99.990%  119.04ms
;;  99.999%  121.79ms
;; 100.000%  122.30ms


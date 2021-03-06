(in-package :bknr.web)

(defclass bknr-authorizer ()
  ())

(defmethod http-request-remote-host ()
  (format *debug-io* "can't determin originating host yet~%")
  #+(or)
  (let ((remote-host (socket:remote-host (request-socket)))
	(forwarded-for (regex-replace
			"^.*?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*$"
			(header-slot-value :x-forwarded-for)
			"\\1")))
    (when (and forwarded-for
	       (equal "127.0.0.1" (socket:ipaddr-to-dotted remote-host)))
      ;; request is via proxy, use client's ip address
      (setf remote-host (socket:dotted-to-ipaddr forwarded-for)))
    (find-host :create t :ipaddr remote-host)))

(defun session-from-request ()
  "Check whether the request has a valid session id in either the bknr-sessionid cookie or query parameter"
  (session-value 'bknr-session))

(defgeneric authorize (authorizer)
  (:documentation "Return the user that is associated with the current request or NIL.")
  (:method ((authorizer bknr-authorizer))
    (with-query-params ((__username "") (__password ""))
      (let ((__username (string-downcase (string-trim '(#\space) __username))))
        (when (or (equal __username "")
                  (equal __password ""))
          (return-from authorize nil))
        (let ((user (find-user __username)))
          (when (and user
                     (not (user-disabled user))
                     (verify-password user __password))
            (set-user-last-login user (get-universal-time))
            (return-from authorize user)))
        nil))))

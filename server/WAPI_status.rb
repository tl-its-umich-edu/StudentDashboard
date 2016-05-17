module WAPIStatus
  # Constants for the status value of the wrapper. The potential
  # errors / status can be different so they need not be the same
  # as the HTTP_STATUS.  These are referenced with the namespace
  # WAPIStatus:: for consistency across modules.  E.g. WAPIStatus::UNKNOWN_ERROR.
  SUCCESS = 200
  UNKNOWN_ERROR = 666
  BAD_REQUEST = 400

  # Constants for the http status of the underlying request.
  HTTP_SUCCESS = 200
  HTTP_UNAUTHORIZED = 401
  HTTP_NOT_FOUND = 404
end

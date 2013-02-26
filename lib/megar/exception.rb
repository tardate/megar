module Megar

  # A general Megar exception
  class Error < StandardError; end

  # Raised when crypto requirements are not met by the ruby platform we're running on
  class CryptoSupportRequirementsError < Error; end

  class MegaRequestError < Error

    # Initialise with +error_code+ returned from Mega
    def initialize(error_code)
      msg = case error_code
      when -1
        "EINTERNAL (-1): An internal error has occurred. Please submit a bug report, detailing the exact circumstances in which this error occurred."
      when -2
        "EARGS (-2): You have passed invalid arguments to this command."
      when -3
        "EAGAIN (-3) (always at the request level): A temporary congestion or server malfunction prevented your request from being processed. No data was altered. Retry. Retries must be spaced with exponential backoff."
      when -4
        "ERATELIMIT (-4): You have exceeded your command weight per time quota. Please wait a few seconds, then try again (this should never happen in sane real-life applications)."
      when -5
        "EFAILED (-5): The upload failed. Please restart it from scratch."
      when -6
        "ETOOMANY (-6): Too many concurrent IP addresses are accessing this upload target URL."
      when -7
        "ERANGE (-7): The upload file packet is out of range or not starting and ending on a chunk boundary."
      when -8
        "EEXPIRED (-8): The upload target URL you are trying to access has expired. Please request a fresh one."
      when -9
        "ENOENT (-9): Object (typically, node or user) not found"
      when -10
        "ECIRCULAR (-10): Circular linkage attempted"
      when -11
        "EACCESS (-11): Access violation (e.g., trying to write to a read-only share)"
      when -12
        "EEXIST (-12): Trying to create an object that already exists"
      when -13
        "EINCOMPLETE (-13): Trying to access an incomplete resource"
      when -14
        "EKEY (-14): A decryption operation failed (never returned by the API)"
      when -15
        "ESID (-15): Invalid or expired user session, please relogin"
      when -16
        "EBLOCKED (-16): User blocked"
      when -17
        "EOVERQUOTA (-17): Request over quota"
      when -18
        "ETEMPUNAVAIL (-18): Resource temporarily not available, please try again later"
      else
        "UNDEFINED Mega error #{error_code}"
      end
      super(msg)
    end

  end

end
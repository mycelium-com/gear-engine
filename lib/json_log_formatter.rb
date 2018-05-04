class JsonLogFormatter

  def call(severity, _time, _progname, msg)
    clock     = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    timestamp = Time.now.utc.iso8601(4)
    JSON.dump(severity: severity, message: clean(msg), timestamp: timestamp, clock: clock).concat("\n")
  end

  # from Logger::Formatter
  def clean(message)
    message = message.to_s.strip
    message.gsub!(/\e\[[0-9;]*m/, '') # remove ansi color codes
    message
  end
end
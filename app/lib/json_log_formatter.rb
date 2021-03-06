class JsonLogFormatter

  def call(severity, _time, _progname, msg)
    clock     = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    timestamp = Time.now.utc.iso8601(4)
    pid       = Process.pid
    tid       = Thread.current.object_id.to_s(36)
    JSON.dump(
        severity_label: severity,
        message:        clean(msg),
        timestamp:      timestamp,
        clock:          clock,
        pid:            pid,
        tid:            tid
    ).concat("\n")
  end

  # from Logger::Formatter
  def clean(message)
    message = message.to_s.strip
    message.gsub!(/\e\[[0-9;]*m/, '') # remove ansi color codes
    message
  end
end
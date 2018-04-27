class JsonLogFormatter

  def call(severity, _time, _progname, msg)
    JSON.dump(severity: severity, message: clean(msg)).concat("\n")
  end

  # from Logger::Formatter
  def clean(message)
    message = message.to_s.strip
    message.gsub!(/\e\[[0-9;]*m/, '') # remove ansi color codes
    message
  end
end
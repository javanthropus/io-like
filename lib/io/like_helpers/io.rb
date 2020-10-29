class IO
  # The PRIORITY, READABLE, and WRITABLE constants are provided here for use on
  # Ruby runtimes that do not include them by default since this gem depends on
  # them as a standard implementation detail.
  unless const_defined?(:PRIORITY)
    PRIORITY = 2
  end

  unless const_defined?(:READABLE)
    READABLE = 1
  end

  unless const_defined?(:WRITABLE)
    WRITABLE = 4
  end
end

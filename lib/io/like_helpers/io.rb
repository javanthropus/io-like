class IO
  unless const_defined?(:PRIORITY)
    ##
    # Defined only if IO::PRIORITY is not defined.
    PRIORITY = 2
  end

  unless const_defined?(:READABLE)
    ##
    # Defined only if IO::READABLE is not defined.
    READABLE = 1
  end

  unless const_defined?(:WRITABLE)
    ##
    # Defined only if IO::WRITABLE is not defined.
    WRITABLE = 4
  end
end

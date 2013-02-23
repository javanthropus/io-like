require File.expand_path("../../../rubyspec/core/io/fixtures/classes",__FILE__)

module IOSpecs

  def self.io_like_fixture(*data)

    io = mock_io_like("io-like-fixture")

    unless data.empty?
      io.instance_variable_set("@data",data)
      def io.unbuffered_read(length)
        raise EOFError if @data.empty?
        result = @data.shift
        raise result, "test error" if result.respond_to?(:exception)
        result 
      end
    end
    io
  end

  def self.readonly_io
    io = self.io_fixture("lines.txt","r")
    return io unless block_given?
    begin
      yield io
    ensure
      io.close unless io.closed?
    end
  end

  def self.writeonly_io(name = "writeonly_file")
    filename = tmp(name)
    if block_given?
       File.open(filename,"w") do |f|
         begin
          result = yield f
         ensure
          rm_r filename
         end
         result
       end
    else
       File.open(filename,"w") 
    end
  end
end

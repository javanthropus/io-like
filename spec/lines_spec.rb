# encoding: UTF-8
# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#lines" do
    before(:each) do
      @io = File.open(IOSpecs.gets_fixtures)
      @iowrapper = ReadableIOWrapper.open(@io)
    end

    after(:each) do
      @iowrapper.close unless @iowrapper.closed?
      @io.close
    end

    it "returns an Enumerator" do
      enum = @iowrapper.lines
      enum.instance_of?(enumerator_class).should be_true

      enum.to_a.should == [
        "Voici la ligne une.\n",
       "Qui è la linea due.\n",
       "\n",
       "\n",
       "Aquí está la línea tres.\n",
       "Ist hier Linie vier.\n",
       "\n",
       "Está aqui a linha cinco.\n",
       "Here is line six.\n"
      ]
    end

    it "ignores a given block" do
      @iowrapper.lines do
        raise "oups"
      end.instance_of?(enumerator_class).should be_true
    end
  end
end

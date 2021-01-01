require_relative '../../../spec_helper'

ruby_version_is ""..."3.0" do
  require 'set'

  describe "SortedSet#pretty_print_cycle" do
    it "passes the 'pretty print' representation of a self-referencing SortedSet to the pretty print writer" do
      pp = mock("PrettyPrint")
      pp.should_receive(:text).with("#<SortedSet: {...}>")
      SortedSet[1, 2, 3].pretty_print_cycle(pp)
    end
  end
end

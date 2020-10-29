# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'
require_relative 'shared/each'

describe "IO::Like#each_line" do
  it_behaves_like :io_like__each, :each_line
end

# vim: ts=2 sw=2 et

# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'
require_relative 'shared/write'

describe "IO::Like#syswrite" do
  it_behaves_like :io_like__write, :syswrite
end

# vim: ts=2 sw=2 et

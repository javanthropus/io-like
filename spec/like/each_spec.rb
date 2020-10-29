# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'
require_relative 'shared/each'

describe "IO::Like#each" do
  it_behaves_like :io_like__each, :each
end

# vim: ts=2 sw=2 et

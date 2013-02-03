require 'spec_helper'
require 'getoptions'

describe Megar::Shell do

  let(:getoptions) { GetOptions.new(Megar::Shell::OPTIONS, options) }
  let(:shell) { Megar::Shell.new(getoptions,argv) }

  describe "#usage" do
    let(:options) { ['-h'] }
    let(:argv) { [] }
    it "should print usage when run" do
      shell.should_receive(:usage)
      shell.run
    end
  end

end
require 'spec_helper'
require 'getoptions'

describe Megar::Shell do

  let(:getoptions) { GetOptions.new(Megar::Shell::OPTIONS, options) }
  let(:shell) { Megar::Shell.new(getoptions,argv) }

  before do
    $stderr.stub(:puts) # silence console feedback chatter
  end

  describe "#usage" do
    let(:options) { ['-h'] }
    let(:argv) { [] }
    it "should print usage when run" do
      shell.should_receive(:usage)
      shell.run
    end
  end

  describe "#ls" do
    let(:options) { ['-e=email','-p=pwd'] }
    let(:argv) { ['ls'] }
    it "should invoke ls" do
      mock_session = mock()
      mock_session.stub(:connected?).and_return(true)
      shell.stub(:session).and_return(mock_session)
      shell.should_receive(:ls)
      shell.run
    end
  end

  describe "#get" do
    let(:options) { ['-e=email','-p=pwd'] }
    let(:argv) { ['get', 'file_id'] }
    it "should invoke get" do
      mock_session = mock()
      mock_session.stub(:connected?).and_return(true)
      shell.stub(:session).and_return(mock_session)
      shell.should_receive(:get).with(argv[1])
      shell.run
    end
  end

end
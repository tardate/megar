require 'spec_helper'

describe Megar::Crypto::AesCtr do
  let(:harness) { Megar::Crypto::AesCtr.new(options) }
  let(:options) { {} }

  describe "#key" do
    subject { harness.key }
    context "when provided as array of int" do
      let(:options) { { key: [0x40404040,0x40404040,0x40404040,0x40404040] } }
      it { should eql('@@@@@@@@@@@@@@@@') }
    end
    context "when provided as a binary string" do
      let(:options) { { key: 'abcd' } }
      it { should eql('abcd') }
    end
  end

  describe "#iv" do
    subject { harness.iv }
    context "when not provided" do
      it { should eql([0,0,0,0]) }
    end
    context "when provided as array of int" do
      let(:options) { { iv: [1,2,3,4] } }
      it { should eql([1,2,3,4]) }
    end
  end

end
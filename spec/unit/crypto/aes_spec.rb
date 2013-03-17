require 'spec_helper'

describe Megar::Crypto::Aes do
  let(:harness) { Megar::Crypto::Aes.new(options) }
  let(:options) { { key: key } }

  describe "#encrypt" do
    subject { harness.encrypt(data) }
    # expectation generation in Javascript:
    #   key = [0,0,0,0]
    #   data = [-1965633819,-2121597728,1547823083,-1677263149]
    #   cipher = new sjcl.cipher.aes(key)
    #   cipher.encrypt(data)
    [
      { data: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], key: [0,0,0,0], expect: [887729479,-1472906423,407560426,1302943674] },
      { data: [887729479,-1472906423,407560426,1302943674], key: [602974403,-1330001938,-1976634718,-894142530], expect: [-19364982,-598654435,1840800477,-1490065331] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:key) { test_case[:key] }
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#encrypt" do
    subject { harness.decrypt(data) }
    # expectation generation in Javascript:
    #   key = prepare_key_pw('NS7j8OKCfGeEEaUK') // [1258112910,-1520042757,-243943422,-1960187198]
    #   data = [887729479,-1472906423,407560426,1302943674]
    #   cipher = new sjcl.cipher.aes(key)
    #   cipher.decrypt(data) // [480935216,755335218,-883525214,599824580]
    [
      { data: [887729479,-1472906423,407560426,1302943674], key: [1258112910,-1520042757,-243943422,-1960187198], expect: [480935216,755335218,-883525214,599824580] },
      { data: [887729479,-1472906423,407560426,1302943674], key: [0,0,0,0], expect: [-1815844893,2108737444,-776061055,22203222] },
      { data: [-19364982,-598654435,1840800477,-1490065331], key: [602974403,-1330001938,-1976634718,-894142530], expect: [887729479,-1472906423,407560426,1302943674] },
      { data: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], key: [0,0,0,0], expect: [-1965633819,-2121597728,1547823083,-1677263149] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:key) { test_case[:key] }
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end
end
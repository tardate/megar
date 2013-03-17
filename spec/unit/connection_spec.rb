require 'spec_helper'

class ConnectionTestHarness
  include Megar::Connection
end

describe Megar::Connection do
  let(:harness) { ConnectionTestHarness.new }

  describe "#sequence_number" do
    subject { harness.sequence_number }
    it { should_not be_nil }
  end

  describe "#next_sequence_number!" do
    let!(:current_sequence_number) { harness.sequence_number }
    subject { harness.next_sequence_number! }
    it { should eql(current_sequence_number + 1)}
  end

  describe "#api_endpoint" do
    subject { harness.api_endpoint }
    it { should eql(Megar::Connection::DEFAULT_API_ENDPOINT) }
    context "when overidden" do
      let(:alternative_endpoint) { 'http://bogative.one' }
      before { harness.api_endpoint = alternative_endpoint }
      it { should eql(alternative_endpoint) }
    end
  end

  describe "#api_uri" do
    subject { harness.api_uri }
    it { should be_a(URI) }
  end

  describe "#api_request" do
    let(:data) { {} }
    subject { harness.api_request(data) }

    {
      as_json: "[-15,-15,-15]",
      as_error_code: "-15"
    }.each do |test_name,given_response|
      context "when mega error response (#{given_response})" do
        it "should raise associated error" do
          harness.stub(:get_api_response).and_return(given_response)
          expect { subject }.to raise_error(Megar::MegaRequestError)
        end
      end
    end

    {
      as_broken_json: "[{,{},{}]"
    }.each do |test_name,given_response|
      context "when invalid JSON response (#{given_response})" do
        it "should raise associated error" do
          harness.stub(:get_api_response).and_return(given_response)
          expect { subject }.to raise_error(Megar::BadApiResponseError)
        end
      end
    end

    {
      as_json: { given: '[{"a":1},{"b":2}]', expect: {'a' => 1} },
      as_unarray: { given: '{"a":1}', expect: {'a' => 1} }
    }.each do |test_name,expectations|
      context "when valid response (#{expectations[:given]})" do
        before { harness.stub(:get_api_response).and_return(expectations[:given]) }
        it "should not raise error" do
          expect { subject }.to_not raise_error
        end
        it { should eql(expectations[:expect]) }
      end
    end

  end

end


require 'spec_helper'

class ConnectionTestHarness
  include Megar::Connection
end

describe Megar::Connection do
  let(:harness) { ConnectionTestHarness.new }

  describe "#sequence_number" do
    subject { harness.sequence_number }
    it { should be_a(Fixnum) }
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
    context "when error response" do
      let(:response_data) { JSON.parse("[-15,-15,-15]") }
      it "should raise associated error" do
        harness.stub(:get_api_response).and_return(response_data)
        expect { subject }.to raise_error(Megar::MegaRequestError)
      end
    end

  end

end


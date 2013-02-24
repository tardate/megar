require 'spec_helper'

describe Megar::Session do
  let(:test_data) { crypto_expectations('sample_user') }

  let(:email) { test_data['email'] }
  let(:password) { test_data['password'] }

  let(:login_response_data) { test_data['login_response_data'] }

  let(:expected_uh) { test_data['expected_uh'] }
  let(:expected_master_key) { test_data['master_key'] }
  let(:expected_sid) { test_data['sid'] }
  let(:expected_rsa_private_key_b64) { test_data['rsa_private_key_b64'] }
  let(:expected_decomposed_rsa_private_key) { test_data['decomposed_rsa_private_key'] }


  context "with username and password" do
    let(:session) { Megar::Session.new(options) }
    let(:base_options) { { 'email' => email, 'password' => password, 'autoconnect' => false } }
    let(:options) { base_options }

    describe "#connected?" do
      subject { session.connected? }
      context "when before login" do
        it { should be_false }
      end
      context "when after login" do
        before { session.sid = "something" }
        it { should be_true }
      end
    end

    describe "#email" do
      subject { session.email }
      it { should eql(email) }
    end

    describe "#password" do
      subject { session.password }
      it { should eql(password) }
    end

    context "when api_endpoint override provided" do
      let(:alternative_endpoint) { 'http://bogative.one' }
      let(:options) { base_options.merge({ api_endpoint: alternative_endpoint }) }
      subject { session.api_endpoint }
      it { should eql(alternative_endpoint) }
    end

    describe "#uh" do
      #
      # expectation generation in Javascript:
      #   aes = new sjcl.cipher.aes(prepare_key_pw(password))
      #   stringhash(email.toLowerCase(), aes)
      #   => EGQjdVjoWPA
      subject { session.uh }
      it { should eql(expected_uh) }
      context "when mixed-case email" do
        let(:email) { test_data['email_mixed_case'] }
        it { should eql(expected_uh) }
      end
    end

    describe "#connect!" do
      let(:connect) { session.connect! }
      let(:expected_params) { {'a' => 'us', 'user' => email, 'uh' => expected_uh} }
      it "should invoke the expected api request" do
        session.should_receive(:api_request).with(expected_params).and_return({})
        connect
      end
      context "after login completed" do
        before do
          session.stub(:api_request).and_return(login_response_data)
          connect
        end
        subject { session }

        its(:master_key) { should eql(expected_master_key) }
        its(:sid) { should eql(expected_sid) }
        its(:rsa_private_key_b64) { should eql(expected_rsa_private_key_b64) }
        its(:decomposed_rsa_private_key) { should eql(expected_decomposed_rsa_private_key) }
      end
    end

    describe "#handle_login_challenge_response" do
      before { session.handle_login_challenge_response(login_response_data) }
      subject { session }

      its(:master_key) { should eql(expected_master_key) }
      its(:sid) { should eql(expected_sid) }
      its(:rsa_private_key_b64) { should eql(expected_rsa_private_key_b64) }
      its(:decomposed_rsa_private_key) { should eql(expected_decomposed_rsa_private_key) }
    end
  end

end



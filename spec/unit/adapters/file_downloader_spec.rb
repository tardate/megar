require 'spec_helper'

describe Megar::FileDownloader do
  let(:model_class) { Megar::FileDownloader }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  describe "#mac" do
    subject { instance.mac }
    [
      {
        file_key: [1029178532, 1095006796,361733076,-1656803926,1405858242,1396716347,870048465,-473559286],
        expected_mac: [870048465,-473559286]
      }
    ].each do |options|
      context "when file key #{options[:file_key]}" do
        before { instance.stub(:key).and_return(options[:file_key]) }
        it { should eql(options[:expected_mac]) }
      end
    end

  end

  crypto_expectations['sample_files'].keys.each do |sample_file_name|
    context "with an active session testing download of #{sample_file_name}" do

      let(:file_name) { sample_file_name }
      let(:file_expectation) { crypto_expectations['sample_files'][file_name] }

      let(:sample_encrypted_content) { crypto_sample_encrypted_file_content(file_name) }
      let(:sample_encrypted_content_digest) { Digest::SHA1.hexdigest(sample_encrypted_content) }

      let(:sample_decrypted_content) { crypto_sample_decrypted_content(file_name) }
      let(:sample_decrypted_content_digest) { Digest::SHA1.hexdigest(sample_decrypted_content) }

      let(:session) { connected_session_with_mocked_api_responses }
      let(:file) { session.files.find_by_name(file_name) }
      let(:attributes) { { file: file } }

      before do
        session.stub(:get_file_download_url_response).and_return(file_expectation['file_download_url_response'])
        instance.stub(:stream).and_return(crypto_sample_encrypted_file_stream(file_name))
      end

      describe "#download_url_response" do
        let(:expected) { file_expectation['file_download_url_response'] }
        subject { instance.download_url_response }
        it { should eql(expected) }
      end

      describe "#download_url" do
        let(:expected) { /mega\.co\.nz\/dl/ }
        subject { instance.download_url }
        it { should match(expected) }
      end

      describe "#download_size" do
        let(:expected) { file_expectation['size'] }
        subject { instance.download_size }
        it { should eql(expected) }
      end

      describe "#download_attributes" do
        let(:expected) { { 'n' => file_name } }
        subject { instance.download_attributes }
        it { should eql(expected) }
      end

      describe "#iv" do
        let(:expected) { file_expectation['iv'] }
        subject { instance.iv }
        it { should eql(expected) }
      end

      describe "#mac" do
        let(:expected) { file_expectation['mac'] }
        subject { instance.mac }
        it { should eql(expected) }
      end

      describe "#initial_counter_value" do
        let(:expected) { file_expectation['initial_counter_value'] }
        subject { instance.initial_counter_value }
        it { should eql(expected) }
      end

      describe "#raw_content" do
        subject { Digest::SHA1.hexdigest(instance.raw_content) }
        it { should eql(sample_encrypted_content_digest) }
      end

      describe "#content" do
        subject { Digest::SHA1.hexdigest(instance.content) }
        it { should eql(sample_decrypted_content_digest) }
      end

    end
  end

end
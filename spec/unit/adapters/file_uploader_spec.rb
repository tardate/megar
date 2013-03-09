require 'spec_helper'

describe Megar::FileUploader do
  let(:model_class) { Megar::FileUploader }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  describe "#upload_key" do
    subject { instance.upload_key }
    it { should be_a(Array) }
    its(:size) { should eql(6) }
  end

  describe "keys" do
    subject { instance }
    [
      {
        upload_key:      [3230625094, 2656764682, 1008836587, 1082599785, 1919494632, 3993726968],
        expected_iv:     152078032723025278718811426614033776640,
        expected_mac_iv: [1919494632, 3993726968,1919494632, 3993726968],
        expected_mac_encryption_key: [3230625094, 2656764682, 1008836587, 1082599785]
      }
    ].each do |options|
      context "when upload_key #{options[:upload_key]}" do
        before       { instance.stub(:upload_key).and_return(options[:upload_key]) }
        its(:iv)     { should eql(options[:expected_iv]) }
        its(:mac_iv) { should eql(options[:expected_mac_iv]) }
        its(:mac_encryption_key) { should eql(options[:expected_mac_encryption_key]) }
      end
    end
  end

  context "with sample file" do
    let(:file_name) { 'megar_test_sample_1.txt' }
    let(:file_expectation) { crypto_expectations['sample_files'][file_name] }
    let(:attributes) { { body: file_handle } }

    context "when given a File" do
      let(:file_handle) { File.open(crypto_sample_file_path(file_name),'rb') }
      it { file_handle.should be_a(File) }
      describe "#upload_size" do
        subject { instance.upload_size }
        it { should eql(file_expectation['size']) }
      end
    end

    context "when given a Pathname" do
      let(:file_handle) { crypto_sample_file_path(file_name) }
      it { file_handle.should be_a(Pathname) }
      describe "#upload_size" do
        subject { instance.upload_size }
        it { should eql(file_expectation['size']) }
      end
    end

    context "when given a file path as a string" do
      let(:file_handle) { crypto_sample_file_path(file_name).to_s }
      it { file_handle.should be_a(String) }
      describe "#upload_size" do
        subject { instance.upload_size }
        it { should eql(file_expectation['size']) }
      end
    end

    context "when given a path string to a non-existent file" do
      let(:file_handle) { crypto_sample_file_path(file_name).to_s + '.bogative' }
      it "should raise an error" do
        expect { instance }.to raise_error(Errno::ENOENT)
      end
    end

    describe "#post!" do
      let(:file_handle) { crypto_sample_file_path(file_name) }
      let(:session) { connected_session_with_mocked_api_responses }
      let(:uploader) { Megar::FileUploader.new(attributes.merge(folder: session.folders.root)) }
      let(:do_post) { uploader.post! }
      let(:upload_attributes_response) { {"f"=>[session.files.find_by_name(file_name).payload]} }
      let(:completion_file_handle) { "h4Zgt7cRyMUlzl6WguZALImGOr2Yyr31cTXd" }

      it "should upload in a single chunk" do
        uploader.should_receive(:post_chunk).and_return(completion_file_handle)
        uploader.should_receive(:send_file_upload_attributes).and_return(upload_attributes_response)
        do_post
      end

    end

  end

end
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

  describe "#iv" do
    subject { instance.iv }
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

  end

end
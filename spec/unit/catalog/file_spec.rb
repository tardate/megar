require 'spec_helper'

describe Megar::File do
  let(:model_class) { Megar::File }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  context "when initialised" do
    let(:id) { 'some id' }
    let(:parent_folder_id) { 'some parent id' }
    let(:name) { 'some name' }
    let(:type) { 0 }
    let(:size) { 33 }
    let(:payload) { {
      's' => size,
      'p' => parent_folder_id
    } }
    let(:attributes) { {
      id: id,
      type: type,
      payload: payload,
      attributes: {
        'n' => name
      }
    } }

    subject { instance }

    its(:id)               { should eql(id) }
    its(:name)             { should eql(name) }
    its(:type)             { should eql(type) }
    its(:size)             { should eql(size) }
    its(:parent_folder_id) { should eql(parent_folder_id) }
    its(:body)             { should be_nil }
  end

  context "with an active session" do
    let(:session) { connected_session_with_mocked_api_responses }
    let(:file) { session.files.find_by_name('megar_test_sample_1.txt') }

    describe "#downloader" do
      subject { instance.downloader }
      it { should be_a(Megar::FileDownloader) }
    end

  end

end
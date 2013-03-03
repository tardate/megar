require 'spec_helper'

describe Megar::Files do
  let(:model_class) { Megar::Files }
  let(:resource_class) { Megar::File }
  let(:instance) { model_class.new }

  let(:other_resource) { resource_class.new(id: "other_resource_id", type: 1) }

  describe "#resource_class" do
    subject { instance.resource_class }
    it { should eql(resource_class) }
  end

  describe "#reset!" do
    before do
      instance.collection << other_resource
    end
    let(:reset) { instance.reset! }
    it "should clear the collection" do
      reset
      instance.collection.should be_empty
    end
  end

  describe "#create" do
    let(:attributes) { { name: 'a name', body: 'file_handle'} }
    subject { instance.create(attributes) }
    it "should create a valid uploader and post!" do
      instance.stub(:parent_folder).and_return('parent_folder')
      uploader = mock()
      uploader.should_receive(:post!)
      Megar::FileUploader.should_receive(:new).with(attributes.merge(folder: 'parent_folder')).and_return(uploader)
      subject
    end
  end

end
require 'spec_helper'

describe Megar::Folders do
  let(:model_class) { Megar::Folders }
  let(:resource_class) { Megar::Folder }
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

  {
    root:  { type: 2, expected_name: "Cloud Drive" },
    inbox: { type: 3, expected_name: "Inbox" },
    trash: { type: 4, expected_name: "Trash Bin" }
  }.each do |special_method_name,options|
    describe "##{special_method_name}" do
      subject { instance.send(special_method_name) }
      context "when not available or defined" do
        it { should be_nil }
      end
      context "when defined" do
        let(:found_resource) { resource_class.new(id: "#{special_method_name}_id", type: options[:type]) }
        let(:expected_name) { options[:expected_name] }
        before do
          instance.collection << found_resource
          instance.collection << other_resource
        end
        it { should eql(found_resource) }
        its(:name) { should eql(expected_name) }
      end
    end
  end

end
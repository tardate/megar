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

end
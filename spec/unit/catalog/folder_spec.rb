require 'spec_helper'

describe Megar::Folder do
  let(:model_class) { Megar::Folder }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  context "when initialised" do
    let(:id) { 'some id' }
    let(:name) { 'some name' }
    let(:type) { 1 }
    let(:payload) { {
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
    its(:id)   { should eql(id) }
    its(:name) { should eql(name) }
    its(:type) { should eql(type) }
  end

end
require 'spec_helper'

describe Megar::Folder do
  let(:model_class) { Megar::Folder }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  context "when initialised" do
    let(:id) { 'some id' }
    let(:parent_folder_id) { 'some parent id' }
    let(:name) { 'some name' }
    let(:type) { 1 }
    let(:payload) { {
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
    its(:parent_folder_id) { should eql(parent_folder_id) }

  end

  describe "#folders" do
    let(:session) { dummy_session_with_files_and_folders }

    subject { folder.folders }

    context "when child folders present" do
      let(:folder) { session.folders.find_by_id('dir1') }
      its(:count) { should eql(1) }
      describe "child folder" do
        subject { folder.folders.first }
        its(:id) { should eql('dir3') }
        its(:parent_folder) { should eql(folder) }
      end
    end

    context "when child folders not present" do
      let(:folder) { session.folders.find_by_id('dir2') }
      its(:count) { should eql(0) }
    end

  end

  describe "#files" do
    let(:session) { dummy_session_with_files_and_folders }

    subject { folder.files }

    context "when child files present" do
      let(:folder) { session.folders.find_by_id('dir1') }
      its(:count) { should eql(2) }
      describe "child file" do
        subject { folder.files.first }
        its(:id) { should eql('file1') }
        its(:parent_folder) { should eql(folder) }
      end
    end

    context "when child files not present" do
      let(:folder) { session.folders.find_by_id('dir2') }
      its(:count) { should eql(0) }
    end

  end


end
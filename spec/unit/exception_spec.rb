require 'spec_helper'

describe "Megar Exceptions" do

  describe "Megar::Error" do
    let(:exception_class) { Megar::Error }
    subject { raise exception_class.new("test") }
    it "should raise correctly" do
      expect { subject }.to raise_error(exception_class)
    end
  end

  describe "Megar::CryptoSupportRequirementsError" do
    let(:exception_class) { Megar::CryptoSupportRequirementsError }
    subject { raise exception_class.new("test") }
    it "should raise correctly" do
      expect { subject }.to raise_error(exception_class)
    end
  end

  describe "Megar::MegaRequestError" do
    let(:exception_class) { Megar::MegaRequestError }
    {
      -15 => 'ESID',
      -6 => 'ETOOMANY',
      -99 => 'UNDEFINED'
    }.each do |error_code,message_partial|
      describe "error #{error_code}" do
        let(:exception_instance) { exception_class.new(error_code) }
        subject { raise exception_instance }
        it "should raise correctly" do
          expect { raise subject }.to raise_error(exception_class)
        end
        describe "#message" do
          subject { exception_instance.message }
          it { should include(message_partial) }
        end
      end
    end

  end

end
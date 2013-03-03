require 'spec_helper'

describe Megar::FileDownloader do
  let(:model_class) { Megar::FileDownloader }
  let(:instance) { model_class.new(attributes) }
  let(:attributes) { {} }

  describe "#get_chunks (protected)" do
    subject { instance.send(:get_chunks,size) }
    {
      122000   => [[0, 122000]],
      332000   => [[0, 131072], [131072, 200928]],
      500000   => [[0, 131072], [131072, 262144], [393216, 106784]],
      800000   => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 13568]],
      1800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 489280]],
      2000000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 33920]],
      2800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 47488]],
      3800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 129984]],
      4800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 1048576], [4718592, 81408]],
      20800000 => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 1048576], [4718592, 1048576], [5767168, 1048576], [6815744, 1048576], [7864320, 1048576], [8912896, 1048576], [9961472, 1048576], [11010048, 1048576], [12058624, 1048576], [13107200, 1048576], [14155776, 1048576], [15204352, 1048576], [16252928, 1048576], [17301504, 1048576], [18350080, 1048576], [19398656, 1048576], [20447232, 352768]],
    }.each do |size,chunks|
      context "when size=#{size}" do
        let(:size) { size }
        let(:expected) { chunks }
        it { should eql(chunks) }
      end
    end
  end

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

  describe "#calculate_chunk_mac (protected)" do
    subject { instance.send(:calculate_chunk_mac,'chunk') }
    before do
      instance.stub(:decomposed_key).and_return('decomposed_key')
      instance.stub(:iv).and_return('iv')
    end
    it "should delegate the correct call to session" do
      session = mock()
      session.should_receive(:calculate_chunk_mac).with('chunk','decomposed_key','iv',true)
      instance.stub(:session).and_return(session)
      subject
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

      # describe "#download_url_response" do
      #   let(:expected) { file_expectation['file_download_url_response'] }
      #   subject { instance.download_url_response }
      #   it { should eql(expected) }
      # end

      # describe "#download_url" do
      #   let(:expected) { /mega\.co\.nz\/dl/ }
      #   subject { instance.download_url }
      #   it { should match(expected) }
      # end

      # describe "#download_size" do
      #   let(:expected) { file_expectation['size'] }
      #   subject { instance.download_size }
      #   it { should eql(expected) }
      # end

      # describe "#download_attributes" do
      #   let(:expected) { { 'n' => file_name } }
      #   subject { instance.download_attributes }
      #   it { should eql(expected) }
      # end

      # describe "#iv" do
      #   let(:expected) { file_expectation['iv'] }
      #   subject { instance.iv }
      #   it { should eql(expected) }
      # end

      # describe "#mac" do
      #   let(:expected) { file_expectation['mac'] }
      #   subject { instance.mac }
      #   it { should eql(expected) }
      # end

      # describe "#initial_counter_value" do
      #   let(:expected) { file_expectation['initial_counter_value'] }
      #   subject { instance.initial_counter_value }
      #   it { should eql(expected) }
      # end

      # describe "#raw_content" do
      #   subject { Digest::SHA1.hexdigest(instance.raw_content) }
      #   it { should eql(sample_encrypted_content_digest) }
      # end

      describe "#content" do
        subject { Digest::SHA1.hexdigest(instance.content) }
        it { should eql(sample_decrypted_content_digest) }
      end

    end
  end

end
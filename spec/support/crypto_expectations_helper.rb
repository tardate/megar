require 'pathname'
require 'json'

module CryptoExpectationsHelper

  def crypto_expectations_path
    Pathname.new(File.dirname(__FILE__)).join('..','fixtures','crypto_expectations')
  end

  def crypto_expectations_sample_path(sample_name,ext='.json')
    crypto_expectations_path.join("#{sample_name}#{ext}")
  end

  # Returns the JSON representation of +sample_name+ expectations
  def crypto_expectations(sample_name='sample_user')
    JSON.parse(crypto_expectations_sample_path(sample_name).read)
  end

  def crypto_sample_encrypted_file_stream(filename)
    File.open(crypto_expectations_sample_path(filename,'.enc'),'rb')
  end

  # Returns the expected raw (encrypted) content for +filename+
  def crypto_sample_encrypted_file_content(filename)
    crypto_sample_encrypted_file_stream(filename).read
  end

  def crypto_sample_files_path
    Pathname.new(File.dirname(__FILE__)).join('..','fixtures','sample_files')
  end

  def crypto_sample_file_path(filename)
    crypto_sample_files_path.join(filename)
  end

  def crypto_sample_file_stream(filename)
    File.open(crypto_sample_file_path(filename),'rb')
  end

  # Returns the expected (decrypted) content for +filename+
  def crypto_sample_decrypted_content(filename)
    crypto_sample_file_path(filename).read
  end

  # Writes the crypto expectations file and returns the file name used
  def write_crypto_expectations(content,sample_name='sample_user')
    filename = crypto_expectations_sample_path(sample_name)
    File.open(filename,'w') do |f|
      f.write JSON.pretty_generate(content)
    end
    filename
  end

  def write_file_download_sample(filename,raw_content)
    fn = crypto_expectations_sample_path(filename,'.enc')
    File.open(fn,'wb') do |f|
      f.write raw_content
    end
  end

  def generate_crypto_expectations(email,password)
    STDERR.puts "\nGenerating crypto_expectations for #{email}..."
    e = {email: email.downcase, email_mixed_case: email.capitalize, password: password, autoconnect: false }
    if session = Megar::Session.new(email: email, password: password)
      e[:login_response_data] = session.send(:get_login_response)
      session.send(:handle_login_challenge_response,e[:login_response_data])
      e[:master_key] = session.master_key
      e[:expected_uh] = session.send(:uh)
      e[:sid] = session.sid
      e[:rsa_private_key_b64] = session.rsa_private_key_b64
      e[:decomposed_rsa_private_key] = session.decomposed_rsa_private_key
      e[:files_response_data] = session.send(:get_files_response)
      session.send(:handle_files_response,e[:files_response_data])
      megar_test_sample_1 = session.files.find_by_name('megar_test_sample_1.txt')
      megar_test_sample_2 = session.files.find_by_name('megar_test_sample_2.png')
      if megar_test_sample_1 && megar_test_sample_2
        downloader = megar_test_sample_1.downloader
        sample_1 = {
          file_download_url_response: downloader.download_url_response,
          key: megar_test_sample_1.key,
          decomposed_key: megar_test_sample_1.decomposed_key,
          size: downloader.download_size,
          iv: downloader.iv,
          initial_counter_value: downloader.initial_counter_value
        }
        write_file_download_sample(megar_test_sample_1.name,downloader.raw_content)

        downloader = megar_test_sample_2.downloader
        sample_2 = {
          file_download_url_response: downloader.download_url_response,
          key: megar_test_sample_2.key,
          decomposed_key: megar_test_sample_2.decomposed_key,
          size: downloader.download_size,
          iv: downloader.iv,
          initial_counter_value: downloader.initial_counter_value
        }
        write_file_download_sample(megar_test_sample_2.name,downloader.raw_content)

        e[:sample_files] = {
          megar_test_sample_1.name => sample_1,
          megar_test_sample_2.name => sample_2
        }
      else
        raise "\n\nI can't find the expected samples files for testing in this account. Please upload the sample files in 'spec/fixtures/sample_files' and try this again.."
      end
    end
    filename = write_crypto_expectations(e)
    STDERR.puts "\nDone! New crypto_expectations for unit test written to:\n#{filename}\n\n"
  end

end


RSpec.configure do |conf|
  conf.extend  CryptoExpectationsHelper # so that these methods are available outside of individual tests
  conf.include CryptoExpectationsHelper
end
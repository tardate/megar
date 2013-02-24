require 'pathname'
require 'json'

module CryptoExpectationsHelper

  def crypto_expectations_path
    Pathname.new(File.dirname(__FILE__)).join('..','fixtures','crypto_expectations')
  end

  def crypto_expectations_sample_path(sample_name)
    crypto_expectations_path.join("#{sample_name}.json")
  end

  # Returns the JSON representation of +sample_name+ expectations
  def crypto_expectations(sample_name)
    JSON.parse(crypto_expectations_sample_path(sample_name).read)
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
    end
    efn = crypto_expectations_sample_path('sample_user')
    ef = File.open(efn,'w')
    ef.write e.to_json
    ef.close
    STDERR.puts "\nDone! New crypto_expectations for unit test written to:\n#{efn}\n\n"
  end

end


RSpec.configure do |conf|
  conf.include CryptoExpectationsHelper
end
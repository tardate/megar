module MocksHelper

  def session_with_mocked_api_responses(options, mock_dataset='sample_user')
    test_data = crypto_expectations(mock_dataset)
    session = Megar::Session.new(options.merge(autoconnect: false))
    session.stub(:get_login_response).and_return(test_data['login_response_data'])
    session.stub(:get_files_response).and_return(test_data['files_response_data'])
    session
  end

  def connected_session_with_mocked_api_responses(options, mock_dataset='sample_user')
    session = session_with_mocked_api_responses(options, mock_dataset='sample_user')
    session.connect!
    session
  end

end


RSpec.configure do |conf|
  conf.include MocksHelper
end
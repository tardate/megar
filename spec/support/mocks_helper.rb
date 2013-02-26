module MocksHelper

  def session_with_mocked_api_responses(options={}, mock_dataset='sample_user')
    test_data = crypto_expectations(mock_dataset)
    base_options = {
      email: test_data['email'],
      password: test_data['password']
    }
    session = Megar::Session.new(base_options.merge(options).merge(autoconnect: false))
    session.stub(:get_login_response).and_return(test_data['login_response_data'])
    session.stub(:get_files_response).and_return(test_data['files_response_data'])
    session
  end

  def connected_session_with_mocked_api_responses(options={}, mock_dataset='sample_user')
    session = session_with_mocked_api_responses(options, mock_dataset)
    session.connect!
    session
  end

  def dummy_session_with_files_and_folders
    session = Megar::Session.new(autoconnect: false)
    session.stub(:api_request).and_return(nil) # just to be sure it wont work
    session.reset_files!
    session.folders.add(id: 'rootid',  type: 2) # Root
    session.folders.add(id: 'inboxid', type: 3) # Inbox
    session.folders.add(id: 'trashid', type: 4) # Trash
    session.folders.add(id: 'dir1',    type: 1, name: 'User Folder 1')
    session.folders.add(id: 'dir2',    type: 1, name: 'User Folder 2')
    session.folders.add(id: 'dir3',    type: 1, name: 'User Folder 3', parent_folder_id: 'dir1')

    session.files.add(id: 'file1',  type: 0, name: 'User File 1', parent_folder_id: 'dir1')
    session.files.add(id: 'file2',  type: 0, name: 'User File 2', parent_folder_id: 'dir1')
    session.files.add(id: 'file3',  type: 0, name: 'User File 3', parent_folder_id: 'dir3')

    session
  end

end


RSpec.configure do |conf|
  conf.include MocksHelper
end
require 'test/unit'
require 'cdnconnect_api'
require 'cdnconnect_api/response'
require 'http_response'


class CDNConnectApiTest < Test::Unit::TestCase
  

  def test_build_upload_queue_source_folder_path_regex
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
        
    test_files_folder = Dir.pwd + '/test/testfiles'
    
    options = { :destination_path => 'url1', :source_folder_path => test_files_folder, :recursive_local_folders => true,
                :valid_extensions => ['js', 'css']}
    api_client.build_upload_queue(options)
    assert_equal 2, api_client.upload_queue.length
    
    upload_queue = api_client.upload_queue
    assert_equal true, upload_queue['url1/subfolder1/subfolder1a'].has_key?(test_files_folder + '/subfolder1/subfolder1a/script.js')
    assert_equal true, upload_queue['url1/subfolder1/subfolder1a'].has_key?(test_files_folder + '/subfolder1/subfolder1a/styles.css')
    
    assert_equal true, upload_queue['url1/subfolder1/subfolder1b'].has_key?(test_files_folder + '/subfolder1/subfolder1b/jquery-2.0.2.min.js')
    assert_equal true, upload_queue['url1/subfolder1/subfolder1b'].has_key?(test_files_folder + '/subfolder1/subfolder1b/jquery.mobile-1.3.1.min.css')
    
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    
    options = { :destination_path => 'url2', :source_folder_path => test_files_folder, :recursive_local_folders => true,
                :valid_extensions => ['jpg']}
    api_client.build_upload_queue(options)
    assert_equal 1, api_client.upload_queue.length
    upload_queue = api_client.upload_queue
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/DSCN0251.JPG')
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/IMAG0355.jpg')
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/IMAG4501.jpg')
  end
  

  def test_build_upload_queue_source_folder_path
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
        
    test_files_folder = Dir.pwd + '/test/testfiles'
    
    options = { :destination_path => 'url1', :source_folder_path => test_files_folder, :recursive_local_folders => false}
    api_client.build_upload_queue(options)
    assert_equal 1, api_client.upload_queue.length
    
    upload_queue = api_client.upload_queue
    assert_equal true, upload_queue['url1'].has_key?(test_files_folder + '/DSCN0251.JPG')
    assert_equal true, upload_queue['url1'].has_key?(test_files_folder + '/IMAG0355.jpg')
    assert_equal true, upload_queue['url1'].has_key?(test_files_folder + '/IMAG4501.jpg')
    
    options = { :destination_path => 'url2', :source_folder_path => test_files_folder, :recursive_local_folders => false}
    api_client.build_upload_queue(options)
    assert_equal 2, api_client.upload_queue.length
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/DSCN0251.JPG')
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/IMAG0355.jpg')
    assert_equal true, upload_queue['url2'].has_key?(test_files_folder + '/IMAG4501.jpg')
    
    options = { :destination_path => 'url3', :source_folder_path => test_files_folder, :recursive_local_folders => true}
    api_client.build_upload_queue(options)
    assert_equal 7, api_client.upload_queue.length
    assert_equal true, upload_queue['url3'].has_key?(test_files_folder + '/DSCN0251.JPG')
    assert_equal true, upload_queue['url3'].has_key?(test_files_folder + '/IMAG0355.jpg')
    assert_equal true, upload_queue['url3'].has_key?(test_files_folder + '/IMAG4501.jpg')
    
    assert_equal true, upload_queue['url3/subfolder1'].has_key?(test_files_folder + '/subfolder1/w00t.txt')
    
    assert_equal true, upload_queue['url3/subfolder1/subfolder1a'].has_key?(test_files_folder + '/subfolder1/subfolder1a/script.js')
    assert_equal true, upload_queue['url3/subfolder1/subfolder1a'].has_key?(test_files_folder + '/subfolder1/subfolder1a/styles.css')
    
    assert_equal true, upload_queue['url3/subfolder1/subfolder1b'].has_key?(test_files_folder + '/subfolder1/subfolder1b/jquery-2.0.2.min.js')
    assert_equal true, upload_queue['url3/subfolder1/subfolder1b'].has_key?(test_files_folder + '/subfolder1/subfolder1b/jquery.mobile-1.3.1.min.css')
    
    assert_equal true, upload_queue['url3/subfolder2'].has_key?(test_files_folder + '/subfolder2/help.html')
    assert_equal true, upload_queue['url3/subfolder2'].has_key?(test_files_folder + '/subfolder2/whatwhat.html')
    
  end


  def test_build_upload_queue_source_file
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal 0, api_client.upload_queue.length
        
    test_files_folder = Dir.pwd + '/test/testfiles'
    
    options = {}
    api_client.build_upload_queue(options)
    assert_equal 0, api_client.upload_queue.length
    
    # source_file_path
    options = { :destination_path => 'url', :source_file_path => test_files_folder + '/DSCN0251.JPG' }
    api_client.build_upload_queue(options)
    assert_equal 1, api_client.upload_queue.length
    api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 25, :max_request_size => 25165824, :queue_processing => true)
    api_client.successful_upload_attempt('url')
    assert_equal 0, api_client.upload_queue.length
    
    # source_file_paths
    options = { :destination_path => 'url2', :source_file_paths => [ test_files_folder + '/DSCN0251.JPG', test_files_folder + '/IMAG0355.jpg'] }
    api_client.build_upload_queue(options)
    assert_equal 1, api_client.upload_queue.length
    api_client.build_post_data(:destination_path => 'url2')
    api_client.successful_upload_attempt('url2')
    assert_equal 0, api_client.upload_queue.length
    
  end
  
  
  def test_failed_upload_attempt
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal 0, api_client.failed_uploads.length

    test_files_folder = Dir.pwd + '/test/testfiles'
    
    api_client.add_source_to_upload_queue('url', test_files_folder + '/DSCN0251.JPG')
    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG0355.jpg')
    post_data = api_client.build_post_data(:destination_path => 'url')
    assert_equal 2, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    
    # Failed attempt 1
    api_client.failed_upload_attempt('url')
    assert_equal 0, api_client.failed_uploads.length
    assert_equal 1, api_client.upload_queue.length
    
    post_data = api_client.build_post_data(:destination_path => 'url')
    assert_equal 2, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    
    # Failed attempt 2
    api_client.failed_upload_attempt('url')
    assert_equal 0, api_client.failed_uploads.length
    assert_equal 1, api_client.upload_queue.length
    
    post_data = api_client.build_post_data(:destination_path => 'url')
    assert_equal 2, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    
    # Failed attempt 3
    api_client.failed_upload_attempt('url')
    assert_equal 2, api_client.failed_uploads.length
    assert_equal 0, api_client.upload_queue.length
    
  end

  
  def test_build_post_data
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal 0, api_client.upload_queue.length
    
    test_files_folder = Dir.pwd + '/test/testfiles'
    
    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG4501.jpg')
    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2)
    assert_equal 1, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    api_client.successful_upload_attempt('url')
    
    api_client.add_source_to_upload_queue('url', test_files_folder + '/DSCN0251.JPG')
    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG0355.jpg')
    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2)
    assert_equal 2, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    api_client.successful_upload_attempt('url')
    assert_equal 0, api_client.upload_queue.length
    
    api_client.add_source_to_upload_queue('url', test_files_folder + '/DSCN0251.JPG')
    assert_equal 1, api_client.upload_queue.length
    assert_equal 1, api_client.upload_queue['url'].length
    assert_equal({"attempts"=>0,"active"=>false}, api_client.upload_queue['url'][test_files_folder + '/DSCN0251.JPG'])

    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG0355.jpg')
    assert_equal 1, api_client.upload_queue.length
    assert_equal 2, api_client.upload_queue['url'].length
    assert_equal({"attempts"=>0,"active"=>false}, api_client.upload_queue['url'][test_files_folder + '/IMAG0355.jpg'])

    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG4501.jpg')
    assert_equal 1, api_client.upload_queue.length
    assert_equal 3, api_client.upload_queue['url'].length
    assert_equal({"attempts"=>0,"active"=>false}, api_client.upload_queue['url'][test_files_folder + '/IMAG4501.jpg'])

    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2)
    assert_equal 2, post_data[:file].length

    api_client.successful_upload_attempt('url')
    assert_equal 1, api_client.upload_queue.length
    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2)
    assert_equal 1, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    api_client.successful_upload_attempt('url')
    assert_equal 0, api_client.upload_queue.length
    
    api_client.add_source_to_upload_queue('url', test_files_folder + '/DSCN0251.JPG')
    api_client.add_source_to_upload_queue('url', test_files_folder + '/IMAG0355.jpg')
    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2, :max_request_size => 1000)
    assert_equal 1, post_data[:file].length
    api_client.successful_upload_attempt('url')
    assert_equal 1, api_client.upload_queue.length
    post_data = api_client.build_post_data(:destination_path => 'url', :max_files_per_request => 2, :max_request_size => 1000)
    assert_equal 1, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    api_client.successful_upload_attempt('url')
    assert_equal 0, api_client.upload_queue.length
    
    api_client.add_source_to_upload_queue('url1', test_files_folder + '/DSCN0251.JPG')
    api_client.add_source_to_upload_queue('url2', test_files_folder + '/IMAG0355.jpg')
    api_client.add_source_to_upload_queue('url3', test_files_folder + '/IMAG4501.jpg')
    post_data = api_client.build_post_data(:destination_path => 'url1', :max_files_per_request => 2)
    assert_equal 1, post_data[:file].length
    assert_equal 3, api_client.upload_queue.length
    
    api_client.successful_upload_attempt('url1')
    assert_equal 2, api_client.upload_queue.length
    
    post_data = api_client.build_post_data(:destination_path => 'url2', :max_files_per_request => 2)
    assert_equal 1, post_data[:file].length
    assert_equal 2, api_client.upload_queue.length
    
    api_client.successful_upload_attempt('url2')
    assert_equal 1, api_client.upload_queue.length
    
    post_data = api_client.build_post_data(:destination_path => 'url3', :max_files_per_request => 2)
    assert_equal 1, post_data[:file].length
    assert_equal 1, api_client.upload_queue.length
    
    api_client.successful_upload_attempt('url3')
    assert_equal 0, api_client.upload_queue.length
    
  end

  
  def test_upload_queue
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal({}, api_client.upload_queue)
    
    api_client.add_source_to_upload_queue('url-a', '1')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.add_source_to_upload_queue('url-a', '1')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.add_source_to_upload_queue('url-a', '2')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}, "2" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
        
    api_client.add_source_to_upload_queue('url-b', '3')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}, "2" => {"attempts"=>0,"active"=>false}}, "url-b" => {"3" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
        
    api_client.add_source_to_upload_queue('url-b', '4')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}, "2" => {"attempts"=>0,"active"=>false}}, "url-b" => {"3" => {"attempts"=>0,"active"=>false}, "4" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)

    api_client.remove_source_from_queue('url-a', 'badpath')
    assert_equal({"url-a" => {"1" => {"attempts"=>0,"active"=>false}, "2" => {"attempts"=>0,"active"=>false}}, "url-b" => {"3" => {"attempts"=>0,"active"=>false}, "4" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.remove_source_from_queue('url-a', '1')
    assert_equal({"url-a" => {"2" => {"attempts"=>0,"active"=>false}}, "url-b" => {"3" => {"attempts"=>0,"active"=>false}, "4" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.remove_source_from_queue('url-a', '2')
    assert_equal({"url-b" => {"3" => {"attempts"=>0,"active"=>false}, "4" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.remove_source_from_queue('url-b', '4')
    assert_equal({"url-b" => {"3" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
    api_client.remove_source_from_queue('url-b', '3')
    assert_equal({}, api_client.upload_queue)
    
    api_client.add_source_to_upload_queue('url-c', '5')
    assert_equal({"url-c" => {"5" => {"attempts"=>0,"active"=>false}}}, api_client.upload_queue)
    
  end

  
  def test_get_prefetched_upload_urls
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')

    upload_url = api_client.get_prefetched_upload_url(nil)
    assert_equal nil, upload_url

    api_client.set_prefetched_upload_url('destination_url', 'upload_url')
    upload_url = api_client.get_prefetched_upload_url('destination_url')
    assert_equal 'upload_url', upload_url

    api_client.set_prefetched_upload_url('destination_url', nil)
    upload_url = api_client.get_prefetched_upload_url('destination_url')
    assert_equal nil, upload_url
  end

  
  def test_prepare_upload_validate_source_files
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')

    exception = assert_raise ArgumentError do
      options = { :source_folder_path => 'invalidpath', :destination_path => 'destination_path' }
      options = api_client.prepare_upload(options)
    end
    assert_equal("source_folder_path \"invalidpath\" is not a valid directory", exception.message)

    exception = assert_raise ArgumentError do
      options = { :source_file_paths => 'not an array', :destination_path => 'destination_path' }
      options = api_client.prepare_upload(options)
    end
    assert_equal("source_file_paths must be an array of strings", exception.message)

    exception = assert_raise ArgumentError do
      options = { :source_file_paths => [Dir.pwd, 'not valid path'], :destination_path => 'destination_path' }
      options = api_client.prepare_upload(options)
    end
    assert_equal("source_file_path \"" + Dir.pwd + "\" is not a valid file", exception.message)

    exception = assert_raise ArgumentError do
      options = { :source_file_paths => [__FILE__, 'not valid path'], :destination_path => 'destination_path' }
      options = api_client.prepare_upload(options)
    end
    assert_equal("source_file_path \"not valid path\" is not a valid file", exception.message)
    
    exception = assert_raise ArgumentError do
      options = { :source_file_path => 'not valid path' }
      options = api_client.prepare_upload(options)
    end
    assert_equal("source_file_path \"not valid path\" is not a valid file", exception.message)

    exception = assert_raise ArgumentError do
      options = {}
      options = api_client.prepare_upload(options)
    end
    assert_equal("source file(s) required", exception.message)
    
  end
  

  def test_prepare
    exception = assert_raise ArgumentError do
        api_client = CDNConnect::APIClient.new(:api_key => 'API_KEY')
    end
    assert_equal("app_host option required when using api_key option", exception.message)

    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    exception = assert_raise ArgumentError do
      api_client.prepare()
    end
    assert_equal "missing api path", exception.message

    api_client = CDNConnect::APIClient.new(:api_key => 'API_KEY', :app_host => 'test.cdnconnect.com')

    options = { :api_path => '/ME_PATH.json' }
    rtn = api_client.prepare(options)
    assert_equal 'https://api.cdnconnect.com/v1/test.cdnconnect.com/ME_PATH.json', rtn[:url]
    assert_equal 'GET', rtn[:method]

    headers = rtn[:headers]
    assert_equal true, headers.has_key?('User-Agent')

  end

  def test_api_response_merge_server_error
    http_response = CDNTestHttpResponse.new(500, 'bloody hell')

    api_response = CDNConnect::APIResponse.new(http_response)
    assert_equal 'bloody hell', api_response.body
    assert_equal nil, api_response.data
    assert_equal 500, api_response.status
    assert_equal true, api_response.is_server_error
    assert_equal false, api_response.is_success
    assert_equal false, api_response.is_client_error
    assert_equal 0, api_response.msgs.length
    assert_equal nil, api_response.object
    assert_equal nil, api_response.files
  end
  
    
  def test_api_response_merge
    http_response = CDNTestHttpResponse.new(200, '{"results":{"files":[{"status":1,"upload_success":true,"name":"humans.txt","msgs":[],"created":"2013-06-05T14:50Z","file_name":"humans","modified":"2013-06-05T21:50Z","org_size":null,"parent_id":"p45Zegzgp65P","ext":"txt","rev_id":"dv2x5U8M","type":"text/plain","id":"nz3AGoEvyy7S","size":244}]},"msgs":[]}')
    
    http_response2 = CDNTestHttpResponse.new(200, '{"results":{"files":[{"status":1,"upload_success":true,"name":"dogs.txt","msgs":[],"created":"2013-06-05T14:50Z","file_name":"dogs","modified":"2013-06-05T21:50Z","org_size":null,"parent_id":"p45Zegzgp65P","ext":"txt","rev_id":"bv2x5U8M","type":"text/plain","id":"ez3AGoEvyy7S","size":244}]},"msgs":[{"text":"text","status":"status"}]}')
  
    api_response = CDNConnect::APIResponse.new(http_response)
    assert_equal 0, api_response.msgs.length
    assert_equal false, api_response.has_msgs
    assert_equal 1, api_response.files.length
    
    api_response2 = CDNConnect::APIResponse.new(http_response2)
    assert_equal 1, api_response2.msgs.length
    assert_equal 1, api_response2.files.length
    
    api_response.merge(api_response2)
    assert_equal 1, api_response.msgs.length
    assert_equal 2, api_response.files.length
    
    
    http_response3 = CDNTestHttpResponse.new(200, '{"results":{},"msgs":[]}')
    api_response3 = CDNConnect::APIResponse.new(http_response3)
    assert_equal nil, api_response3.files
    
    api_response.merge(api_response3)
    assert_equal 1, api_response.msgs.length
    assert_equal 2, api_response.files.length
    
    api_response3.merge(api_response2)
    assert_equal 1, api_response3.msgs.length
    assert_equal 1, api_response3.files.length
    
    api_response4 = CDNConnect::APIResponse.new()
    assert_equal nil, api_response4.body
    assert_equal ({"results" => {}, "msgs" => []}), api_response4.data
    assert_equal true, api_response.has_msgs
    assert_equal 0, api_response4.status
    assert_equal false, api_response4.is_server_error
    assert_equal false, api_response4.is_success
    assert_equal false, api_response4.is_client_error
    assert_equal 0, api_response4.msgs.length
    assert_equal nil, api_response4.object
    assert_equal nil, api_response4.files
    
    api_response4.merge(api_response)
    assert_equal 200, api_response4.status
    assert_equal 1, api_response4.msgs.length
    assert_equal 2, api_response4.files.length
    
  end
  

  def test_api_response_success
    http_response = CDNTestHttpResponse.new(200, '{"results":{"files":[{"status":1,"upload_success":true,"name":"humans.txt","msgs":[],"created":"2013-06-05T14:50Z","file_name":"humans","modified":"2013-06-05T21:50Z","org_size":null,"parent_id":"p45Zegzgp65P","ext":"txt","rev_id":"dv2x5U8M","type":"text/plain","id":"nz3AGoEvyy7S","size":244}]},"msgs":[]}')
  
    api_response = CDNConnect::APIResponse.new(http_response)
    assert_equal 200, api_response.status
    assert_equal [], api_response.msgs
    assert_equal 1, api_response.files.length
    assert_equal true, api_response.files[0]['upload_success']
    assert_equal 'humans.txt', api_response.files[0]['name']
    assert_equal 'humans.txt', api_response.object['name']
    assert_equal true, api_response.is_success
    assert_equal false, api_response.is_error
    assert_equal false, api_response.is_server_error
  end


  def test_initialize_client
    api_client = CDNConnect::APIClient.new(:client_id => 'CLIENT_ID')
    assert_equal "CLIENT_ID", api_client.client_id
    assert_equal nil, api_client.code

    api_client = CDNConnect::APIClient.new(:client_secret => 'CLIENT_SECRET')
    assert_equal "CLIENT_SECRET", api_client.client_secret
    
    api_client = CDNConnect::APIClient.new(:scope => 'SCOPE')
    assert_equal "SCOPE", api_client.scope
    
    api_client = CDNConnect::APIClient.new(:state => 'STATE')
    assert_equal "STATE", api_client.state
    
    api_client = CDNConnect::APIClient.new(:code => 'CODE')
    assert_equal "CODE", api_client.code

    api_client = CDNConnect::APIClient.new(:redirect_uri => 'https://REDIRECT_URI')
    assert_equal "https://REDIRECT_URI", api_client.redirect_uri

    assert_raise ArgumentError do
      api_client = CDNConnect::APIClient.new(:redirect_uri => 'REDIRECT_URI')
    end
    
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal "ACCESS_TOKEN", api_client.access_token

  end
  
end


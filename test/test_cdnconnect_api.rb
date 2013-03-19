require 'test/unit'
require 'cdnconnect_api'

class CDNConnectApiTest < Test::Unit::TestCase

  def test_get_prefetched_upload_urls
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')

    upload_url = api_client.get_prefetched_upload_url(nil, nil, nil)
    assert_equal nil, upload_url

    api_client.set_prefetched_upload_url('destination_url', nil, nil, 'upload_url')
    upload_url = api_client.get_prefetched_upload_url('destination_url', nil, nil)
    assert_equal 'upload_url', upload_url

    api_client.set_prefetched_upload_url('destination_url', nil, nil, nil)
    upload_url = api_client.get_prefetched_upload_url('destination_url', nil, nil)
    assert_equal nil, upload_url

    api_client.set_prefetched_upload_url(nil, 'app_id', 'obj_id', 'upload_url')
    upload_url = api_client.get_prefetched_upload_url(nil, 'app_id', 'obj_id')
    assert_equal 'upload_url', upload_url

    api_client.set_prefetched_upload_url(nil, 'app_id', 'obj_id', nil)
    upload_url = api_client.get_prefetched_upload_url(nil, 'app_id', 'obj_id')
    assert_equal nil, upload_url
  end

  
  def test_prepare_upload
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')

    assert_raise ArgumentError do
      options = {}
      api_client.prepare_upload(options)
    end

    assert_raise ArgumentError do
      options = { :source_local_path => 'source_local_path' }
      options = api_client.prepare_upload(options)
    end

    options = { :source_file_local_path => 'source_file_local_path', :destination_folder_url => 'destination_folder_url' }
    options = api_client.prepare_upload(options)
    assert_equal 'application/octet-stream', options[:mime_type]

    options = { :source_file_local_path => 'source_file_local_path', :destination_folder_url => 'destination_folder_url', :mime_type => 'mime_type' }
    options = api_client.prepare_upload(options)
    assert_equal 'mime_type', options[:mime_type]

    options = { :source_file_local_path => 'source_file_local_path', :destination_folder_url => 'destination_folder_url', :mime_type => 'mime_type' }
    options = api_client.prepare_upload(options)
    assert_equal 'mime_type', options[:mime_type]

    assert_raise ArgumentError do
      options = { :source_file_local_path => 'source_file_local_path', :app_id => 'app_id' }
      options = api_client.prepare_upload(options)
    end

    assert_raise ArgumentError do
      options = { :source_file_local_path => 'source_file_local_path', :obj_id => 'obj_id' }
      options = api_client.prepare_upload(options)
    end

  end


  def test_prepare
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_raise ArgumentError do
      api_client.prepare()
    end

    options = {}
    assert_raise ArgumentError do
      response = api_client.prepare(options)
    end

    options = { :path => '/v1/ME_PATH.json' }
    rtn = api_client.prepare(options)
    assert_equal 'https://api.cdnconnect.com/v1/ME_PATH.json', rtn[:url]
    assert_equal 'GET', rtn[:method]

    headers = rtn[:headers]
    assert_equal true, headers.has_key?('User-Agent')

  end


  def test_generate_obj_path
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    path = api_client.generate_obj_path(:url => 'demo.cdnconnect.com/images/file.jpg')
    assert_equal "demo.cdnconnect.com/images/file.jpg", path

    path = api_client.generate_obj_path(:app_id => 'app_id', :obj_id => 'obj_id')
    assert_equal "apps/app_id/objects/obj_id", path

    assert_raise ArgumentError do
      api_client.generate_obj_path(:app_id => 'app_id')
    end

    assert_raise ArgumentError do
      api_client.generate_obj_path(:obj_id => 'obj_id')
    end
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
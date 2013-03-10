require 'test/unit'
require 'cdnconnect_api'

class CDNConnectApiTest < Test::Unit::TestCase
  
  def test_prepare_upload
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')

    assert_raise ArgumentError do
      options = {}
      api_client.prepare_upload(options)
    end

    assert_raise ArgumentError do
      options = { :source_file => 'source_file' }
      api_client.prepare_upload(options)
    end

    options = { :source_file => 'source_file', :mime_type => 'mime_type' }
    api_client.prepare_upload(options)

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

    options = { :path => '/ME_PATH' }
    rtn = api_client.prepare(options)
    assert_equal rtn[:response_format], 'application/json'
    assert_equal rtn[:uri], 'https://api.cdnconnect.com/ME_PATH.json'
    assert_equal rtn[:method], 'GET'

    options = { :path => '/ME_PATH', :response_format => 'application/xml' }
    rtn = api_client.prepare(options)
    assert_equal rtn[:response_format], 'application/xml'
    assert_equal rtn[:uri], 'https://api.cdnconnect.com/ME_PATH.xml'

    options = { :path => '/ME_PATH', :response_format => 'text/html', :method => 'POST' }
    rtn = api_client.prepare(options)
    assert_equal rtn[:response_format], 'text/html'
    assert_equal rtn[:uri], 'https://api.cdnconnect.com/ME_PATH.html'
    assert_equal rtn[:method], 'POST'

    options = { :path => '/ME_PATH', :response_format => 'wrong/type' }
    rtn = api_client.prepare(options)
    assert_equal rtn[:response_format], 'application/json'
    assert_equal rtn[:uri], 'https://api.cdnconnect.com/ME_PATH.json'
    assert_equal rtn[:method], 'GET'

    headers = rtn[:headers]
    assert_equal true, headers.has_key?('User-Agent')

  end


  def test_generate_obj_path
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    path = api_client.generate_obj_path(:uri => 'demo.cdnconnect.com/images/file.jpg')
    assert_equal "/v1/demo.cdnconnect.com/images/file.jpg", path

    path = api_client.generate_obj_path(:app_id => 'app_id', :obj_id => 'obj_id')
    assert_equal "/v1/apps/app_id/objects/obj_id", path

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
    assert_equal 'application/json', api_client.response_format

    api_client = CDNConnect::APIClient.new(:client_secret => 'CLIENT_SECRET')
    assert_equal "CLIENT_SECRET", api_client.client_secret
    
    api_client = CDNConnect::APIClient.new(:scope => 'SCOPE')
    assert_equal "SCOPE", api_client.scope
    
    api_client = CDNConnect::APIClient.new(:state => 'STATE')
    assert_equal "STATE", api_client.state
    
    api_client = CDNConnect::APIClient.new(:code => 'CODE')
    assert_equal "CODE", api_client.code

    api_client = CDNConnect::APIClient.new(:response_format => 'application/xml')
    assert_equal "application/xml", api_client.response_format

    api_client = CDNConnect::APIClient.new(:redirect_uri => 'https://REDIRECT_URI')
    assert_equal "https://REDIRECT_URI", api_client.redirect_uri

    assert_raise ArgumentError do
      api_client = CDNConnect::APIClient.new(:redirect_uri => 'REDIRECT_URI')
    end
    
    api_client = CDNConnect::APIClient.new(:access_token => 'ACCESS_TOKEN')
    assert_equal "ACCESS_TOKEN", api_client.access_token

    assert_raise ArgumentError do
      api_client = CDNConnect::APIClient.new()
    end
  end
  
end
# Copyright 2013 CDN Connect
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'faraday'
require 'faraday/utils'
require 'signet/oauth_2/client'
require 'cdnconnect_api/response'


module CDNConnect

  class APIClient
  
    @@application_name = 'cdnconnect-api-ruby'
    @@application_version = '0.0.1'
    @@api_host = 'https://api.cdnconnect.com'
    @@user_agent = @@application_name + ' v' + @@application_version

    ##
    # Creates a client to authorize interactions with the API using the OAuth 2.0 protocol.
    # This can be given a known API Key (access_token) or can use OAuth 2.0 
    # web application flow designed for 3rd party web sites (clients).
    #
    # @param [Hash] options
    #   The configuration parameters for the client.
    #   - <code>:api_key</code> -
    #     An API Key (commonly known as an access_token) which was previously 
    #     created within CDN Connect's account for a specific app.
    #   - <code>:response_format</code> -
    #     How data should be formatted on the response. Possible values for
    #     include application/json, application/xml. JSON is the default.
    #   - <code>:client_id</code> -
    #     A unique identifier issued to the client to identify itself to CDN Connect's
    #     authorization server. This is issued by CDN Connect to individual clients.
    #   - <code>:client_secret</code> -
    #     A shared secret issued by the CDN Connect's authorization server,
    #     which is used to authenticate the client. Do not confuse this is an access_token
    #     or an api_key.
    #   - <code>:scope</code> -
    #     The scope of the access request, expressed either as an Array
    #     or as a space-delimited String.
    #   - <code>:state</code> -
    #     An unguessable random string designed to allow the client to maintain state
    #     to protect against cross-site request forgery attacks.
    #   - <code>:code</code> -
    #     The authorization code received from the authorization server.
    #   - <code>:redirect_uri</code> -
    #     The redirection URI used in the initial request.
    #   - <code>:access_token</code> -
    #     The current access token for this client, also known as the API Key.
    def initialize(options={})
      # Normalize key to String to allow indifferent access.
      options = options.inject({}) { |accu, (k, v)| accu[k.to_s] = v; accu }
      
      # Initialize all of the options
      @client_id = options["client_id"]
      @client_secret = options["client_secret"]
      @scope = options["scope"]
      @state = options["state"]
      @code = options["code"]
      @redirect_uri = options["redirect_uri"]
      options["access_token"] = options["access_token"] || options["api_key"] # both work
      @access_token = options["access_token"]
      @response_format = options["response_format"] || 'application/json'
      @prefetched_upload_urls = {}
      
      # Create the OAuth2 client which will be used to authorize the requests
      @client = Signet::OAuth2::Client.new(:client_id => client_id,
                                           :client_secret => @client_secret,
                                           :scope => @scope,
                                           :state => @state,
                                           :code => @code,
                                           :redirect_uri => @redirect_uri,
                                           :access_token => @access_token)
      return self
    end


    ##
    # Used to receive information about an object, which can be either a file or 
    # folder. This method requires either a CDN Connect URL, or both an
    # app_id and obj_id.
    #
    # @param [Hash] options
    #   The configuration parameters for the client.
    #   - <code>:url</code> -
    #     The URL of the object to get data on. If the URL option is not provided
    #     then you must use the app_id and obj_id options.
    #   - <code>:app_id</code> -
    #     The app_id of the object to get data on. If the app_id or obj_id options 
    #     are not provided then you must use the url option.
    #   - <code>:obj_id</code> -
    #     The obj_id of the object to get data on. If the app_id or obj_id options 
    #     are not provided then you must use the url option.
    def get(options={})
      options[:path] = self.generate_obj_path(options)
      return self.fetch(options)
    end


    ##
    # Used to upload a file or files within a folder to a destination folder within
    # a CDN Connect app. This method requires either a CDN Connect URL, or both an app_id
    # and obj_id. If you are uploading many files be sure to use the same client instance.
    #
    # @param [Hash] options
    #   The configuration parameters for the client.
    #   - <code>:destination_folder_url</code> -
    #     The URL of the folder to upload to. If the destination folder URL option 
    #     is not provided then you must use the app_id and obj_id options.
    #   - <code>:app_id</code> -
    #     The app_id of the app to upload to. If the app_id or obj_id options 
    #     are not provided then you must use the url option.
    #   - <code>:obj_id</code> -
    #     The obj_id of the folder to upload to. If the app_id or obj_id options 
    #     are not provided then you must use the url option.
    #   - <code>:source_file_local_path</code> -
    #     A string of a source file's local paths to upload.
    def upload(options={})
      # Make sure we've got good data before starting the upload
      prepare_upload(options)

      i = 1
      begin

        # Check if we have a prefetched upload url before requesting a new one
        upload_url = get_prefetched_upload_url(options[:destination_folder_url], 
                                               options[:app_id], 
                                               options[:obj_id])
        if upload_url == nil
          # We do not already have an upload url created. The first upload request
          # will need to make a request for an upload url. After the first upload
          # each upload response will also include a new upload url which can be used 
          # for the next upload when uploading to the same folder.
          upload_url_response = self.get_upload_url(options)
          if upload_url_response.is_error
            return upload_url_response
          end
          upload_url = upload_url_response.get_result('upload_url')
        end

        # Create the POST data that gets sent in the request
        post_data = {}
        post_data[:create_upload_url] = 'true' # have the API also create the next upload url
        post_data[:file] = Faraday::UploadIO.new(options[:source_file_local_path], options[:mime_type])

        # Build the request to the API
        conn = Faraday.new() do |req|
          # https://github.com/lostisland/faraday
          req.headers['User-Agent'] = @@user_agent
          req.headers['Authorization'] = 'Bearer ' + @access_token
          req.request :multipart
          req.adapter :net_http
        end

        # Kick it off!
        api_response = conn.post upload_url, post_data

        # Woot! Convert the response to our model and see what's up
        response = APIResponse.new(api_response)

        # an upload response also contains a new upload url. Save it for the next upload.
        set_prefetched_upload_url(options[:destination_folder_url], 
                                  options[:app_id], 
                                  options[:obj_id],
                                  response.get_result('upload_url'))

        # Rettempt the upload a max of two times if there was a server error
        # Otherwise return the response data
        if not response.is_server_error or i > 2
          return response
        end
        i += 1
      end while i <= 3
      
    end


    ##
    # This method should not be called directly, but is used by the upload method
    # to get the options all ready to go and validated before uploading a file(s).
    # @!visibility private
    def prepare_upload(options={})
      # Validate we've got a source file
      source_file_local_path = options[:source_file_local_path]
      if source_file_local_path == nil
        raise ArgumentError, 'source_file_local_path required'
      end

      # Validate we've got a destination folder to upload to
      destination_folder_url = options[:destination_folder_url]
      app_id = options[:app_id]
      obj_id = options[:obj_id]
      if destination_folder_url == nil and (app_id == nil or obj_id == nil)
        raise ArgumentError, 'destination_folder_url or app_id/obj_id required'
      end      

      # Ideally it'd be awesome to already set what the mime type is, but getting that
      # info accurately is a pain. If you do not send in the mime_type we will 
      # figure it out for you by the file extension (so ALWAYS have an extension)
      # This will only work when using the source_file option, and will not 
      # work with the source_files or source_folder option.
      if options[:mime_type] == nil
        options[:mime_type] = 'application/octet-stream'
      end

      options
    end


    ##
    # This method should not be called directly, but is used to check if we
    # already have an upload url ready to go for the folder we're uploading to.
    # @!visibility private
    def get_prefetched_upload_url(destination_url, app_id, obj_id)
      # Build a unique key for the folder which was used to save an new upload url
      key = destination_url || ''
      key += app_id || ''
      key += obj_id || ''
      rtn_url = @prefetched_upload_urls[key]
      @prefetched_upload_urls[key] = nil
      return rtn_url
    end


    ##
    # This method should not be called directly, but is used to remember an upload url 
    # for the next upload to this folder.
    # @!visibility private
    def set_prefetched_upload_url(destination_url, app_id, obj_id, upload_url)
      # Build a unique key for the folder to save an new upload url value to
      key = destination_url || ''
      key += app_id || ''
      key += obj_id || ''
      @prefetched_upload_urls[key] = upload_url
    end


    ##
    # An upload url must be optained first before uploading a file. After the first
    # upload url is received, all upload responses contain another upload which can be
    # used to eliminate the need to do seperate requests for an upload url.
    # @!visibility private
    def get_upload_url(options={})
      destination_folder_url = options[:destination_folder_url]

      path = nil
      if destination_folder_url != nil
        path = '/v1/' + destination_folder_url + '/upload'
      else
        path = generate_obj_path(options) + '/upload'
      end

      i = 1
      begin
        response = self.fetch(:path => path)
        if not response.is_server_error or i > 2
          return response
        end
        i += 1
      end while i <= 3
    end


    ##
    # This method should not be called directly, but is used to build the api
    # path common needed by a few methods.
    # @!visibility private
    def generate_obj_path(options={})
      app_id = options[:app_id]
      obj_id = options[:obj_id]
      uri = options[:uri] || options[:url]
      path = nil

      # An object's path can either be made up of an app_id and an obj_id
      # Or it can be made up of the entire URI
      if app_id != nil and obj_id != nil
        path = 'apps/' + app_id + '/objects/' + obj_id
      elsif uri != nil
        path = uri
      end

      if path == nil
        raise ArgumentError, "missing url or both app_id and obj_id"
      end

      return '/v1/' + path
    end


    ##
    # This method should not be called directly, but is used to validate data
    # and make it all pretty before firing off the request to the API.
    # @!visibility private
    def prepare(options={})
      if options[:path] == nil
        raise ArgumentError, 'missing api path'
      end

      options[:response_format] = options[:response_format] || @response_format

      headers = { 'User-Agent' => @@user_agent }

      # There are three possible response content-types: JSON, XML
      # Default Content-Type is application/json with a .json extension
      if options[:response_format] == 'application/xml'
        headers['Content-Type'] = 'application/xml'
        response_extension = 'xml'
      else
        options[:response_format] = 'application/json'
        headers['Content-Type'] = 'application/json'
        response_extension = 'json'       
      end
      options[:headers] = headers

      options[:uri] = @@api_host + options[:path] + '.' + response_extension
      options[:url] = options[:uri]
      options[:method] = options[:method] || 'GET'

      return options
    end


    ##
    # Guts of an authorized request. Do not call this directly.
    # @!visibility private
    def fetch(options={})
      # Prepare the data to be shipped in the request
      options = self.prepare(options)

      begin
        # Send the request and get the response
        response = @client.fetch_protected_resource(options)

        # Return the API response
        return APIResponse.new(response)
      rescue Signet::AuthorizationError => detail
        return APIResponse.new(detail.response)
      end

    end


    def client_id
      @client_id
    end

    def client_secret
      @client_secret
    end

    def scope
      @scope
    end

    def state
      @state
    end

    def code
      @code
    end

    def redirect_uri
      @redirect_uri
    end

    def access_token
      @access_token
    end

    def response_format
      @response_format
    end

  end

end

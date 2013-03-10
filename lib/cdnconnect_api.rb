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

    
    def initialize(options)
      # Normalize key to String to allow indifferent access.
      options = options.inject({}) { |accu, (k, v)| accu[k.to_s] = v; accu }
      
      # Initialize all of the options
      @client_id = options["client_id"]
      @client_secret = options["client_secret"]
      @scope = options["scope"]
      @state = options["state"]
      @code = options["code"]
      @redirect_uri = options["redirect_uri"]
      @access_token = options["access_token"]
      @response_format = options["response_format"] || 'application/json'
      @prefetched_upload_url = nil
      
      # Create the OAuth2 client which will be used to authorize the requests
      @client = Signet::OAuth2::Client.new(:client_id => @client_id,
                                           :client_secret => @client_secret,
                                           :scope => @scope,
                                           :state => @state,
                                           :code => @code,
                                           :redirect_uri => @redirect_uri,
                                           :access_token => @access_token)
    end


    def get(options)
      options[:path] = self.generate_obj_path(options)
      return self.fetch(options)
    end


    def prepare_upload(options)
      source_file = options[:source_file]
      if source_file == nil
        raise ArgumentError, 'missing source_file'
      end

      mime_type = options[:mime_type]
      if mime_type == nil
        raise ArgumentError, 'missing mime_type'
      end
    end


    def upload(options)
      # Make sure we've got good data before starting the upload
      prepare_upload(options)

      i = 1
      begin

        upload_url = @prefetched_upload_url
        if upload_url != nil
          # If we already have an upload url created, then there's no need to get another.
          # Reset prefetched_upload_url and use this variable to store the next upload url
          # which will come with the response of the last upload.
          @prefetched_upload_url = nil
        else
          # We do not already have an upload url created. The very first upload
          # will need to make a request for an upload url. After the first upload
          # each upload response will also include a new upload url which can be used.
          upload_url_response = self.get_upload_url(options)
          if upload_url_response.is_error
            return upload_url_response
          end
          upload_url = upload_url_response.get_result('upload_url')
        end

        # Create the POST data that gets sent in the request
        post_data = {}
        post_data[:create_upload_url] = 'true'
        post_data[:file] = Faraday::UploadIO.new(options[:source_file], options[:mime_type])

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

        # Rettempt the upload a max of two times if there was a server error
        # Otherwise return the response data
        if not response.is_server_error or i > 2
          @prefetched_upload_url = response.get_result('upload_url')
          return response
        end
        i += 1
      end while i <= 3
    end


    def get_upload_url(options)
      path = generate_obj_path(options) + '/upload'
      i = 1
      begin
        response = self.fetch(:path => path)
        if not response.is_server_error or i > 2
          return response
        end
        i += 1
      end while i <= 3
    end


    def generate_obj_path(options)
      app_id = options[:app_id]
      obj_id = options[:obj_id]
      uri = options[:uri]
      path = nil

      # An object's path can either be made up of an app_id and an obj_id
      # Or it can be made up of the entire URI
      if app_id != nil and obj_id != nil
        path = 'apps/' + app_id + '/objects/' + obj_id
      elsif uri != nil
        path = uri
      end

      if path == nil
        raise ArgumentError, "missing uri or both app_id and obj_id"
      end

      return '/v1/' + path
    end


    def prepare(options)
      if options[:path] == nil
        raise ArgumentError, 'missing api path'
      end

      options[:response_format] = options[:response_format] || @response_format

      headers = { 'User-Agent' => @@user_agent }

      # There are three possible response content-types: JSON, XML, HTML
      # Default Content-Type is application/json with a .json extension
      if options[:response_format] == 'application/xml'
        headers['Content-Type'] = 'application/xml'
        response_extension = 'xml'
      elsif options[:response_format] == 'text/html'
        headers['Content-Type'] = 'text/html'
        response_extension = 'html'
      else
        options[:response_format] = 'application/json'
        headers['Content-Type'] = 'application/json'
        response_extension = 'json'          
      end
      options[:headers] = headers

      options[:uri] = @@api_host + options[:path] + '.' + response_extension
      options[:method] = options[:method] || 'GET'

      return options
    end


    def fetch(options)
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
      return @client_id
    end

    def client_secret
      return @client_secret
    end

    def scope
      return @scope
    end

    def state
      return @state
    end

    def code
      return @code
    end

    def redirect_uri
      return @redirect_uri
    end

    def access_token
      return @access_token
    end

    def response_format
      return @response_format
    end

  end

end

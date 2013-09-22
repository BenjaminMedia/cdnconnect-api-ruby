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
require 'logger'


module CDNConnect

  ##
  # Used to easily interact with CDN Connect API.
  class APIClient
  
    @@application_name = 'cdnconnect-api-ruby'
    @@application_version = '0.3.0'
    @@user_agent = @@application_name + ' v' + @@application_version
    @@api_host = 'https://api.cdnconnect.com'
    @@api_version = 'v1'

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
    #   - <code>:client_id</code> -
    #     A unique identifier issued to the client to identify itself to CDN Connect's
    #     authorization server. This is issued by CDN Connect to external clients.
    #     This is only needed if an API Key isn't already known. 
    #   - <code>:client_secret</code> -
    #     A secret issued by the CDN Connect's authorization server,
    #     which is used to authenticate the client. Do not confuse this is an access_token
    #     or an api_key. This is only required if an API Key
    #     isn't already known. A client secret should not be shared.
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
    #     access_token and api_key options are interchangeable.
    #   - <code>:api_key</code> -
    #     The current access token for this client, also known as the access token. 
    #     access_token and api_key options are interchangeable.
    #   - <code>:app_host</code> -
    #     The CDN Connect App host. For example, demo.cdnconnect.com is a CDN Connect
    #     app host. The app host should not include https://, http:// or a URL path.
    #   - <code>:log_device</code> -
    #     Ruby Logger logdev argument in Logger.new(logdev). Defaults to STDOUT.
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
        @app_host = options["app_host"]
        @@api_host = options["api_host"] || @@api_host
        @prefetched_upload_urls = {}
        @upload_queue = {}
        @failed_uploads = []

        log_device = options["log_device"] || STDOUT
        @logger = Logger.new(log_device, 10, 1024000)
        @logger.sev_threshold = options["log_sev_threshold"] || Logger::WARN

        if options["api_key"] != nil and options["app_host"] == nil
            err_msg = 'app_host option required when using api_key option'
            @logger.error(err_msg)
            raise ArgumentError, err_msg
        end

        @logger.debug("#{@@user_agent}, #{@@api_host}")

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
    # Upload a file or multiple files from a local machine to a folder within 
    # a CDN Connect app. The upload method provides numerous ways to upload files or files, 
    # to include recursively drilling down through local folders and uploading only files 
    # that match your chosen extensions. If any of the folders within the upload path do not 
    # already exist then they will be created automatically.
    #
    # @param [Hash] options
    #   The configuration parameters for the client.
    #   - <code>:destination_path</code> -
    #     The path of the CDN Connect folder to upload to. If the destination folder does
    #     not already exist it will automatically be created.
    #   - <code>:source_file_path</code> -
    #     A string of a source file's local path to upload to the destination folder. 
    #     If you have more than one file to upload it'd be better to use 
    #     `source_file_paths` or `source_folder_path` instead.
    #   - <code>:source_file_paths</code> -
    #     A list of a source file's local paths to upload. This option uploads all of 
    #     the files to the destination folder. If you want to upload files in a 
    #     local folder then `source_folder_path` option may would be easier 
    #     than listing out files manually.
    #   - <code>:source_folder_path</code> -
    #     A string of a source folder's local path to upload. This will upload all of the
    #     files in this source folder to the destination url. By using the `valid_extensions`
    #     parameter you can also restrict which files should be uploaded according to extension.
    #   - <code>:valid_extensions</code> -
    #     An array of valid extensions which should be uploaded. This is only applied when the
    #     `source_folder_path` options is used. If nothing is provided, which is the
    #     default, all files within the folder are uploaded. The extensions should be in all 
    #     lower case, and they should not contain a period or asterisks.
    #     Example `valid_extensions` array => ['js', 'css', 'jpg', jpeg', 'png', 'gif', 'webp']
    #   - <code>:recursive_local_folders</code> -
    #     A true or false value indicating if this call should recursively upload all of the 
    #     local folder's sub-folders, and their sub-folders, etc. This option is only used
    #     when the `source_folder_path` option is used. Default is true.
    #   - <code>:destination_file_name</code> -
    #     The name which the uploaded file should be renamed to. By default the file name
    #     will be the same as the file being uploaded. The `destination_file_name` option is
    #     only used for a single file upload, it does not work for multiple file requests.
    #   - <code>queue_processing/code> -
    #     A true or false value indicating if the processing of the data should be queued or 
    #     processed immediately. A response with "queued_processing" 
    #     will be faster because the resposne doesn't wait on the system to complete 
    #     processing the data. However, because an queued processing response does not wait 
    #     for the data to complete processing then the response will not contain any information 
    #     about the data which was just uploaded. Use queued processing only if you do not 
    #     need to know the details of the upload. Additionally you can use the `webhook_url` 
    #     to post back the uploads details once it's processed. Default is false.
    #   - <code>:webhook_url</code> -
    #     A URL which the system should `POST` the response to. This works for both immediate 
    #     processing or queued processing calls. The data sent to the `webhook_url` will be 
    #     the same as the data that is responded in a synchronous response, and is sent 
    #     within the `data` parameter. The format sent can be in either `json` or `xml` by 
    #     using the `webhook_format` parameter. By default there is no webhook URL.
    #   - <code>:webhook_format</code> -
    #     When a `webhook_url` is provided, you can have the data formatted as either `json`
    #     or `xml`. The defautl format is `json`.
    #
    # @return [APIResponse] A response object with helper methods to read the response.
    def upload(options={})
        # Make sure we've got good source data before starting the upload
        prepare_upload(options)

        # Place all of the source files in an upload queue for each destination folder.
        # Up to 25 files can be sent in one POST request. As uploads are successful
        # the files will be removed from the queue and uploading will stop when
        # each directory's upload queue is empty.
        build_upload_queue(options)
        
        # The returning response object. Its empty to start with then as 
        # uploads complete it fills this up with each upload's response info
        api_response = CDNConnect::APIResponse.new()
        
        # If there are files in the upload_queue then start the upload process
        while @upload_queue.length > 0
            
            # Get the destination_path in the list of upload queues
            destination_path = @upload_queue.keys[0]
            @logger.debug("destination_path: #{destination_path}")
      
            # Check if we have a prefetched upload url before requesting a new one
            upload_url = get_prefetched_upload_url(destination_path)
            if upload_url == nil
                # We do not already have an upload url created. The first upload request
                # will need to make a request for an upload url. After the first upload
                # each upload response will also include a new upload url which can be used 
                # for the next upload when uploading to the same folder.
                upload_url_response = self.get_upload_url(destination_path)
                if upload_url_response.is_error
                    return upload_url_response
                end
                upload_url = upload_url_response.get_result('upload_url')
                @logger.debug("Received new upload url")
            else
                @logger.debug("Use prefetched upload url")
            end

            # Build the data that gets sent in the POST request
            post_data = build_post_data(:destination_path => destination_path,
                                        :destination_file_name => options[:destination_file_name],
                                        :queue_processing => options.fetch(:queue_processing, true),
                                        :webhook_url => options[:webhook_url],
                                        :webhook_format => options[:webhook_format])

            # Build the request to send to the API
            # Uses the Faraday: https://github.com/lostisland/faraday
            conn = Faraday.new() do |req|
              req.headers = {
                'User-Agent' => @@user_agent
              }
              req.request :multipart
              req.adapter :net_http
            end

            # Kick off the request!
            http_response = conn.post upload_url, post_data

            # w00t! Convert the http response into APIResponse and see what's up
            upload_response = APIResponse.new(http_response)
            for msg in upload_response.msgs
                @logger.info("Upload " + msg["status"] + ": " + msg["text"])
            end

            # merge the two together so we build one awesome response
            # object with everything you need to know about every upload
            api_response.merge(upload_response)
            
            # Read the response and see what we got
            if upload_response.is_server_error
                # There was a server error, empty the active upload queue
                failed_upload_attempt(destination_path)
                @logger.error(upload_response.body)

                # put the upload url back in the list
                # of prefetched urls so it can be reused
                set_prefetched_upload_url(destination_path, upload_url)
            else
                # successful upload, clear out the active upload queue
                # and remove uploaded files from the upload queue
                successful_upload_attempt(destination_path)
                
                @logger.info("Successful upload")

                # an upload response also contains a new upload url. 
                # Save it for the next upload to the same destination.
                set_prefetched_upload_url(destination_path,
                                          upload_response.get_result('upload_url'))
            end
      
        end 
        
        return api_response
    end
    
    
    ##
    # Build the POST data that gets sent in the request
    # @!visibility private
    def build_post_data(options)
        # @active_uploads will hold all of the upload keys  
        # which are actively being uploaded.
        @active_uploads = []

        # set defaults
        max_files_per_request = options[:max_files_per_request] || 25
        max_request_size = options[:max_request_size] || 25165824
        
        # post_data will contain all of the data that gets sent
        post_data = {}
        
        # have the API also create the next upload url
        post_data[:create_upload_url] = 'true'
        
        # the set what the file name will be. By default it will be named the same as
        # the uploaded file. This will only work for single file uploads.
        post_data[:destination_file_name] = options[:destination_file_name]

        # Processing of the data can be queued. However, an `queue_processing` response
        # will not contain any information about the data uploaded.
        if options[:queue_processing] == true
            post_data[:queue_processing] = 'true'
        end

        # send with the post data the webhook_url if there is one
        if options[:webhook_url] != nil
            post_data[:webhook_url] = options[:webhook_url]
            # send in the webhook_format, but defaults to json if nothing sent
            if options[:webhook_format] != nil
                post_data[:webhook_format] = options[:webhook_format]
            end
        end
        
        # Mime type doesn't matter because it gets figured out on the server-side
        # using the file extension. So be sure file extensions are valid!
        mime_type = 'application/octet-stream'
        
        # the 'file' parameter will hold the actual file data
        post_data[:file] = []
        
        # tally up how large of a request this will be (in bytes)
        total_request_size = 0

        total_files = 0
        
        # Add each source file in the queue to the request as multipart-post data
        @upload_queue[ options[:destination_path] ].each_pair do |source_file_path, value|
        
            # Figure out how large this file is
            file_size = File.stat(source_file_path).size

            @logger.debug(" - #{source_file_path} (#{human_file_size(file_size)})")

            # Add this file's size to the overall request size total
            total_request_size += file_size
        
            # Increment the upload attempts for this file
            @upload_queue[ options[:destination_path] ][source_file_path]['attempts'] += 1
            
            # Set that this file is actively being uploaded
            @upload_queue[ options[:destination_path] ][source_file_path]['active'] = true
        
            # Add the source file it to the request's post data
            post_data[:file].push( Faraday::UploadIO.new(source_file_path, mime_type) )
            
            total_files = post_data[:file].length

            if total_request_size > max_request_size
                # If the total request size is larger than the max
                # then do not add any more files
                @logger.debug(" - Reached max request size per request")
                break
            elsif total_files >= max_files_per_request
                # only add XX files per post request
                # any left over will be picked up in the next upload
                @logger.debug(" - Reached max files per request")
                break
            end
        end
        
        @logger.info(" - Upload, File Count: #{total_files}, File Size: #{human_file_size(total_request_size)}")

        return post_data
    end
    
    
    ##
    # Upload was successful, clear it out from the upload queue.
    # @!visibility private
    def successful_upload_attempt(destination_path)
        # Loop through each active upload for the destination folder url
        if @upload_queue.has_key?(destination_path)
            # Loop through each file for this destination folder
            @upload_queue[destination_path].each_pair do |source_file_path, value|
                # If the file was actively being uploaded then remove it
                if @upload_queue[destination_path][source_file_path]['active']
                    remove_source_from_queue(destination_path, source_file_path)
                end
            end        
        end
    end
    
    
    ##
    # Upload failed, clear it out from the active upload queue.
    # If it was attempted too many times then remove it from the queue.
    # @!visibility private
    def failed_upload_attempt(destination_path)
        @logger.error("failed_upload_attempt: #{destination_path}")

        # Loop through each active upload for the destination folder url
        if @upload_queue.has_key?(destination_path)
            # Loop through each file for this destination folder
            @upload_queue[destination_path].each_pair do |source_file_path, value|
                # If the file was actively being uploaded then reset it to false
                if @upload_queue[destination_path][source_file_path]['active']
                    @upload_queue[destination_path][source_file_path]['active'] = false
                    # If it was attempted too many times, then remove it
                    if @upload_queue[destination_path][source_file_path]['attempts'] >= 3
                        @failed_uploads.push(source_file_path)
                        remove_source_from_queue(destination_path, source_file_path)
                    end
                end
            end        
        end
    end
    
    
    ##
    # Add source files to an upload queue for each destination folder.
    # Up to 25 files can be sent in one POST request. As uploads are successful
    # the files will be removed from the queue and uploading will stop when
    # each directory's upload queue is empty.
    # @!visibility private
    def build_upload_queue(options)
    
      if options[:source_folder_path] != nil
        # Queue from all of the files in a folder
        build_upload_queue_from_folder(options[:destination_path], 
                                       options[:source_folder_path], 
                                       options[:valid_extensions], 
                                       options.fetch(:recursive_local_folders, true))
        
      elsif options[:source_file_paths] != nil
        # Queue from all of the files in an array
        for source_file_path in options[:source_file_paths]
            add_source_to_upload_queue(options[:destination_path],
                                       source_file_path)
        end
        
      elsif options[:source_file_path] != nil
        # Queue from just one path
        add_source_to_upload_queue(options[:destination_path],
                                   options[:source_file_path])
                                   
      end
    
    end
    
    
    ##
    # Add files to the destination folder's upload queue by going through the given 
    # local folder. By default all files will be added, but with the regex you can
    # narrow down which files within the folder should be uploaded.
    # @!visibility private
    def build_upload_queue_from_folder(destination_path, source_folder_path, valid_extensions, recursive_local_folders)
        # Queue from all of the files in a folder

        Dir.foreach(source_folder_path) do |name|
            # Ignore certain names and don't bother uploading them
            next if name == '.' or name == '..' or name == '.DS_Store' or name == 'Thumbs.db'

            # Build the full local path for the item
            full_local_path = source_folder_path + '/' + name
            
            if File.file?(full_local_path)
                # This item is a file
                                
                # Get this file's extension
                file_extension = File.extname(full_local_path)
                
                # only upload if it has a file extension (required by cdn connect)
                if file_extension != nil and file_extension != ''
                    # normalize the extension, lower case and remove the dot
                    file_extension = file_extension.downcase
                    file_extension.slice! "."
                    
                    if valid_extensions == nil or valid_extensions.include? file_extension
                        add_source_to_upload_queue(destination_path, full_local_path)
                    end 
                    
                end          
                
            elsif recursive_local_folders and File.directory?(full_local_path)
                # This item is a folder and we want to recursively drill down through it
                destination_sub_folder_url = destination_path + '/' + name
                build_upload_queue_from_folder(destination_sub_folder_url, full_local_path, valid_extensions, recursive_local_folders)
                
            end
            
        end
    end
    

    ##
    # Add a source file to the upload queue for its destination folder.
    # @!visibility private
    def add_source_to_upload_queue(destination_path, source_file_path)
        # Build a unique key for the destination folder for the @upload_queue. 
        # Each destination folder holds its own list of files to upload.
        if not @upload_queue.has_key?(destination_path)
            # Create an array for this destination to hold all of its uploads
            @upload_queue[destination_path] = {}
        end

        # Check if this source file has already been added for this destination
        if @upload_queue[destination_path].has_key?(source_file_path)
            # This upload already exists for this destination, don't add it again
            return
        end
        
        # add to this local path to this destination's upload queue
        # Its valud is the number of times its been attempted to upload
        @upload_queue[destination_path][source_file_path] = { 'attempts' => 0, 'active' => false }
    end
    
    
    ##
    # Remove a source file from the destination folders upload queue
    # @!visibility private
    def remove_source_from_queue(destination_path, source_file_path)
        if @upload_queue.has_key?(destination_path)
            if @upload_queue[destination_path].has_key?(source_file_path)
                # remove from the upload_queue
                @upload_queue[destination_path].delete(source_file_path)
            end
            if @upload_queue[destination_path].length == 0
                @upload_queue.delete(destination_path)
            end
        end
    end
    

    ##
    # This method should not be called directly, but is used by the upload method
    # to get the options all ready to go and validated before uploading a file(s).
    # @!visibility private
    def prepare_upload(options={})

      # Check if we've got valid source files
      if options[:source_folder_path] != nil
        # Check that the source folder exists
        if not File.directory?(options[:source_folder_path])
            raise ArgumentError, 'source_folder_path "' + options[:source_folder_path] + '" is not a valid directory'
        end
        
      elsif options[:source_file_paths] != nil
        # Check that source_file_paths is an array
        if not options[:source_file_paths].kind_of?(Array)
            raise ArgumentError, 'source_file_paths must be an array of strings'
        end
        # Check that each source file in the array exists
        for source_file_path in options[:source_file_paths]
            if not File.file?(source_file_path)
                raise ArgumentError, 'source_file_path "' + source_file_path + '" is not a valid file'
            end
        end
        
      elsif options[:source_file_path] != nil
        # Check that the single file exists
        if not File.file?(options[:source_file_path])
            raise ArgumentError, 'source_file_path "' + options[:source_file_path] + '" is not a valid file'
        end
        
      else
        # Did not pass in any of the valid options for source files, raise error
        raise ArgumentError, 'source file(s) required'
        
      end

      # Validate we've got a destination folder to upload to
      destination_path = options[:destination_path]
      if destination_path == nil 
        raise ArgumentError, 'destination_path required'
      end      

      return options
    end
    

    ##
    # This method should not be called directly, but is used to check if we
    # already have an upload url ready to go for the folder we're uploading to.
    # @!visibility private
    def get_prefetched_upload_url(destination_path)
        # Build a unique key for the folder which was used to save an new upload url
        rtn_url = @prefetched_upload_urls[destination_path]
        @prefetched_upload_urls[destination_path] = nil
        return rtn_url
    end


    ##
    # This method should not be called directly, but is used to remember an upload url 
    # for the next upload to this folder.
    # @!visibility private
    def set_prefetched_upload_url(destination_path, upload_url)
        # Build a unique key for the folder to save an new upload url value to
        @prefetched_upload_urls[destination_path] = upload_url
    end


    ##
    # An upload url must be optained first before uploading a file. After the first
    # upload url is received, all upload responses contain another upload which can be
    # used to eliminate the need to do seperate requests for an upload url.
    # @!visibility private
    def get_upload_url(destination_path)
        if destination_path == "/"
            destination_path = ""
        end
        upload_id = Random.new.rand(1_000_000..9_999_999)
        api_path = "#{destination_path}/upload-#{upload_id}.json"

        @logger.debug("get_upload_url: #{api_path}")

        i = 1
        begin
            response = get(api_path)
            if not response.is_server_error
                return response
            elsif i > 2
                @logger.error("Too many get_upload_url attempts")
                return response
            end
            @logger.error(response.body)
            i += 1
        end while i <= 3
    end

    
    ##
    # Get object info, which can be either a file or folder.
    #
    # @param [Hash] options
    #   - <code>:path</code> -
    #     The path to the CDN Connect object to get. (required)
    #   - <code>:files</code> -
    #     True or false value indicating if a folder's response should contain
    #     its sub-files or not. Default is false.
    #   - <code>:folders</code> -
    #     True or false value indicating if a folder's response should contain
    #     its sub-folders or not. Default is false.
    # @return [APIResponse] A response object with helper methods to read the response.
    def get_object(options={})
        api_path = options[:path] + '.json'
        data = {}
        if options[:files] == true
            data[:files] = true
        end
        if options[:folders] == true
            data[:folders] = true
        end
        get(api_path, data)
    end

    
    ##
    # Rename object, which can be either a file or folder.
    #
    # @param [Hash] options
    #   - <code>:path</code> -
    #     The path to the CDN Connect object to get. (required)
    #   - <code>:new_name</code> -
    #     The new filename or folder name for the object. (required)
    # @return [APIResponse] A response object with helper methods to read the response.
    def rename_object(options={})
        api_path = options[:path] + '/rename.json'
        data = { :new_name => options[:new_name] }
        put(api_path, data)
    end

    
    ##
    # Delete object info, which can be either a file or folder.
    #
    # @param [Hash] options
    #   - <code>:path</code> -
    #     The path to the CDN Connect object to delete. (required)
    # @return [APIResponse] A response object with helper methods to read the response.
    def delete_object(options={})
        api_path = options[:path] + '.json'
        delete(api_path)
    end

    
    ##
    # Create a folder path. If any of the folders within the given path do not
    # already exist they will be created.
    #
    # @return [APIResponse] A response object with helper methods to read the response.
    def create_path(options={})
        api_path = options[:path] + '/create-path.json'
        get(api_path)
    end
    

    ##
    # Executes a GET request to an API URL and returns a response object.
    # GET requests are used when reading data.
    #
    # @param api_path [String] The API path to send the GET request to.
    # @param data [Hash] Data which will be placed in the GET request's querystring. (Optional)
    # @return [APIResponse] A response object with helper methods to read the response.
    def get(api_path, data={})
        fetch(:api_path => api_path, :method => 'GET', :data => data)
    end


    ##
    # Executes a POST request to an API URL and returns a response object. 
    # POST requests are used when creating data.
    #
    # @param api_path [String] The API path to send the POST request to.
    # @param data [Hash] Data which will be sent in the POST request.
    # @return [APIResponse] A response object with helper methods to read the response.
    def post(api_path, data)
        fetch(:api_path => api_path, :method => 'POST', :data => data)
    end


    ##
    # Executes a PUT request to an API URL and returns a response object.
    # PUT requests are used when updating data.
    #
    # @param api_path [String] The API path to send the PUT request to.
    # @param data [Hash] Data which will be sent in the PUT request.
    # @return [APIResponse] A response object with helper methods to read the response.
    def put(api_path, data)
        fetch(:api_path => api_path, :method => 'PUT', :data => data)
    end


    ##
    # Executes a DELETE request to an API URL and returns a response object.
    # DELETE requests are used when (you guessed it) deleting data.
    #
    # @param api_path [String] The API path to send the DELETE request to.
    # @return [APIResponse] A response object with helper methods to read the response.
    def delete(api_path)
        fetch(:api_path => api_path, :method => 'DELETE')
    end
    

    ##
    # This method should not be called directly, but is used to validate data
    # and make it all pretty before firing off the request to the API.
    # @!visibility private
    def prepare(options={})
        if options[:api_path] == nil
            raise ArgumentError, 'missing api path'
        end

        options[:headers] = { 'User-Agent' => @@user_agent }
        options[:uri] = "#{@@api_host}/#{@@api_version}/#{@app_host}#{options[:api_path]}"

        options[:method] = options[:method] || 'GET'

        if options[:method] == 'GET' and options[:data] != nil and options[:data].length > 0
            require "addressable/uri"
            uri = Addressable::URI.new
            uri.query_values = options[:data]
            options[:uri] = "#{options[:uri]}?#{uri.query}"
            options[:data] = nil
        end

        options[:url] = options[:uri]

        options
    end


    ##
    # Guts of an authorized request. Do not call this directly.
    # @!visibility private
    def fetch(options={})
        # Prepare the data to be shipped in the request
        options = prepare(options)

        @logger.debug(options[:method] + ': ' + options[:uri])

        begin
            # Send the request and get the response
            options[:body] = options[:data]
            http_response = @client.fetch_protected_resource(options)

            # Return the API response
            api_response = APIResponse.new(http_response)

            for msg in api_response.msgs
                @logger.debug(msg["status"] + ": " + msg["text"])
            end

            return api_response
        rescue Signet::AuthorizationError => authorization_error
            # whoopsy doodle. Probably an incorrect API Key or App Host. 
            # Validate your authorization info.
            @logger.error(authorization_error)
            return APIResponse.new(authorization_error.response)
        end
    end


    ##
    # OAuth2 parameter. A unique identifier issued to the client to identify itself to CDN Connect's
    # authorization server. This is issued by CDN Connect to external clients.
    # This is only needed if an API Key isn't already known. 
    #
    # @return [String]
    def client_id
        @client_id
    end


    ##
    # OAuth2 parameter. A secret issued by the CDN Connect's authorization server,
    # which is used to authenticate the client. Do not confuse this is an access_token
    # or an api_key. This is only required if an API Key
    # isn't already known. A client secret should not be shared.
    #
    # @return [String]
    def client_secret
        @client_secret
    end


    ##
    # OAuth2 parameter. The scope of the access request, expressed either as an Array
    # or as a space-delimited String. This is only required if an API Key
    # isn't already known. 
    #
    # @return [String]
    def scope
        @scope
    end


    ##
    # OAuth2 parameter. An unguessable random string designed to allow the client to maintain state
    # to protect against cross-site request forgery attacks. 
    # This is only required if an API Key isn't already known. 
    #
    # @return [String]
    def state
        @state
    end


    ##
    # OAuth2 value. The authorization code received from the authorization server.
    # @return [String]
    def code
        @code
    end


    ##
    # OAuth2 value. The redirection URI used in the initial request.
    # @return [String]
    def redirect_uri
        @redirect_uri
    end


    ##
    # OAuth2 value. An API Key (commonly known as an access_token) which was previously 
    # created within CDN Connect's account for a specific app.
    #
    # @return [String]
    def access_token
        @access_token
    end


    ##
    # The CDN Connect App host. For example, demo.cdnconnect.com is a CDN Connect app host.
    # The app host value should not include https://, http:// or a URL path.
    #
    # @return [String]
    def app_host
        @app_host
    end


    ##
    # The current files queued to be uploaded.
    #
    # @return [Hash]
    # @!visibility private
    def upload_queue
        @upload_queue
    end

    ##
    # An array of files which failed.
    #
    # @return [Array]
    def failed_uploads
        @failed_uploads
    end

    def human_file_size(bytes)
        units = %w{B KB MB GB TB}
        e = (Math.log(bytes)/Math.log(1024)).floor
        s = "%.2f" % (bytes.to_f / 1024**e)
        s.sub(/\.?0*$/, units[e])
    end

  end

end

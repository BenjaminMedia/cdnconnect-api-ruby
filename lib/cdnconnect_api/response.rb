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

require 'json'

module CDNConnect

  ##
  # Used to simpilfy things with helper functions to read response 
  # data. Responses from the API are all structured the same way, and
  # this class is used as a wrapper to make it easier to read 
  # resposne data.
  class APIResponse

    def initialize(http_response=nil)
      @http_response = http_response
      if http_response != nil
        @status = http_response.status
        @data = nil
      else
        @status = 0
        @data = {"results" => {}, "msgs" => []}
      end
      return self
    end

    
    ##
    # A list of all the files that were uploaded. Each file in the array is a hash.
    #
    # @return [array] An array of hashes each representing a CDN Connect object.
    def files
      return get_result('files')
    end

    
    ##
    # Can be either a file or folder object, or the first file in the files array.
    #
    # @return [hash] A hash representing a CDN Connect object.
    def object
      obj = get_result('object')
      if obj != nil
        return obj
      end
      fs = files
      if fs != nil and fs.length > 0
        return fs[0]
      end
      nil
    end
    

    ##
    # Content body of the http response. This will be read by the
    # data method so the body can be parsed into a hash.
    #
    # @return [String]
    def body
      if @http_response != nil 
        return @http_response.body
      end
      nil
    end


    ## 
    # Decode the response body from JSON into a hash.
    # Store the parsed data in an instance variable (@data) so we 
    # don't keep parsing it every time we reference data.
    #
    # @return [Hash]
    def data
      if @data == nil and body != nil
        begin
          @data = JSON.parse(body)
        rescue
        end
      end
      @data
    end


    ##
    # Helper method to read the results hash.
    #
    # @return [Hash]
    def results
      d = data
      if d != nil and d.has_key?('results')
        return d['results']
      end
      nil
    end


    ##
    # A helper method to read a key within the results.
    def get_result(key)
      r = results
      if r != nil
        return r.fetch(key, nil)
      end
      nil
    end


    ##
    # An array of messages, and each message is a hash.
    # Example message within the msgs array: 
    # "text" => "info about the message", "status" => "error"
    #
    # @return [array] A response object with helper methods to read the response.
    def msgs
      d = data
      if d != nil
        return d.fetch('msgs', [])
      end
      return []
    end
    

    ##
    # @return [bool] A boolean indicating if this response has messages or not.
    def has_msgs
      msgs and msgs.length > 0
    end
    

    ##
    # @return [bool] A boolean indicating if this response has messages or not.
    def has_errors
      if msgs and msgs.length > 0
        for msg in msgs
          if msg["status"] == "error"
            return true
          end
        end
      end
      false
    end


    ##
    # Used to merge two responses into one APIResponse. This is
    # done automatically when uploading numerous files.
    #
    # @return [APIResponse]
    def merge(updating_response)
      if updating_response == nil or updating_response.data == nil
        return self
      end
      
      if updating_response.status > status
        @status = updating_response.status
      end
      
      if data == nil
        @data = updating_response.data
        return self
      end
            
      @data['msgs'] += updating_response.msgs
      
      if updating_response.files != nil
          f = files
          if f != nil
            @data['results']['files'] += updating_response.files
          else
            @data['results']['files'] = updating_response.files
          end
      end
      
      return self
    end


    ##
    # @return [int] The HTTP response status.
    def status
      @status
    end

    ##
    # @return [bool]
    def is_success
      status >= 200 and status < 300 and not has_errors
    end

    ##
    # @return [bool]
    def is_error
      status >= 400 or has_errors
    end

    ##
    # @return [bool]
    def is_client_error
      status >= 400 and status < 500
    end

    ##
    # @return [bool]
    def is_bad_request
      status == 400
    end

    ##
    # @return [bool]
    def is_unauthorized
      status == 401
    end

    ##
    # @return [bool]
    def is_forbidden
      status == 403
    end

    ##
    # @return [bool]
    def is_not_found
      status == 404
    end

    ##
    # @return [bool]
    def is_method_not_allowed
      status == 405
    end

    ##
    # @return [bool]
    def is_server_error
      status >= 500
    end

    ##
    # @return [bool]
    def is_bad_gateway
      status == 502
    end

    ##
    # @return [bool]
    def is_service_unavailable
      status == 503
    end

  end

end
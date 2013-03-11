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

module CDNConnect

  ##
  # Used to simpilfy things by creating easy to use helper functions to read
  # response data. Responses from the API are all structured the same way,
  # and this class is used as a small wrapper to make it easier to get data.
  class APIResponse

    def initialize(response)
      @response = response
      @data = nil
      return self
    end

    def body()
      @response.body
    end

    def data()
      # Convert the response body depending on the response format
      # Keep the parsed data in an instance variable so we 
      # don't keep parsing it every time we reference data()
      if @data == nil
        if format.include? 'application/json'
          @data = ActiveSupport::JSON.decode(body)
        elsif format.include? 'application/xml'
          @data = ActiveSupport::XML.decode(body)
        else
          @data = body
        end
      end
      @data
    end

    def results()
      if format.include? 'text/html'
        return body
      end
      # this is just double checking the results data
      # exists and is built with the correct structure
      d = data
      if d.has_key?('results')
        return d['results']
      end
      nil
    end

    def get_result(key)
      # A handy method so you don't have to do any nil checking
      # as you dig through the response results
      r = results
      if r != nil
        return results[key]
      end
      nil
    end

    def msgs()
      if format.include? 'text/html'
        return body
      end
      # this is just double checking the msgs data
      # exists and is built with the correct structure
      d = data
      if d.has_key?('msgs')
        return d['msgs']
      end
      nil
    end

    def format()
      @response.headers['content-type']
    end

    def status()
      @response.status
    end

    def is_success()
      (status >= 200 and status < 300)
    end

    def is_error()
      (status >= 400)
    end

    def is_bad_request()
      (status == 400)
    end

    def is_unauthorized()
      (status == 401)
    end

    def is_forbidden()
      (status == 403)
    end

    def is_not_found()
      (status == 404)
    end

    def is_method_not_allowed()
      (status == 405)
    end

    def is_server_error()
      (status >= 500)
    end

    def is_bad_gateway()
      (status >= 502)
    end

    def is_service_unavailable()
      (status >= 503)
    end

  end

end
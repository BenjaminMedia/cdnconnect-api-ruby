# CDN Connect API Ruby Client, v0.1.1

CDN Connect makes it easier to manage production assets for teams of developers and designers, all while serving files from a fast content delivery network. Features include image optimization, resizing, cropping, filters, etc. The CDN Connect API Ruby Client makes it easier to upload files and interact with the API. Most interactions with CDN Connect APIs require users to authorize applications via OAuth 2.0. This library simplifies the communication with CDN Connect even further allowing you to easily upload files and get information with only a few lines of code.

[View the full CDN Connect API documentation](http://api.cdnconnect.com/)

## Install

    $ gem install cdnconnect-api

[RubyGems.org: cdnconnect-api](https://rubygems.org/gems/cdnconnect-api)


## API Key

An API Key can be created for a specific app within your CDN Connect's account. Sign into your account and go to the "API Key" tab for the app you want to interact with. Next click "Add API Key" and use this value when creating a new API client within the code. The API Key can be revoked
by you at any time and numerous keys can be created.


## Upload Example

    # Initialize the CDN Connect API client
    require 'cdnconnect_api'
    api_client = CDNConnect::APIClient.new(:api_key => YOUR_API_KEY)
    
    # Upload to a folder in the app the API Key was created for
    response = api_client.upload(:destination_folder_url => 'demo.cdnconnect.com/images', 
                                 :source_file_local_path => 'meowzers.jpg')

    # Read the response
    if response.is_success
      # "Woot!"
    end


## API Requests

Following the [API documentation](http://api.cdnconnect.com/), you can use these methods to  build a requests and return an APIResponse object.

* `get`: GET Request. Used when needing to just read data.
* `post`: POST Request. Used when creating data.
* `put`: PUT Request. Used when updating data.
* `delete`: DELETE Request. Used when deleting data.

Each of these methods take one parameter which is the API path you want to request. Depending on which method you use, it will send the request with the correct HTTP verb.

    response = api_client.get('/v1/demo.cdnconnect.com/images/meowzers.jpg.json')
    puts response.results['data']['name']           #=> "meowzers.jpg"

The path in the API request is broken down as:

* `/v1/` The API version, which must always prefix an API request path.
* `demo.cdnconnect.com/images/meowzers.jpg` The URL which you want to get information about.
* `.json` The response format, which can be `json` or `xml`.


## Response Object

All responses will be structured the same with both a `results` and `msgs` object at the root level, such as:

    {
        "results":
        {
            "data":
            {
                "id": "bU1SS1JyvF9I", 
                "status": 1,
                "name": "images",
                "created": "2013-03-12T17:02Z",
                "parent_id": "iF637hnbwI4G",
                "folder": true, 
                "files": [],
                "folders": []
            }
        },
        "msgs":[]
    }

Be sure to view the [API documentation](http://api.cdnconnect.com/) describing what each response object will contain depending on the API resource.


## Support

Please [report any bugs](https://github.com/cdnconnect/cdnconnect-api-ruby/issues) on this project's issues page. Additionally, please don't hesitate to contact us and/or submit a pull request with any ideas you may have to improve the service. We will continue to improve upon and build out the API in order to bring more value to you and your projects.


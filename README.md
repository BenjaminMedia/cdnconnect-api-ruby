# CDN Connect API Ruby Client, v0.0.1

## Description

The CDN Connect API Ruby Client makes it easier to upload files and interact with
our API. Most interactions with CDN Connect APIs require users to authorize applications via OAuth 2.0. This library simplifies the communication with CDN Connect even further allowing you
to easily upload files and get information with only a few lines of code.

## Install

    $ sudo gem install cdnconnect-api

## API Key

An API Key is can be created for a specific app within your CDN Connect's account. Sign into your account and go to the "API Key" tab for the app you want to interact with. Next click "Add API Key" and use this value when creating a new API client within the code. The API Key can be revoked
by you at any time and numerous keys can be created.

## Example Usage

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

## Get Object Data

An object can be either a file or a folder. Pass the `get` method the `url` you want to receive data about.

    # Get file information
    response = api_client.get(:url => 'demo.cdnconnect.com/images/meowzers.jpg')
    puts response.results['data']['name']           #=> "meowzers.jpg"

    # Get folder information
    response = api_client.get(:url => 'demo.cdnconnect.com/images')
    puts response.results['data']['name']           #=> "images"


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

The `results` object contains the guts of the information your looking for, and the `msgs` object contains an array of messages which can represent errors, warnings and information. The `results` object can be null, or it can contain many objects within it. Each response can have different data within `results` object and `msgs` object. In the case above, the `results` object contains the key `data`, and within the `data` object it contains summary information of the images folder. 

## Support

Please [report any bugs](https://github.com/cdnconnect/cdnconnect-api-ruby/issues) on this project's issues page. Additionally, please don't hesitate to contact us and/or submit a pull request with any ideas you may have to improve the service. We will continue to improve upon and build out the API in order to bring more value to you and your projects.


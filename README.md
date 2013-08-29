# CDN Connect API Ruby Client, v0.2.5

CDN Connect makes it easier to manage production assets for teams of developers and designers, all while serving files from a fast content delivery network. Features include image optimization, resizing, cropping, filters, changing output formats, convert to WebP image format, etc. The CDN Connect API Ruby Client makes it easier to upload files and interact with the API with only a few lines of code.

[View the full CDN Connect API documentation](http://api.cdnconnect.com/)

## Install

    $ gem install cdnconnect-api

[RubyGems.org: cdnconnect-api](https://rubygems.org/gems/cdnconnect-api)


## Setup the API Client

First step is to create an api client instance which will be used to connect to your CDN Connect app. The required options are `app_host` and `api_key`.

#### App Host
The CDN Connect App host includes your app subdomain and the `cdnconnect.com` domain. For example, `demo.cdnconnect.com` is a CDN Connect app host. The app host should not include `https://`, `http://` or a URL path such as `/images`.

#### API Key

Most interactions with CDN Connect APIs require users to authorize applications via OAuth 2.0. An API Key can be created for a specific app within your CDN Connect's account. Sign into your account and go to the "API Key" tab for the app you want to interact with. Next click "Add API Key" and use this value when creating a new API client within the code. The API Key can be revoked by you at any time and numerous keys can be created.


#### Example API Client

    require 'cdnconnect_api'

    api_client = CDNConnect::APIClient.new(:app_host => 'YOUR_APP.cdnconnect.com', 
                                           :api_key => 'YOUR_API_KEY')


## Upload Files

Upload a file or multiple files from a local machine to a folder within a CDN Connect app. The `upload` method provides numerous ways to upload files or files, to include recursively drilling down through local folders and uploading only files that match your chosen extensions. If any of the folders within the upload path do not already exist then they will be created automatically.

Below are the possible parameters for the `upload` method. You must set `destination_path` and use one of the options to select where the source files are uploaded from.

 - `destination_path` : The URL of the CDN Connect folder to upload to. If the destination folder does not already exist it will automatically be created.
 - `source_file_path` : A string of a source file's local path to upload to the destination folder. If you have more than one file to upload it'd be better to use `source_file_paths` or `source_folder_path` instead.
 - `source_file_paths` : A list of a source file's local paths to upload. This option uploads all of the files to the destination folder. If you want to upload files in a local folder then `source_folder_path` option may would be easier than listing out files manually.
 - `source_folder_path` : A string of a source folder's local path to upload. This will upload all of the files in this source folder to the destination url. By using the `valid_extensions` parameter you can also restrict which files should be uploaded according to extension.
 - `valid_extensions` : An array of valid extensions which should be uploaded. This is only applied when the `source_folder_path` options is used. If nothing is provided, which is the default, all files within the folder are uploaded. The extensions should be in all lower case, and they should not contain a period or asterisks. Example `valid_extensions => ['js', 'css', 'jpg', jpeg', 'png', 'gif', 'webp']`
 - `recursive_local_folders` : A true or false value indicating if this call should recursively upload all of the local folder's sub-folders, and their sub-folders, etc. This option is only used when the `source_folder_path` option is used.
 - `destination_file_name` : The name which the uploaded file should be renamed to. By default the file name will be the same as the file being uploaded. The `destination_file_name` option is only used for a single file upload, it does not work for multiple file requests.
 - `queue_processing` : A true or false value indicating if the processing of the data should be queued or processed immediately. A response with "queued_processing" will be faster because the resposne doesn't wait on the system to complete processing the data. However, because an queued processing response does not wait for the data to complete processing then the response will not contain any information about the data which was just uploaded. Use queued processing only if you do not need to know the details of the upload. Additionally you can use the `webhook_url` to post back the uploads details once it's processed. Default is false.
 - `webhook_url` : A URL which the system should `POST` the response to. This works for both immediate processing or queued processing calls. The data sent to the `webhook_url` will be the same as the data that is responded in a synchronous response, and is sent within the `data` parameter. The format sent can be in either `json` or `xml` by using the `webhook_format` parameter. By default there is no webhook URL.
 - `webhook_format` : When a `webhook_url` is provided, you can have the data formatted as either `json` or `xml`. The defautl format is `json`.

### Upload One File: `source_file_path`

Use this option if you simply want to upload just one file. If you have many files to upload we recommend using either `source_file_paths` or `source_folder_path`.

    response = api_client.upload(:destination_path => '/images', 
                                 :source_file_path => '/Users/Ellie/Pictures/meowzers.jpg')
    
### Upload A List Of Files: `source_file_paths`
    
Specify a list of local files that should be uploaded to an app folder. Use this option if you want to manually select which files should be uploaded. Use the `source_folder_path` option if you want to easily upload all of the files
in a folder.
    
    response = api_client.upload(:destination_path => '/images/kitty', 
                                 :source_file_paths => [
                                    '/Users/Ellie/Pictures/furball.jpg',
                                    '/Users/Ellie/Pictures/smuckers.jpg',
                                    '/Users/Ellie/Pictures/socks.jpg'
                                 ])
    
### Upload All Of The Files In The Folder: `source_folder_path`
    
All files within the local `Pictures` folder will be uploaded. Additionally, by default all files within its subfolders will also be uploaded. Refer to the `recursive_local_folders` parameter if you do not want to recursively upload files in subfolders. 
    
    response = api_client.upload(:destination_path => '/images/', 
                                 :source_folder_path => '/Users/Ellie/Pictures/')


## Get File or Folder Information

Both files and folders are considered "objects", and object data contains information stating if it is a file or a folder. A folder can contain many sub-folders, and many files, and a file is contained by a folder. The concept of files and folders is no different than how your computer handles them, and their hierarchy is what builds the URL. Getting information about a file or a folder both use `get_object`.


#### Get File Information

    response = api_client.get_object(:path => '/images/spacewalk.jpg')


#### Get Folder's Basic Information

    response = api_client.get_object(:path => '/images')


#### Get Folder's Sub-Files and Sub-Folders

    response = api_client.get_object(:path => '/images', :files => true, :folders => true)


## Rename File or Folder

Renames a file or folder, which are both also known as an object.

    response = api_client.rename_object(:path => '/images/tv-shows/night-rider.jpeg',
                                        :new_name => 'knight-rider.jpg')


## Create A Folder Path

Creates a folder structure according to the path provided. If any of the folders do not already exist they will be created. The response contains data for every folder in the path, new and existing. The feature of creating the path automatically is also available when uploading files.

In the example below, if the folders `images` or `movies` did not already exist with the CDN Conenct app then they would automatically be created.

    response = api_client.create_path(:path => '/images/movies')


## API Response

HTTP responses will be formatted in json, but the library takes the HTTP response and decodes into a hash for the `APIResponse` class. The `APIResponse` class is used to simpilfy things by using helper functions to read response data. Responses from the API are all structured the same way, and this class is used as a small wrapper to make it easier to get data from it.


 - `files` : `array` : A list of all the files that were uploaded. Each file in the array is a hash.
 - `object`: `hash` : Can be either a file or folder, or the first file in the `files` array.
 - `msgs ` : `array` : An array of messages, and each message is a hash. Example message within the `msgs` array: `{"text" => "info about the message", "status" => "error"}`
 - `is_success` : `bool` : Successful API call, the response should contain the data your looking for.
 - `is_error` : `bool` : Unsuccessful API call. Could be a client error (400) or a server error (500).
 - `is_client_error` : `bool` : Unsuccessful API call due to a client error. Review the `msgs` array for more info.
 - `is_bad_request` : `bool` : Unsuccessful API call due to sending invalid data. Review the `msgs` array for more info.
 - `is_unauthorized` : `bool` : Unsuccessful API call due to not being authorized.
 - `is_not_found` : `bool` : Unsuccessful API call because the resource does not exist.
 - `is_server_error` : `bool` : Unsuccessful API call because server is having issues (its also possible, but hopefully you'll never see this).


#### Example Upload Response

    if response.is_success

        for file in response.files
            puts "Uploaded " + file["name"]
        end

    end


#### Example Get Object Response

    if response.is_success

        puts "Got object " + response.object["name"]

    end


#### Example Error Response

    if response.is_error

        puts "CDN Connect Error"

        for msg in response.msgs
            puts msg["status"] + ": " + msg["text"]
        end

    end

Note that this HTTP response will be parsed and can be easily read using the APIResponse. Be sure to view the [API documentation](http://api.cdnconnect.com/) describing what each response object will contain depending on the API resource.


## Support

Please [report any bugs](https://github.com/cdnconnect/cdnconnect-api-ruby/issues) on this project's issues page. Additionally, please don't hesitate to contact us and/or submit a pull request with any ideas you may have to improve the service. We will continue to improve upon and build out the API in order to bring more value to you and your projects.


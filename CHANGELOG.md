# 0.3.0

* Reuse the same upload url if there is an upload error
* Add an upload_id parameter to the upload url so it 
  always gets a new one when requested (cannot be querystring!)
* Added Ruby Logger: 
  http://www.ruby-doc.org/stdlib-1.8.7/libdoc/logger/rdoc/Logger.html
* queue_processing is the default
* build_post_data() method now uses options={} arg


# 0.2.4

* Renamed "async" parameter to "queue_processing"
* Added "destination_file_name" parameter so you can specify what
  a file's name will be once it's uploaded


# 0.2.3

* Authentication header no longer required on upload POST.
  The upload url contains encrypted information, can only
  be used once, and if its not used it expires.


# 0.2.2

* Correctly send webhook_url and webhook_format


# 0.2.1

* Support for receiving a files and folders within a folder


# 0.2.0

* Group multiple files into one request
* Upload an entire folder and recursively drill down and upload
  all of its sub-folder's files
* Upload multiple files with an array of local file paths
* Set an async option so processing the upload is asynchronous
  allowing the upload response to be faster
* Set a webhook_url option
* Add 'get_object' method
* Add 'rename_object' method
* Add 'delete_object' method
* Add 'create_path' method
* Add 'files' and 'object' properties to the APIResponse object
* Removed ability to upload via app_id and obj_id


# 0.1.2

* Remove XML from data format possibilities. API supports XML
  but there is no need for this library to support both.
  

# 0.1.1

* Client needs to specify the version number in the path
* Library does not assume /v1/ in the path
* Added debug option to print out debugging info


# 0.1.0

* Have the client call the exact API path they need data from.
* Added http verb methods for GET/POST/PUT/DELETE API requests.
* get() method is no longer used to receive object information only.
* Initial alpha release


# 0.0.2

* Documentation updates


# 0.0.1

* Initial dev release
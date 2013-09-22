# If you haven't already, install the cdnconnect-api gem
# gem install cdnconnect-api

require 'cdnconnect_api'



# Your CDN Connect App Config
APP_HOST = 'demo.cdnconnect.com'
API_KEY = '1bPz6lscwNQjs5cBJEw3Pi4olaQccorpnkbSSSFNf'



# Create an API Client
api_client = CDNConnect::APIClient.new(:api_key => API_KEY, 
                                       :app_host => APP_HOST,
                                       :log_device => STDOUT, # log_device could also be a file path
                                       :log_sev_threshold => Logger::DEBUG)



puts "Upload one file (default uses queue_processing)"
response = api_client.upload(:destination_path => '/sample/one-file', 
                             :source_file_path => './test/testfiles/DSCN0251.JPG')

if response.is_success
  puts "File uploaded and processing will be queued"
end



puts "Upload multiple files to the same folder using an array of file paths"
response = api_client.upload(:destination_path => '/sample/multiple-files', 
                             :source_file_paths => [
                                './test/testfiles/IMAG0355.jpg',
                                './test/testfiles/IMAG4501.jpg'
                              ],
                              :queue_processing => false)

if response.is_success
  
  for file in response.files
    puts " - #{file["name"]}"
    for msg in file["msgs"]
      puts "    - #{msg["text"]}"
    end
  end

end


puts "Upload all files within a folder recursively, keep the same path structure"
response = api_client.upload(:destination_path => '/sample/entire-folder', 
                             :source_folder_path => './test/testfiles',
                             :queue_processing => false)

if response.is_success
  
  for file in response.files
    puts " - #{file["name"]}"
    for msg in file["msgs"]
      puts "    - #{msg["text"]}"
    end
  end

end



puts "Upload certain files with specific file extensions within a folder recursively"
response = api_client.upload(:destination_path => '/sample/folder-specific-extensions', 
                             :source_folder_path => './test/testfiles',
                             :valid_extensions => ['js', 'css', 'jpg'],
                             :queue_processing => false)

if response.is_success

  for file in response.files
    puts " - #{file["name"]}"
    for msg in file["msgs"]
      puts "    - #{msg["text"]}"
    end
  end

end



puts "Upload multiple files within a folder path not recursively"
response = api_client.upload(:destination_path => '/sample/folder-no-recursion', 
                             :source_folder_path => './test/testfiles',
                             :recursive_local_folders => false,
                             :queue_processing => false)

if response.is_success

  for file in response.files
    puts " - #{file["name"]}"
    for msg in file["msgs"]
      puts "    - #{msg["text"]}"
    end
  end

end



puts "Upload multiple files, queue the processing of the data, then send response to webhook"
# Response will not contain uploaded file data but uploads will be quicker
# In this example, when the files are done processing the data will be sent via POST
# to the webhook_url
response = api_client.upload(:destination_path => '/sample/queue_processing', 
                             :source_folder_path => './test/testfiles',
                             :queue_processing => true,
                             :webhook_url => 'http://yousite.com/webhook')

if response.is_success
  puts "Queued processing upload completed"
end



puts "Get a folder's basic information only"
response = api_client.get_object(:path => '/sample')

if response.is_success
  puts "Got folder #{response.object["name"]}"
end



puts "Get a folder's sub-files and sub-folders"
response = api_client.get_object(:path => '/sample/entire-folder', :files => true, :folders => true)

if response.is_success
  puts "Got folder #{response.object["name"]} and its #{response.object["files"].length} files and #{response.object["folders"].length} folders"
end



puts "Get a file's information"
response = api_client.get_object(:path => '/sample/one-file/DSCN0251.JPG')

if response.is_success
  puts "Got folder #{response.object["name"]}"
end



puts "Create a path"
response = api_client.create_path(:path => '/sample/creating/a/new/path/in/one/request')

if response.is_success
  puts "Renamed #{response.results["old_name"]} to #{response.results["new_name"]}"
end



puts "Rename a file"
response = api_client.rename_object(:path => '/sample/one-file/DSCN0251.JPG', 
                                    :new_name => 'DSCN0251-renamed.jpg')

if response.is_success
  puts "Renamed #{response.results["old_name"]} to #{response.results["new_name"]}"
end


puts "Upload a file so it can be deleted"
response = api_client.upload(:destination_path => '/sample/delete-file', 
                             :source_file_path => './test/testfiles/DSCN0251.JPG',
                             :queue_processing => false
                             )
if response.is_success
  puts "Test file uploaded so it can be deleted in the next test"
end

puts "Delete the uploaded test file"
response = api_client.delete_object(:path => '/sample/delete-file/DSCN0251.JPG')
if response.is_success
  puts "File deleted"
end



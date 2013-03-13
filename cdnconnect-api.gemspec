# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name               = "cdnconnect-api"
  s.version            = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.authors = ["Adam Bradley"]
  s.email = "developer@cdnconnect.com"

  s.date = "2013-04-01"
  s.description = "CDN Connect API Ruby Client which makes it easier to interact with api.cdnconnect.com."
  
  s.extra_rdoc_files = ["README.md"]
  s.require_paths = ["lib"]
  s.files = ["lib/cdnconnect_api.rb", "lib/cdnconnect_api/response.rb", "LICENSE", "README.md"]
  s.homepage = "http://www.cdnconnect.com/"
  s.rubygems_version = "1.8.10"
  s.summary = "Package Summary"

  s.add_dependency(%q<faraday>, [">= 0.8.6"])
  s.add_dependency(%q<signet>, [">= 0.4.5"])

end
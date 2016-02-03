Pod::Spec.new do |s|

  s.name         = "HJResourceManager"
  s.version      = "1.0.0"
  s.summary      = "You can download resource files with cache support, and easily append cryptogram, reprocessing module. Based on Hydra framework."
  s.homepage     = "https://github.com/P9SOFT/HJResourceManager"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/HJResourceManager.git", :tag => "1.0.0" }
  s.source_files  = "HJResourceManager/*.{h,m}"
  s.public_header_files = "Sources/*.h"
  s.libraries = 'z'

  s.dependency 'Hydra'
  s.dependency 'HJAsyncHttpDeliverer'

end

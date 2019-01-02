Pod::Spec.new do |s| 
  s.name         = "BBWebImage"
  s.version      = "0.1.0"
  s.summary      = "BBWebImage is a Swift library for downloading, caching and editing web images asynchronously."

  s.description  = <<-DESC
                   View extensions for `UIImageView`, `UIButton`, `MKAnnotationView` and `CALayer` to set image from URL.
                   Asynchronous image downloader.
                   Asynchronous memory + file + SQLite image cache with least recently used algorithm.
                   Asynchronous image decompressing.
                   Asynchronous image editing without modifying original image disk data.
                   Independent image cache, downloader, coder and editor for separate use.
                   Customized image cache, downloader and coder.
                   DESC

  s.homepage     = "https://github.com/Silence-GitHub/BBWebImage"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Kaibo Lu" => "lukaibolkb@gmail.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/Silence-GitHub/BBWebImage.git", :tag => s.version }

  s.source_files  = "BBWebImage/BBWebImage/BBWebImage.h", "BBWebImage/**/*.swift", "BBWebImage/**/*.cikernel"

  s.public_header_files = "BBWebImage/BBWebImage/BBWebImage.h"

  s.requires_arc = true

end

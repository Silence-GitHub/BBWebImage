Pod::Spec.new do |s|
  s.name         = 'BBWebImage'
  s.version      = '1.1.3'
  s.summary      = 'A high performance Swift library for downloading, caching and editing web images asynchronously.'

  s.description  = <<-DESC
                   View extensions for `UIImageView`, `UIButton`, `MKAnnotationView` and `CALayer` to set image from URL.
                   Asynchronous image downloader.
                   Asynchronous memory + file + SQLite image cache with least recently used algorithm.
                   Asynchronous image decompressing.
                   Asynchronous image editing without modifying original image disk data.
                   Animated image smart decoding, decompressing, editing and caching.
                   Independent image cache, downloader, coder and editor for separate use.
                   Customized image cache, downloader and coder.
                   High performance.
                   DESC

  s.homepage     = 'https://github.com/Silence-GitHub/BBWebImage'

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { 'Kaibo Lu' => 'lukaibolkb@gmail.com' }

  s.platform     = :ios, '8.0'

  s.swift_version = '5.0'

  s.source       = { :git => 'https://github.com/Silence-GitHub/BBWebImage.git', :tag => s.version }

  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'BBWebImage/BBWebImage/BBWebImage.h', 'BBWebImage/BBWebImage/**/*.swift'
    core.exclude_files = 'BBWebImage/BBWebImage/Extensions/MKAnnotationView+BBWebCache.swift', 'BBWebImage/BBWebImage/Filter/*'
  end

  s.subspec 'MapKit' do |mk|
    mk.source_files = 'BBWebImage/BBWebImage/Extensions/MKAnnotationView+BBWebCache.swift'
    mk.dependency 'BBWebImage/Core'
  end

  s.subspec 'Filter' do |filter|
    filter.source_files = 'BBWebImage/BBWebImage/Filter'
    filter.resources = 'BBWebImage/BBWebImage/**/*.cikernel'
    filter.dependency 'BBWebImage/Core'
  end 

end

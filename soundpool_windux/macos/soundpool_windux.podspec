#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint soundpool_windux.podspec` to validate before publishing.
#
require 'fileutils'

FileUtils.cp_r('../target/release/libsoundpool.dylib', 'libs/libsoundpool.dylib', remove_destination: true)

Pod::Spec.new do |s|
  s.name             = 'soundpool_windux'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://ukaszapps.pl'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Łukasz Huculak' => 'ukasz.apps@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  # s.public_header_files = 'libs/libsoundpool.h'
  s.vendored_libraries = 'libs/libsoundpool.dylib'
  # s.libraries = 'soundpool'
  
end

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint soundpool_macos.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'soundpool_macos'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter Sound Pool for playing short media files.'
  s.description      = <<-DESC
  A Flutter Sound Pool for playing short media files.
                       DESC
  s.homepage         = 'https://github.com/ukasz123/soundpool/tree/master/soundpool_macos'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Łukasz Huculak' => 'ukasz.apps@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

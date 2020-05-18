#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint soundpool.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'soundpool'
  s.version          = '1.0.1'
  s.summary          = 'No-op implementation of soundpool MacOS plugin to avoid build issues on MacOS'
  s.description      = <<-DESC
temp fake soundpool plugin
                       DESC
  s.homepage         = 'https://github.com/ukasz123/soundpool/tree/master/soundpool'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

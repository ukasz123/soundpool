#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint soundpool_web.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'soundpool_web'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of soundpool web plugin to avoid build issues on iOS'
  s.description      = <<-DESC
temp fake soundpool_web plugin
                       DESC
  s.homepage         = 'https://github.com/ukasz123/soundpool/tree/master/soundpool_web'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'UkaszApps' => 'ukasz.apps@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end

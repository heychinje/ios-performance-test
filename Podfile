# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
plugin 'cocoapods-art', :sources => [
  'telenav-cocoapods-releases',
  'telenav-cocoapods-snapshots',
  'telenav-cocoapods-preprod-local'
]

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '14.0'
workspace 'PerformanceTest.xcworkspace'

target 'PerformanceTest' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for PerformanceTest
  pod 'TelenavDriveMotion', '2.2.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # fixes for DriveMotion lib crash
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end


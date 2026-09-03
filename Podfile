# Yorva Podfile
# 依赖管理：CocoaPods
# 强制引入：IQKeyboardManagerSwift、SnapKit

platform :ios, '14.0'
use_frameworks!

target 'Yorva' do
  # 项目根路径（含 .xcodeproj）
  project 'Yorva/Yorva.xcodeproj'

  pod 'IQKeyboardManagerSwift'
  pod 'SnapKit', '~> 5.7.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end

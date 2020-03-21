# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# ignore all warnings from all pods
inhibit_all_warnings!

def sharedPods
  pod 'BitmarkSDK/RxSwift', git: 'https://github.com/bitmark-inc/bitmark-sdk-swift.git', branch: 'master'
  pod 'Intercom'
  pod 'OneSignal'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.4.1'

  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'RxOptional'
  pod 'Moya/RxSwift'
  pod 'RealmSwift'
  pod 'RxRealm'
  pod 'RxTheme'
  pod 'RxSwiftExt'

  pod 'IQKeyboardManagerSwift'
  pod 'Hero'
  pod 'PanModal'
  pod 'SVProgressHUD'
  pod 'SwiftEntryKit'
  pod 'R.swift'
  pod 'SnapKit'
  pod 'ESTabBarController-swift'
  pod 'FlexLayout'

  pod 'SwifterSwift'

  pod 'XCGLogger', '~> 7.0.0'
    
  pod 'Charts'
  pod 'ChartsRealm'
  pod 'SwiftDate'
  pod 'Kingfisher'
  pod 'UPCarouselFlowLayout'
  pod 'SwiftRichString'
  pod 'MaterialProgressBar'
  pod 'RxAppState'
end

target 'Spring' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Spring
  sharedPods
end


target 'Spring Dev' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Spring Dev
  sharedPods
  pod 'SwiftLint'

  target 'SpringTests' do
    inherit! :search_paths

    pod 'Quick'
    pod 'Nimble'
    pod 'RxTest'
    pod 'RxBlocking'
    pod 'Mockit'
    pod 'Fakery'
  end
end

target 'Spring Inhouse' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Spring Inhouse
  sharedPods
end

target 'OneSignalNotificationServiceExtension' do
  use_frameworks!

  pod 'OneSignal'
end

target 'OneSignalNotificationServiceDevExtension' do
  use_frameworks!

  pod 'OneSignal'
end

target 'OneSignalNotificationServiceInhouseExtension' do
  use_frameworks!

  pod 'OneSignal'
end

#
#  Be sure to run `pod spec lint GenericIAPHelper.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ConsumableWallet"
  spec.version      = "0.0.5"
  spec.summary      = "A lightweight swift library for managing consumable credits"

  spec.description  = <<-DESC 
                    IOS Client Helper for tracking consumable credits. In this project, this client library is backed by 
a server side implementation for managing credits. When a user purchases credits pack in the ios app, this library will 
communicate with the credit server deployed and add credits to your designated wallet. For a wallet, 3 types of identity is used 
to identify users wallet uniquely. DeviceLocal(KeyChain UUID), SubscriptionID(current active subscription's original transaction id) and 
AppleID (if apple sign in is done by the user)
                   DESC

  spec.homepage     = "https://github.com/KGS-Global/ConsumableWallet"
  
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "KGS-Global" => "kgs.bitbucket.manager@gmail.com" }
  
  spec.platform     = :ios, "15.0"
  spec.source       = { :git => "https://github.com/KGS-Global/ConsumableWallet.git", :tag => "#{spec.version}" }

  spec.source_files  = "ConsumableWallet", "ConsumableWallet/**/*.{h,m,swift}"

  spec.swift_version = "5.0"

end

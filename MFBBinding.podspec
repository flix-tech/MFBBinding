#
# Be sure to run `pod lib lint MFBBinding.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MFBBinding'
  s.version          = '0.2.0'
  s.summary          = 'Data binding framework for Objective-C'

  s.description      = <<-DESC
MFBBinding provides data binding mechanism with Interface Builder support, which could be used on iOS platform as alternative to Cocoa Bindings.
                       DESC

  s.homepage         = 'https://github.com/flix-tech/MFBBinding'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nickolay Tarbayev' => 'tarbayev-n@yandex.ru' }
  s.source           = { :git => 'https://github.com/flix-tech/MFBBinding.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Sources/**/*.{h,m}'
end

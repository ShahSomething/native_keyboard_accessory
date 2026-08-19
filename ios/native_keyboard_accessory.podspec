#
# Run `pod lib lint native_keyboard_accessory.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_keyboard_accessory'
  s.version          = '0.1.0'
  s.summary          = 'A real UIKit inputAccessoryView for Flutter text fields on iOS.'
  s.description      = <<-DESC
Adds the native iOS keyboard accessory bar (previous / next / done) above the
keyboard for Flutter text fields, by attaching a real UIKit inputAccessoryView
to the engine's own text input view rather than drawing a Flutter overlay.
                       DESC
  s.homepage         = 'https://github.com/ShahSomething/native_keyboard_accessory'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ShahSomething' => 'shahsomething@yahoo.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'native_keyboard_accessory/Sources/native_keyboard_accessory/**/*.{h,m}'
  s.public_header_files = 'native_keyboard_accessory/Sources/native_keyboard_accessory/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.resource_bundles = {
    'native_keyboard_accessory_privacy' => ['native_keyboard_accessory/Sources/native_keyboard_accessory/PrivacyInfo.xcprivacy']
  }
end

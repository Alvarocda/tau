#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'tau_web'
  s.version          = '9.0.0-alpha.13'
  s.summary          = 'No-op implementation of tau_web web plugin to avoid build issues on iOS'
  s.description      = <<-DESC
temp fake tau_web plugin
                       DESC
                       s.homepage         = s.homepage         = 'https://github.com/Canardoux/tau/tau_web'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Larpoux' => 'larpoux@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '10.0'
end

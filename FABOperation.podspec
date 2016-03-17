Pod::Spec.new do |s|
  s.name             = "FABOperation"
  s.version          = "0.0.1"
  s.summary          = "A simple asynchronous NSOperation interface"
  s.description      = <<-DESC
    FABOperation is a small framework with classes that extend Apple's `NSOperation` API. `FABAsyncOperation` is an asynchronous implementation that you can subclass to encapsulate logic involving things like networking or interprocess communication (like working with XPC or `NSTask`).
  DESC

  s.homepage         = "https://github.com/twitter-fabric/FABOperation"
  s.license          = 'MIT'
  s.author           = "Fabric"
  s.source           = { :git => "https://github.com/twitter-fabric/FABOperation.git" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = true

  s.source_files = 'FABOperation/*.{h,m}'
  s.public_header_files = 'FABOperation/*.h'
end
Pod::Spec.new do |s|
  s.name             = "MUKArrayDelta"
  s.version          = "1.0.0"
  s.summary          = "Spot differences between to arrays"
  s.description      = ""
  s.homepage         = "https://github.com/muccy/MUKArrayDelta"
  s.license          = 'MIT'
  s.author           = { "Marco Muccinelli" => "muccymac@gmail.com" }
  s.source           = { :git => "https://github.com/muccy/MUKArrayDelta.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes', 'Pod/Classes/**/*.{h,m}'
  s.private_header_files = 'Pod/Classes/Private/*.h'
  s.compiler_flags  = '-Wdocumentation'
end

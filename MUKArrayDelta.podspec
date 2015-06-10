Pod::Spec.new do |s|
  s.name             = "MUKArrayDelta"
  s.version          = "1.0.0"
  s.summary          = "Spot differences between two arrays"
  s.description      = "You feed two array and you will get inserted indexes, deleted indexes, changed indexes and movements"
  s.homepage         = "https://github.com/muccy/MUKArrayDelta"
  s.license          = 'MIT'
  s.author           = { "Marco Muccinelli" => "muccymac@gmail.com" }
  s.source           = { :git => "https://github.com/muccy/MUKArrayDelta.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = '*.{h,m}'
  s.compiler_flags  = '-Wdocumentation'
end

Pod::Spec.new do |s|
  s.name             = "FranticApparatusObjC"
  s.version          = "1.0.0"
  s.summary          = "A Promises/A+ implementation for Objective-C"
  s.description      = <<-DESC
                       An Objective-C port of the FranticApparatus library for Swift.
                       DESC
  s.homepage         = "https://github.com/jkolb/FranticApparatusObjC"
  s.license          = 'MIT'
  s.author           = { "Justin Kolb" => "franticapparatus@gmail.com" }
  s.source           = { :git => "https://github.com/jkolb/FranticApparatusObjC.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nabobnick'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'FranticApparatusObjC' => ['Pod/Assets/*.png']
  }
end

Pod::Spec.new do |s|

  s.name         = "MatchedTransition"
  s.version      = "1.1.0"
  s.summary      = "A primitive stuff for transition"
  s.description  = <<-DESC
  A library that provides stuff for transition in UIKit
                   DESC

  s.homepage     = "http://github.com/muukii/MatchedTransition"
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com" }
  s.ios.deployment_target = "12.0"
  s.source       = { :git => "https://github.com/muukii/MatchedTransition.git", :tag => "#{s.version}" }
  s.source_files  = "MatchedTransition/**/*.swift"
  s.swift_versions = ["5.3", "5.4"]
end

Pod::Spec.new do |s|
  s.name             = 'plugin_universal_in_app_browser'
  s.version          = '0.1.1'
  s.summary          = 'Universal in-app browser experience for Flutter applications.'
  s.description      = <<-DESC
                       A lightweight Flutter plugin for presenting web content
                       with a small, friendly API across common in-app browser flows.
                       DESC
  s.homepage         = 'https://github.com/bushra-muneer/Plugin-Universal-in-app-browser'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bushra Muneer' => 'gptpros3@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
end

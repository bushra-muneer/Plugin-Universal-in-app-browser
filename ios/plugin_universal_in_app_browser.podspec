Pod::Spec.new do |s|
  s.name             = 'plugin_universal_in_app_browser'
  s.version          = '0.1.0'
  s.summary          = 'Universal in-app browser experience for Flutter applications.'
  s.description      = <<-DESC
                       Presents web content via platform native browser components
                       with a unified Flutter API.
                       DESC
  s.homepage         = 'https://github.com/bushra-muneer/Plugin-Universal-in-app-browser'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'plugin_universal_in_app_browser' => 'maintainers@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
end

Pod::Spec.new do |s|
  s.name         = 'URLSessionAdapter'
  s.version      = '2.2.5'
  s.homepage     = 'https://github.com/denissimon/URLSessionAdapter'
  s.authors      = { 'Denis Simon' => 'denis.v.simon@gmail.com' }
  s.summary      = 'A Codable wrapper around URLSession for networking. Includes both APIs: async/await and callbacks.'
  s.license      = { :type => 'MIT' }

  s.swift_versions = ['5']
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.watchos.deployment_target = '8.0'
  s.tvos.deployment_target = '15.0'
  s.source       =  { :git => 'https://github.com/denissimon/URLSessionAdapter.git', :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'
  s.frameworks  = 'Foundation'
end

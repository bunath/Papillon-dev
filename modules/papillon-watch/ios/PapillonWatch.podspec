Pod::Spec.new do |s|
  s.name           = 'PapillonWatch'
  s.version        = '1.0.0'
  s.summary        = 'Sends the timetable and homework to the Apple Watch app.'
  s.description    = 'A thin WatchConnectivity bridge: JavaScript hands over a JSON payload and the watch app receives it as an application context.'
  s.author         = 'Papillon'
  s.homepage       = 'https://getpapillon.xyz'
  s.license        = { :type => 'GPL-3.0' }
  s.platforms      = { :ios => '15.1' }
  s.swift_version  = '5.9'
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.frameworks = 'WatchConnectivity'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end

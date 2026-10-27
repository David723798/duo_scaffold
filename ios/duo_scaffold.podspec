Pod::Spec.new do |s|
  s.name             = 'duo_scaffold'
  s.version          = '0.3.2'
  s.summary          = 'Hinge state for duo_scaffold.'
  s.description      = 'Reports the device hinge to duo_scaffold through UIHingeInteraction.'
  s.homepage         = 'https://github.com/David723798/duo_scaffold'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'David Chow' => 'testdavidchow@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'duo_scaffold/Sources/duo_scaffold/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
end

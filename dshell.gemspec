# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dshell/version'

Gem::Specification.new do |spec|
  spec.name          = "dshell"
  spec.version       = Dshell::VERSION
  spec.authors       = ["Sergei Matheson"]
  spec.email         = ["sergei.matheson@gmail.com"]

  spec.summary       = %q{fake shell for downlink game}
  spec.description   = %q{fake shell for downlink game}
  spec.homepage      = "https://github.com/downlink/dshell"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
end

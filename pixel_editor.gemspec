# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pixel_editor/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Daniel X. Moore", "Matt Diebolt"]
  gem.email         = ["yahivin@gmail.com"]
  gem.description   = %q{Some kind of pixel editor}
  gem.summary       = %q{Some kind of pixel editor}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pixel_editor"
  gem.require_paths = ["lib"]
  gem.version       = PixelEditor::VERSION
end

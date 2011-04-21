
$:.push File.expand_path("lib")
require "xample/version"

Gem::Specification.new do |s|
  s.name        = "xample"
  s.version     = Xample::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ola Bini"]
  s.email       = ["ola.bini@gmail.com"]
  s.homepage    = "http://xample.rubyforge.org"
  s.summary     = %q{Xample allows you to use a template based approach to creating DSLs}
  s.description = s.summary

  s.add_dependency 'ruby2ruby', '1.1.9'
  s.add_dependency 'ParseTree', '2.2.0'

  s.add_development_dependency 'rspec', '~>2.5'
  s.add_development_dependency 'ci_reporter', '~>1.6'

  s.rubyforge_project = "xample"

  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--title' << 'xample' << '--main' << 'README' << '--line-numbers'

  s.files         = Dir['{lib,test}/**/*.rb', '[A-Z]*$', 'Rakefile'].to_a
  s.test_files    = Dir['{test}/**/*.rb'].to_a
  s.require_paths = ["lib"]
end

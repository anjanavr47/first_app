# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rubygems-bundler"
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Josh Hull", "Michal Papis"]
  s.date = "2012-04-09"
  s.description = "Stop using bundle exec. Integrate Rubygems and Bundler. Make rubygems generate bundler aware executable wrappers."
  s.email = ["joshbuddy@gmail.com", "mpapis@gmail.conf"]
  s.executables = ["noexec"]
  s.extensions = ["ext/wrapper_installer/extconf.rb"]
  s.files = ["bin/noexec", "ext/wrapper_installer/extconf.rb"]
  s.homepage = "http://mpapis.github.com/rubygems-bundler"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Stop using bundle exec"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
  end
end

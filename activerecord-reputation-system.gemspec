require File.join(File.dirname(__FILE__), 'lib', 'reputation_system', 'version')

Gem::Specification.new do |s|
  s.name = "activerecord-reputation-system"
  s.version = ::ReputationSystem::VERSION
  s.authors = ["Katsuya Noguchi"]
  s.email = ["katsuya@twitter.com"]
  s.homepage = "https://github.com/twitter/activerecord-reputation-system"
  s.description = "ActiveRecord Reputation System gem allows rails apps to compute and publish reputation scores for active record models."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.summary = "ActiveRecord Reputation System gem allows rails apps to compute and publish reputation scores for active record models"

  s.add_development_dependency 'activerecord', '~> 4.0'
  s.add_development_dependency 'rake', ">=0.8.7"
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'database_cleaner', "~> 1.2.0"
  s.add_development_dependency 'sqlite3', "~>1.3.5"

  s.require_path = 'lib'
  s.files = %w(LICENSE README.md Rakefile) + Dir.glob("{lib,spec}/**/*")
end

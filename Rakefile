require "bundler/gem_tasks"
require 'rspec'
require 'rspec/core/rake_task'

desc "Run all test examples"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress"]
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "megar"
  rdoc.rdoc_files.include('README*', 'lib/**/*.rb')
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r megar.rb"
end

namespace :gen do
  desc "Generate new unit test expectations given email=your_email password=your_password"
  task :crypto_expectations do
    require './spec/spec_helper.rb'
    include CryptoExpectationsHelper
    generate_crypto_expectations(ENV['email'], ENV['password'])
  end
end

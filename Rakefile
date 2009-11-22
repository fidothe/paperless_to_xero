require "rubygems"
require 'rake'
require 'rake/rdoctask'
gem 'rspec'
require 'spec/rake/spectask'
require 'lib/paperless_to_xero/version.rb'

desc 'Generate documentation for Paperless to Xero.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Paperless to Xero'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{Rake.original_dir}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

namespace :spec do
  desc "Run all specs in spec directory with RCov (excluding plugin specs)"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_opts = ['--options', "\"#{Rake.original_dir}/spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("#{Rake.original_dir}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    end
  end
  
  desc "Print Specdoc for all specs (excluding plugin specs)"
  Spec::Rake::SpecTask.new(:doc) do |t|
    t.spec_opts = ["--format", "specdoc", "--dry-run"]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name              = "paperless_to_xero"
    s.summary           = "Convert Paperless CSV exports to Xero invoice import CSV"
    s.description       = File.read('README.rdoc')
    s.authors           = ["Matt Patterson"]
    s.email             = "matt@reprocessed.org"
    s.homepage          = "http://github.com/fidothe/paperless_to_xero/"
    
    s.extra_rdoc_files  = %w(README.rdoc)
    s.rdoc_options      = %w(--main README.rdoc)

    s.require_paths     = ["lib"]

    # If you want to depend on other gems, add them here, along with any
    # relevant versions

    s.add_development_dependency("rspec") # add any other gems for testing/development

    # If you want to publish automatically to rubyforge, you'll may need
    # to tweak this, and the publishing task below too.
    s.rubyforge_project = "paperless_to_xero"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
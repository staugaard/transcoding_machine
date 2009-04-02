require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "transcoding_machine"
    s.summary = %Q{TODO}
    s.email = "mick@staugaard.com"
    s.homepage = "http://github.com/staugaard/transcoding_machine"
    s.description = "TODO"
    s.authors = ["Mick Staugaard"]
    s.add_dependency(%q<activesupport>, [">= 2.2.2"])
    s.add_dependency(%q<unicode>, [">= 0.1"])
    s.add_dependency(%q<right_aws>, [">= 1.10.0"])
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'transcoding_machine'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end
rescue LoadError
  puts "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
end

task :default => :test

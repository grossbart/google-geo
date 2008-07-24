require 'rubygems'
Gem.manage_gems
require 'rake/gempackagetask'

README = File.readlines("#{File.dirname __FILE__}/README")

spec = Gem::Specification.new do |s| 
  s.name             = 'google-geo'
  s.version          = '2.1'
  s.summary          = README[2]
  s.files            = FileList['{lib}/**/*'].to_a + FileList['{test}/**/*'].to_a + FileList['{vendor}/**/*'].to_a
  s.require_path     = 'lib'
  # s.autorequire      = 'google/geo'
  s.test_files       = FileList['{test}/**/*test.rb'].to_a
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README CHANGELOG )
  s.author, s.homepage, s.email = README[README.index(README.grep(/contributors/i)[0])+1].split(' - ')
end

Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem"
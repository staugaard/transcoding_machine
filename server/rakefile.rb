#    This file is part of EC2 on Rails.
#    http://rubyforge.org/projects/ec2onrails/
#
#    Copyright 2007 Paul Dowman, http://pauldowman.com/
#
#    EC2 on Rails is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    EC2 on Rails is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


# This script is meant to be run by build-ec2onrails.sh, which is run by
# Eric Hammond's Ubuntu build script: http://alestic.com/
# e.g.:
# bash /mnt/ec2ubuntu-build-ami --script /mnt/ec2onrails/server/build-ec2onrails.sh ...



require "rake/clean"
require 'yaml'
require 'erb'

if `whoami`.strip != 'root'
  raise "Sorry, this buildfile must be run as root."
end

@packages = %w(
  aptitude
  curl
  irb
  libdbm-ruby
  libgdbm-ruby
  libmysql-ruby
  libopenssl-ruby
  libreadline-ruby
  libruby
  libssl-dev
  libyaml-ruby
  libzlib-ruby
  openssh-server
  rdoc
  ri
  rsync
  ruby
  ruby1.8-dev
  unzip
  wget
  build-essential
  mplayer
  ffmpeg
  atomicparsley
  libimage-exiftool-perl
)

@rubygems = [
  "staugaard-transcoding_machine"
]

@build_root = "/mnt/build"
@fs_dir = "#{@build_root}/ubuntu"

task :default => :configure

desc "Removes all build files"
task :clean_all do |t|
  rm_rf @build_root
end

desc "Use apt-get to install required packages inside the image's filesystem"
task :install_packages do |t|
  unless_completed(t) do
    #ENV['DEBIAN_FRONTEND'] = 'noninteractive'
    ENV['LANG'] = ''
    run_chroot "apt-get update"
    run_chroot "apt-get install -y #{@packages.join(' ')}"
    run_chroot "apt-get autoremove -y"
    run_chroot "apt-get clean"
  end
end

desc "Install required ruby gems inside the image's filesystem"
task :install_gems => [:install_packages] do |t|
  unless_completed(t) do
    run_chroot "sh -c 'cd /tmp && wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz && tar zxf rubygems-1.3.1.tgz'"
    run_chroot "sh -c 'cd /tmp/rubygems-1.3.1 && ruby setup.rb'"
    run_chroot "ln -sf /usr/bin/gem1.8 /usr/bin/gem"
    run_chroot "gem update --system --no-rdoc --no-ri"
    run_chroot "gem update --no-rdoc --no-ri"
    run_chroot "gem sources -a http://gems.github.com"
    @rubygems.each do |g|
      run_chroot "gem install #{g} --no-rdoc --no-ri"
    end
  end
end

desc "Copy files into the image"
task :copy_files do |t|
  unless_completed(t) do
    sh("cp -r files/* #{@fs_dir}")
  end
end

desc "Configure the image"
task :configure => [:install_gems, :copy_files] do |t|
end
##################

# Execute a given block and touch a stampfile. The block won't be run if the stampfile exists.
def unless_completed(task, &proc)
  stampfile = "#{@build_root}/#{task.name}.completed"
  unless File.exists?(stampfile)
    yield  
    touch stampfile
  end
end

def run_chroot(command, ignore_error = false)
  run "chroot '#{@fs_dir}' #{command}", ignore_error
end

def run(command, ignore_error = false)
  puts "*** #{command}" 
  result = system command
  raise("error: #{$?}") unless result || ignore_error
end

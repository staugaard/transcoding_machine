#!/bin/sh

# Use this script with Eric Hammond's Ubuntu build script (http://alestic.com/)
# to create a fresh TranscodingMachine server.

# bash ec2ubuntu-build-ami --codename hardy --bucket transcodingmachine /
# --user YOUR-ID --access-key YOUR-KEY --secret-key YOUR-SECRET /
# --private-key /mnt/pk*.pem --cert /mnt/cert*.pem --no-run-user-data --script PATH_TO_THIS_FILE

if [ -z `which rake` ] ; then
  echo "Installing rake..."
  (
  cd /tmp
  wget http://rubyforge.org/frs/download.php/19879/rake-0.7.3.tgz
  tar xvf rake-0.7.3.tgz
  cd rake-0.7.3
  ruby install.rb
  )
fi

cd `dirname $0`

if [ $(uname -m) = 'x86_64' ]; then
  export ARCH=x86_64
  rake
else
  rake
fi

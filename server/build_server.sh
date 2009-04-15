#run this bad boy on an instance of ami-b1fe19d8
#remember to copy your keys to /mnt

cd /mnt

echo 'deb http://ppa.launchpad.net/handbrake-ubuntu/ppa/ubuntu hardy main' > /etc/apt/sources.list.d/handbrake.list
echo 'deb-src http://ppa.launchpad.net/handbrake-ubuntu/ppa/ubuntu hardy main' >> /etc/apt/sources.list.d/handbrake.list
echo 'deb http://packages.medibuntu.org/ hardy free non-free' > /etc/apt/sources.list.d/medibuntu.list
echo 'deb-src http://packages.medibuntu.org/ hardy free non-free' >> /etc/apt/sources.list.d/medibuntu.list
apt-get -y update

echo "Installing ruby tools."
apt-get -y --force-yes install aptitude curl irb libdbm-ruby libgdbm-ruby libopenssl-ruby libreadline-ruby libruby libssl-dev libyaml-ruby libzlib-ruby rdoc ri rsync ruby ruby1.8-dev rake unzip wget build-essential
sh -c 'cd /mnt && wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz && tar zxf rubygems-1.3.1.tgz'
sh -c 'cd /mnt/rubygems-1.3.1 && ruby setup.rb'
ln -sf /usr/bin/gem1.8 /usr/bin/gem
gem update --system --no-rdoc --no-ri
gem update --no-rdoc --no-ri
gem sources -a http://gems.github.com
gem install staugaard-transcoding_machine --no-rdoc --no-ri


echo "Installing AtomicParsley."
apt-get install -y --force-yes subversion zlib1g-dev build-essential autoconf
svn co https://atomicparsley.svn.sourceforge.net/svnroot/atomicparsley/trunk/atomicparsley atomicparsley
cd atomicparsley
autoconf
autoheader
./configure
make
cp AtomicParsley /usr/bin
cd ..

echo "installing other tools."
apt-get -y --force-yes install non-free-codecs ffmpeg eyed3 mplayer mencoder libimage-exiftool-perl gpac handbrake-cli
ldconfig

echo '#!/bin/sh -e' > /etc/rc.local
echo 'update_transcoding_machine_ec2_server' >> /etc/rc.local
echo 'transcoding_machine_ec2_server' >> /etc/rc.local
echo 'exit 0' >> /etc/rc.local
chmod +x /etc/rc.local

echo "You're running Ubuntu version: \c";
version=$( cat /etc/issue | grep 8.10 >/dev/null && echo 8.10 || (cat /etc/issue | grep 8.04 >/dev/null && echo 8.04 || echo "Unsupported version of Ubuntu") )
echo $version

if [ "$version" = "8.04" ]; then
    liblame="liblame-dev"
elif [ "$version" = "8.10" ]; then
    liblame="libmp3lame-dev"
else
    exit
fi

echo "Purging currently installed x264 libraries and ffmpeg."
apt-get -y purge ffmpeg x264 libx264-dev

echo "Installing dependencies."
apt-get -y --force-yes install build-essential subversion git-core checkinstall texi2html

echo "Installing codec dev libraries."
apt-get -y --force-yes install libdc1394-dev libfaad-dev libfaac-dev $liblame libtheora-dev libvorbis-dev libxvidcore4-dev libschroedinger-dev libspeex-dev libgsm1-dev libfaac-dev libdts-dev libgsm1-dev zlib1g-dev
apt-get -y --force-yes build-dep ffmpeg

if [ "$version" = "8.04" ]; then
    echo "Need to install YASM from source."
    wget http://www.tortall.net/projects/yasm/releases/yasm-0.7.2.tar.gz
    tar xzvf yasm-0.7.2.tar.gz
    cd yasm-0.7.2
    ./configure
    make
    checkinstall --pkgname=yasm --default
    cd ..
else
    echo "Installing YASM from apt respositories."
    apt-get -y --force-yes install yasm
fi

echo "Installing x264 codec."
git clone git://git.videolan.org/x264.git
cd x264
./configure --enable-shared
make
checkinstall --fstrans=no --install=yes --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0ubuntu1" --default
ldconfig
cd ..

echo "Getting ffmpeg source."
wget http://ffmpeg.org/releases/ffmpeg-0.5.tar.bz2
tar xjvf ffmpeg-0.5.tar.bz2
cd ffmpeg-0.5

echo "Installing ffmpeg."
./configure --enable-gpl --enable-postproc --enable-pthreads --enable-libfaac --enable-libfaad --enable-libmp3lame --enable-libtheora --enable-libx264 --enable-libxvid --enable-libvorbis --enable-libdc1394 --enable-libgsm
make
checkinstall --fstrans=no --install=yes --pkgname=ffmpeg --pkgversion "3:0.svn`date +%Y%m%d`-12ubuntu3" --default
cd ..

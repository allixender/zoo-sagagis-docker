#!/bin/bash

export RUNTIME_PACKAGES="wget libxml2 curl openssl apache2 libfcgi0ldbl libcairo2 libgeotiff2 libtiff5 \
libgdal1h libgeos-3.4.2 libgeos-c1 libgd-dev libwxbase3.0-0 libgfortran3 libmozjs185-1.0 libproj0 \
wx-common zip libwxgtk3.0-0 libjpeg62 libpng3 libxslt1.1 python2.7 apache2"

apt-get update -y \
      && apt-get install -y --no-install-recommends $RUNTIME_PACKAGES

export BUILD_PACKAGES="subversion unzip flex bison libxml2-dev autotools-dev autoconf libmozjs185-dev python-dev \
build-essential libxslt1-dev software-properties-common libgdal-dev automake libtool libcairo2-dev \
 libgd-gd2-perl libgd2-xpm-dev ibwxbase3.0-dev  libwxgtk3.0-dev wx3.0-headers wx3.0-i18n \
libproj-dev libnetcdf-dev libfreetype6-dev libxslt1-dev libfcgi-dev \
libtiff5-dev libgeotiff-dev"

apt-get install -y --no-install-recommends $BUILD_PACKAGES

# for mapserver
export CMAKE_C_FLAGS=-fPIC
export CMAKE_CXX_FLAGS=-fPIC

# useful declarations
export BUILD_ROOT=/opt/build
export ZOO_BUILD_DIR=/opt/build/zoo-project
export CGI_DIR=/usr/lib/cgi-bin
export CGI_DATA_DIR=$CGI_DIR/data
export CGI_TMP_DIR=$CGI_DATA_DIR/tmp
export CGI_CACHE_DIR=$CGI_DATA_DIR/cache
export WWW_DIR=/var/www/html

mkdir -p $BUILD_ROOT \
  && mkdir -p $CGI_DIR \
  && mkdir -p $CGI_DATA_DIR \
  && mkdir -p $CGI_TMP_DIR \
  && mkdir -p $CGI_DATA_DIR \
  && ln -s /usr/lib/x86_64-linux-gnu /usr/lib64

wget -nv -O $BUILD_ROOT/mapserver-6.0.4.tar.gz http://download.osgeo.org/mapserver/mapserver-6.0.4.tar.gz \
  && cd $BUILD_ROOT/ && tar -xzf mapserver-6.0.4.tar.gz \
  && cd $BUILD_ROOT/mapserver-6.0.4 \
  && ./configure --with-ogr=/usr/bin/gdal-config --with-gdal=/usr/bin/gdal-config \
               --with-proj --with-curl --with-sos --with-wfsclient --with-wmsclient \
               --with-wcs --with-wfs --with-kml=yes --with-geos \
               --with-xml --with-xslt --with-threads --with-cairo \
  && sed -i "s/-lgeos-3.4.2_c/-lgeos-3.4.2\ -lgeos_c/g" Makefile \
  && sed -i "s/-lm -lstdc++/-lm -lstdc++ -ldl/g" Makefile \
  && make && cp mapserv $CGI_DIR

wget -nv -O $BUILD_ROOT/liblas_1.2.1.orig.tar.gz https://launchpad.net/ubuntu/+archive/primary/+files/liblas_1.2.1.orig.tar.gz
wget -nv -O $BUILD_ROOT/liblas_1.2.1-5.1ubuntu1.diff.gz https://launchpad.net/ubuntu/+archive/primary/+files/liblas_1.2.1-5.1ubuntu1.diff.gz

cd $BUILD_ROOT && gunzip liblas_1.2.1-5.1ubuntu1.diff.gz \
  && tar -xzf liblas_1.2.1.orig.tar.gz \
  && patch -p0 < liblas_1.2.1-5.1ubuntu1.diff

cd $BUILD_ROOT/liblas-1.2.1 \
  && patch -p1 < debian/patches/gcc4.5 \
  && patch -p1 < debian/patches/autoreconf \
  && patch -p1 < debian/patches/missing.diff \
  && patch -p1 < debian/patches/format-security \
  && patch -p1 < debian/patches/iterator.hpp \
  && patch -p1 < debian/patches/noundefined \
  && ./configure --prefix=/usr --exec-prefix=/usr \
    --with-gdal=/usr/bin/gdal-config --with-geotiff=/usr \
  && make -j2 && make install && cd $BUILD_ROOT && ldconfig

wget -nv -O $BUILD_ROOT/saga_2.1.4.tar.gz "http://downloads.sourceforge.net/project/saga-gis/SAGA%20-%202.1/SAGA%202.1.4/saga_2.1.4.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fsaga-gis%2Ffiles%2FSAGA%2520-%25202.1%2FSAGA%25202.1.4%2F&ts=1460433920&use_mirror=heanet"

cd $BUILD_ROOT && tar -xzf saga_2.1.4.tar.gz \
  && cd saga-2.1.4 \
  && ./configure --prefix=/usr --exec-prefix=/usr \
  && make -j2 \
  && make install

# here are the thirds
ln -s /usr/lib/libfcgi.so.0.0.0 /usr/lib64/libfcgi.so \
  && ln -s /usr/lib/libfcgi++.so.0.0.0 /usr/lib64/libfcgi++.so

svn checkout http://svn.zoo-project.org/svn/trunk/thirds/ $BUILD_ROOT/thirds \
  && cd $BUILD_ROOT/thirds/cgic206 && make

svn checkout http://svn.zoo-project.org/svn/trunk/zoo-project/ $ZOO_BUILD_DIR \
  && cd $ZOO_BUILD_DIR/zoo-kernel && autoconf \
  && ./configure --with-cgi-dir=$CGI_DIR \
  --prefix=/usr \
  --exec-prefix=/usr \
  --with-fastcgi=/usr \
  --with-gdal-config=/usr/bin/gdal-config \
  --with-geosconfig=/usr/bin/geos-config \
  --with-python \
  --with-mapserver=$BUILD_ROOT/mapserver-6.0.4 \
  --with-xml2config=/usr/bin/xml2-config \
  --with-pyvers=2.7 \
  --with-js=/usr \
  --with-saga=/usr \
  && make && make install

# install SAGA GIS config
cd $BUILD_ROOT/thirds/saga2zcfg \
  && make \
  && mkdir zcfgs \
  && cd zcfgs \
  && ../saga2zcfg \
  && mkdir -p $CGI_DIR/SAGA \
  && cp -r * $CGI_DIR/SAGA

# however, auto additonal packages won't get removed
# maybe auto remove is a bit too hard
# RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# ENV AUTO_ADDED_PACKAGES $(apt-mark showauto)
# RUN apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES

apt-get remove --purge -y $BUILD_PACKAGES \
  && rm -rf /var/lib/apt/lists/*

# do we need to consider /usr/lib/saga ?
# 611M    /opt/build/saga-2.1.4 ouch
rm -rf /opt/build/saga-2.1.4
rm -rf /opt/build/saga_2.1.4.tar.gz
rm -rf $BUILD_ROOT/mapserver-6.0.4
rm $BUILD_ROOT/mapserver-6.0.4.tar.gz
# rm -rf $ZOO_BUILD_DIR
# rm -rf $BUILD_ROOT/thirds

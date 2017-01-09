#!/bin/bash

export RUNTIME_PACKAGES="wget libxml2 curl openssl apache2 libfcgi0ldbl libcairo2 libgeotiff2 libtiff5 \
libgdal1h libgeos-3.4.2 libgeos-c1 libgd-dev libwxbase3.0-0 libgfortran3 libmozjs185-1.0 libproj0 \
wx-common zip libwxgtk3.0-0 libjpeg62 libpng3 libxslt1.1 python2.7 apache2 cgal libcgal10"

apt-get update -y \
      && apt-get install -y --no-install-recommends $RUNTIME_PACKAGES

export BUILD_PACKAGES="subversion unzip flex bison libxml2-dev autotools-dev autoconf libmozjs185-dev python-dev \
build-essential libxslt1-dev software-properties-common libgdal-dev automake libtool libcairo2-dev \
 libgd-gd2-perl libgd2-xpm-dev ibwxbase3.0-dev  libwxgtk3.0-dev wx3.0-headers wx3.0-i18n \
libproj-dev libnetcdf-dev libfreetype6-dev libxslt1-dev libfcgi-dev \
libtiff5-dev libgeotiff-dev libcgal10 libcgal-dev"

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

# should build already there from base
# mkdir -p $BUILD_ROOT \
#   && mkdir -p $CGI_DIR \
#   && mkdir -p $CGI_DATA_DIR \
#   && mkdir -p $CGI_TMP_DIR \
#   && mkdir -p $CGI_CACHE_DIR \
#   && ln -s /usr/lib/x86_64-linux-gnu /usr/lib64


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
  && make && make install || exit 1

# install SAGA GIS config - needs to happen after zoo kernel build
cd $BUILD_ROOT/thirds/saga2zcfg \
  && make \
  && mkdir zcfgs \
  && cd zcfgs \
  && ../saga2zcfg \
  && mkdir -p $CGI_DIR/SAGA \
  && cp -r * $CGI_DIR/SAGA || exit 1

# however, auto additonal packages won't get removed
# maybe auto remove is a bit too hard
# RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# ENV AUTO_ADDED_PACKAGES $(apt-mark showauto)
# RUN apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES

apt-get remove --purge -y $BUILD_PACKAGES \
  && rm -rf /var/lib/apt/lists/*

# clean up from base
rm -rf $BUILD_ROOT/mapserver-6.0.4
rm -rf $ZOO_BUILD_DIR
# rm -rf $BUILD_ROOT/thirds

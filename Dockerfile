#vim:set ft=dockerfile
###
# A builder image
###
FROM opensuse:latest AS build
LABEL maintainer="Torsten Dreyer <torsten@t3r.de>"
LABEL version="1.0"
LABEL description="FlightGear Scenery Toolbox"


RUN true && \
  zypper --no-gpg-check in -y \
    boost-devel \
    cgal-devel \
    cmake \
    gcc-c++ \
    cgal-devel \
    gdal-devel \
    git \
    libcurl-devel \
    libtiff-devel \
    zlib-devel

RUN useradd --create-home --home-dir=/home/flightgear --shell=/bin/false flightgear
USER flightgear

ARG SGBRANCH=next
ARG SGURL=https://git.code.sf.net/p/flightgear/simgear
ARG TGBRANCH=next
ARG TGURL=https://git.code.sf.net/p/flightgear/terragear

# Build SimGear
WORKDIR /home/flightgear
RUN true \
    && mkdir -p build/simgear \
    && git clone -b ${SGBRANCH} --single-branch ${SGURL} \
    && pushd simgear \
    && git status && git log HEAD^..HEAD \
    && popd \
    && pushd build/simgear \
    && cmake -D CMAKE_BUILD_TYPE=Release -D "CMAKE_CXX_FLAGS=-pipe" -DSIMGEAR_HEADLESS=ON -DENABLE_TESTS=OFF -DENABLE_PKGUTIL=OFF -DENABLE_DNS=OFF -DENABLE_SIMD=OFF -DENABLE_RTI=OFF -DCMAKE_PREFIX_PATH=$HOME/dist -DCMAKE_INSTALL_PREFIX:PATH=$HOME/dist ../../simgear \
    && make -j4 install \
    && popd

#
# Build TerraGear
# double cmake is by intention
RUN true \
    && git clone -b ${TGBRANCH} --single-branch ${TGURL} \
    && pushd terragear \
    && git status && git log HEAD^..HEAD \
    && popd \
    && mkdir -p build/terragear \
    && pushd build/terragear \
    && cmake -D CMAKE_BUILD_TYPE=Release -D "CMAKE_CXX_FLAGS=-pipe -std=c++11" -DCMAKE_PREFIX_PATH=$HOME/dist -D CMAKE_INSTALL_PREFIX:PATH=$HOME/dist ../../terragear  \
    && cmake -D CMAKE_BUILD_TYPE=Release -D "CMAKE_CXX_FLAGS=-pipe -std=c++11" -DCMAKE_PREFIX_PATH=$HOME/dist -D CMAKE_INSTALL_PREFIX:PATH=$HOME/dist ../../terragear  \
    && make -j4 install  \
    && popd
USER root

###
# Now, build the final terragear image
##
FROM opensuse:latest
LABEL maintainer="Torsten Dreyer <torsten@t3r.de>"
LABEL version="1.0"
LABEL description="FlightGear Scenery Toolbox"

RUN true && \
  zypper ar -G http://download.opensuse.org/repositories/Application:/Geo/openSUSE_Leap_42.3/ Geo && \
  zypper in -y \
  libboost_thread1_54_0 \
  libgdal20 \
  gdal \
  libmpfr4 \
  make \
  unzip \
  wget \
  python

RUN ln -s /usr/lib64/libproj.so.9 /usr/lib64/libproj.so.12

RUN groupadd --gid 1000 flightgear && useradd --uid 1000 --gid flightgear --create-home --home-dir=/home/flightgear --shell=/bin/bash flightgear

WORKDIR /home/flightgear
COPY --from=build /home/flightgear/dist/bin/* /usr/local/bin/
COPY --from=build /home/flightgear/dist/share/TerraGear /usr/local/share/TerraGear
COPY --from=build /home/flightgear/dist/lib64/* /usr/lib64/
COPY --from=build /home/flightgear/dist/lib/* /usr/lib64/
COPY --from=build /usr/lib64/libproj.so* /usr/lib64/
COPY --from=build /usr/lib64/libCGAL* /usr/lib64/
COPY --from=build /usr/lib64/libboost_chrono.so.1.54.0 /usr/lib64/
COPY --from=build /usr/lib64/libboost_date_time.so.1.54.0 /usr/lib64/
COPY --from=build /usr/lib64/libboost_atomic.so.1.54.0 /usr/lib64/
#COPY --from=build /home/flightgear/build/terragear/src/Prep/Terra/libTerra.so /usr/lib64/

USER flightgear

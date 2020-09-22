FROM phusion/baseimage:bionic-1.0.0
LABEL maintainer="Tiryoh <tiryoh@gmail.com>"

# Base setup
RUN apt-get update && apt-get install -y \
  sudo \
  build-essential \
  git \
  libgtk-3-dev \
  gcc \
  git \
  wget \
  make \
  libncurses-dev \
  flex \
  bison \
  gperf \
  python \
  python-pip \
  python-setuptools \
  python-serial \
  cmake \
  ninja-build \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

ENV HOME=/root

# Setup ESP32 Environments
WORKDIR $HOME/esp32
ENV IDF_PATH=$HOME/esp32/esp-idf
RUN git config --global http.postBuffer 524288000
RUN git clone -b v3.3.2 --depth=1 --recursive https://github.com/espressif/esp-idf.git
RUN wget https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz \
&& tar -zxvf xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz \
&& rm xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz
RUN python -m pip install --user -r $IDF_PATH/requirements.txt
ENV PATH=$PATH:$HOME/esp32/xtensa-esp32-elf/bin:$IDF_PATH/tools

# Setup Moddable SDK
ENV MODDABLE=$HOME/Projects/moddable
WORKDIR $HOME/Projects
ADD https://api.github.com/repos/Moddable-OpenSource/moddable/git/refs/heads/public moddable-repository.json
RUN git clone --depth=1 https://github.com/Moddable-OpenSource/moddable

# Build toolchain for Linux
WORKDIR $MODDABLE/build/makefiles/lin
ENV PATH=$PATH:$MODDABLE/build/bin/lin/release
RUN make
# Avoid updating icon cache for docker environment
RUN sed -i 's/.*gtk-update-icon-cache/#&/g' \
  ${MODDABLE}/build/makefiles/lin/simulator.mk \
  ${MODDABLE}/build/tmp/lin/release/xsbug/makefile
RUN make install

# If upload port is not detected automatically, Set UPLOAD_PORT.
# ENV UPLOAD_PORT=/dev/ttyUSB0

# Add workspace for mounting
WORKDIR /workspace
RUN mkdir -p $HOME/.config
CMD ["/bin/bash"]

FROM espressif/idf:release-v4.2
LABEL maintainer="Shinya Ishikawa <ishikawa.s.1027@gmail.com>"

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

# Setup Moddable SDK
ENV MODDABLE=$HOME/Projects/moddable
WORKDIR $HOME/Projects
ARG GIT_TAG
RUN git clone --depth=1 -b $GIT_TAG https://github.com/Moddable-OpenSource/moddable && \
    sed -e "s#TOOLS_ROOT ?= \$(HOME)/.espressif#TOOLS_ROOT ?= \$(IDF_TOOLS_PATH)#g" -i moddable/tools/mcconfig/make.esp32.mk

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

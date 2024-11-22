FROM ubuntu:18.04

# Install common dependencies
RUN apt-get -y update && \
    apt-get -y install sudo \
    apt-utils \
    build-essential \
    openssl \
    clang \
    graphviz-dev \
    git \
    libgnutls28-dev

RUN apt-get -y install libc6-dbg glibc-source libasan4-dbg gcc-7-source vim

RUN apt-get -y install sudo apt-utils build-essential openssl clang \
    libgraphviz-dev git libgnutls28-dev ntp libseccomp-dev libtool gettext \
    libssl-dev pkg-config libini-config-dev autoconf \
    linux-tools-common linux-tools-generic linux-cloud-tools-generic llvm tcl \
    efibootmgr python3-pip rustc rust-src cmake

# Add a new user ubuntu, pass: ubuntu
RUN groupadd ubuntu && \
    useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1000 ubuntu -p "$(openssl passwd -1 ubuntu)"

# Use ubuntu as default username
USER ubuntu
WORKDIR /home/ubuntu

# Download and compile AFLNet
ENV LLVM_CONFIG="llvm-config-6.0"

RUN git clone https://github.com/andronat/aflnet && \
    cd aflnet && \
    make clean all && \
    cd llvm_mode && make

# Set up environment variables for AFLNet
ENV AFLNET="/home/ubuntu/aflnet"
ENV PATH="${PATH}:${AFLNET}"
ENV AFL_PATH="${AFLNET}"
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1

# Download and compile LightFTP
RUN cd /home/ubuntu && \
    git clone https://github.com/hfiref0x/LightFTP.git && \
    cd LightFTP && \
    git checkout 5980ea1 && \
    patch -p1 < ${AFLNET}/tutorials/lightftp/5980ea1.patch && \
    cd Source/Release && \
    CC=afl-clang-fast make clean all

# Set up LightFTP for fuzzing
RUN cd /home/ubuntu/LightFTP/Source/Release && \
    cp ${AFLNET}/tutorials/lightftp/fftp.conf ./ && \
    cp ${AFLNET}/tutorials/lightftp/ftpclean.sh ./ && \
    cp -r ${AFLNET}/tutorials/lightftp/certificate ~/ && \
    mkdir ~/ftpshare

RUN cd /home/ubuntu && \
    V="1.0.18" && \
    wget "https://download.libsodium.org/libsodium/releases/libsodium-${V}.tar.gz" && \
    tar xzf "libsodium-${V}.tar.gz" && \
    cd "libsodium-${V}" && \
    ./configure && \
    make && make check && \
    sudo make install

RUN cd /home/ubuntu && \
    git clone https://github.com/zboxfs/zbox-c && \
    cd zbox-c && \
    mkdir -p m4 && \
    ./autogen.sh && \
    ./configure && \
    make && make check && \
    sudo make install

# Download and compile SaBRe
RUN cd /home/ubuntu && \
    git clone --single-branch --branch snapfuzz_2.0 https://github.com/andronat/SaBRe.git && \
    cd SaBRe && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make

# cp ~/snapfuzz/SaBRe/build/sabre .
# cp ~/snapfuzz/SaBRe/build/plugins/sbr-zbox/libsbr-zbox.so .

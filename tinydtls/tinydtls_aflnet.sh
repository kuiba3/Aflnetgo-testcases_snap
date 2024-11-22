
export AFLNET=$PWD/../aflnet

export PATH=$PATH:$AFLNET
export AFL_PATH=$AFLNET
export WORKDIR=$PWD
cd $WORKDIR
rm -rf tinydtls_aflnet
cp -r tinydtls_0 tinydtls_aflnet
#git clone https://github.com/DCMTK/dcmtk.git
cd tinydtls_aflnet/tests



export CC=$AFLNET/afl-clang-fast
export CXX=$AFLNET/afl-clang-fast++


make clean all

cp $AFLNET/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./

timeout 24h afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/tinydtls/handshake_captures/ -o out-tinydtls/ -N udp://127.0.0.1/20220 -P DTLS12 -D 10000 -q 3 -s 3 -E -K -R -W 30 ./dtls-server 2>log.txt

#afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/tinydtls/handshake_captures/ -o out-tinydtls/ -N udp://127.0.0.1/20220 -P DTLS12 -D 10000 -q 3 -s 3 -E -K -R -W 30 ./dtls-server 2>log.txt



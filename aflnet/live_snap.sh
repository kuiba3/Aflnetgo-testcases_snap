export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1"

make -j all && cd llvm_mode/ && make -j && echo $? && cd ..

unset CFLAGS

export AFLNET=$PWD
cd ../live555_1
export TMP_DIR=$PWD/temp
export CC=$AFLNET/afl-clang-fast
export CXX=$AFLNET/afl-clang-fast++

export AFL_USE_ASAN=1

export PATH=$PATH:$AFLNET
export AFL_PATH=$AFLNET

./genMakefiles linux
make clean all
cd testProgs
cp $AFLNET/tutorials/live555/sample_media_sources/*.* ./
#afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/live555/in-rtsp -o out-live555_aflnet -N tcp://127.0.0.1/8554 -x $AFLNET/tutorials/live555/rtsp.dict -P RTSP -D 10000 -q 3 -s 3 -E -K -R -m none ./testOnDemandRTSPServer 8554 2>logtest3.txt


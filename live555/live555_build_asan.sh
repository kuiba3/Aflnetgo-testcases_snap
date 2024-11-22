
export WORKDIR=$PWD/
export AFLNET=$PWD/../aflnet/
#cd /sys/devices/system/cpu
#echo performance | tee cpu*/cpufreq/scaling_governor


export PATH=$PATH:$AFLNET
export AFL_PATH=$AFLNET

cd $WORKDIR
rm -rf live555_asan
cp -r live555_0 live555_asan
#git clone https://github.com/DCMTK/dcmtk.git
cd live555_asan



#git checkout 7f8564c
#patch -p1 < $AFLNET/tutorials/dcmqrscp/7f8564c.patch
#python3 $AFLNET/scripts/State_machine_instrument.py $PWD 



## add target in this
export AFL_USE_ASAN=1
export CC=$AFLNET/afl-clang-fast
export CXX=$AFLNET/afl-clang-fast++

./genMakefiles linux
make clean all

cd testProgs
cp $AFLNET/tutorials/live555/sample_media_sources/*.* ./
cp $AFLNET/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./
#timeout 24h afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/live555/in-rtsp -o out-live555_test -N tcp://127.0.0.1/8553 -x $AFLNET/tutorials/live555/rtsp.dict -P RTSP -D 10000 -q 3 -s 3 -E -K -R ./testOnDemandRTSPServer 8553 2>logtest.txt

if [ -z $1 ];then
	echo "fomat: ./**.sh [temp_path]"
	exit
fi
export WORKDIR=$PWD/
export AFLNET_PLUS=$PWD/../aflnet_go_v5/
#cd /sys/devices/system/cpu
#echo performance | tee cpu*/cpufreq/scaling_governor


export PATH=$PATH:$AFLNET_PLUS
export AFL_PATH=$AFLNET_PLUS

cd $WORKDIR
rm -rf live555_5_$1
cp -r live555_0 live555_5_$1
#git clone https://github.com/DCMTK/dcmtk.git
cd live555_5_$1



#git checkout 7f8564c
#patch -p1 < $AFLNET_PLUS/tutorials/dcmqrscp/7f8564c.patch
#python3 $AFLNET_PLUS/scripts/State_machine_instrument.py $PWD 

mkdir temp
mv state_BBnames.txt temp/state_BBnames.txt
cp -r $WORKDIR/aflnet_plus/$1/temp/* ./temp/
export TMP_DIR=$PWD/temp

## add target in this

export CC=$AFLNET_PLUS/afl-clang-fast
export CXX=$AFLNET_PLUS/afl-clang-fast++

export COPY_CFLAGS=$CFLAGS
export COPY_CXXFLAGS=$CXXFLAGS
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
export CFLAGS="$CFLAGS $ADDITIONAL"
export CXXFLAGS="$CXXFLAGS $ADDITIONAL"
export LDFLAGS="$LDFLAGS $ADDITIONAL"

./genMakefiles linux
make clean all

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLNET_PLUS/scripts/gen_distance_fast.py $WORKDIR/live555_5_$1/testProgs/ $TMP_DIR testOnDemandRTSPServer
export CFLAGS="$COPY_CFLAGS -distance=$TMP_DIR/distance.cfg.txt"
export CXXFLAGS="$COPY_CXXFLAGS -distance=$TMP_DIR/distance.cfg.txt"

make clean all
cd testProgs
cp $AFLNET_PLUS/tutorials/live555/sample_media_sources/*.* ./
cp $AFLNET_PLUS/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET_PLUS/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./
timeout 24h afl-fuzz -A libsnapfuzz.so -z exp -b 15h -d -i $AFLNET_PLUS/tutorials/live555/in-rtsp -o out-live555_test -N tcp://127.0.0.1/$2 -x $AFLNET_PLUS/tutorials/live555/rtsp.dict -P RTSP -D 10000 -q 3 -s 3 -E -K -R ./testOnDemandRTSPServer $2 2>logtest.txt












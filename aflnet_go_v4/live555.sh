export AFLNET_GO=$PWD
cd ../live555
export TMP_DIR=$PWD/temp
export CC=$AFLNET_GO/afl-clang-fast
export CXX=$AFLNET_GO/afl-clang-fast++

export COPY_CFLAGS=$CFLAGS
export COPY_CXXFLAGS=$CXXFLAGS
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
export CFLAGS="$CFLAGS $ADDITIONAL"
export CXXFLAGS="$CXXFLAGS $ADDITIONAL"
export LDFLAGS="$LDFLAGS $ADDITIONAL"

export PATH=$PATH:$AFLNET_GO
export AFL_PATH=$AFLNET_GO

./genMakefiles linux
make clean all
cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLNET_GO/scripts/gen_distance_fast.py /home/txf/live555/testProgs/ $TMP_DIR testOnDemandRTSPServer
export CFLAGS="$COPY_CFLAGS -distance=$TMP_DIR/distance.cfg.txt"
export CXXFLAGS="$COPY_CXXFLAGS -distance=$TMP_DIR/distance.cfg.txt"

make clean all
cd testProgs
cp $AFLNET_GO/tutorials/live555/sample_media_sources/*.* ./
timeout 24h afl-fuzz -z exp -b 15h -d -i $AFLNET_GO/tutorials/live555/in-rtsp -o out-live555_test_3 -N tcp://127.0.0.1/8554 -x $AFLNET_GO/tutorials/live555/rtsp.dict -P RTSP -D 10000 -q 3 -s 3 -E -K -R ./testOnDemandRTSPServer 8554 2>logtest3.txt

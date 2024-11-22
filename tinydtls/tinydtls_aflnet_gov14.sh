if [ -z $1 ];then
	echo "fomat: ./**.sh [temp_path]"
	exit
fi

export WORKDIR=$PWD/
export AFLNET_GO=$PWD/../aflgo_plus


export PATH=$PATH:$AFLNET_GO
export AFL_PATH=$AFLNET_GO


rm -rf tinydtls_1_$1
cp -r tinydtls_0 tinydtls_1_$1

cd tinydtls_1_$1

python3 $WORKDIR/change_tinydtls_port.py $2
python3 $AFLNET_GO/scripts/State_machine_instrument.py $PWD

mkdir temp
mv state_BBnames.txt temp/state_BBnames.txt
cp -r $WORKDIR/aflgo_plus/$1/temp/* ./temp/
export TMP_DIR=$PWD/temp
#echo "rm -rf ACME_STORE/*" > temp/clean.sh
#chmod +x temp/clean.sh
## add target in this

export CC=$AFLNET_GO/afl-clang-fast
export CXX=$AFLNET_GO/afl-clang-fast++

export COPY_CFLAGS=$CFLAGS
export COPY_CXXFLAGS=$CXXFLAGS
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
export CFLAGS="$CFLAGS $ADDITIONAL"
export CXXFLAGS="$CXXFLAGS $ADDITIONAL"


cd tests

make clean all

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLNET_GO/scripts/gen_distance_fast.py $WORKDIR/tinydtls_1_$1/tests/ $TMP_DIR dtls-server
export CFLAGS="$COPY_CFLAGS -distance=$TMP_DIR/distance.cfg.txt"
export CXXFLAGS="$COPY_CXXFLAGS -distance=$TMP_DIR/distance.cfg.txt"

make clean all

cd $WORKDIR/tinydtls_1_$1/tests
 
cp $AFLNET_GO/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET_GO/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./




timeout 24h afl-fuzz -A libsnapfuzz.so -d -i $AFLNET_GO/tutorials/tinydtls/handshake_captures/ -o out-tinydtls/ -N udp://127.0.0.1/$2 -P DTLS12 -D 10000 -q 3 -s 3 -E -K -R -W 30 ./dtls-server  2>log.txt
#afl-fuzz -A libsnapfuzz.so -d -i $AFLNET_GO/tutorials/tinydtls/handshake_captures/ -o out-tinydtls/ -N udp://127.0.0.1/$2 -P DTLS12 -D 10000 -q 3 -s 3 -E -K -R -W 30 ./dtls-server  2>log.txt








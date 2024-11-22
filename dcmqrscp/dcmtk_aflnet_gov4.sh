if [ -z $1 ];then
	echo "fomat: ./**.sh [temp_path]"
	exit
fi

export WORKDIR=$PWD/
export AFLNET_GO=$PWD/../aflnet_go_v4


export PATH=$PATH:$AFLNET_GO
export AFL_PATH=$AFLNET_GO


rm -rf dcmtk_4_$1
cp -r dcmtk_0 dcmtk_4_$1

cd dcmtk_4_$1
mkdir build

python3 $AFLNET_GO/scripts/State_machine_instrument.py $PWD -b $WORKDIR/blocked_variables_dcmtk.txt
python3 $WORKDIR/changecmake.py $AFLNET_GO

mkdir temp
mv state_BBnames.txt temp/state_BBnames.txt
cp -r $WORKDIR/aflnet_go/$1/temp/* ./temp/
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


cd build
cmake ..
make dcmqrscp

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLNET_GO/scripts/gen_distance_fast.py $WORKDIR/dcmtk_4_$1/build/bin/ $TMP_DIR dcmqrscp
export CFLAGS="$COPY_CFLAGS -distance=$TMP_DIR/distance.cfg.txt"
export CXXFLAGS="$COPY_CXXFLAGS -distance=$TMP_DIR/distance.cfg.txt"

make clean
rm -rf *
cmake ..
make dcmqrscp

cd $WORKDIR/dcmtk_4_$1/build/bin
mkdir ACME_STORE 
cp $AFLNET_GO/tutorials/dcmqrscp/dcmqrscp.cfg ./
cp $AFLNET_GO/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET_GO/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./


python3 $WORKDIR/change_dcmqrscp_cfg.py $WORKDIR $2
cd ../../
export DCMDICTPATH=$PWD/dcmdata/data/dicom.dic
cd ./build/bin

timeout 24h afl-fuzz -A libsnapfuzz.so -z exp -b 15h -d -i $AFLNET_GO/tutorials/dcmqrscp/in-dicom -o out-dicom_test -N tcp://127.0.0.1/$2 -P DICOM -D 10000 -E -K -R  -m 1000 ./dcmqrscp 2>logtest.txt
#afl-fuzz -A libsnapfuzz.so -z exp -b 15h -d -i $AFLNET_GO/tutorials/dcmqrscp/in-dicom -o out-dicom_test -N tcp://127.0.0.1/5158 -P DICOM -D 10000 -E -K -R  -m 1000 ./dcmqrscp 2>logtest.txt



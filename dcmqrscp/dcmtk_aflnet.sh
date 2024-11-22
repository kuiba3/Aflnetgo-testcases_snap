
export AFLNET=$PWD/../aflnet

export PATH=$PATH:$AFLNET
export AFL_PATH=$AFLNET
export WORKDIR=$PWD
cd $WORKDIR
rm -rf dcmtk_aflnet
cp -r dcmtk_0 dcmtk_aflnet
#git clone https://github.com/DCMTK/dcmtk.git
cd dcmtk_aflnet
mkdir build
#git checkout 7f8564c
#patch -p1 < $AFLNET/tutorials/dcmqrscp/7f8564c.patch

python3 $WORKDIR/changecmake.py $AFLNET 5157

mkdir temp

export TMP_DIR=$PWD/temp
echo "rm -rf ACME_STORE/*" > temp/clean.sh
chmod +x temp/clean.sh
## add target in this

export CC=$AFLNET/afl-clang-fast
export CXX=$AFLNET/afl-clang-fast++



cd build
cmake ..
make dcmqrscp


cd $WORKDIR/dcmtk_aflnet/build/bin
mkdir ACME_STORE
cp $AFLNET/tutorials/dcmqrscp/dcmqrscp.cfg ./
cp $AFLNET/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./

python3 $WORKDIR/change_dcmqrscp_cfg.py $WORKDIR
cd ../../
export DCMDICTPATH=$PWD/dcmdata/data/dicom.dic
cd ./build/bin

#timeout 24h afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/dcmqrscp/in-dicom -o out-dicom_test -N tcp://127.0.0.1/5157 -P DICOM -D 10000 -E -K -R -c $TMP_DIR/clean.sh -m 1000 ./dcmqrscp 2>logtest.txt

afl-fuzz -A libsnapfuzz.so -d -i $AFLNET/tutorials/dcmqrscp/in-dicom -o out-dicom_test -N tcp://127.0.0.1/5157 -P DICOM -D 10000 -E -K -R -c $TMP_DIR/clean.sh -m 1000 ./dcmqrscp 2>logtest.txt

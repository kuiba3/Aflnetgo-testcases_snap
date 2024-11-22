if [ -z $1 ];then
	echo "fomat: ./**.sh [temp_path]"
	exit
fi
export WORKDIR=$PWD/
export AFLNET_GO=$PWD/../aflnet_go_v4

export PATH=$PATH:$AFLNET_GO
export AFL_PATH=$AFLNET_GO


rm -rf lightftp_4_$1
cp -r lightftp_0 lightftp_4_$1

cd lightftp_4_$1/Source



mkdir temp
mv state_BBnames.txt temp/state_BBnames.txt
cp -r $WORKDIR/aflnet_go/$1/temp/* ./temp/

export TMP_DIR=$PWD/temp

cd Release

export CC=$AFLNET_GO/afl-clang-fast
export CXX=$AFLNET_GO/afl-clang-fast++

export COPY_CFLAGS=$CFLAGS
export COPY_CXXFLAGS=$CXXFLAGS
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
export CFLAGS="$CFLAGS $ADDITIONAL"
export CXXFLAGS="$CXXFLAGS $ADDITIONAL"

make clean all

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLNET_GO/scripts/gen_distance_fast.py $WORKDIR/lightftp_4_$1/Source/Release/ $TMP_DIR fftp
export CFLAGS="$COPY_CFLAGS -distance=$TMP_DIR/distance.cfg.txt"
export CXXFLAGS="$COPY_CXXFLAGS -distance=$TMP_DIR/distance.cfg.txt"

make clean all


cp $AFLNET_GO/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET_GO/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./
cp $AFLNET_GO/tutorials/lightftp/ftpclean.sh ./
cp $AFLNET_GO/tutorials/lightftp/fftp.conf ./
cp -r $AFLNET_GO/tutorials/lightftp/certificate ~/
mkdir ftpshare
chmod 777 ./ftpshare

python3 $WORKDIR/change_fftp_cfg.py ~ $2


timeout 24h afl-fuzz -A libsnapfuzz.so -d -m 512 -i $AFLNET_GO/tutorials/lightftp/in-ftp -o out-lightftp -N tcp://127.0.0.1/$2 -x $AFLNET_GO/tutorials/lightftp/ftp.dict -P FTP -D 10000 -q 3 -s 3 -E -R ./fftp fftp.conf $2 2>logest.txt





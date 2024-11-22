
export AFLNET=$PWD/../aflnet

export PATH=$PATH:$AFLNET
export AFL_PATH=$AFLNET
export WORKDIR=$PWD
cd $WORKDIR
rm -rf lightftp_aflnet
cp -r lightftp_0 lightftp_aflnet
#git clone https://github.com/DCMTK/dcmtk.git
cd lightftp_aflnet/Source/Release



export CC=$AFLNET/afl-clang-fast
export CXX=$AFLNET/afl-clang-fast++


make clean all

cp $AFLNET/SnapFuzz/SaBRe/build/sabre ./
cp $AFLNET/SnapFuzz/SaBRe/build/plugins/snapfuzz/libsnapfuzz.so ./
cp $AFLNET/tutorials/lightftp/ftpclean.sh ./
cp $AFLNET/tutorials/lightftp/fftp.conf ./
cp -r $AFLNET/tutorials/lightftp/certificate ~/
mkdir ftpshare
chmod 777 ./ftpshare

python3 $WORKDIR/change_fftp_cfg.py ~ 2200


#-m 512 -t 5000 -i ./conf/in-ftp -x ./conf/ftp.dict -P FTP -c ./conf/ftpclean.sh -q 3 -s 3 -E -R
#afl-fuzz -A libsnapfuzz.so -d -m 512 -i $AFLNET/tutorials/lightftp/in-ftp -o out-lightftp -N tcp://127.0.0.1/2200 -x $AFLNET/tutorials/lightftp/ftp.dict -P FTP -D 10000 -q 3 -s 3 -E -R ./fftp fftp.conf 2200

timeout 24h  afl-fuzz -A libsnapfuzz.so -d -m 512 -i $AFLNET/tutorials/lightftp/in-ftp -o out-lightftp -N tcp://127.0.0.1/2200 -x $AFLNET/tutorials/lightftp/ftp.dict -P FTP -D 10000 -q 3 -s 3 -E -R -c ./ftpclean.sh ./fftp fftp.conf 2200 2>logest.txt



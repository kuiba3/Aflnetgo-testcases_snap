export WORKDIR=$PWD
export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1" 
cd aflnet_go_v3
make clean all && cd llvm_mode && make clean all && cd ../distance_calculator/ && cmake -G Ninja ./ && cmake --build ./
cd ..
unset CFLAGS

cd SnapFuzz 
cd SaBRe/plugins
ln -s ../../snapfuzz snapfuzz 
cd .. 
mkdir build
cd build 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=ON .. 
make -j

cd $WORKDIR
export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1" 
cd aflgo_plus
make clean all && cd llvm_mode && make clean all && cd ../distance_calculator/ && \
	cmake -G Ninja ./ && cmake --build ./
cd ..
unset CFLAGS

cd SnapFuzz 
cd SaBRe/plugins
ln -s ../../snapfuzz snapfuzz 
cd .. 
mkdir build
cd build 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=ON .. 
make -j


cd $WORKDIR
export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1" 
cd aflnet_go_v4
make clean all && cd llvm_mode && make clean all && cd ../distance_calculator/ && \
	cmake -G Ninja ./ && cmake --build ./
cd ..
unset CFLAGS

cd SnapFuzz 
cd SaBRe/plugins
ln -s ../../snapfuzz snapfuzz 
cd .. 
mkdir build
cd build 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=ON .. 
make -j

cd $WORKDIR
export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1" 
cd aflnet_go_v5
make clean all && cd llvm_mode && make clean all && cd ../distance_calculator/ && \
	cmake -G Ninja ./ && cmake --build ./
cd ..
unset CFLAGS

cd SnapFuzz 
cd SaBRe/plugins
ln -s ../../snapfuzz snapfuzz 
cd .. 
mkdir build
cd build 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=ON .. 
make -j


cd $WORKDIR
export CFLAGS="-O3 -funroll-loops -DNOAFFIN_BENCH=1 -DLONG_BENCH=1" 
cd aflnet
make clean all && cd llvm_mode && make clean all
cd ..
unset CFLAGS

cd SnapFuzz 
cd SaBRe/plugins
ln -s ../../snapfuzz snapfuzz 
cd .. 
mkdir build
cd build 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=ON .. 
make -j

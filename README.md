## 实验环境
**Ubuntu 18.0
llvm11.0.0
g++10
cmake（>=3.13.4）**

环境建立：
```
LLVM_DEP_PACKAGES="build-essential make cmake ninja-build git binutils-gold binutils-dev curl wget"
sudo apt install -y $LLVM_DEP_PACKAGES

UBUNTU_VERSION='cat /etc/os-release | grep VERSION_ID | cut -d= -f 2'
UBUNTU_YEAR=`echo $UBUNTU_VERSION | cut -d. -f 1`
UBUNTU_MONTH=`echo $UBUNTU_VERSION | cut -d. -f 2`


if [[ "$UBUNTU_YEAR" > "16" || "$UBUNTU_MONTH" > "04" ]]
then
    sudo apt install -y python3-distutils
fi

export CXX=g++
export CC=gcc
unset CFLAGS
unset CXXFLAGS

mkdir ~/build; cd ~/build
mkdir llvm_tools; cd llvm_tools
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-11.0.0.src.tar.xz
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/clang-11.0.0.src.tar.xz
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/compiler-rt-11.0.0.src.tar.xz
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/libcxx-11.0.0.src.tar.xz
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/libcxxabi-11.0.0.src.tar.xz

tar xf llvm-11.0.0.src.tar.xz
tar xf clang-11.0.0.src.tar.xz
tar xf compiler-rt-11.0.0.src.tar.xz
tar xf libcxx-11.0.0.src.tar.xz
tar xf libcxxabi-11.0.0.src.tar.xz
mv clang-11.0.0.src ~/build/llvm_tools/llvm-11.0.0.src/tools/clang
mv compiler-rt-11.0.0.src ~/build/llvm_tools/llvm-11.0.0.src/projects/compiler-rt
mv libcxx-11.0.0.src ~/build/llvm_tools/llvm-11.0.0.src/projects/libcxx
mv libcxxabi-11.0.0.src ~/build/llvm_tools/llvm-11.0.0.src/projects/libcxxabi

mkdir -p build-llvm/llvm; cd build-llvm/llvm
cmake -G "Ninja" \
      -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" \
      -DLLVM_BINUTILS_INCDIR=/usr/include ~/build/llvm_tools/llvm-11.0.0.src
ninja 
sudo ninja install

cd ~/build/llvm_tools
mkdir -p build-llvm/msan; cd build-llvm/msan
cmake -G "Ninja" \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DLLVM_USE_SANITIZER=Memory -DCMAKE_INSTALL_PREFIX=/usr/msan/ \
      -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" \
       ~/build/llvm_tools/llvm-11.0.0.src
ninja cxx
sudo ninja install-cxx

mkdir -p /usr/lib/bfd-plugins
sudo cp /usr/local/lib/libLTO.so /usr/lib/bfd-plugins
sudo cp /usr/local/lib/LLVMgold.so /usr/lib/bfd-plugins


export LC_ALL=C
sudo apt update
sudo apt install -y python-dev python3 python3-dev python3-pip autoconf automake libtool-bin python-bs4 libboost-all-dev # libclang-11.0-dev
python3 -m pip install --upgrade pip
python3 -m pip install networkx pydot pydotplus


sudo apt-get install libcap-dev libgraphviz-dev
```


## 编译模糊测试器
```
./build.sh
```

## 测试
### 测试的目标软件有：
- live555
- dcmqrscp
- lightftp
- tinydtls

可以参考run_<package>.sh中的脚本。
如run_live555.sh中的
```
./live555_aflnet_gov5.sh 1 8634
```
其中 1 对应的是testcases_snap/live555/aflnet_go/1/temp/BBtargets.txt
8634 对应的是端口号，可以随便设置空闲的端口号


可以使用
```
afl-fuzz
```

来查看参数使用

## 参考的资料
AFLNET：**[https://github.com/aflnet/aflnet](https://github.com/aflnet/aflnet)**
AFLGo:**[https://github.com/aflgo/aflgo](https://github.com/aflgo/aflgo)**
SnapFuzz:**[https://github.com/srg-imperial/SnapFuzz](https://github.com/srg-imperial/SnapFuzz)**
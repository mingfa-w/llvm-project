# This is a script to help install LLVM 11.0.1
current_dir=$(cd $(dirname $0); pwd)
export rebuild=$1 # 0-重新编译llvm-project
TARGET_ARCH=`uname -m`
LLVM_MAJ_VER=main

# llvm-project path
llvm_src_dir=${current_dir}/..
llvm_build_dir=${current_dir}/build/llvm-$LLVM_MAJ_VER-$TARGET_ARCH
llvm_install_dir=${HOME}/.local/llvm-$LLVM_MAJ_VER-$TARGET_ARCH
llvm_dir=${llvm_install_dir}/lib/cmake/llvm

# if [ ! -d "$llvm_src_dir" ]; then
#     cd "$llvm_src_dir"
#     # git clone https://github.com/llvm/llvm-project
#     git clone --depth 1 -b release/12.x git@code.byted.org:flowcompiler-toolchain/llvm-project.git
# fi

function build_llvm(){
    # 如果参数为0，则删除build目录，重新生成makefile，再编译
    if [ ! -z $rebuild ] && [ $rebuild == 0 ]; then
        echo ==== restrat to build llvm-project, please input: y/n ====
        # read input
        input='y'
        echo =========input: $input =======
        if [ $input == 'y' ]; then
            echo ========= remove ${llvm_build_dir} =======
            rm -rf ${llvm_build_dir} ${llvm_install_dir}
        fi
    fi

    if [ ! -d ${llvm_build_dir} ]; then
        mkdir -p ${llvm_build_dir}
        mkdir -p ${llvm_install_dir}

        LLVM_OPTS=" -DLLVM_OPTIMIZED_TABLEGEN=ON \
                    -DLLVM_USE_SPLIT_DWARF=ON \
                    -DLLVM_PARALLEL_LINK_JOBS=8 \
                    -DLLVM_CCACHE_BUILD=ON \
                    -DLLVM_INSTALL_UTILS=ON \
                    -DLLDB_INCLUDE_TESTS=OFF \
                  "
        # LLVM_PROJ=" -DLLVM_ENABLE_PROJECTS="clang\;lld\;lldb\;compiler-rt\;mlir\;clang-tools-extra" \
        LLVM_PROJ=" -DLLVM_ENABLE_PROJECTS="clang\;mlir" \
                    -DLLVM_TARGETS_TO_BUILD="Native\;NVPTX\;AMDGPU" \
                    -DLLVM_ENABLE_RTTI=ON \
                  "
        LLVM_TOOLS=" -DCMAKE_C_COMPILER="clang" \
                    -DCMAKE_CXX_COMPILER="clang++" \
                    -DLLVM_USE_LINKER="lld" \
                  "

        cmake -G Ninja -S ${llvm_src_dir}/llvm -B ${llvm_build_dir} \
                -DCMAKE_OSX_ARCHITECTURES=$TARGET_ARCH \
                -DCMAKE_BUILD_TYPE="Debug" \
                -DCMAKE_CXX_STANDARD=17 \
                -DCMAKE_INSTALL_PREFIX=${llvm_install_dir} \
                ${LLVM_OPTS} \
                ${LLVM_PROJ} \
                ${LLVM_TOOLS}
    fi
    #ninja -C $build_llvm -j $(nproc)
    ninja -C ${llvm_build_dir} -j $(nproc) install
}

build_llvm

echo "Please add the follwing environment variables"
echo "export LLVM_INS_DIR=$llvm_install_dir"
echo "export LLVM_DIR=$llvm_dir"
echo "export PATH=\$LLVM_INS_DIR/bin:\$PATH"
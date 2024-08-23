CUDA_TOOLKIT_ROOT_DIR="${CUDA_TOOLKIT_ROOT_DIR:-/usr/local/cuda-11.2}"
CUDA_ROOT_DIR="${CUDA_ROOT_DIR:-/usr/local/cuda-11.2}"
export CC=/usr/bin/gcc-8
export CXX=/usr/bin/g++-8
cp /usr/include/crypt.h /opt/conda/envs/ismrmmocoworkshop/include/crypt.h
if [ -d "optox" ]; then
  rm -rf optox
fi
git clone https://github.com/midas-tum/optox.git
cd optox || exit
mkdir -p build
cd build || exit
cmake .. -DWITH_PYTHON=ON -DWITH_PYTORCH=ON -DWITH_TENSORFLOW=ON -DCUDA_ROOT=$CUDA_ROOT_DIR
make install


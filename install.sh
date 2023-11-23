#!/bin/bash

# environment variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CUDA_ROOT_DIR="${CUDA_ROOT_DIR:-/usr/local/cuda}"

echo "CUDA is installed in: " $CUDA_ROOT_DIR
export CUDA_ROOT_DIR=$CUDA_ROOT_DIR
export LDFLAGS=-L$CUDA_ROOT_DIR/lib64

USE_OPTOX=false

# Start setup
read -p "Create new conda env (y/n)? " CONT

if [ "$CONT" == "n" ]; then
  echo "Activate conda environemnt: conda activate ismrmmocoworkshop"
else
  # user chooses to create conda env
  # prompt user for conda env name
  read -p "Creating new conda environment, choose name [ismrmmocoworkshop]: " input_variable
  input_variable=${input_variable:-ismrmmocoworkshop}
  echo "Name $input_variable was chosen"

  echo "installing base packages"
  conda create --name $input_variable \
  python=3.8 jupyter notebook numpy \
  pandas scipy numpy scikit-learn

  eval "$(conda shell.bash hook)"
  conda activate $input_variable
  export CUDA_ROOT_DIR=$CUDA_ROOT_DIR
  export LDFLAGS=-L$CUDA_ROOT_DIR/lib64
  cp -r $SCRIPT_DIR/utils/* $SCRIPT_DIR
  # Python packages
  pip install --upgrade pip
  pip install -r requirements.txt
  pip install simpleitk medutils-mri python-pysap scikit-image voxelmorph
  git clone https://github.com/voxelmorph/voxelmorph.git

  # ESPIRIT
  git clone https://github.com/mikgroup/espirit-python.git
  cp $SCRIPT_DIR/espirit-python/espirit.py .

  # GPUNUFFT
  cd $SCRIPT_DIR
  git clone --branch cuda_streams https://github.com/khammernik/gpuNUFFT.git
  mkdir -p gpuNUFFT/CUDA/build
  cd gpuNUFFT/CUDA/build
  cmake .. -DGEN_MEX_FILES=OFF
  make
  apt install libnfft3-dev
  pip install gpuNUFFT pynfft2

  # Optox
  if [ "$USE_OPTOX" = true ] ; then
    cd $SCRIPT_DIR
    git clone https://github.com/midas-tum/optox.git
    export GPUNUFFT_ROOT_DIR=$SCRIPT_DIR/gpuNUFFT
    cd $SCRIPT_DIR/optox
    pip install -r requirements.txt
    mkdir -p $SCRIPT_DIR/optox/build
    cd $SCRIPT_DIR/optox/build
    cmake .. -DWITH_PYTHON=ON -DWITH_PYTORCH=OFF -DWITH_TENSORFLOW=ON -DCUDA_ROOT=$CUDA_ROOT_DIR
    make install
  fi

  # MERLIN
  cd $SCRIPT_DIR
  git clone https://github.com/midas-tum/merlin.git
  cd merlin/python
  python ./setup.py build
  cd ..
  pip install ./python
  pip install ./pytorch
  pip install ./tensorflow

  # BART
  # Install BARTs dependencies
  apt-get install -y make gcc libfftw3-dev liblapacke-dev libpng-dev libopenblas-dev &> /dev/null

  # Install additional dependencies for converting ISMRMRD files
  apt-get install -y libismrmrd-dev libboost-all-dev libhdf5-serial-dev &> /dev/null

  cd $SCRIPT_DIR
  [ -d bart ] && rm -r bart
  git clone https://github.com/mrirecon/bart/ bart &> /dev/null

  cd bart

  # Define compile options
  COMPILE_SPECS=" PARALLEL=1
                  CUDA=1
                  NON_DETERMINISTIC=1
                  ISMRMRD=1
                  "

  printf "%s\n" $COMPILE_SPECS > Makefiles/Makefile.local

  # set path to cuda for Colab
  echo "CUDA_BASE=$CUDA_ROOT_DIR" >> Makefiles/Makefile.local
  echo "CUDA_LIB=lib64" >> Makefiles/Makefile.local

  make &> /dev/null

  echo "=== Installation finished! ===="
fi

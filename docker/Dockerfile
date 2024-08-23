FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

ARG http_proxy
ARG https_proxy
ARG no_proxy
ENV http_proxy "$http_proxy"
ENV https_proxy "$https_proxy"
ENV no_proxy "$no_proxy"


# Set environment variables to avoid timezone prompt
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Update and install required packages
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        git cmake g++ gcc \
        libhdf5-dev libxml2-dev libxslt1-dev g++-10 gcc-10 \
        libboost-all-dev libfftw3-dev libcrypt-dev libc6-dev-i386 \
        make liblapacke-dev libpng-dev libopenblas-dev gfortran wget nano dos2unix libnfft3-dev && \
    mkdir -p /opt/code
#RUN --mount=type=cache,target=/root/.cache/wget \
 #   wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh && \
  #  bash /miniconda.sh -b -p /opt/conda && \
   # rm /miniconda.sh

COPY Miniconda3-latest-Linux-x86_64.sh /miniconda.sh

RUN bash /miniconda.sh -b -p /opt/conda && rm /miniconda.sh

# Set environment variables for Miniconda
ENV PATH=/opt/conda/bin:$PATH

# Set environment variables for CUDA
ENV PATH=/usr/local/cuda-11.2/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.2/lib64:$LD_LIBRARY_PATH

# Create code directory
RUN mkdir -p /opt/code

# Conda environment
WORKDIR /root
COPY ismrmmocoworkshop.yml ./
COPY requirements_optox.txt ./
COPY optox.sh ./

# Disable SSL verification for conda
RUN conda config --set ssl_verify false

	
# Update conda and create the environment
RUN --mount=type=cache,target=/opt/conda/pkgs conda update conda -y
RUN --mount=type=cache,target=/opt/conda/pkgs conda env create -f ismrmmocoworkshop.yml

# Initialize Conda for bash and activate the conda environment
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    conda init bash

RUN git clone https://github.com/lab-midas/ismrm-moco-workshop.git /workspace
# Set the working directory
WORKDIR /workspace


ENV CUDA_ROOT_DIR=/usr/local/cuda-11.2
ENV CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-11.2
ENV LDFLAGS=-L/usr/local/cuda-11.2/lib64
ENV CXXFLAGS="-I/usr/include -I/opt/conda/envs/ismrmmocoworkshop/include"

# Clone the repositories and perform operations with caching for git and copy operations


RUN git clone https://github.com/voxelmorph/voxelmorph.git && \
    git clone https://github.com/mikgroup/espirit-python.git && \
    cp /workspace/espirit-python/espirit.py /workspace && \
    git clone https://github.com/mrirecon/bart.git /workspace/bart && \
    git clone --branch cuda_streams https://github.com/khammernik/gpuNUFFT.git && \
    mkdir -p /workspace/gpuNUFFT/CUDA/build

# Set up for building gpuNUFFT
WORKDIR /workspace/gpuNUFFT/CUDA/build

# Install dependencies and build with caching of CMake and make steps
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    cmake .. -DGEN_MEX_FILES=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$CXXFLAGS -I/opt/conda/envs/ismrmmocoworkshop/include" -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_TOOLKIT_ROOT_DIR && \
    cmake --debug-output --trace-expand . > cmake_debug.log && \
    make && \
    cat cmake_debug.log

# Install Python packages with caching for pip
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    pip install gpuNUFFT 

# Install and set up Optox if specified, with appropriate caching
RUN cp /usr/include/crypt.h /opt/conda/envs/ismrmmocoworkshop/include/crypt.h
ARG USE_OPTOX=false
ENV CUDA_BIN_PATH = "-I/opt/conda/envs/ismrmmocoworkshop/bin"
ENV CC=/usr/bin/gcc-9
ENV CXX=/usr/bin/g++-9
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    if [ "$USE_OPTOX" = "true" ]; then \
        git clone https://github.com/midas-tum/optox.git /workspace/optox && \
        cd /workspace/optox && \
        mkdir -p /workspace/optox/build && \
        cd /workspace/optox/build && \
        cmake .. -DCMAKE_C_COMPILER=/usr/bin/gcc-9 -DCMAKE_CXX_COMPILER=/usr/bin/g++-9 -DWITH_PYTHON=ON -DWITH_PYTORCH=OFF -DWITH_TENSORFLOW=ON -DCUDA_ROOT=$CUDA_ROOT_DIR && \
        make install; \
    fi

WORKDIR /workspace	
	
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    conda install -c conda-forge pynfft micromamba
	
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    pip install pysap-mri==0.4.0 modopt

WORKDIR /workspace
# Install merlin python packages
RUN git clone https://github.com/midas-tum/merlin.git
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    cd /workspace/merlin/python && \
    python setup.py build
	
WORKDIR /workspace
# Install merlin python packages
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    pip install /workspace/merlin/python && \
    pip install /workspace/merlin/pytorch && \
    pip install /workspace/merlin/tensorflow

	
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ismrmmocoworkshop && \
    CC=/usr/bin/gcc-10 CXX=/usr/bin/g++-10 pip install --upgrade --upgrade-strategy=only-if-needed python-pysap
	
# Set the working directory to /workspace
WORKDIR /workspace
# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "ismrmmocoworkshop", "/bin/bash", "-c"]

# Expose the Jupyter notebook port
# EXPOSE 8888

# Start Jupyter notebook
# CMD [ "bash", "-c", "source activate ismrmmocoworkshop && jupyter notebook --ip=0.0.0.0 --no-browser --allow-root" ]

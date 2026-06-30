FROM nvidia/cuda:11.6.1-devel-ubuntu20.04 AS build

#directories
ENV colmap_mount_dir=/mnt/col
ARG conda_install_dir_d=/opt/miniconda3

# based off your GPU (8.6=RTX 3060TI)
ENV TORCH_CUDA_ARCH_LIST="8.6"


ENV conda_install_dir=${conda_install_dir_d}

# install packages
RUN export DEBIAN_FRONTEND=noninteractive && \
	export DEBCONF_NONINTERACTIVE_SEEN=true && \
	apt-get update && apt-get install -y \
    wget libgl1 libglib2.0-0 libtiff5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# install conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O conda.sh && \
	echo -e "\nyes\n${conda_install_dir_d}\n\n" | \
		bash ./conda.sh && \
	rm conda.sh


FROM build as dev

WORKDIR /mnt/gaussian-splatting
RUN eval "$($conda_install_dir/bin/conda shell.bash hook)" && \
	bash

# docker build --target dev -t gaussian-splatting .
# docker container run -it --name gaussian-splatting --gpus all --volume /mnt/i/FIT/MyStuff/Jason-1_LEO_VBAR_dx10.00_tumble5_ecl_brdf:/mnt/col gaussian-splatting --volume /mnt/i/projects/NETs/stamparkour/gaussian-splatting:/mnt/gaussian-splatting gaussian-splatting-dev

FROM build as main

# install gaussian splatting
WORKDIR /opt/gaussian-splatting
COPY . .


RUN eval "$($conda_install_dir/bin/conda shell.bash hook)" && \
	conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
	conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
	conda env create --file environment.yml

# run gaussian splatting
CMD eval "$($conda_install_dir/bin/conda shell.bash hook)" && \
	conda activate gaussian_splatting && \
	python train.py -s $colmap_mount_dir -m $colmap_mount_dir/gaussian-splatting

# docker build --target main -t gaussian-splatting .
# docker container run -it --name gaussian-splatting --gpus all --volume /mnt/i/FIT/MyStuff/Jason-1_LEO_VBAR_dx10.00_tumble5_ecl_brdf:/mnt/col gaussian-splatting
FROM ubuntu:22.04 

ARG L4T_RELEASE="36"
ARG L4T_VERSION="5.0"

ENV BSP_PACKAGE="Jetson_Linux_r${L4T_RELEASE}.${L4T_VERSION}_aarch64.tbz2"
ENV ROOTFS_PACKAGE="Tegra_Linux_Sample-Root-Filesystem_r${L4T_RELEASE}.${L4T_VERSION}_aarch64.tbz2"
ENV DOWNLOAD_BASE="https://developer.nvidia.com/downloads/embedded/l4t/r${L4T_RELEASE}_release_v${L4T_VERSION}/release"

RUN apt update && apt upgrade -y
RUN apt install -y wget lbzip2 sudo fakeroot qemu-user-static
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Attention: make sure both the bsp and rootfs are the same version!
# See https://developer.nvidia.com/embedded/jetson-linux-archive
RUN wget -q ${DOWNLOAD_BASE}/${BSP_PACKAGE}
RUN wget -q ${DOWNLOAD_BASE}/${ROOTFS_PACKAGE}

# Here, we assemble the rootfs, according to 
# https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/IN/QuickStart.html#to-flash-the-jetson-developer-kit-operating-software
RUN tar xf ${BSP_PACKAGE}
RUN sudo tar xpf ${ROOTFS_PACKAGE} -C Linux_for_Tegra/rootfs/
RUN sudo Linux_for_Tegra/tools/l4t_flash_prerequisites.sh
RUN sudo Linux_for_Tegra/apply_binaries.sh


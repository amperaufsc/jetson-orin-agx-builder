FROM ubuntu:22.04

ENV L4T_DOWNLOAD_BASE_URL=https://developer.nvidia.com/downloads/embedded/l4t
ENV L4T_VERSION=r36.5.0
ENV L4T_RELEASE_PACKAGE=Jetson_Linux_${L4T_VERSION}_aarch64.tbz2
ENV SAMPLE_FS_PACKAGE=Tegra_Linux_Sample-Root-Filesystem_${L4T_VERSION}_aarch64.tbz2
ENV BOARD=jetson-agx-orin-devkit

RUN apt update && apt upgrade -y
RUN apt install -y wget lbzip2 sudo fakeroot qemu-user-static
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Attention: make sure both the bsp and rootfs are the same version!
# See https://developer.nvidia.com/embedded/jetson-linux-archive
RUN wget -q ${L4T_DOWNLOAD_BASE_URL}/r36_release_v5.0/release/${L4T_RELEASE_PACKAGE}
RUN wget -q ${L4T_DOWNLOAD_BASE_URL}/r36_release_v5.0/release/${SAMPLE_FS_PACKAGE}

# Here, we assemble the rootfs, according to https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/IN/QuickStart.html#to-flash-the-jetson-developer-kit-operating-software
RUN tar xf ${L4T_RELEASE_PACKAGE}
RUN sudo tar xpf ${SAMPLE_FS_PACKAGE} -C Linux_for_Tegra/rootfs/
RUN sudo Linux_for_Tegra/tools/l4t_flash_prerequisites.sh
RUN sudo Linux_for_Tegra/apply_binaries.sh


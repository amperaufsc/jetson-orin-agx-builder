#!/usr/bin/env bash
set -euo pipefail

echo "==> Purgin snap"
sudo systemctl stop snapd
sudo apt purge -y snapd
sudo rm -rf /var/cache/snapd/ ~/snap
sudo apt-mark hold snapd

echo "==> Updating apt sources"
sudo apt update

echo "==> Installing JetPack + terminator"
sudo apt-get install -y nvidia-jetpack terminator

echo "==> Installing uv"
wget -qO- https://astral.sh/uv/install.sh | sh

echo "==> Setting up ROS 2 (Humble) apt source"
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update
sudo apt install -y curl

ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
    | grep -F "tag_name" | awk -F'"' '{print $4}')

curl -L -o /tmp/ros2-apt-source.deb \
    "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb

echo "==> Installing ROS 2 Humble Desktop"
sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-humble-desktop

echo "==> Installing Firefox"
sudo apt install -y firefox

echo "==> Setting up VS Code apt source"
sudo apt install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

echo "==> Installing VS Code"
sudo apt update
sudo apt install -y code

echo "==> Setup complete"

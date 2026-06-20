# jetson-orin-agx-builder

Scripts to build, flash and setup Linux for the Jetson Orin Agx.

## Requirements

- [Docker Engine](https://docs.docker.com/engine/) (with root access!)

## Building

As the scripts provided by Nvidia [chroot](https://wiki.archlinux.org/title/Chroot) into the Jetson's rootfs to run commands and Jetson's CPU architecture is arm64, if you're not on an arm host you'll need to register a static qemu entry to emulate the arm architecture. Fortunately, there is a convenient Docker available that does that registering for us.

```bash
$ sudo docker run --rm --privileged tonistiigi/binfmt --install linux/arm64
```

This image must be build with sudo, otherwise it fails to register the binary format file correctly under `/proc/sys/fs/binfmt_misc/`. Verify you have a `qemu-aarch64` file under `binfmt_misc/` before proceeding.

Now we can build the Docker image that will prepare the Jetson's rootfs.

```bash
$ sudo docker buildx build --platform linux/arm64 -t jetson-builder .
```

You can see your Docker images with `$ sudo docker images`. Beware, for rootless Docker, running `$ docker images` without sudo only shows the images also built without sudo.

## Flashing

The flashing process reboots the Jetson multiple times via the connected USB. Because of that, the host machine's (your computer) kernel might trigger the power autosuspend feature for the port you're using, disrupting the flashing process.

To prevent that, we can set an [`udev`](https://wiki.archlinux.org/title/Udev) rule to automatically disable the autosuspend feature for the USB port being used everytime the Jetson is connected to that port in recovery mode.

```bash
sudo tee /etc/udev/rules.d/99-nvidia-jetson.rules << 'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="0955", ATTR{idProduct}=="7023", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
```

Now, we need to put the Jetson in recovery mode.

1. Turn off the device.
2. Press and hold the Recovery button.
3. Press and release the Power button.
4. Wait 2 seconds and release the Recovery button.
5. Connect a USB cable between a USB port of your machine and the Jetson's USB-C port besides the 40-pin connector.

Check if the autosuspend feature has been diabled after connecting the Jetson (in recovery mode) to your machine:

```bash
$ cat /sys/bus/usb/devices/$(lsusb -d 0955:7023 | awk '{print $2"/"$4}' | tr -d :)/power/autosuspend # must show: -1
```

Check if the device is visible:

```bash
$ lsusb | grep NVIDIA  # must show: NVIDIA Corp. APX
```

It is recommended you use an USB 3.0 (or faster) cable and port. On USB 3.0, the flashing process took me about 12 minutes.

```bash
$ dmesg | grep -i usb | tail -5 # must show: high-speed
```

If it shows `full-speed`, change the cable or the port on your machine until you find `high-speed` port. This is not necessary, but is recommended.

With the Jetson successfully connected in recovery mode, you can flash it with the following command:

```bash
$ sudo docker run --rm -it --privileged \
    -v /dev:/dev \
    -v /dev/bus/usb:/dev/bus/usb \
    -w /workspace/Linux_for_Tegra \
    jetson-builder sudo USER=root ./flash.sh jetson-agx-orin-devkit internal
```

Notice we bind mount our host's `/dev` and `/dev/bus/usb` directories onto the container. The first directory is needed so the container can access the host's [loop devices](https://en.wikipedia.org/wiki/Loop_device) and the second grants access to the USB ports.

## Setting up

After successfully flashing the Jetson and booting it for the first time, you can install all development and production dependencies running the `setup.sh` script. It is recommended you run this script as soon as you log in for the first time after a flash.

```bash
$ ./setup.sh
```

## Upgrading

TODO!


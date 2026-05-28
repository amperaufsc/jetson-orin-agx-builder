# jetson-agx-orin-builder

A Docker-based build environment for generating reproducible Jetson Linux (L4T) flash images for the **Jetson AGX Orin 64GB**, without needing a native Ubuntu host.

## How it works

Image generation and flashing are split into two separate steps:

1. **Build** — runs inside Docker, no Jetson needed. Produces a flash image tarball.
2. **Flash** — runs with the Jetson connected in recovery mode. Consumes the tarball from step 1.

This means you can generate a known-good image once and flash it to the device at any time.

## Requirements

- Docker
- Linux host (for USB passthrough during flashing)
- Jetson AGX Orin 64GB devkit

## Repository structure

```
.
├── Dockerfile
├── README.md
└── output/          # generated flash images land here (git-ignored)
```

## Usage

### 1. Build the Docker image

```bash
docker build -t jetson-agx-orin-builder .
```

This downloads the L4T BSP and sample root filesystem from NVIDIA, applies the binaries, and bakes everything into the image. Takes a while on first run.

### 2. Generate the flash image

No Jetson required for this step.

```bash
docker run --rm \
  --privileged \
  -v $(pwd)/output:/workspace/output \
  jetson-agx-orin-builder \
  bash -c "cd Linux_for_Tegra && \
    ./tools/kernel_flash/l4t_initrd_flash.sh --no-flash \
    jetson-agx-orin-devkit internal && \
    cp tools/kernel_flash/images/internal/*.tar.gz /workspace/output/"
```

The flash image tarball is saved to `output/` on your host.

### 3. Flash the Jetson

Put the Jetson into recovery mode first:

1. Power off the device
2. Hold the **Recovery** button
3. Press and release **Power**
4. Wait 2 seconds, release **Recovery**
5. Connect USB-C (the port next to the 40-pin header) to your host

Verify the device is visible:

```bash
lsusb | grep NVIDIA
# should show: NVIDIA Corp. APX
```

Then flash:

```bash
docker run --rm \
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd)/output:/workspace/output \
  jetson-agx-orin-builder \
  bash -c "cd Linux_for_Tegra && \
    ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only \
    jetson-agx-orin-devkit internal"
```

## Customizing the root filesystem

To pre-install packages or drop in config files before generating the image, add steps to the `Dockerfile` after `apply_binaries.sh`. The rootfs is at `Linux_for_Tegra/rootfs/` inside the container.

Example — pre-install a package into the rootfs:

```dockerfile
RUN cd Linux_for_Tegra && \
    chroot rootfs apt-get install -y <your-package>
```

## L4T version

This builder uses **L4T r36.4.4** (JetPack 6.1), based on Ubuntu 22.04.

To upgrade, replace the BSP and rootfs download URLs in the `Dockerfile` and update the version tag.

## Notes

- `--privileged` is required for `loop` device access during image generation
- The `output/` directory is bind-mounted so the image persists after the container exits
- Flashing requires the host to be Linux; the USB device must pass through cleanly
- If flashing fails mid-way, put the Jetson back into recovery mode and retry

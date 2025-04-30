# meta-kp-classes

This layer provides common bitbake files used in KP Labs' Yocto layers.


## Available classes

- `bitstream.bbclass` - generate bitstream with possibility to append additional .dtsi files
- `bootbin.bbclass` - generate bootbin image
- `fitimage.bbclass` - generate a signed FIT image
- `u-boot-script.bbclass` - generate U-Boot scripts from .cmd files
- `udev-rules.bbclass` - install udev rules to image


## Available distros
- `kplabs-dpu` - trimmed-down systemd-based Linux distro.


## Dependencies

This layer depends on:

```
URI: https://git.yoctoproject.org/poky
layers: meta
```

```
URI: https://github.com/Xilinx/meta-xilinx.git
layers: meta-xilinx-core
```

```
URI: https://github.com/Xilinx/meta-xilinx-tools.git
layers: *
```
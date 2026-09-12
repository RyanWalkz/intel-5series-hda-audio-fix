# Intel 5-Series HDA Audio Fix

A small Linux workaround for an Intel 5-Series/3400 Series High Definition Audio controller that may fail to initialize during boot with errors such as:

```text
CORB reset timeout#2
no AFG or MFG node found
no codecs initialized
```

When this happens, ALSA may report:

```text
aplay: device_list:279: no soundcards found...
```

The workaround re-enumerates the affected PCI audio controller during boot. On the tested system, this causes `snd_hda_intel` to initialize the Realtek ALC269VB codec correctly.

> **Important:** This is a workaround, not a kernel-level fix.

## Tested hardware

Original test system:

- Acer Aspire 4745
- Intel Core i3 M 330
- Intel 5-Series/3400 Series chipset
- Intel HDA controller: `8086:3b56`
- PCI address on the test system: `0000:00:1b.0`
- Realtek ALC269VB codec
- Legacy BIOS
- CachyOS
- `6.18.42-1-cachyos-lts`
- `7.1.8-1-cachyos`

The audio controller also works normally on the same laptop under MX Linux with a 6.12-series kernel.

## Symptoms

Check the audio devices:

```bash
aplay -l
```

Affected systems may show:

```text
no soundcards found...
```

Check the kernel messages:

```bash
sudo dmesg | grep -iE 'snd_hda|hdaudio|alc269|codec'
```

Relevant failure messages include:

```text
snd_hda_intel 0000:00:1b.0: CORB reset timeout#2
hdaudio hdaudioC0D0: no AFG or MFG node found
snd_hda_intel 0000:00:1b.0: no codecs initialized
```

Check the controller:

```bash
lspci -nn -s 00:1b.0
```

The affected controller is:

```text
Intel Corporation 5 Series/3400 Series Chipset High Definition Audio
PCI ID: 8086:3b56
```

## Workaround

The workaround removes the PCI device from the kernel and rescans the PCI bus:

```bash
echo 1 | sudo tee /sys/bus/pci/devices/0000:00:1b.0/remove
sleep 2
echo 1 | sudo tee /sys/bus/pci/rescan
```

After re-enumeration, the codec can initialize correctly.

For the original test system, `aplay -l` then reports:

```text
card 0: MID [HDA Intel MID], device 0: ALC269VB Analog
card 0: MID [HDA Intel MID], device 1: ALC269VB Digital
card 0: MID [HDA Intel MID], device 3: HDMI 0
```

## Distribution compatibility

This workaround is **not specific to Arch-based distributions**.

The PCI operations are provided by the Linux kernel through sysfs. The included automatic solution uses `systemd`, so it is intended for distributions using systemd.

It may work on distributions such as:

- Arch Linux
- CachyOS
- EndeavourOS
- Debian
- Ubuntu
- Linux Mint
- Fedora
- openSUSE

Compatibility is not guaranteed on every distribution or every Intel HDA controller.

## Installation

Clone the repository:

```bash
git clone https://github.com/RyanWalkz/intel-5series-hda-audio-fix.git
cd intel-5series-hda-audio-fix
```

Make the installer executable:

```bash
chmod +x install.sh uninstall.sh
```

Install:

```bash
sudo ./install.sh
```

The installer checks for the expected Intel HDA PCI device before installing the service.

Reboot:

```bash
sudo reboot
```

After boot, check:

```bash
aplay -l
```

## Check the service

```bash
systemctl status fix-hda-audio.service
```

View its logs:

```bash
journalctl -u fix-hda-audio.service
```

The service searches for the Intel `8086:3b56` audio controller instead of assuming that every machine uses PCI address `00:1b.0`.

## Uninstall

```bash
sudo ./uninstall.sh
```

Then reboot.

## How it works

```text
Linux boot
    |
    v
snd_hda_intel initializes
    |
    +---- failure ----> CORB reset timeout
    |                   no codecs initialized
    |                   no ALSA sound card
    |
    v
fix-hda-audio.service
    |
    v
Remove PCI HDA device
    |
    v
Wait 2 seconds
    |
    v
Rescan PCI bus
    |
    v
snd_hda_intel initializes again
    |
    v
Realtek codec detected
    |
    v
ALSA audio device available
```

## Safety and limitations

This project directly removes and re-enumerates a PCI device.

The service is intentionally limited to the Intel HDA controller with:

```text
Vendor: 8086
Device: 3b56
PCI class: 0403 (audio)
```

It does not modify:

- the Linux kernel
- firmware
- BIOS settings
- ALSA configuration
- PipeWire configuration
- PCI BAR addresses permanently

Because PCI device manipulation is involved, **do not use the service blindly on unrelated hardware**.

If your system does not have the expected controller, the installer refuses to install the service.

## Troubleshooting

Collect the following information before opening an issue:

```bash
uname -r
lspci -nn -s 00:1b.0
lspci -vv -s 00:1b.0
aplay -l
sudo dmesg | grep -iE 'snd_hda|hdaudio|alc269|codec'
systemctl status fix-hda-audio.service
```

Also include your distribution and desktop environment.

## Background

The original problem was reproduced on an Acer Aspire 4745 with an Intel 5-Series HDA controller (`8086:3b56`) and Realtek ALC269VB codec.

The same hardware worked on a 6.12-series kernel, while newer kernels reproduced the HDA initialization failure. A PCI remove/rescan cycle restored the codec without changing the kernel.

This repository documents that practical workaround so other owners of similar hardware can test it.

## Contributing

If this workaround fixes your system:

1. Open an issue with your hardware and kernel information.
2. Report whether the fix survives reboot.
3. Include the relevant `dmesg` output.
4. If possible, report whether the controller is also `8086:3b56`.

Please avoid posting personal information or full system logs containing unrelated data.

## License

MIT License. See [LICENSE](LICENSE).
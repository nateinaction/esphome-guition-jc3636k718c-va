# AGENTS.md

## Flashing

Flash over OTA, using the device's Tailscale IP from `wifi: use_address` in
`guition-va.yaml`:

```sh
esphome run guition-va.yaml --device 100.78.186.34
```

Run it inside the dev shell (direnv loads it on `cd`, or `nix develop`) so the
pinned ESPHome version is used.

### Do not flash over USB with `esphome upload --device /dev/tty...`

For a serial port ESPHome writes `firmware.factory.bin` starting at offset 0x0,
which covers the `nvs` partition at 0x9000. That erases the Tailscale node key,
so the device re-registers as a *brand new* tailnet node: new machine name, new
100.x IP, and (if the tailnet requires device approval) no peers at all until
someone approves it in the admin console. `wifi: use_address` and Home
Assistant's ESPHome config entry then both point at a dead address.

Flash over OTA. If the device is only reachable over USB, write just the app
partition so NVS survives:

```sh
esphome compile guition-va.yaml
esptool.py --port /dev/tty.usbmodem1101 write_flash 0x10000 \
  .esphome/build/voice-knob/build/firmware.ota.bin
```

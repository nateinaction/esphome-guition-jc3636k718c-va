# AGENTS.md

## Flashing

Flash over OTA, using the device's Tailscale IP from `wifi: use_address` in
`guition-va.yaml`:

```sh
esphome run guition-va.yaml --device 100.97.230.52
```

Run it inside the dev shell (direnv loads it on `cd`, or `nix develop`) so the
pinned ESPHome version is used.

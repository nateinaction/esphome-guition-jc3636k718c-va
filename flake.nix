{
  description = "Dev environment for the Guition JC3636W518 ESPHome config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # The firmware core needs ESPHome 2026.7.0+ (see README.md): as of that release
        # images use the platform form (`image:` -> `- platform: file` / `online_image`),
        # and the config fails to validate on anything older. nixpkgs is still on 2026.6.5,
        # so ESPHome comes from PyPI via uv instead of pkgs.esphome. Nix still pins uv and
        # the interpreter, so the environment stays reproducible.
        #
        # Using pkgs.esphome is also actively painful here: it propagates its Python deps,
        # so its wrapper exports a PYTHONPATH of python3.14 site-packages to every child
        # process. ESPHome builds ESP-IDF through a private python3.13 venv, that PYTHONPATH
        # shadows the venv's own packages with 3.14 builds whose C extensions the 3.13
        # interpreter can't load, and the build dies claiming the ESP-IDF venv is corrupted.
        esphomeVersion = "2026.7.4";
        python = pkgs.python313;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.uv
            python
          ];

          # Keep uv off the network for the interpreter and out of ~/.local: the venv is
          # built from the Nix python above and lives in the repo.
          env = {
            UV_PYTHON = python.interpreter;
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            # Belt and braces: nothing here propagates Python deps today, but a stray
            # PYTHONPATH is what breaks ESPHome's ESP-IDF venv (see comment above).
            unset PYTHONPATH

            if [ ! -x .venv/bin/esphome ] \
               || [ "$(.venv/bin/esphome version 2>/dev/null | tr -d '\n')" != "Version: ${esphomeVersion}" ]; then
              echo "Setting up .venv with esphome ${esphomeVersion} ..."
              uv venv --quiet --allow-existing .venv
              # --python is required: UV_PYTHON above would otherwise aim the install at
              # the Nix interpreter itself, which is read-only and rejects it.
              uv pip install --quiet --python .venv/bin/python "esphome==${esphomeVersion}"
            fi
            export PATH="$PWD/.venv/bin:$PATH"
          '';
        };
      });
}

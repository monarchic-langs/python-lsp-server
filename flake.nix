{
  description = "Nix package for Python LSP Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    python = pkgs.python3;
    pythonPackages = python.pkgs;
    source = pkgs.lib.cleanSource ./.;
    sourcePackage = pythonPackages.python-lsp-server.overridePythonAttrs (old: {
      version = "0.0.0";
      src = source;
      patches = [];
      SETUPTOOLS_SCM_PRETEND_VERSION = "0.0.0";
      CI = "true";
      OS = "linux";
      preCheck =
        (old.preCheck or "")
        + ''
          python -m venv /tmp/pyenv
          site_packages="$(
            /tmp/pyenv/bin/python - <<'PY'
          import site

          print(site.getsitepackages()[0])
          PY
          )"
          mkdir -p "$site_packages"
          cat > "$site_packages/loghub.py" <<'PY'
          """Changelog generator used by python-lsp-server's Jedi environment tests."""
          PY
        '';
    });
    sourceCheckEnv = python.withPackages (ps: [
      sourcePackage
      ps.build
      ps.jsonschema
      ps.ruff
      ps.setuptools-scm
      ps.twine
    ]);
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };
    packages = {
      ${system}.default = sourcePackage;
    };
    checks = {
      ${system} = {
        default = sourcePackage;

        flake-format =
          pkgs.runCommand "python-lsp-server-flake-format-check"
          {nativeBuildInputs = [pkgs.alejandra];}
          ''
            alejandra --check ${./flake.nix}
            touch $out
          '';

        package-metadata =
          pkgs.runCommand "python-lsp-server-package-metadata-check"
          {}
          ''
            test "${pkgs.lib.getName pkgs.python3Packages.python-lsp-server}" = "python-lsp-server"
            touch $out
          '';

        cli-smoke =
          pkgs.runCommand "python-lsp-server-cli-smoke-check"
          {nativeBuildInputs = [sourcePackage];}
          ''
            pylsp --help >/dev/null
            touch $out
          '';

        source-static =
          pkgs.runCommand "python-lsp-server-source-static-check"
          {nativeBuildInputs = [sourceCheckEnv];}
          ''
            cp -R ${source} source
            cd source
            chmod -R u+w .
            ruff check pylsp test
            ruff format --check pylsp test
            echo '{}' | jsonschema pylsp/config/schema.json
            python scripts/jsonschema2md.py pylsp/config/schema.json EXPECTED_CONFIGURATION.md
            diff EXPECTED_CONFIGURATION.md CONFIGURATION.md
            touch $out
          '';

        source-dist =
          pkgs.runCommand "python-lsp-server-source-dist-check"
          {nativeBuildInputs = [sourceCheckEnv];}
          ''
            cp -R ${source} source
            cd source
            chmod -R u+w .
            export SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0
            python -m build --no-isolation --sdist --wheel
            python -m twine check dist/*
            touch $out
          '';
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [
          sourceCheckEnv
          sourcePackage
          python
        ];
      };
    };
  };
}

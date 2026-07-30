{
  description = "Nix package for Python LSP Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };
    packages = {
      ${system}.default = pkgs.python3Packages.python-lsp-server;
    };
    checks = {
      ${system} = {
        default = pkgs.python3Packages.python-lsp-server;

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
          {nativeBuildInputs = [pkgs.python3Packages.python-lsp-server];}
          ''
            pylsp --help >/dev/null
            touch $out
          '';
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [pkgs.python3Packages.python-lsp-server pkgs.python3];
      };
    };
  };
}

{
  description = "Nix package for Python LSP Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;
    packages.${system}.default = pkgs.python3Packages.python-lsp-server;
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.python3Packages.python-lsp-server pkgs.python3];
    };
  };
}

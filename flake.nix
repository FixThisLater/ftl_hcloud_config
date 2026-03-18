# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.terranix.flakeModule ];
      systems = [ "x86_64-linux" ];

      perSystem = { pkgs, ... }: {
        terranix.terranixConfigurations.fixthislater = {
          terraformWrapper.package = pkgs.opentofu;
          terraformWrapper.prefixText = ''
            TF_VAR_hcloud_api_token="$(cat hcloud_api_token)"
            export TF_VAR_hcloud_api_token
          '';
          modules = [ ./config.nix ];
        };
      };
    };
}

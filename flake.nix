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
          terraformWrapper = {
            package = pkgs.opentofu;
            extraRuntimeInputs = [ pkgs.jq ];
            # Assumes these 3 sops-nix secrets are already available and just need
            # to be imported (safely) as envvars in the terranix shell
            prefixText = ''
              TF_VAR_hcloud_api_token="$(cat /run/secrets/hcloud-api-token)"
              AWS_ACCESS_KEY_ID="$(cat /run/secrets/hcloud-s3-access-key)"
              AWS_SECRET_ACCESS_KEY="$(cat /run/secrets/hcloud-s3-secret-key)"

              export TF_VAR_hcloud_api_token
              export AWS_ACCESS_KEY_ID
              export AWS_SECRET_ACCESS_KEY
              export AWS_DEFAULT_REGION="us-east-2"
            '';
          };
          modules = [ ./config.nix ];
      };
    };
  };
}

{

  description = ''
    Terranix & NixOS configurations for the Fix This Later resources in the
    Hetzner Cloud.

    This is a good working example of a Terranix flake that manages a set of
    HCloud resources
  '';

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
        terranix.terranixConfigurations.default = {
          terraformWrapper = {
            # Causes OpenTofu to be used instead of Terraform
            package = pkgs.opentofu;
            # Assumes these 3 sops-nix secrets are already available and just need
            # to be imported (safely) as envvars in the terranix shell
            prefixText = ''
              TF_VAR_hcloud_api_token="$(cat /run/secrets/hcloud-api-token)"
              AWS_ACCESS_KEY_ID="$(cat /run/secrets/ftl-s3-access-key)"
              AWS_SECRET_ACCESS_KEY="$(cat /run/secrets/ftl-s3-secret-key)"

              export TF_VAR_hcloud_api_token
              export AWS_ACCESS_KEY_ID
              export AWS_SECRET_ACCESS_KEY
              
              AWS_DEFAULT_REGION=us-east-2
              export AWS_DEFAULT_REGION
            '';
          };
          modules = [
            ./config.nix # Contains all the actual terraform resource definitions
          ];
      };
    };
  };
}

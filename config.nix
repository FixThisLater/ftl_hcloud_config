{ lib, ... }:
{

  terraform.backend.s3 = {
    bucket = "fixthislater";
    key    = "terraform.tfstate";
    endpoints.s3 = "https://hel1.your-objectstorage.com";
    skip_requesting_account_id = true;
    skip_credentials_validation = true;
    skip_metadata_api_check = true;
    skip_region_validation = true;
    use_path_style = true;
  };

  terraform.required_providers.hcloud = {
    source  = "hetznercloud/hcloud";
    version = "1.59.0";
  };

  variable.hcloud_api_token.sensitive = "true";

  provider.hcloud.token = "\${var.hcloud_api_token}";

  resource.hcloud_ssh_key.ftl_init_key = {
    name       = "ftl_init_key";
    public_key = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7S7PdB82d8y2/Blc/4auUYBQDUaoHdTulAYcpsDNaL fixthislater@protonmail.com
    '';
  };

  resource.hcloud_server.fixthislater = {
    name        = "fixthislater";
    location    = "nbg1";
    server_type = "cpx32";
    image       = "debian-13";
    public_net  = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
    ssh_keys    = [ "\${hcloud_ssh_key.ftl_init_key.id}" ];
  };

}

# Terraform resource configurations

{ lib, ... }:
{

  terraform.required_providers.hcloud = {
    source  = "hetznercloud/hcloud";
    version = "1.59.0";
  };

  # Save the state file to an S3-compatible storage bucket
  # (Created manually and not managed by this stack)
  terraform.backend.s3 = {
    bucket = "fixthislater.com";
    key = "terraform.tfstate";
    region = "us-east-2";
  };

  # Import HCloud token from the TF_VAR_hcloud_api_token envvar
  variable.hcloud_api_token.sensitive = "true";
  provider.hcloud.token = "\${var.hcloud_api_token}";

  # Indicate key to be used for root login - will be used only to install NixOS anyway
  resource.hcloud_ssh_key.ftl_init_key = {
    name       = "ftl_init_key";
    public_key = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7S7PdB82d8y2/Blc/4auUYBQDUaoHdTulAYcpsDNaL fixthislater@protonmail.com
    '';
  };

  # The main server
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

  # Hosted zone for the fixthislater.com domain
  resource.hcloud_zone.fixthislater = {
    name = "fixthislater.com";
    mode = "primary";
    delete_protection = true;
  };

  # DNS record sets for the server
  resource.hcloud_zone_rrset = {
    fixthislater_A = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "A";
      records = [ { value = "\${hcloud_server.fixthislater.ipv4_address}"; } ];
      change_protection = true;
    };
    fixthislater_AAAA = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "AAAA";
      records = [ {value = "\${hcloud_server.fixthislater.ipv6_address}"; } ];
      change_protection = true;
    };
  };

  # Reverse DNS - IPv4
  resource.hcloud_rdns.fixthislater_ipv4 = {
    server_id = "\${hcloud_server.fixthislater.id}";
    ip_address = "\${hcloud_server.fixthislater.ipv4_address}";
    dns_ptr = "fixthislater.com";
  };

  # Reverse DNS - IPv6
  resource.hcloud_rdns.fixthislater_ipv6 = {
    server_id = "\${hcloud_server.fixthislater.id}";
    ip_address = "\${hcloud_server.fixthislater.ipv6_address}";
    dns_ptr = "fixthislater.com";
  };

}

{ lib, ... }:
{

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

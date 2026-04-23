# Terraform resource configurations

{ ... }:
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
    # Base A record pointing to server IP
    fixthislater_A = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "A";
      records = [ { value = "\${hcloud_server.fixthislater.ipv4_address}"; } ];
      change_protection = true;
    };
    # Base AAAA record pointing to server IP
    fixthislater_AAAA = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "AAAA";
      records = [ {value = "\${hcloud_server.fixthislater.ipv6_address}"; } ];
      change_protection = true;
    };
    # Base TXT record
    fixthislater_mailserver_TXT = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "TXT";
      records = [
        # SPF record for mailserver
        { value = "\"v=spf1 a:mail.fixthislater.com -all\""; }
      ];
      change_protection = true;
    };
    # MX record for mailserver
    fixthislater_mailserver_MX = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "@";
      type = "MX";
      records = [ {value = "10 mail.fixthislater.com."; } ];
      change_protection = true;
    };
    # TXT record for GitHub domain verification
    fixthislater_github_verification = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "_gh-fixthislater-o";
      type = "TXT";
      records = [ {value = "\"b1358cd61e\""; } ];
      change_protection = true;
    };
    # TXT record for GitHub Pages verification
    fixthislater_github_pages_verification = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "_github-pages-challenge-fixthislater";
      type = "TXT";
      records = [ {value = "\"7a76612661a0e2751729c439e93347\""; } ];
      change_protection = true;
    };
    # A record for mailserver
    fixthislater_mailserver_A = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "mail";
      type = "A";
      records = [ {value = "\${hcloud_server.fixthislater.ipv4_address}"; } ];
      change_protection = true;
    };
    # AAAA record for mailserver
    fixthislater_mailserver_AAAA = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "mail";
      type = "AAAA";
      records = [ {value = "\${hcloud_server.fixthislater.ipv6_address}"; } ];
      change_protection = true;
    };
    # TXT record for mailserver DKIM
    # Note: TXT record strings have a 255-character limit, but the DKIM protocol
    # allows for multiple strings in one value and just treats them as one
    fixthislater_mailserver_DKIM = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "mail._domainkey";
      type = "TXT";
      records = [ {value = "\"v=DKIM1; k=rsa; \" \"p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAonfQ/wAu0Srwo0Eoh/Siuk+0f2sqfoRN6GILd+lzSrrENJphhKKAttHYBEx3svBdiFdXjNhxNUBOHa3+Hz33JT+7W5XahFTkbF5hNzrkVZXxlE/CWS0NbFbgrGSO+7yleRAxx11ch3qaKxIpCNflegZeZMsmvQcu8eg42Lpu1CnldeG8S6bUCCdPpEOYxtG0ul+oqHsATWF0/4Jdi\" \"kylGBpL9JWppsOkHnRCfzvw4goHhJtzYD879zrDGJf0MZX+HVZsVfaCljJ9fxyG23t9Xjav+EaJN1iVVkZNoJ2frHHyNbLa2n+pCldruPK2VdnahOpF5szdq1RNO+NNIqIHoQIDAQAB\""; } ];
      change_protection = true;
    };
    # DMARC record for mailserver
    fixthislater_mailserver_DMARC = {
      zone = "\${hcloud_zone.fixthislater.name}";
      name = "_dmarc";
      type = "TXT";
      records = [ {value = "\"v=DMARC1; p=none\""; } ];
      change_protection = true;
    };
  };

  # Reverse DNS - IPv4
  resource.hcloud_rdns = {
    fixthislater_ipv4 = {
      server_id = "\${hcloud_server.fixthislater.id}";
      ip_address = "\${hcloud_server.fixthislater.ipv4_address}";
      dns_ptr = "fixthislater.com";
      };
    fixthislater_ipv6 = {
      server_id = "\${hcloud_server.fixthislater.id}";
      ip_address = "\${hcloud_server.fixthislater.ipv6_address}";
      dns_ptr = "fixthislater.com";
    };
  };

}

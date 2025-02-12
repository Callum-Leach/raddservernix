# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./secrets.nix
      inputs.nix-minecraft.nixosModules.minecraft-servers
    ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  #networking.networkmanager.enable = true;
  #networking.firewall.allowedTCPPorts = [ 80 443 25565 ];

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
    hostName = "raddservernix";

    firewall.allowedTCPPorts = [ 80 443 25565 ];

    interfaces = {
      enp3s0 = {
        useDHCP = false;
        ipv4.addresses = [ {
          address = "192.168.1.22";
          prefixLength = 24;
        } ];
      };
    };
    defaultGateway = "192.168.1.1";
    nameservers = [ "8.8.8.8" ];
  localCommands = ''
    ip rule add to 192.168.1.1/24 priority 2500 lookup main
  '';
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };

  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.callumleach = {
    isNormalUser = true;
    description = "Callum Leach";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      git
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    git
    btop
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
    mergerfs
    caddy
    vaultwarden
    homepage-dashboard
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

#  virtualisation = {
#    docker = {
#      enable = true;
#      autoPrune = {
#        enable = true;
#        dates = "weekly";
#      };
#    };
#  };

  # List services that you want to enable:

  services.minecraft-servers = {
    enable = false;
    eula = true;

    servers = {
      callums-server1 = {
        enable = true;
        jvmOpts = "-Xms16G -Xmx16G";
        package = pkgs.fabricServers.fabric-1_21_4;
        
        serverProperties = {/* */};
        whitelist = {/* */};

        symlinks =
        let
          modpack = pkgs.fetchPackwizModpack {
            url = "https://raw.githubusercontent.com/Callum-Leach/raddservernix/refs/heads/main/Modpack/pack.toml";
            packHash = "sha256-5KyzvP8CYHTr0bhaiQX7Y0ASZZb/Z+wTRauhjSWJrHQ=";
          };
        in
        {
          "mods" = "${modpack}/mods";
        };
      };
    }; 
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/main/";
    user = "callumleach";
  };

#  services.sonarr = {
#    enable = true;
#    openFirewall = true;
#  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    # Store your variables like admin password here
    environmentFile = config.age.secrets.vaultwarden.path;
    config = {
      websocketEnabled = true;
      ROCKET_PORT = 8222;
      signupsAllowed = true;
      signupsDomainsWhitelist = "vaultwarden.raddserver.co.uk";

#      DOMAIN = "https://vaultwarden.raddserver.co.uk";
      databaseUrl = "postgresql://vaultwarden@/vaultwarden";
    };
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "vaultwarden" ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "callumleach31@gmail.com";

    certs."raddserver.co.uk" = {
      group = config.services.caddy.group;

      domain = "raddserver.co.uk";
      extraDomainNames = [ "*.raddserver.co.uk" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.age.secrets.cloudflare_dns_api.path;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.raddserver.co.uk".extraConfig = ''
      reverse_proxy http://192.168.1.22:8096

      tls /var/lib/acme/raddserver.co.uk/cert.pem /var/lib/acme/raddserver.co.uk/key.pem {
        protocols tls1.3
      }
    '';

    virtualHosts."raddserver.co.uk".extraConfig = ''
      reverse_proxy http://192.168.1.22:8082
      
      tls /var/lib/acme/raddserver.co.uk/cert.pem /var/lib/acme/raddserver.co.uk/key.pem {
        protocols tls1.3
      }
    '';

    virtualHosts."vaultwarden.raddserver.co.uk".extraConfig = ''
      reverse_proxy http://127.0.0.1:8222

      tls /var/lib/acme/raddserver.co.uk/cert.pem /var/lib/acme/raddserver.co.uk/key.pem {
        protocols tls1.3
      }
    '';

  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    environmentFile = config.age.secrets.homepage-dashboard.path;
    bookmarks = [{
      dev = [
        {
          github = [{
            abbr = "GH";
            href = "https://github.com/";
            icon = "github-light.png";
          }];
        }
        {
          "homepage docs" = [{
            abbr = "HD";
            href = "https://gethomepage.dev";
            icon = "homepage.png";
          }];
        }
      ];
      machines = [
        {
          tower = [{
            abbr = "TR";
            href = "https://dash.crgrd.uk";
            icon = "homarr.png";
          }];
        }
        {
          gbox = [{
            abbr = "GB";
            href = "https://dash.gbox.crgrd.uk";
            icon = "homepage.png";
          }];
        }
      ];
    }];
    services = [
      {
        media = [
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
              description = "media management";
              widget = {
                type = "jellyfin";
                url = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "{{HOMEPAGE_VAR_RADARR_URL}}";
              description = "film management";
              widget = {
                type = "radarr";
                url = "{{HOMEPAGE_VAR_RADARR_URL}}";
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "{{HOMEPAGE_VAR_SONARR_URL}}";
              description = "tv management";
              widget = {
                type = "sonarr";
                url = "{{HOMEPAGE_VAR_SONARR_URL}}";
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "{{HOMEPAGE_VAR_PROWLARR_URL}}";
              description = "index management";
              widget = {
                type = "prowlarr";
                url = "{{HOMEPAGE_VAR_PROWLARR_URL}}";
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
              };
            };
          }
          {
            Sabnzbd = {
              icon = "sabnzbd.png";
              href = "{{HOMEPAGE_VAR_SABNZBD_URL}}/";
              description = "download client";
              widget = {
                type = "sabnzbd";
                url = "{{HOMEPAGE_VAR_SABNZBD_URL}}";
                key = "{{HOMEPAGE_VAR_SABNZBD_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        infra = [
          {
            Files = {
              description = "file manager";
              icon = "files.png";
              href = "https://files.jnsgr.uk";
            };
          }
          {
            "Syncthing (thor)" = {
              description = "syncthing ui for thor";
              icon = "syncthing.png";
              href = "https://thor.sync.jnsgr.uk";
            };
          }
          {
            "Syncthing (kara)" = {
              description = "syncthing ui for kara";
              icon = "syncthing.png";
              href = "https://kara.sync.jnsgr.uk";
            };
          }
          {
            "Syncthing (freyja)" = {
              description = "syncthing ui for freyja";
              icon = "syncthing.png";
              href = "https://freyja.sync.jnsgr.uk";
            };
          }
        ];
      }
      {
        machines = [
          {
            KVM = {
              description = "KVM";
              icon = "tailscale.png";
              href = "https://raddserver.co.uk";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_KVM_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
              };
            };
          }
        ];
      }
    ];
    settings = {
      title = "raddserver";
      favicon = "";
      headerStyle = "clean";
      layout = {
        media = { style = "row"; columns = 3; };
        infra = { style = "row"; columns = 4; };
        machines = { style = "row"; columns = 4; };
      };
    };
    widgets = [
      { search = { provider = "google"; target = "_blank"; }; }
      { resources = { label = "system"; cpu = true; memory = true; }; }
      { resources = { label = "storage"; disk = [ "/mnt/main" ]; }; }
      {
        openmeteo = {
          label = "Tiverton";
          timezone = "Europe/London";
          units = "metric";
        };
      }
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

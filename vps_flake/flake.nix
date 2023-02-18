{
    description = "System config";

    inputs = {
        nixpkgs.url = "nixpkgs/master";
    };

    outputs = { self, nixpkgs, home-manager }@attrs:
        let
          system = "x86_64-linux";
        in {
        nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = attrs;
            modules = [
              ({config, pkgs, lib, ... }: {
                  # HARDWARE
                  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
                  boot.kernelModules = [ ];
                  boot.extraModulePackages = [ ];
                  fileSystems."/" =
                    { device = "/dev/disk/by-uuid/b9470789-6d82-4ad4-9a4a-7e19b8fcc8dc";
                    fsType = "ext4";
                  };
                  nix.maxJobs = lib.mkDefault 1;
                  # END HARDWARE

                  nix.gc.automatic = true;
                  imports = [ ];

                  nixpkgs.overlays = [ ( self: super: {
                      mautrix-telegram = super.mautrix-telegram.overrideAttrs (old: {
                         #src = pkgs.fetchFromGitHub {
                         #    owner = "tulir";
                         #    repo = old.pname;
                         #    #rev = "v${version}";
                         #    # Literal next commit to fix double-puppeting 2 typing 2 furious
                         #    rev = "eca1032d1660099216e71a7e0b24d35bb4833d74";
                         #    sha256 = "1vpdgi1szhlccni1d87bbcsi2p08ifs1s2iinimkc7d8ldqv1p52";
                         #};
                          propagatedBuildInputs = old.propagatedBuildInputs ++ (with pkgs.python3.pkgs; [
                            #asyncpg
                            python-olm pycryptodome unpaddedbase64
                          ]);
                      });
                  }) ];

                  # Use the GRUB 2 boot loader.
                  boot.loader.grub.enable = true;
                  boot.loader.grub.version = 2;
                  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

                  swapDevices = [{
                    device = "/var/swapfile";
                    size = 4096;
                  }];

                  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
                  # WireGuard
                  networking.nat.enable = true;
                  networking.nat.externalInterface = "ens3";
                  networking.nat.internalInterfaces = ["wg0"];
                  networking.firewall = {
                      #allowedTCPPorts = [ 22 80 443 3478 3479 ];
                      #allowedUDPPorts = [ 22 80 443 5349 5350 51820 ];
                      allowedTCPPorts = [ 22 80 443 ];
                      allowedUDPPorts = [ 22 80 443 51820 ];
                      extraCommands = ''
                          iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                      '';
                  };
                  networking.wireguard.interfaces = {
                      wg0 = {
                        ips = [ "10.100.0.1/24" ];
                        listenPort = 51820;
                        privateKeyFile = "/home/nathan/wireguard-keys/private";
                        peers = [
                          {
                            publicKey = "FqJShA/dz8Jj73tSyjzcsyASOEv6uAFs6e/vRol8ygc=";
                            allowedIPs = [ "10.100.0.2/32" ];
                          }
                          {
                            publicKey = "aAgay9pn/3Vj1nHC4GFY2vysW12n5VFyuUcB5+0pux8=";
                            allowedIPs = [ "10.100.0.3/32" ];
                          }
                          {
                            publicKey = "u55Jkd4dRdBqnhliIP9lwsxIYow2Tr8BhPPhKFtaVAc=";
                            allowedIPs = [ "10.100.0.4/32" ];
                          }
                          {
                            publicKey = "J/BWU33DYMkoWOKSZWrtAqWciep03YuicaDMD5MCqWg=";
                            allowedIPs = [ "10.100.0.5/32" ];
                          }
                          {
                            publicKey = "y2gAEhg1vwK1+nka2Knu7NyOk8HaaY4w18nD6EMyLSk=";
                            allowedIPs = [ "10.100.0.6/32" ];
                          }
                          {
                            publicKey = "SoaYh1mb6DYd6TuOEFl4lRCZUBTPQfOnWHIOmtkgxxM=";
                            allowedIPs = [ "10.100.0.7/32" ];
                          }
                        ];
                      };
                  };

                  services.openssh.enable = true;
                  services.openssh.passwordAuthentication = false;
                  services.openssh.kbdInteractiveAuthentication = false;
                  services.openssh.permitRootLogin = "prohibit-password";

                  services.mastodon = {
                    enable = true;
                    localDomain = "mastodon.room409.xyz";
                    configureNginx = true;
                    smtp.fromAddress = "notifications@mastodon.room409.xyz";
                  };

                  services.mautrix-telegram = {
                      enable = true;
                      settings = {
                          homeserver = {
                              address = "https://synapse.room409.xyz";
                              domain = "synapse.room409.xyz";
                          };
                          bridge.permissions = {
                              "synapse.room409.xyz" = "full";
                              "@miloignis:synapse.room409.xyz" = "admin";
                          };
                          bridge.encryption = {
                              allow = true;
                              require_verification = false;
                          };
                      };
                      environmentFile = /var/lib/mautrix-telegram/secrets;
                  };

                  #services.bookbot = {
                  #  enable = true;
                  #  port = 8888;
                  #};

                  services.matrix-synapse = {
                      enable = true;

                      settings = {
                        server_name = "synapse.room409.xyz";
                        public_baseurl = "https://synapse.room409.xyz/";

                        enable_registration = false;
                        #registration_shared_secret = null;
                        database.name = "psycopg2";
                        url_preview_enabled = true;
                        report_stats = true;
                        max_upload_size = "100M";

                        listeners = [
                            {
                                port = 8008;
                                tls = false;
                                resources = [
                                    {
                                        compress = true;
                                        names = ["client" "federation"];
                                    }
                                ];
                            }
                        ];
                        app_service_config_files = [
                            "/var/lib/matrix-synapse/telegram-registration.yaml"
                            "/var/lib/matrix-synapse/facebook-registration.yaml"
                        ];
                      };
                  };

                  services.gitea = {
                      enable = true;
                      disableRegistration = true;
                      appName = "Room409.xyz Forge";
                      domain = "forge.room409.xyz";
                      rootUrl = "https://forge.room409.xyz/";
                      httpPort = 3001;
                  };

                  services.postgresql = {
                      enable = true;
                      # postgresql user and db name in the service.matrix-synapse.databse_args setting is default
                      initialScript = pkgs.writeText "synapse-init.sql" ''
                          CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
                          CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
                              TEMPLATE template0
                              LC_COLLATE = "C"
                              LC_CTYPE = "C";
                      '';
                  };

                  security.acme.email = "miloignis@gmail.com";
                  security.acme.acceptTerms = true;
                  services.nginx = {
                      enable = true;
                      recommendedGzipSettings = true;
                      recommendedOptimisation = true;
                      recommendedProxySettings = true;
                      recommendedTlsSettings = true;

                      virtualHosts."forge.room409.xyz" = {
                          forceSSL = true;
                          enableACME = true;
                          locations."/".proxyPass = "http://localhost:3001";
                      };

                      virtualHosts."synapse.room409.xyz" = {
                          forceSSL = true;
                          enableACME = true;
                          locations."/.well-known/matrix/server".extraConfig = ''
                              add_header Content-Type application/json;
                              return 200 '{ "m.server": "synapse.room409.xyz:443" }';
                          '';
                          locations."/.well-known/matrix/client".extraConfig = ''
                              add_header Content-Type application/json;
                              add_header Access-Control-Allow-Origin *;
                              return 200 '{ "m.homeserver": {"base_url": "https://synapse.room409.xyz"}, "m.identity_server":  { "base_url": "https://vector.im"} }';
                          '';
                          locations."/".proxyPass = "http://localhost:8008";
                          locations."/".extraConfig = ''
                              client_max_body_size 100M;
                              proxy_set_header X-Forwarded-For $remote_addr;
                          '';
                      };

                      virtualHosts."element-synapse.room409.xyz" = {
                          forceSSL = true;
                          enableACME = true;
                          root = pkgs.element-web.override {
                              conf = {
                                  default_server_name = "synapse.room409.xyz";
                                  default_server_config = "";
                              };
                          };
                      };

                      virtualHosts."kraken-lang.org" = {
                        forceSSL = true;
                        enableACME = true;
                        root = "/var/www/kraken-lang.org";
                        locations."/k_prime.wasm".extraConfig = ''
                             default_type application/wasm;
                        '';
                      };
                      virtualHosts."faint.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        root = "/var/www/faint.room409.xyz";
                      };
                      #virtualHosts."www.kraken-lang.org" = {
                      #  forceSSL = true;
                      #  enableACME = true;
                      #  root = "/var/www/kraken-lang.org";
                      #  locations."/k_prime.wasm".extraConfig = ''
                      #       default_type application/wasm;
                      #  '';
                      #};
                      virtualHosts."room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/" = {
                          root = pkgs.writeTextDir "index.html" ''<!DOCTYPE html>
                          <html lang="en">
                              <head>
                                  <meta charset="utf-8">
                                  <title>room409.xyz</title>
                                  <style>
                                      h1, h2 ,h3 { line-height:1.2; }
                                      body {
                                          max-width: 45em;
                                          margin: 1em auto;
                                          padding: 0 .62em;
                                          font: 1.2em/1.62 sans-serif;
                                      }
                                  </style>
                              </head>
                              <body>
                                  <header><h1>So Mean and Clean</h1></header>
                                  <i>It's like a hacker wrote it</i>
                                  <br> <br>
                                  <b>Keyboard Cowpeople Team:</b> <a href="https://github.com/Limvot/Serif">Serif, a cross platform Matrix client</a>
                                  <br> <br>
                                  <b>MiloIgnis:</b> <a href="https://kraken-lang.org/">Kraken Programming Language</a>
                              </body>
                          </html>
                          '';
                        };
                        #locations."/bookclub/".proxyPass = "http://localhost:8888/room/!xSMgeFJYbuYTOGAGga:synapse.room409.xyz/";
                      };

                      virtualHosts."miloignis.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/" = {
                          root = pkgs.writeTextDir "index.html" ''<!DOCTYPE html>
                          <html lang="en">
                              <head>
                                  <meta charset="utf-8">
                                  <title>MiloIgnis's Website</title>
                                  <style>
                                      h1, h2 ,h3 { line-height:1.2; }
                                      body {
                                          max-width: 45em;
                                          margin: 1em auto;
                                          padding: 0 .62em;
                                          font: 1.2em/1.62 sans-serif;
                                      }
                                  </style>
                              </head>
                              <body>
                                  <header><h1>MiloIgnis's Website</h1></header>
                                  <br> <br>
                                  Hello! I'm MiloIgnis, a part-time PhD student studing programming languages and compilers.
                                  My current project is making a functional language based on Vau-calculus (inspired by John Shutt's work) practial via partial evlauation and some clever compilation techniques.
                                  That project, Kraken, is <a href="https://kraken-lang.org/">here</a>.
                                  
                                  <ol>
                                      <li>Matrix - <a href="https://matrix.to/#/@miloignis:synapse.room409.xyz">@miloignis:synapse.room409.xyz</a></li>
                                      <li>Mastodon - <a rel="me" href="https://mastodon.room409.xyz/@miloignis">@miloignis</a></li>
                                  </ol>
                                  <br> <br>
                              </body>
                          </html>
                          '';
                        };
                      };

                      virtualHosts."internet-list.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/" = {
                          root = pkgs.writeTextDir "index.html" ''<!DOCTYPE html>
                          <html lang="en">
                              <head>
                                  <meta charset="utf-8">
                                  <title>room409.xyz</title>
                                  <style>
                                      h1, h2 ,h3 { line-height:1.2; }
                                      body {
                                          max-width: 45em;
                                          margin: 1em auto;
                                          padding: 0 .62em;
                                          font: 1.2em/1.62 sans-serif;
                                      }
                                  </style>
                              </head>
                              <body>
                                  <header><h1>A list of colors on the internet</h1></header>
                                  <ol>
                                      <li>Blue</li>
                                      <li>Chilladelphia</li>
                                      <li>Kenny</li>
                                  </ol>
                              </body>
                          </html>
                          '';
                        };
                      };

                      #virtualHosts."4800H.room409.xyz" = {
                      #  forceSSL = true;
                      #  enableACME = true;
                      #  locations."/".proxyPass = "http://10.100.0.7:80";
                      #};
                  };

                  services.journald.extraConfig = "SystemMaxUse=50M";

                  environment.systemPackages = with pkgs; [
                      htop tmux git vim wget unzip file
                      iftop ripgrep
                      #wireguard
                  ];
                  users.extraUsers.nathan = {
                    name = "nathan";
                    isNormalUser = true;
                    group = "users";
                    extraGroups = [ "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" "networkmanager" "plugdev"];
                    createHome = true;
                    home = "/home/nathan";
                    shell = "/run/current-system/sw/bin/bash";
                    openssh.authorizedKeys.keys = [
                      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjyWh/SPOgx+yOgrc8g8+7PR0+CWMrWZ4PaWcmgDzfUGAWyj2FHBNG2gLvIKn4+TAwvbEPp+7YXxlmiYltUWNlEXEzryhrhYiqeun9uApT+fgzxF278/VeS+NErX4S2WGwhUdybk6MSs0cpUVp+TNiZFUH+ltTcLai3aLaMaL13Z024DzjpD4jRVG4PErHTe/6dTfdmg6AS7gB0b+LTjFzdYSdeYsHxqcig+d+34vQkNmV2dIvLpNkbpzyfUyE3g1gpYTgRKgY4mZqd6QUKOyIH0SDqPUDrmK6e1LK2yTYe1jP39G2JhAMOrSm8jEFm7RLxHXJ862EqD8gFV2aCQ2HUFlFpx7t02Tgvw80grQRoJKJyYtElO6CAr+oFnhxWnYgUsoYmGLSp5Nv1wV9WHkprWnGyuj/CGM8D3gwFSL672IYQOGTwQElcclRZ/uMlNjtyw6ky4VV22gDZag1hMfZhWf/nmMNql8dCoqY7K36XAAEDXjiS5J9EZe7AexLV68= nathan@nixos_4800H"

                      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtmGhDNdwDXulhJ8MGehlfLQZ8Qzxv2K4vXqyvJWSkMj5XzCRcylKME0qdfiA+G0SeozCY2Qhd2xiPsaL3PaZX7HD1fiesO0jofl9Ph+VIbwwP2LT7kYYSoUXSdj3uPBdZD8BhSZsMHIPVQfzj5JkvE1W9AQik+d5o7RPO8srpo8JHRpH0lgJbuiLWkpLX2sD2hjlI5uMhMekGnI0UA3ie3x9Xnh3J019X0K3Efxm8X31k60j9J0bgGLhxYwu42+kiJKabdpk5tFsqLvDRbzPUGSm+5ZiWMX5ILDbr+/Aczzb2ek5rzsEB2s48BmxBtJnXfjnQtBo6URuJYzVSI9V6vEgUnueGPY/DN1oeRZqTcqujIADh3ZMcdKg1cfdvNYoSk2FcFz0rZXTLjkwOAK2HMRZFXK5ijX7tpnb5GXsiDa0uoWhJVByzrnlqZ65LuHdLFPbe+A/N+T3wzykIkG2hNv8mRJi7/pWjNy2O2iKsSSSabN5xjxI7aFzyUQK+23UF2wzLc1+f4qMcB5HoHhktOV1QRM4RKtvYhdkAG0O/C5Wu0BItrjQbAoqSa29QLlBpHCIlY4Vr8S4kNXf8mm8gRrKATHNZBTUAVNMDYFcd9n4hyK8ERGodaXFDP7m/r+yZaHLcpQQ46sYjq2nbkP1yYaCbmVoEEUpKRtP2UDc91w== miloignis@gmail.com"
                    ];
                  };
                  
                  system.stateVersion = "20.03";
              })
            ];
        };
    };
}

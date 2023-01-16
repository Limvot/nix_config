{
    description = "System config";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows =  "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager }@attrs:
        let
          system = "x86_64-linux";
          homeManagerSharedModule = {
              home-manager.useGlobalPkgs = true;
              home-manager.users.nathan = { config, pkgs, lib, ... }:{ 
                  # This value determines the Home Manager release that your
                  # configuration is compatible with. This helps avoid breakage
                  # when a new Home Manager release introduces backwards
                  # incompatible changes.
                  #
                  # You can update Home Manager without changing this value. See
                  # the Home Manager release notes for a list of state version
                  # changes in each release.
                  home.stateVersion = "22.11";
                  
                  home.packages = with pkgs; [ ];
                  programs.starship = {
                    enable = true;
                    enableBashIntegration = true;
                    settings = {
                      add_newline = false;
                      format = lib.concatStrings [
                        "$username"
                        "$hostname"
                        "$directory"
                        "$jobs"
                        "$cmd_duration"
                        "$character"
                      ];
                      directory = {
                        truncation_length = 10;
                        truncate_to_repo = false;
                      };
                      scan_timeout = 10;
                      character = {
                        success_symbol = "➜";
                        error_symbol = "➜";
                      };
                    };
                  };
                  programs.bash = {
                    enable = true;
                    sessionVariables = {
                    };
                    profileExtra = ''
                      if [ -e /home/nathan/.nix-profile/etc/profile.d/nix.sh ]; then . /home/nathan/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
                    '';
                  };
                  programs.git = {
                    enable = true;
                    userName = "Nathan Braswell";
                    userEmail = "nathan@braswell.email";
                  };
                  programs.vim = {
                    enable = true;
                    plugins = with pkgs.vimPlugins; [ nerdcommenter vim-polyglot ];
                    settings = {
                      # Is the need for these obliviated by vim-polyglot using sleuth?
                      #expandtab = false;
                      tabstop = 4;
                      shiftwidth = 4;
                    };
                    extraConfig = ''
                      set number
                      set hlsearch
                      nnoremap <leader>m :bn<CR>
                      nnoremap <leader>t :tabnew<CR>
                      nnoremap <leader>. :tabn<CR>
                      nnoremap <leader>, :tabp<CR>
                      nnoremap <leader>v :vsplit<CR>
                      nnoremap <leader>h :split<CR>
                      nnoremap <leader>q :q<CR>
                      inoremap jk <Esc>
                      inoremap kj <Esc>
                    '';
                  };
                  programs.tmux = {
                    enable = true;
                    extraConfig = ''
                      #$Id: vim-keys.conf,v 1.2 2010-09-18 09:36:15 nicm Exp $
                      #
                      # vim-keys.conf, v1.2 2010/09/12
                      #
                      # By Daniel Thau.  Public domain.
                      #
                      # This configuration file binds many vi- and vim-like bindings to the
                      # appropriate tmux key bindings.  Note that for many key bindings there is no
                      # tmux analogue.  This is intended for tmux 1.3, which handles pane selection
                      # differently from the previous versions
                  
                      # split windows like vim
                      # vim's definition of a horizontal/vertical split is reversed from tmux's
                      bind s split-window -v
                      bind v split-window -h
                  
                      # move around panes with hjkl, as one would in vim after pressing ctrl-w
                      bind h select-pane -L
                      bind j select-pane -D
                      bind k select-pane -U
                      bind l select-pane -R
                  
                      # resize panes like vim
                      # feel free to change the "1" to however many lines you want to resize by, only
                      # one at a time can be slow
                      bind < resize-pane -L 1
                      bind > resize-pane -R 1
                      bind - resize-pane -D 1
                      bind + resize-pane -U 1
                  
                      # bind : to command-prompt like vim
                      # this is the default in tmux already
                      bind : command-prompt
                  
                      # vi-style controls for copy mode
                      setw -g mode-keys vi
                    '';
                  };
              };
          };
          commonConfigFunc = ({ config, lib, pkgs, modulesPath, ... }: {
                  nixpkgs.config.allowUnfree = true;
                  nix.settings.experimental-features = [ "nix-command" "flakes" ];
                  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
                  time.timeZone = "America/New_York";
                  users.extraUsers.nathan = {
                      name = "nathan";
                      isNormalUser = true;
                      group = "users";
                      extraGroups = [ "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" "networkmanager" "sway" "plugdev" "adbusers"];
                      createHome = true;
                      home = "/home/nathan";
                      shell = "/run/current-system/sw/bin/bash";
                  };

                  services.pipewire = {
                    enable = true;
                    alsa.enable = true;
                    pulse.enable = true;
                  };
                  services.dbus.enable = true;
                  xdg.portal = {
                    enable = true;
                    wlr.enable = true;
                    extraPortals = [pkgs.xdg-desktop-portal-gtk ];
                    gtkUsePortal = true;
                  };
                  services.blueman.enable = true;

                  services.printing.enable = true;
                  services.printing.drivers = [ pkgs.brlaser ];

                  programs.sway = {
                    enable = true;
                    wrapperFeatures.gtk = true;
                    extraPackages = with pkgs; [
                      swaylock # lockscreen
                      swayidle
                      xwayland # for legacy apps
                      #waybar # status bar
                      mako # notification daemon
                      kanshi # autorandr
                      bemenu # is this right?
                      i3status
                    ];
                  };

                  environment = {
                    etc = {
                      "sway/config".source = ./sway_config;
                    };
                  };
                  # For steam, and Vulkan in general
                  hardware.opengl.driSupport = true;
                  hardware.opengl.driSupport32Bit = true;

                  environment.systemPackages = with pkgs; [
                    tmux vim wget curl git w3m iftop iotop killall file unzip zip ripgrep imv killall gomuks htop
                    firefox-wayland chromium gnome.nautilus
                    vlc steam calibre foliate transmission-gtk mupdf

                    foot pavucontrol pywal
                    sway wayland glib dracula-theme gnome.adwaita-icon-theme swaylock swayidle wl-clipboard
                    (pkgs.writeTextFile {
                      name = "dbus-sway-environment";
                      destination = "/bin/dbus-sway-environment";
                      executable = true;

                      text = ''
                        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
                        systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
                        systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
                      '';
                    })
                    # currently, there is some friction between sway and gtk:
                    # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
                    # the suggested way to set gtk settings is with gsettings
                    # for gsettings to work, we need to tell it where the schemas are
                    # using the XDG_DATA_DIR environment variable
                    # run at the end of sway config
                    (pkgs.writeTextFile {
                        name = "configure-gtk";
                        destination = "/bin/configure-gtk";
                        executable = true;
                        text = let
                          schema = pkgs.gsettings-desktop-schemas;
                          datadir = "${schema}/share/gsettings-schemas/${schema.name}";
                        in ''
                          export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
                          gnome_schema=org.gnome.desktop.interface
                          gsettings set $gnome_schema gtk-theme 'Dracula'
                          '';
                    })
                  ];
                  programs.waybar.enable = true;

                  # kanshi systemd service
                  systemd.user.services.kanshi = {
                    description = "kanshi daemon";
                    serviceConfig = {
                      Type = "simple";
                      ExecStart = "${pkgs.kanshi}/bin/kanshi -c kanshi_config_file";
                    };
                  };
                  services.syncthing = {
                    enable = true;
                    user = "nathan";
                    dataDir = "/home/nathan/syncthing_stuff";
                    configDir = "/home/nathan/syncthing_stuff/.config/syncthing";
                  };

                  services.openssh.enable = true;
                  networking.firewall.enable = false;
          });
        in {
        nixosConfigurations.nixos4800H = nixpkgs.lib.nixosSystem {
            inherit system; 
            specialArgs = attrs;
            modules = [
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs) {
                  # HARDWARE
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

                  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" ];
                  boot.initrd.kernelModules = [ ];
                  boot.kernelModules = [ "kvm-amd" ];
                  boot.extraModulePackages = [ ];

                  fileSystems."/" = { device = "/dev/disk/by-uuid/ae8e4a92-53dd-49b5-bf3a-aeb9a109c01e"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/disk/by-uuid/28E9-0409"; fsType = "vfat"; };
                  swapDevices = [ ];
                  nix.maxJobs = lib.mkDefault 16;
                  # END HARDWARE

                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;
                  boot.kernelPackages = pkgs.linuxPackages_latest;
                  networking.hostName = "nixos4800H"; # Define your hostname.

                  # THIS SEEMS CONTRADICTORY
                  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
                  # Per-interface useDHCP will be mandatory in the future, so this generated config
                  # replicates the default behaviour.
                  networking.useDHCP = false;
                  networking.interfaces.eno1.useDHCP = true;
                  networking.interfaces.wlp1s0.useDHCP = true;
                  networking.wireguard.interfaces = {
                    wg0 = {
                        ips = [ "10.100.0.7/24" ];
                        privateKeyFile = "/home/nathan/wireguard-keys/private";
                        peers = [
                            {
                                publicKey = "WXx7XXJzerPJBPMTvZ454iQhx5Q5bFvBgF6NsPPX9nk=";
                                allowedIPs = [ "10.100.0.0/24" ];
                                #allowedIPs = [ "0.0.0.0/0" ];
                                ## Then sudo ip route add 104.238.179.164 via 10.0.0.1 dev enp30s0
                                endpoint = "104.238.179.164:51820";
                                persistentKeepalive = 25;
                            }
                        ];
                    };
                  };
                  system.stateVersion = "20.03";
                }))
            ];
        };
        nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
            inherit system; 
            specialArgs = attrs;
            modules = [
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs) {
                  # HARDWARE
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
                  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
                  boot.initrd.kernelModules = [ ];
                  boot.kernelModules = [ "kvm-amd" ];
                  boot.extraModulePackages = [ ];
                  boot.supportedFilesystems = [ "ntfs" ];
                  fileSystems."/" = { device = "/dev/disk/by-uuid/163c1731-2f66-436b-a74f-20f84ec628dd"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/disk/by-uuid/9C44-5411"; fsType = "vfat"; };
                  fileSystems."/big_disk" = { device = "/dev/sdb1"; fsType = "ntfs3"; options = ["rw" "uid=1000"]; };
                  swapDevices = [ ];
                  networking.useDHCP = lib.mkDefault true;
                  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
                  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
                  # END HARDWARE

                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;
                  networking.hostName = "nixos-desktop"; # Define your hostname.
                  system.stateVersion = "22.11";
                }))
            ];
        };
    };
}

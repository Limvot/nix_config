{
    description = "System config";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        stylix = {
          url = "github:danth/stylix";
          inputs.nixpkgs.follows =  "nixpkgs";
        };

        niri = {
            url = "github:sodiboo/niri-flake";
            inputs.nixpkgs.follows =  "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows =  "nixpkgs";
        };
        nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    };

    outputs = { self, nixpkgs, stylix, niri, home-manager, nixos-hardware }@attrs:
        let
          system = "x86_64-linux";
          make_besley = pkgs:(lib: (pkgs.stdenvNoCC.mkDerivation rec {
                      pname = "besley";
                      version = "4.0";
                      src = pkgs.fetchFromGitHub {
                          owner = "indestructible-type";
                          repo = "Besley";
                          rev = "99d5b97fcb863c4a667571ac8f86f745c345d3ab";
                          sha256 = "sha256-N6QU3Pd6EnIrdbRtDT3mW5ny683DBWo0odADJBSdA2E=";
                      };
                      installPhase = ''
                        install -D -t $out/share/fonts/opentype/ $(find $src -type f -name '*.otf')
                        install -D -t $out/share/fonts/truetype/ $(find $src -type f -name '*.ttf')
                      '';
                      meta = with lib; {
                        homepage = "https://indestructibletype.com/Besley.html";
                        description = "by indestructable-type";
                        license = licenses.ofl;
                        maintainers = [ ];
                        platforms = platforms.all;
                      };
                    }));
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
                  
                  fonts.fontconfig.enable = true;
                  home.packages = with pkgs; [
                    fira-code jetbrains-mono iosevka monoid recursive inter (make_besley pkgs lib)
                    xwayland-satellite swww
                  ]; 

                  systemd.user.services.mpris-proxy = {
                    Unit.Description = "Mpris proxy";
                    Unit.After = [ "network.target" "sound.target" ];
                    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
                    Install.WantedBy = [ "default.target" ];
                  };

                  programs.fuzzel.enable = true;

                  programs.waybar = {
                    enable = true;
                    settings = {
                      mainBar = {
                        layer = "top";
                        position = "top";
                        height = 18;
                        modules-left = [ "memory" "disk" "network" ];
                        modules-center = [ "clock" ];
                        modules-right = [ "battery" "power-profiles-daemon" "backlight" "pulseaudio" ];
                        reload_style_on_change = true;
                      };
                    };
                    style = ''
                      /*
                      * {
                        border: none;
                        border-radius: 0;
                        font-family: Recursive;
                      }
                      */
                      window#waybar {
                        background: transparent;
                        color: #ffffff;
                      }
                      button {
                        box-shadow: none;
                        border: none;
                        border-radius: 0;
                        transition-property: none;
                      }
                      #workspaces button {
                        padding: 0 5px;
                        background-color: transparent;
                        color: #ffffff;
                      }
                      #mode {
                        background-color: #64829D;
                        border-bottom: 3px solid #ffffff;
                      }
                      #memory, #disk, #network, #pulseaudio, #battery, #power-profiles-daemon, #backlight, #clock {
                        padding: 0 10px;
                        color: #f0f0ff;
                        background-color: rgba(30,30,46,0.6);
                        border-radius: 99px;
                        margin-left: 4px;
                      }
                      #window, #workspaces {
                        margin: 0 4px;
                      }
                      #clock {
                        font-weight: bold;
                      }
                      #battery {
                        margin-left: 4px;
                      }
                      /*
                      #pulseaudio {
                        color: #000000;
                        background-color: #f1c40f;
                      }
                      */
                    '';
                  };

                  programs.niri.settings = {
                    prefer-no-csd = true;
                    input.keyboard.xkb = {
                      options = "ctrl:nocaps";
                    };
                    environment = {
                      DISPLAY = ":0"; # xwayland-satellite
                    };
                    spawn-at-startup = [
                      { command = [ "swww-daemon" ]; }
                      { command = [ "swww" "img" "${config.stylix.image}" ]; }
                      { command = [ "waybar" ]; }
                      { command = [ "xwayland-satellite" ]; }
                    ];
                    window-rules = [
                      {
                        draw-border-with-background = false;
                        geometry-corner-radius = let r = 4.0; in {
                          top-left = r;
                          top-right = r;
                          bottom-left = r;
                          bottom-right = r;
                        };
                        clip-to-geometry = true;
                        #opacity = 0.95;
                      }
                      {
                        matches = [{is-focused = false;}];
                        #opacity = 0.85;
                        opacity = 0.95;
                      }
                    ];
                    layout = {
                      #gaps = 8;
                      gaps = 16;
                      center-focused-column = "never";
                      preset-column-widths = [
                        { proportion = 1.0 / 3.0; }
                        { proportion = 1.0 / 2.0; }
                        { proportion = 2.0 / 3.0; }
                      ];
                      #If you leave the brackets empty, the windows themselves will decide their initial width.
                      #preset-window-heights = {};
                      default-column-width = { proportion = 1.0 / 2.0; };
                      #focus-ring = {
                      #  enable = false;
                      #  width = 8;
                      #  # Color of the ring on the active monitor.
                      #  active.color = "#7fc8ff";
                      #  # Color of the ring on inactive monitors.
                      #  inactive.color = "#505050";
                      #};
                      #border = {
                      #  enable = true;
                      #  width = 4;
                      #  active = {
                      #    gradient = {
                      #      angle = 130;
                      #      relative-to = "workspace-view";
                      #      from = "#90F090";
                      #      to   = "#909090";
                      #    };
                      #  };
                      #  inactive = {
                      #    gradient = {
                      #      angle = 130;
                      #      relative-to = "workspace-view";
                      #      from = "#409040";
                      #      to   = "#404040";
                      #    };
                      #  };
                      #};
                      #struts = {
                        #left   = 64;
                        #right  = 64;
                        #top    = 64;
                        #bottom = 64;
                      #};
                    };
                    binds = with config.lib.niri.actions; {
                      #"Alt+P".action = spawn "bemenu-run";
                      "Alt+P".action = spawn "fuzzel";
                      "Alt+Return".action = spawn "ghostty";
                      "Alt+Shift+Return".action = spawn "foot";
                      "Alt+Shift+Slash".action = show-hotkey-overlay;

                      "Alt+Shift+C".action = close-window;

                      "Alt+Left"  .action = focus-column-left;
                      "Alt+Down"  .action = focus-window-down;
                      "Alt+Up"    .action = focus-window-up;
                      "Alt+Right" .action = focus-column-right;
                      "Alt+H"     .action = focus-column-left;
                      #"Alt+J"     .action = focus-window-down;
                      #"Alt+K"     .action = focus-window-up;
                      "Alt+L"     .action = focus-column-right;

                      "Alt+Shift+Left"  .action = move-column-left;
                      "Alt+Shift+Down"  .action = move-window-down;
                      "Alt+Shift+Up"    .action = move-window-up;
                      "Alt+Shift+Right" .action = move-column-right;
                      "Alt+Shift+H"     .action = move-column-left;
                      #"Alt+Shift+J"     .action = move-window-down;
                      #"Alt+Shift+K"     .action = move-window-up;
                      "Alt+Shift+L"     .action = move-column-right;

                      # Nice alts
                      "Alt+J"      .action = focus-window-or-workspace-down;
                      "Alt+K"      .action = focus-window-or-workspace-up;
                      "Alt+Shift+J".action = move-window-down-or-to-workspace-down;
                      "Alt+Shift+K".action = move-window-up-or-to-workspace-up;


                      "Alt+Ctrl+Left" .action = focus-monitor-left;
                      "Alt+Ctrl+Down" .action = focus-monitor-down;
                      "Alt+Ctrl+Up"   .action = focus-monitor-up;
                      "Alt+Ctrl+Right".action = focus-monitor-right;
                      "Alt+Ctrl+H"    .action = focus-monitor-left;
                      "Alt+Ctrl+J"    .action = focus-monitor-down;
                      "Alt+Ctrl+K"    .action = focus-monitor-up;
                      "Alt+Ctrl+L"    .action = focus-monitor-right;

                      "Alt+Shift+Ctrl+Left"  .action = move-column-to-monitor-left;
                      "Alt+Shift+Ctrl+Down"  .action = move-column-to-monitor-down;
                      "Alt+Shift+Ctrl+Up"    .action = move-column-to-monitor-up;
                      "Alt+Shift+Ctrl+Right" .action = move-column-to-monitor-right;
                      "Alt+Shift+Ctrl+H"     .action = move-column-to-monitor-left;
                      "Alt+Shift+Ctrl+J"     .action = move-column-to-monitor-down;
                      "Alt+Shift+Ctrl+K"     .action = move-column-to-monitor-up;
                      "Alt+Shift+Ctrl+L"     .action = move-column-to-monitor-right;


                      #...
                      "Alt+1".action = focus-workspace 1;
                      "Alt+2".action = focus-workspace 2;
                      "Alt+3".action = focus-workspace 3;
                      "Alt+4".action = focus-workspace 4;
                      "Alt+5".action = focus-workspace 5;
                      "Alt+6".action = focus-workspace 6;
                      "Alt+7".action = focus-workspace 7;
                      "Alt+8".action = focus-workspace 8;
                      "Alt+9".action = focus-workspace 9;
                      #"Alt+Shift+1".action = move-column-to-workspace 1;
                      #"Alt+Shift+2".action = move-column-to-workspace 2;
                      #"Alt+Shift+3".action = move-column-to-workspace 3;
                      #"Alt+Shift+4".action = move-column-to-workspace 4;
                      #"Alt+Shift+5".action = move-column-to-workspace 5;
                      #"Alt+Shift+6".action = move-column-to-workspace 6;
                      #"Alt+Shift+7".action = move-column-to-workspace 7;
                      #"Alt+Shift+8".action = move-column-to-workspace 8;
                      #"Alt+Shift+9".action = move-column-to-workspace 9;

                      #Consume one window from the right into the focused column.
                      "Alt+Comma"  .action = consume-window-into-column;
                      #Expel one window from the focused column to the right.
                      "Alt+Period" .action = expel-window-from-column;

                      #There are also commands that consume or expel a single window to the side.
                      "Alt+BracketLeft"  .action = consume-or-expel-window-left;
                      "Alt+BracketRight" .action = consume-or-expel-window-right;

                      "Alt+R".action = switch-preset-column-width;
                      "Alt+Shift+R".action = switch-preset-window-height;
                      "Alt+Ctrl+R".action = reset-window-height;
                      "Alt+F".action = maximize-column;
                      "Alt+Shift+F".action = fullscreen-window;
                      "Alt+C".action = center-column;

                      "Alt+Minus".action = set-column-width "-10%";
                      "Alt+Equal".action = set-column-width "+10%";

                      "Alt+Shift+Minus".action = set-window-height "-10%";
                      "Alt+Shift+Equal".action = set-window-height "+10%";

                      #"Print".action = screenshot;
                      #"Ctrl+Print".aciton = screenshot-screen;
                      #"Alt+Print".action = screenshot-window;

                      "Alt+Shift+E".action = quit;
                      "Ctrl+Alt+Delete".action = quit;

                      "Alt+Shift+P".action = power-off-monitors;
                    };
                  };

                  programs.ghostty = {
                    enable = true;
                    settings = {
                      window-decoration = false;
                      minimum-contrast = 1.5;
                      #font-family = "Recursive Mono Linear Static";
                      #font-size = 11;
                      #theme = "GruvboxDarkHard";
                      #theme = "Horizon";
                      #theme = "IC_Green_PPL";
                      #theme = "IC_Orange_PPL";
                      #theme = "iceberg-dark";
                      #theme = "Kanagawa Dragon";
                      #theme = "Kanagawa Wave";
                      #theme = "kanagawabones";
                      #theme = "kurokula";
                      #theme = "Later This Evening";
                      #theme = "MaterialDarker";
                      #theme = "MaterialOcean";
                      #theme = "matrix";
                      #theme = "Medallion";
                      #theme = "Mellifluous";
                      #theme = "Molokai";
                      #theme = "MonaLisa";
                      #theme = "Monokai Remastered";
                      #theme = "Monokai Soda";

                      #theme = "NightLion v2";

                      #theme = "niji";
                      #theme = "Nocturnal Winter";
                      #theme = "nord";
                      #theme = "NvimDark";
                      #theme = "Oceanic-Next";
                      #theme = "OneHalfDark";
                      #theme = "Paraiso Dark";
                      #theme = "PaulMillr";
                      #theme = "PencilDark";
                      #theme = "Peppermint";
                      #theme = "Pnevma";
                      #theme = "Popping and Locking";
                      #theme = "Red Planet";
                      #theme = "rose-pine";
                      #theme = "Ryuuko";
                      #theme = "SeaShells";
                      #theme = "Seti";
                      #theme = "Shaman";
                      #theme = "Slate";
                      #theme = "Smyck";
                      #theme = "Snazzy";
                      #theme = "SoftServer";
                      #theme = "Solarized Dark - Patched";
                      #theme = "Solarized Dark Higher Contrast";
                      #theme = "SpaceGray Bright";
                      #theme = "SpaceGray Eighties";
                      #theme = "SpaceGray Eighties Dull";
                      #theme = "terafox";
                      #theme = "Thayer Bright";
                      #theme = "Tinacious Design (Dark)";
                      #theme = "tokyonight";
                      #theme = "tokyonight-storm";
                      #theme = "Tomorrow Night Burns";
                      #theme = "UltraViolent";
                      #theme = "Violet Dark";
                      #theme = "Whimsy";
                      #theme = "WildCherry";
                      #theme = "wilmersdorf";
                      #theme = "Wombat";
                      #theme = "xcodewwdc";
                      #theme = "zenbones_dark";
                      #theme = "zenwritten_dark";
                    };
                  };
                  programs.foot = {
                    enable = true;
                    settings = {
                      main = {
                        #font = "Fira Code:size=8";
                        #font = "JetBrainsMono:size=8";
                        #font = "Iosevka:size=18";
                        #font = "Monoid:size=6";
                        #font = "Recursive:size=16"; # seems to be Recursive Mono Linear Static in Ghostty
                        #dpi-aware = "yes";
                      };
                      mouse = {
                        hide-when-typing = "yes";
                      };
                    };
                  };
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
                    shellAliases = {
                      ng  ="nmcli c up NETGEAR97";
                      ng24="nmcli c up NETGEAR97_24_2Ghz";
                      ng58="nmcli c up NETGEAR97_28_5Ghz";
                      ng5c="nmcli c up NETGEAR97_2C_5Ghz";
                    };
                  };
                  programs.git = {
                    enable = true;
                    userName = "Nathan Braswell";
                    userEmail = "nathan@braswell.email";
                  };
                  programs.vim = {
                    enable = true;
                    plugins = with pkgs.vimPlugins; [
                      nerdcommenter vim-polyglot #parinfer-rust
                    ];
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

                      " Thanks to https://unix.stackexchange.com/questions/140898/vim-hide-status-line-in-the-bottom
                      let s:hidden_all = 0
                      function! ToggleHiddenAll()
                          if s:hidden_all  == 0
                              let s:hidden_all = 1
                              set noshowmode
                              set noruler
                              set laststatus=0
                              set noshowcmd
                          else
                              let s:hidden_all = 0
                              set showmode
                              set ruler
                              set laststatus=2
                              set showcmd
                          endif
                      endfunction

                      nnoremap <S-h> :call ToggleHiddenAll()<CR>
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
                  programs.emacs = {
                    enable = true;
                    extraConfig = ''
                      (menu-bar-mode   -1)
                      (tool-bar-mode    -1)
                      (scroll-bar-mode  -1)

                      ;; Use spaces, not tabs, for indentation.
                      (setq-default indent-tabs-mode nil)
                      ;; Highlight matching pairs of parentheses.
                      (setq show-paren-delay 0)
                      (show-paren-mode)

                      ;(require 'smartparens-config)


                      (setq evil-want-C-u-scroll t)
                      (evil-mode 1)
                      (evil-set-undo-system 'undo-redo)
                      (setq key-chord-two-keys-delay 0.5)
                      (key-chord-define evil-insert-state-map "jk" 'evil-normal-state)
                      (key-chord-mode 1)
                      (custom-set-variables
                      ;; custom-set-variables was added by Custom.
                      ;; If you edit it by hand, you could mess it up, so be careful.
                      ;; Your init file should contain only one such instance.
                      ;; If there is more than one, they won't work right.
                      '(custom-safe-themes
                      '("3ff4a0ad1a2da59a72536e6030291cf663314c14c8a5a9eb475f3c28436d071d" default)))
                      (custom-set-faces
                      ;; custom-set-faces was added by Custom.
                      ;; If you edit it by hand, you could mess it up, so be careful.
                      ;; Your init file should contain only one such instance.
                      ;; If there is more than one, they won't work right.
                      )
                      (load-theme 'dracula t)
                    '';
                    extraPackages = epkgs: with epkgs; [
                      evil key-chord magit proof-general
                      #paredit
                      #smartparens
                      #parinfer-rust-mode
                      rainbow-delimiters dracula-theme
                    ];
                  };
              };
          };
          commonConfigFunc = ({ config, lib, pkgs, modulesPath, ... }: (specificPkgs: {
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

                  #fonts.fonts = with pkgs; [ fira-code jetbrains-mono iosevka ];

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
                    #gtkUsePortal = true;
                  };

                  hardware.bluetooth.enable = true;
                  services.blueman.enable = true;

                  services.printing.enable = true;
                  services.printing.drivers = [ pkgs.brlaser ];

                  stylix = {
                    enable = true;
                    #image = /home/nathan/Wallpapers/walls/green-tea.jpg;
                    #image = ./cherry_tree.jpg;
                    #image = ./skyscraper.jpg;
                    #image = ./village.jpg;
                    #image = ./stones-water.jpg;
                    #image = ./moss.jpeg;
                    #image = ./ruinedmansion.jpg;
                    image = ./130_1zhJtUA.jpeg; #the city street
                    #image = pkgs.fetchurl {
                    #  url = "https://raw.githubusercontent.com/kiedtl/walls/refs/heads/master/green-tea.jpg";
                    #  sha256 = "sha256-+NcZMBnbEWurmkOkzdrxGwBlxzUO3Sitt6Uoq9plc7o=";
                    #};
                    polarity = "dark";
                    #polarity = "light";
                    fonts = {
                      # hehe casual as serif
                      serif     = { package = (make_besley pkgs lib); name = "Besley"; };
                      #serif = { package = pkgs.recursive; name = "Recursive Sans Linear Static"; };
                      #sansSerif = { package = pkgs.recursive; name = "Recursive Sans Linear Static"; };
                      sansSerif = { package = pkgs.inter; name = "Inter"; };
                      monospace = { package = pkgs.recursive; name = "Recursive Mono Linear Static"; };
                      emoji     = { package = pkgs.noto-fonts-emoji; name = "Noto Color Emoji"; };
                    };
                  };
                  programs.niri = {
                    enable = true;
                    package = pkgs.niri;
                  };
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
                  #hardware.opengl.driSupport = true;
                  hardware.opengl.driSupport32Bit = true;
                  hardware.steam-hardware.enable = true;
                  programs.steam.enable = true;

                  environment.systemPackages = with pkgs; [
                    tmux vim wget curl git w3m iftop iotop killall file unzip zip p7zip ripgrep imv killall
                    btop htop python3
                    waypipe firefox-wayland chromium chawan nautilus
                    vlc mpv wayfarer libreoffice calibre foliate #transmission-gtk mupdf
                    gimp
                    pavucontrol pywal
                    sway wayland glib dracula-theme adwaita-icon-theme swaylock swayidle wl-clipboard
                    circumflex
                    #monado openxr-loader xrgears
                    #lean4 blas elan vscode
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
                  ] ++ specificPkgs;

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
                  services.tailscale.enable = true;
                  networking.firewall.enable = false;
          }));
        in {
        nixosConfigurations.nixos-framework = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = attrs;
            modules = [
                nixos-hardware.nixosModules.framework-13-7040-amd
                stylix.nixosModules.stylix
                niri.nixosModules.niri
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs [ pkgs.light pkgs.gpodder pkgs.evince pkgs.wezterm pkgs.vulkan-tools pkgs.tor-browser ]) {
                  # HARDWARE
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
                  
                  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
                  boot.initrd.kernelModules = [ "amdgpu" ];
                  hardware.opengl.extraPackages = with pkgs; [ amdvlk ];
                  boot.kernelModules = [ "kvm-amd" ];
                  boot.extraModulePackages = [ ];
                  
                  fileSystems."/" =
                    { device = "/dev/disk/by-uuid/427e2f6d-d42d-4d49-be35-713bf9526dc9";
                      fsType = "ext4";
                    };
                  
                  fileSystems."/boot" =
                    { device = "/dev/disk/by-uuid/2A78-5373";
                      fsType = "vfat";
                    };
                  
                  swapDevices =
                    [ { device = "/dev/disk/by-uuid/9b0357e8-f721-4a06-aae0-97b6efc19209"; }
                    ];
                  
                  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
                  # (the default) this is the recommended approach. When using systemd-networkd it's
                  # still possible to use this option, but it's recommended to use it in conjunction
                  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
                  networking.useDHCP = lib.mkDefault true;
                  # networking.interfaces.enp195s0f3u1c2.useDHCP = lib.mkDefault true;
                  
                  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
                  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
                  # END HARDWARE
                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;
                  boot.kernelPackages = pkgs.linuxPackages_latest;
                  #boot.kernelPackages = pkgs.linuxPackages_testing;
                  #boot.kernelParams = [ "amdgpu.sg_display=0" ];
                  networking.hostName = "nixos-framework"; # Define your hostname.
                  system.stateVersion = "22.11"; # Did you read the comment?
                  programs.fuse.userAllowOther = true;
                  #services.jellyfin.enable = true;
                  services.fwupd.enable = true;
                  #services.xserver = {
                  #  enable = true;
                  #  displayManager.gdm.enable = true;
                  #  desktopManager.gnome.enable = true;
                  #};
                }))
            ];
        };
        nixosConfigurations.nixos4800H = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = attrs;
            modules = [
                niri.nixosModules.niri
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs [ pkgs.light pkgs.gpodder pkgs.evince ]) {
                  # HARDWARE
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

                  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" ];
                  boot.initrd.kernelModules = [ "amdgpu" ];
                  hardware.opengl.extraPackages = with pkgs; [ amdvlk ];
                  boot.kernelModules = [ "kvm-amd" ];
                  boot.extraModulePackages = [ ];

                  fileSystems."/" = { device = "/dev/disk/by-uuid/ae8e4a92-53dd-49b5-bf3a-aeb9a109c01e"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/disk/by-uuid/28E9-0409"; fsType = "vfat"; };
                  fileSystems."/nas_disk1" = { device = "/dev/disk/by-uuid/d7907ed2-2aff-4cfc-bb4d-fa46b3f1af57"; fsType = "ext4"; };
                  swapDevices = [ ];
                  # END HARDWARE

                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;
                  boot.kernelPackages = pkgs.linuxPackages_latest;
                  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
                  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
                  networking.hostName = "nixos4800H"; # Define your hostname.

                  programs.fuse.userAllowOther = true;
                  services.jellyfin.enable = true;

                  # THIS SEEMS CONTRADICTORY
                  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
                  # Per-interface useDHCP will be mandatory in the future, so this generated config
                  # replicates the default behaviour.
                  networking.useDHCP = false;
                  networking.interfaces.eno1.useDHCP = true;
                  networking.interfaces.wlp1s0.useDHCP = true;
                  system.stateVersion = "20.03";
                  users.extraUsers.marcus = {
                      name = "marcus";
                      isNormalUser = true;
                      group = "users";
                      extraGroups = [ "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" "networkmanager" "sway" "plugdev" "adbusers"];
                      createHome = true;
                      home = "/home/marcus";
                      shell = "/run/current-system/sw/bin/bash";
                  };
                  users.extraUsers.pratik = {
                    name = "pratik";
                    isNormalUser = true;
                    group = "users";
                    extraGroups = [ "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" "networkmanager" "plugdev"];
                    createHome = true;
                    home = "/home/pratik";
                    shell = "/run/current-system/sw/bin/bash";
                    openssh.authorizedKeys.keys = [
                      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmLFCW0HGGJzTO42/ZuWFmDY80ZpV8e8qEc3CEBclF8 pratik@elmerus.fedora"
                    ];
                  };
                }))
            ];
        };
        nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = attrs;
            modules = [
                niri.nixosModules.niri
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs []) {
                  # HARDWARE
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
                  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
                  boot.initrd.kernelModules = [ ];
                  boot.kernelModules = [ "kvm-amd" ];
                  boot.extraModulePackages = [ ];
                  boot.supportedFilesystems = [ "ntfs" ];
                  fileSystems."/" = { device = "/dev/disk/by-uuid/163c1731-2f66-436b-a74f-20f84ec628dd"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/disk/by-uuid/9C44-5411"; fsType = "vfat"; };
                  fileSystems."/reborn" = { device = "/dev/disk/by-label/reborn"; fsType = "ext4"; };
                  #fileSystems."/big_disk" = { device = "/dev/disk/by-uuid/B610D69310D65A47"; fsType = "ntfs3"; options = ["rw" "uid=1000"]; };
                  #fileSystems."/big_disk" = { device = "/dev/sdb1"; fsType = "ntfs3"; options = ["rw" "uid=1000"]; };
                  swapDevices = [ ];
                  networking.useDHCP = lib.mkDefault true;
                  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
                  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
                  # END HARDWARE

                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;
                  networking.hostName = "nixos-desktop"; # Define your hostname.
                  system.stateVersion = "22.11";

                  #services.jellyfin.enable = true;
                }))
            ];
        };
        nixosConfigurations.condoserver = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = attrs;
            modules = [
                niri.nixosModules.niri
                home-manager.nixosModules.home-manager
                homeManagerSharedModule
                ({ config, lib, pkgs, modulesPath, ... }@innerArgs: (lib.recursiveUpdate (commonConfigFunc innerArgs []) {
                  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
                  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "sdhci_pci" ];
                  boot.initrd.kernelModules = [ ];
                  boot.kernelModules = [ "kvm-intel" ];
                  boot.extraModulePackages = [ ];
                  fileSystems."/" = { device = "/dev/disk/by-uuid/0ef06a3a-080d-4f15-b53e-54c91adb8ec9"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/disk/by-uuid/86F4-9779"; fsType = "vfat"; };
                  swapDevices = [ { device = "/dev/disk/by-uuid/20cc65f9-f35e-419a-b00f-252cd576b2ce"; } ];
                  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
                  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;

                  # don't suspend on lid close
                  services.logind.lidSwitch = "ignore";
                  services.glusterfs.enable = true;
                  networking.hostName = "condoserver"; # Define your hostname.


                  system.stateVersion = "22.11"; # Did you read the comment?
                }))
            ];
        };
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
                  # END HARDWARE

                  fileSystems."/var/lib/matrix-synapse/media" = {
                    device = "nathan@100.64.0.1:/home/nathan/synapse_media/media/";
                    fsType = "sshfs";
                    options = [
                      # Filesystem Options
                      "allow_other"            # non-root access
                      "_netdev"                # this is a network fs
                      "x-systemd.automount"    # mount on demand

                      # SSH options
                      "reconnect"              # handle connection drops
                      "ServerAliveInterval=15" # Keep connections alive
                      "IdentityFile=/var/lib/private/sshfs-key"
                    ];
                  };

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

                      #lemmy-server = super.lemmy-server.overrideAttrs (old: {
                      #  patches = (old.patches or []) ++ [(super.fetchpatch {
                      #    name = "fix-db-migrations.patch";
                      #    url = "https://gist.githubusercontent.com/matejc/9be474fa581c1a29592877ede461f1f2/raw/83886917153fcba127b43d9a94a49b3d90e635b3/fix-db-migrations.patch";
                      #    hash = "sha256-BvoA4K9v84n60lG96j1+91e8/ERn9WlVTGk4Z6Fj4iA=";
                      #  })];
                      #});

                  }) ];

                  # Use the GRUB 2 boot loader.
                  boot.loader.grub.enable = true;
                  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

                  swapDevices = [{
                    device = "/var/swapfile";
                    size = 4096;
                  }];

                  networking.hostName = "vps"; # Define your hostname.
                  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
                  # WireGuard
                  networking.nat.enable = true;
                  networking.nat.externalInterface = "ens3";
                  networking.nat.internalInterfaces = ["wg0"];
                  networking.firewall = {
                      #allowedTCPPorts = [ 22 80 443 3478 3479 ];
                      #allowedUDPPorts = [ 22 80 443 5349 5350 51820 ];
                      allowedTCPPorts = [ 22 80 443 8789 30000 ]; #30000 is minetest
                      allowedUDPPorts = [ 22 80 443 8789 51820 30000 ];
                      #extraCommands = ''
                      #    iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                      #'';
                  };
                  #networking.wireguard.interfaces = {
                  #    wg0 = {
                  #      ips = [ "10.100.0.1/24" ];
                  #      listenPort = 51820;
                  #      privateKeyFile = "/home/nathan/wireguard-keys/private";
                  #      peers = [
                  #        {
                  #          publicKey = "FqJShA/dz8Jj73tSyjzcsyASOEv6uAFs6e/vRol8ygc=";
                  #          allowedIPs = [ "10.100.0.2/32" ];
                  #        }
                  #        {
                  #          publicKey = "aAgay9pn/3Vj1nHC4GFY2vysW12n5VFyuUcB5+0pux8=";
                  #          allowedIPs = [ "10.100.0.3/32" ];
                  #        }
                  #        {
                  #          publicKey = "u55Jkd4dRdBqnhliIP9lwsxIYow2Tr8BhPPhKFtaVAc=";
                  #          allowedIPs = [ "10.100.0.4/32" ];
                  #        }
                  #        {
                  #          publicKey = "J/BWU33DYMkoWOKSZWrtAqWciep03YuicaDMD5MCqWg=";
                  #          allowedIPs = [ "10.100.0.5/32" ];
                  #        }
                  #        {
                  #          publicKey = "y2gAEhg1vwK1+nka2Knu7NyOk8HaaY4w18nD6EMyLSk=";
                  #          allowedIPs = [ "10.100.0.6/32" ];
                  #        }
                  #        {
                  #          publicKey = "SoaYh1mb6DYd6TuOEFl4lRCZUBTPQfOnWHIOmtkgxxM=";
                  #          allowedIPs = [ "10.100.0.7/32" ];
                  #        }
                  #      ];
                  #    };
                  #};

                  services.openssh.enable = true;
                  services.openssh.settings = {
                    PasswordAuthentication = false;
                    KbdInteractiveAuthentication = false;
                    PermitRootLogin = "prohibit-password";
                  };

                  #services.mastodon = {
                  #  enable = true;
                  #  localDomain = "mastodon.room409.xyz";
                  #  configureNginx = true;
                  #  smtp.fromAddress = "notifications@mastodon.room409.xyz";
                  #};

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

                  # for password resets run (with appropriate paths)
                  # ./k8ngn95hsi9qrdkvr734slj9fx3j3lbb-matrix-synapse-1.128.0/bin/hash_password -c /nix/store/ql794v5ilmxa619ha83ya61pk12066dh-homeserver.yaml
                  # and then use `psql -d matrix-synapse -U matrix-synapse -h localhost`
                  # with the password 'synapse'
                  # and do
                  # UPDATE users SET password_hash='$2b$12$ED4NT7N6tI4Mbq/IKZES6.oilx0k2iK4DN3a6wPWIEpXSAsIOWe3e' WHERE name='<MATRIX_USERNAME>';
                  services.matrix-synapse = {
                      enable = true;

                      settings = {
                        server_name = "synapse.room409.xyz";
                        public_baseurl = "https://synapse.room409.xyz/";

                        enable_registration = false;
                        #enable_registration_without_verification = true;
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
                            #"/var/lib/matrix-synapse/telegram-registration.yaml"
                            "/var/lib/matrix-synapse/facebook-registration.yaml"
                        ];
                      };
                  };

                  services.gitea = {
                      enable = true;
                      settings.service.DISABLE_REGISTRATION = true;
                      appName = "Room409.xyz Forge";
                      settings.server = {
                        DOMAIN = "forge.room409.xyz";
                        ROOT_URL = "https://forge.room409.xyz/";
                        HTTP_PORT = 3001;
                      };
                  };

                  #systemd.services.lemmy.environment.RUST_BACKTRACE = "full";
                  #systemd.services.lemmy.environment.LEMMY_DATABASE_URL = pkgs.lib.mkForce "postgres:///lemmy?host=/run/postgresql&user=lemmy";
                  #services.lemmy = {
                  #    enable = true;
                  #    database.createLocally = true;
                  #    settings = {
                  #        hostname = "lemmy.room409.xyz";
                  #    };
                  #    nginx.enable = true;
                  #};

                  services.postgresql = {
                      package = pkgs.postgresql_16;
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

                  services.headscale = {
                    enable = true;
                    address = "0.0.0.0";
                    port = 8789;
                    settings.serverUrl = "https://headscale.room409.xyz";
                    settings.dns.base_domain = "wg.test";
                    settings.logtail.enabled = false;
                  };

                  services.ttyd = {
                    enable = true;
                    port = 9134;
                    writeable = true;
                    username = "miloignis";
                    passwordFile = /var/lib/ttyd/secrets;
                    clientOptions.fontFamily="Recursive";
                  };

                  security.acme = {
                    acceptTerms = true;
                    defaults.email = "miloignis@gmail.com";
                  };
                  services.nginx = {
                      enable = true;
                      recommendedGzipSettings = true;
                      recommendedOptimisation = true;
                      recommendedProxySettings = true;
                      recommendedTlsSettings = true;

                      virtualHosts."headscale.room409.xyz" = {
                          forceSSL = true;
                          enableACME = true;
                          locations."/" = {
                            proxyPass = "http://localhost:8789";
                            proxyWebsockets = true;
                          };
                      };

                      ## the rest is defined by the lemmy service
                      #virtualHosts."lemmy.room409.xyz" = {
                      #    forceSSL = true;
                      #    enableACME = true;
                      #};

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
                              return 200 '{ "m.homeserver": {"base_url": "https://synapse.room409.xyz"}, "org.matrix.msc3575.proxy": { "url": "https://syncv3.room409.xyz" }, "m.identity_server":  { "base_url": "https://vector.im"} }';
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
                      virtualHosts."shell.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/" = {
                          proxyPass = "http://localhost:9134";
                          proxyWebsockets = true;
                        };
                      };
                      #virtualHosts."drop.room409.xyz" = {
                        #forceSSL = true;
                        #enableACME = true;
                        #locations."/" = {
                          #proxyPass = "http://localhost:9009";
                          #proxyWebsockets = true;
                          #extraConfig = ''
                              #client_max_body_size 500M;
                          #'';
                        #};
                      #};
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

                      virtualHosts."lotusronin.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/" = {
                          root = pkgs.writeTextDir "index.html" ''<!DOCTYPE html>
                          <html lang="en">
                              <head>
                                  <meta charset="utf-8">
                                  <title>LotusRonin's Website</title>
                                  <style>
                                      h1, h2 ,h3 { line-height:1.2; }
                                      .bodyStuff {
                                          max-width: 45em;
                                          margin: 1em auto;
                                          padding: 0 .62em;
                                          font: 1.2em/1.62 sans-serif;
                                      }
                                      .floatLeft {
                                        float: left;
                                          max-width: 55em;
                                          margin: 1em auto;
                                          padding: 0 .62em;
                                          font: 1.2em/1.62 sans-serif;
                                      }
                                  </style>
                              </head>
                              <body>
                                  <div class="bodyStuff">
                                  <header><h1>Main Page</h1></header>
                                  <br> <br>
                                  Take control of your tools, break from the system. Less is more.
                                  </div>
                                  <div class="floatLeft">
                                    <ol>
                                       <li><a href="">📜 Blog</a></li>
                                       <li><a href="">👨‍💻 Code</a></li>
                                       <li><a href="">🕹️ Games</a></li>
                                       <li><a href="">(.)(.) MLKRs.shop signup</a></li>
                                       <li><a href="">📄 Resume/About Me</a></li>
                                    </ol>
                                  </div>
                              </body>
                          </html>
                          '';
                        };
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

                      virtualHosts."batou.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/".proxyPass = "http://100.64.0.1:8090";
                      };

                      #virtualHosts."4800H.room409.xyz" = {
                      #  forceSSL = true;
                      #  enableACME = true;
                      #  locations."/".proxyPass = "http://10.100.0.7:80";
                      #};
                      virtualHosts."batou-jf.room409.xyz" = {
                        forceSSL = true;
                        enableACME = true;
                        locations."/".proxyPass = "http://100.64.0.1:8096";
                      };
                  };

                  services.journald.extraConfig = "SystemMaxUse=50M";

                  services.tailscale.enable = true;
                  environment.systemPackages = with pkgs; [
                      htop tmux git vim wget unzip file
                      iftop ripgrep
                      config.services.headscale.package
                      #wireguard
                      droopy
                      sshfs

    #  (let
    #  # XXX specify the postgresql package you'd like to upgrade to.
    #  # Do not forget to list the extensions you need.
    #  newPostgres = pkgs.postgresql_16.withPackages (pp: [
    #    # pp.plv8
    #  ]);
    #in pkgs.writeScriptBin "upgrade-pg-cluster" ''
    #  set -eux
    #  # XXX it's perhaps advisable to stop all services that depend on postgresql
    #  systemctl stop postgresql

    #  export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"

    #  export NEWBIN="${newPostgres}/bin"

    #  export OLDDATA="${config.services.postgresql.dataDir}"
    #  export OLDBIN="${config.services.postgresql.package}/bin"

    #  install -d -m 0700 -o postgres -g postgres "$NEWDATA"
    #  cd "$NEWDATA"
    #  sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

    #  sudo -u postgres $NEWBIN/pg_upgrade \
    #    --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
    #    --old-bindir $OLDBIN --new-bindir $NEWBIN \
    #    "$@"
    #'')


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
                      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjyWh/SPOgx+yOgrc8g8+7PR0+CWMrWZ4PaWcmgDzfUGAWyj2FHBNG2gLvIKn4+TAwvbEPp+7YXxlmiYltUWNlEXEzryhrhYiqeun9uApT+fgzxF278/VeS+NErX4S2WGwhUdybk6MSs0cpUVp+TNiZFUH+ltTcLai3aLaMaL13Z024DzjpD4jRVG4PErHTe/6dTfdmg6AS7gB0b+LTjFzdYSdeYsHxqcig+d+34vQkNmV2dIvLpNkbpzyfUyE3g1gpYTgRKgY4mZqd6QUKOyIH0SDqPUDrmK6e1LK2yTYe1jP39G2JhAMOrSm8jEFm7RLxHXJ862EqD8gFV2aCQ2HUFlFpx7t02Tgvw80grQRoJKJyYtElO6CAr+oFnhxWnYgUsoYmGLSp5Nv1wV9WHkprWnGyuj/CGM8D3gwFSL672IYQOGTwQElcclRZ/uMlNjtyw6ky4VV22gDZag1hMfZhWf/nmMNql8dCoqY7K36XAAEDXjiS5J9EZe7AexLV68= nathan@nixos_4800H" # laptop

                      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtmGhDNdwDXulhJ8MGehlfLQZ8Qzxv2K4vXqyvJWSkMj5XzCRcylKME0qdfiA+G0SeozCY2Qhd2xiPsaL3PaZX7HD1fiesO0jofl9Ph+VIbwwP2LT7kYYSoUXSdj3uPBdZD8BhSZsMHIPVQfzj5JkvE1W9AQik+d5o7RPO8srpo8JHRpH0lgJbuiLWkpLX2sD2hjlI5uMhMekGnI0UA3ie3x9Xnh3J019X0K3Efxm8X31k60j9J0bgGLhxYwu42+kiJKabdpk5tFsqLvDRbzPUGSm+5ZiWMX5ILDbr+/Aczzb2ek5rzsEB2s48BmxBtJnXfjnQtBo6URuJYzVSI9V6vEgUnueGPY/DN1oeRZqTcqujIADh3ZMcdKg1cfdvNYoSk2FcFz0rZXTLjkwOAK2HMRZFXK5ijX7tpnb5GXsiDa0uoWhJVByzrnlqZ65LuHdLFPbe+A/N+T3wzykIkG2hNv8mRJi7/pWjNy2O2iKsSSSabN5xjxI7aFzyUQK+23UF2wzLc1+f4qMcB5HoHhktOV1QRM4RKtvYhdkAG0O/C5Wu0BItrjQbAoqSa29QLlBpHCIlY4Vr8S4kNXf8mm8gRrKATHNZBTUAVNMDYFcd9n4hyK8ERGodaXFDP7m/r+yZaHLcpQQ46sYjq2nbkP1yYaCbmVoEEUpKRtP2UDc91w== miloignis@gmail.com" # desktop

                      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSG8Mi192YYB1PSmRUQGT0WxMuG8f3HKmdC6Y/NTKlRZDMeyV81cxmJpMjpKszc0P5e0j6F4Q1y9R0GybRPVFFgA5I5ETReWcJ1pe8Bs/BxZpxcl/fESUl2YOoEWxGzwha7CAIAlgMFTljj9osYTx+b8j+6MFhlsRnUCaxngRle2JeSmkCFYMlkKjynTHME4OjfRb3xR1VmB489s25tMmRjpzGuD6+5o0x+nX3yk8t711vKcuYx0irwi3sn4w9bKXamPOZH/5sCNz1Q7Qgz9BWOPYXMpnYytDcps7ACAqpKu3etzBvMQo+TZzivr+yZhePhUWovE1HpPVTBqEf3D+ekHZ5ZdQ6Y4W3/16WdDYCq9eCdZvsPOAFi9Sl/lf74LuzEqD1pPHg7avh7+fNJN2r0KoyozuvDSIwW8Kwo1uSav0XCHvdsFmSUmEXjwb4M2Bue6XDWCrVa8FiRpS1F/uvLgdWsZIkBJCX6vy6zPkFMJoKG9IdT4KYCn1KW3ifwTs= nathan@nixos" #condoserver

                    ];
                  };
                  
                  system.stateVersion = "20.03";
              })
            ];
        };
    };
}

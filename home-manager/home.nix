{ username, homeDirectory }: ({ config, pkgs, lib, ... }:{
                  # This value determines the Home Manager release that your
                  # configuration is compatible with. This helps avoid breakage
                  # when a new Home Manager release introduces backwards
                  # incompatible changes.
                  #
                  # You can update Home Manager without changing this value. See
                  # the Home Manager release notes for a list of state version
                  # changes in each release.
                  home.stateVersion = "22.11";
                  home.username = username;
                  home.homeDirectory = homeDirectory;
                  
                  fonts.fontconfig.enable = true;
                  home.packages = with pkgs; [
                    fira-code jetbrains-mono iosevka monoid recursive inter
                    xwayland-satellite swww
                    niri
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
                        opacity = 0.85;
                        #opacity = 0.95;
                      }
                    ];
                    layout = {
                      gaps = 8;
                      #gaps = 16;
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

                      "Alt+S".action.screenshot.show-pointer = false;
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
                      . "$HOME/.cargo/env"
                      export PATH="/run/system-manager/sw/bin/:/home/nbraswell6/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
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
                    lfs.enable = true;
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
              })

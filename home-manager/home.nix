{ username, homeDirectory, backgroundImg, email }: ({ config, pkgs, lib, ... }:{
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
                    xwayland-satellite
                    swww
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
                    # TV at 1080 instead of 4k
                    #outputs."DP-4".mode = {
                    #  width = 1920;
                    #  height = 1080;
                    #  refresh = 60.000;
                    #};
                    ## LG Ultrawide
                    #outputs."DP-4".mode = {
                    #  width = 1920;
                    #  height = 1080;
                    #  refresh = 60.000;
                    #};
                    input.keyboard.xkb = {
                      options = "ctrl:nocaps";
                    };
                    environment = {
                      DISPLAY = ":0"; # xwayland-satellite
                    };
                    spawn-at-startup = [
                      { command = [ "awww-daemon" ]; }
                      { command = [ "awww" "img" "${backgroundImg}" ]; }
                      #{ command = [ "swww-daemon" ]; }
                      #{ command = [ "swww" "img" "${backgroundImg}" ]; }
                      { command = [ "waybar" ]; }
                      { command = [ "xwayland-satellite" ]; }
                    ];
                    window-rules = [
                      {
                        draw-border-with-background = false;
                        geometry-corner-radius = let r = 2.0; in {
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
                        #opacity = 0.95;
                      }
                    ];
                    layout = {
                      gaps = 4;
                      #gaps = 4;
                      #gaps = 8;
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
                      border.width = 2;
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
                      #"Super+P".action = spawn "bemenu-run";
                      "Super+P".action = spawn "fuzzel";
                      "Super+Return".action = spawn "wezterm";
                      "Super+Shift+Return".action = spawn "foot";
                      "Super+Shift+Slash".action = show-hotkey-overlay;

                      "Super+Shift+C".action = close-window;

                      "Super+Left"  .action = focus-column-left;
                      "Super+Down"  .action = focus-window-down;
                      "Super+Up"    .action = focus-window-up;
                      "Super+Right" .action = focus-column-right;
                      "Super+H"     .action = focus-column-left;
                      #"Super+J"     .action = focus-window-down;
                      #"Super+K"     .action = focus-window-up;
                      "Super+L"     .action = focus-column-right;

                      "Super+Shift+Left"  .action = move-column-left;
                      "Super+Shift+Down"  .action = move-window-down;
                      "Super+Shift+Up"    .action = move-window-up;
                      "Super+Shift+Right" .action = move-column-right;
                      "Super+Shift+H"     .action = move-column-left;
                      #"Super+Shift+J"     .action = move-window-down;
                      #"Super+Shift+K"     .action = move-window-up;
                      "Super+Shift+L"     .action = move-column-right;

                      # Nice alts
                      "Super+J"      .action = focus-window-or-workspace-down;
                      "Super+K"      .action = focus-window-or-workspace-up;
                      "Super+Shift+J".action = move-window-down-or-to-workspace-down;
                      "Super+Shift+K".action = move-window-up-or-to-workspace-up;


                      "Super+Ctrl+Left" .action = focus-monitor-left;
                      "Super+Ctrl+Down" .action = focus-monitor-down;
                      "Super+Ctrl+Up"   .action = focus-monitor-up;
                      "Super+Ctrl+Right".action = focus-monitor-right;
                      "Super+Ctrl+H"    .action = focus-monitor-left;
                      "Super+Ctrl+J"    .action = focus-monitor-down;
                      "Super+Ctrl+K"    .action = focus-monitor-up;
                      "Super+Ctrl+L"    .action = focus-monitor-right;

                      "Super+Shift+Ctrl+Left"  .action = move-column-to-monitor-left;
                      "Super+Shift+Ctrl+Down"  .action = move-column-to-monitor-down;
                      "Super+Shift+Ctrl+Up"    .action = move-column-to-monitor-up;
                      "Super+Shift+Ctrl+Right" .action = move-column-to-monitor-right;
                      "Super+Shift+Ctrl+H"     .action = move-column-to-monitor-left;
                      "Super+Shift+Ctrl+J"     .action = move-column-to-monitor-down;
                      "Super+Shift+Ctrl+K"     .action = move-column-to-monitor-up;
                      "Super+Shift+Ctrl+L"     .action = move-column-to-monitor-right;


                      #...
                      "Super+1".action = focus-workspace 1;
                      "Super+2".action = focus-workspace 2;
                      "Super+3".action = focus-workspace 3;
                      "Super+4".action = focus-workspace 4;
                      "Super+5".action = focus-workspace 5;
                      "Super+6".action = focus-workspace 6;
                      "Super+7".action = focus-workspace 7;
                      "Super+8".action = focus-workspace 8;
                      "Super+9".action = focus-workspace 9;
                      #"Super+Shift+1".action = move-column-to-workspace 1;
                      #"Super+Shift+2".action = move-column-to-workspace 2;
                      #"Super+Shift+3".action = move-column-to-workspace 3;
                      #"Super+Shift+4".action = move-column-to-workspace 4;
                      #"Super+Shift+5".action = move-column-to-workspace 5;
                      #"Super+Shift+6".action = move-column-to-workspace 6;
                      #"Super+Shift+7".action = move-column-to-workspace 7;
                      #"Super+Shift+8".action = move-column-to-workspace 8;
                      #"Super+Shift+9".action = move-column-to-workspace 9;

                      #Consume one window from the right into the focused column.
                      "Super+Comma"  .action = consume-window-into-column;
                      #Expel one window from the focused column to the right.
                      "Super+Period" .action = expel-window-from-column;

                      #There are also commands that consume or expel a single window to the side.
                      "Super+BracketLeft"  .action = consume-or-expel-window-left;
                      "Super+BracketRight" .action = consume-or-expel-window-right;

                      "Super+R".action = switch-preset-column-width;
                      "Super+Shift+R".action = switch-preset-window-height;
                      "Super+Ctrl+R".action = reset-window-height;
                      "Super+F".action = maximize-column;
                      "Super+Shift+F".action = fullscreen-window;
                      "Super+C".action = center-column;

                      "Super+Minus".action = set-column-width "-10%";
                      "Super+Equal".action = set-column-width "+10%";

                      "Super+Shift+Minus".action = set-window-height "-10%";
                      "Super+Shift+Equal".action = set-window-height "+10%";

                      "Super+S".action.screenshot.show-pointer = false;
                      #"Print".action = screenshot;
                      #"Ctrl+Print".aciton = screenshot-screen;
                      #"Super+Print".action = screenshot-window;

                      "Super+Shift+E".action = quit;
                      "Ctrl+Super+Delete".action = quit;

                      "Super+Shift+P".action = power-off-monitors;
                    };
                  };
                  programs.firefox = {
                    enable = true;
                    profiles = let 
                      shared = {
                        search = {
                          force = true;
                          default = "Kagi";
                          engines = {
                            "Kagi" = {
                              urls = [
                                {
                                  template = "https://kagi.com/search?q={searchTerms}";
                                }
                              ];
                            };
                          };
                        };
                        settings = {
                          extensions.autoDisableScopes = 0;
                        };
                        extensions = {
                          force = true;
                          packages = with pkgs.nur.repos.rycee.firefox-addons; [
                            vimium
                            darkreader
                            bitwarden
                            ublock-origin
                          ];
                        };
                      };
                    in {
                      default = shared //  {
                        isDefault = true;
                        id = 0;
                      };
                      st = shared // {
                        isDefault = false;
                        id = 1;
                      };
                    };
                  };
                  stylix.targets.firefox = {
                    colorTheme.enable = true;
                    profileNames = [ "default" "st" ];
                  };

                  programs.wezterm = {
                    enable = true;
                    extraConfig = ''
                      config.hide_tab_bar_if_only_one_tab = true;
                      config.line_height = 0.98; -- matching ghostty
                      config.window_padding = {
                        left   = 0,
                        right  = 0,
                        top    = 0,
                        bottom = 0,
                      };
                    '';
                  };

                  programs.ghostty = {
                    enable = true;
                    settings = {
                      window-decoration = false;
                      minimum-contrast = 1.5;
                    };
                  };
                  programs.foot = {
                    enable = true;
                    settings = {
                      main = {
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
                      EDITOR = "vim";
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
                    userEmail = email;
                  };
                  programs.jujutsu = {
                    enable = true;
                    settings.user = {
                      name = "Nathan Braswell";
                      email = email;
                    };
                  };
                  programs.helix = {
                    enable = true;
                    settings = {
                      keys.insert.k.j = "normal_mode";
                    };
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
                  programs.zellij = {
                    enable = true;
                    settings = {
                      pane_frames = false;
                      # default_layout = "compact";
                      default_mode = "locked";
                    };
                    extraConfig = ''
                      keybinds clear-defaults=true {
                          normal {
                          }
                          locked {
                              bind "Ctrl g" { SwitchToMode "Normal"; }
                          }
                          resize {
                              bind "r" { SwitchToMode "Normal"; }
                              bind "h" "Left" { Resize "Increase Left"; }
                              bind "j" "Down" { Resize "Increase Down"; }
                              bind "k" "Up" { Resize "Increase Up"; }
                              bind "l" "Right" { Resize "Increase Right"; }
                              bind "H" { Resize "Decrease Left"; }
                              bind "J" { Resize "Decrease Down"; }
                              bind "K" { Resize "Decrease Up"; }
                              bind "L" { Resize "Decrease Right"; }
                              bind "=" "+" { Resize "Increase"; }
                              bind "-" { Resize "Decrease"; }
                          }
                          pane {
                              bind "p" { SwitchToMode "Normal"; }
                              bind "h" "Left" { MoveFocus "Left"; }
                              bind "l" "Right" { MoveFocus "Right"; }
                              bind "j" "Down" { MoveFocus "Down"; }
                              bind "k" "Up" { MoveFocus "Up"; }
                              bind "Tab" { SwitchFocus; }
                              bind "n" { NewPane; SwitchToMode "Locked"; }
                              bind "d" { NewPane "Down"; SwitchToMode "Locked"; }
                              bind "r" { NewPane "Right"; SwitchToMode "Locked"; }
                              bind "s" { NewPane "stacked"; SwitchToMode "Locked"; }
                              bind "x" { CloseFocus; SwitchToMode "Locked"; }
                              bind "f" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
                              bind "z" { TogglePaneFrames; SwitchToMode "Locked"; }
                              bind "w" { ToggleFloatingPanes; SwitchToMode "Locked"; }
                              bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
                              bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
                              bind "i" { TogglePanePinned; SwitchToMode "Locked"; }
                          }
                          move {
                              bind "m" { SwitchToMode "Normal"; }
                              bind "n" "Tab" { MovePane; }
                              bind "p" { MovePaneBackwards; }
                              bind "h" "Left" { MovePane "Left"; }
                              bind "j" "Down" { MovePane "Down"; }
                              bind "k" "Up" { MovePane "Up"; }
                              bind "l" "Right" { MovePane "Right"; }
                          }
                          tab {
                              bind "t" { SwitchToMode "Normal"; }
                              bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
                              bind "h" "Left" "Up" "k" { GoToPreviousTab; }
                              bind "l" "Right" "Down" "j" { GoToNextTab; }
                              bind "n" { NewTab; SwitchToMode "Locked"; }
                              bind "x" { CloseTab; SwitchToMode "Locked"; }
                              bind "s" { ToggleActiveSyncTab; SwitchToMode "Locked"; }
                              bind "b" { BreakPane; SwitchToMode "Locked"; }
                              bind "]" { BreakPaneRight; SwitchToMode "Locked"; }
                              bind "[" { BreakPaneLeft; SwitchToMode "Locked"; }
                              bind "1" { GoToTab 1; SwitchToMode "Locked"; }
                              bind "2" { GoToTab 2; SwitchToMode "Locked"; }
                              bind "3" { GoToTab 3; SwitchToMode "Locked"; }
                              bind "4" { GoToTab 4; SwitchToMode "Locked"; }
                              bind "5" { GoToTab 5; SwitchToMode "Locked"; }
                              bind "6" { GoToTab 6; SwitchToMode "Locked"; }
                              bind "7" { GoToTab 7; SwitchToMode "Locked"; }
                              bind "8" { GoToTab 8; SwitchToMode "Locked"; }
                              bind "9" { GoToTab 9; SwitchToMode "Locked"; }
                              bind "Tab" { ToggleTab; }
                          }
                          scroll {
                              bind "s" { SwitchToMode "Normal"; }
                              bind "e" { EditScrollback; SwitchToMode "Locked"; }
                              bind "f" { SwitchToMode "EnterSearch"; SearchInput 0; }
                              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
                              bind "j" "Down" { ScrollDown; }
                              bind "k" "Up" { ScrollUp; }
                              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                              bind "d" { HalfPageScrollDown; }
                              bind "u" { HalfPageScrollUp; }
                              bind "Alt left" { MoveFocusOrTab "left"; SwitchToMode "locked"; }
                              bind "Alt down" { MoveFocus "down"; SwitchToMode "locked"; }
                              bind "Alt up" { MoveFocus "up"; SwitchToMode "locked"; }
                              bind "Alt right" { MoveFocusOrTab "right"; SwitchToMode "locked"; }
                              bind "Alt h" { MoveFocusOrTab "left"; SwitchToMode "locked"; }
                              bind "Alt j" { MoveFocus "down"; SwitchToMode "locked"; }
                              bind "Alt k" { MoveFocus "up"; SwitchToMode "locked"; }
                              bind "Alt l" { MoveFocusOrTab "right"; SwitchToMode "locked"; }
                          }
                          search {
                              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
                              bind "j" "Down" { ScrollDown; }
                              bind "k" "Up" { ScrollUp; }
                              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                              bind "d" { HalfPageScrollDown; }
                              bind "u" { HalfPageScrollUp; }
                              bind "n" { Search "down"; }
                              bind "p" { Search "up"; }
                              bind "c" { SearchToggleOption "CaseSensitivity"; }
                              bind "w" { SearchToggleOption "Wrap"; }
                              bind "o" { SearchToggleOption "WholeWord"; }
                          }
                          entersearch {
                              bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
                              bind "Enter" { SwitchToMode "Search"; }
                          }
                          renametab {
                              bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
                              bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
                          }
                          renamepane {
                              bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
                              bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
                          }
                          session {
                              bind "o" { SwitchToMode "Normal"; }
                              bind "d" { Detach; }
                              bind "w" {
                                  LaunchOrFocusPlugin "session-manager" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                              bind "c" {
                                  LaunchOrFocusPlugin "configuration" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                              bind "p" {
                                  LaunchOrFocusPlugin "plugin-manager" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                              bind "a" {
                                  LaunchOrFocusPlugin "zellij:about" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                              bind "s" {
                                  LaunchOrFocusPlugin "zellij:share" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                              bind "l" {
                                  LaunchOrFocusPlugin "zellij:layout-manager" {
                                      floating true
                                      move_to_focused_tab true
                                  };
                                  SwitchToMode "Locked"
                              }
                          }
                          shared_except "locked" "renametab" "renamepane" {
                              bind "Ctrl g" { SwitchToMode "Locked"; }
                              bind "Ctrl q" { Quit; }
                          }
                          shared_except "renamepane" "renametab" "entersearch" "locked" {
                              bind "esc" { SwitchToMode "locked"; }
                          }
                          shared_among "normal" "locked" {
                              bind "Alt n" { NewPane; }
                              bind "Alt f" { ToggleFloatingPanes; }
                              bind "Alt i" { MoveTab "Left"; }
                              bind "Alt o" { MoveTab "Right"; }
                              bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
                              bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
                              bind "Alt j" "Alt Down" { MoveFocus "Down"; }
                              bind "Alt k" "Alt Up" { MoveFocus "Up"; }
                              bind "Alt =" "Alt +" { Resize "Increase"; }
                              bind "Alt -" { Resize "Decrease"; }
                              bind "Alt [" { PreviousSwapLayout; }
                              bind "Alt ]" { NextSwapLayout; }
                              bind "Alt p" { TogglePaneInGroup; }
                              bind "Alt Shift p" { ToggleGroupMarking; }
                          }
                          shared_except "locked" "renametab" "renamepane" {
                              bind "Enter" { SwitchToMode "Locked"; }
                          }
                          shared_except "pane" "locked" "renametab" "renamepane" "entersearch" {
                              bind "p" { SwitchToMode "Pane"; }
                          }
                          shared_except "resize" "locked" "renametab" "renamepane" "entersearch" {
                              bind "r" { SwitchToMode "Resize"; }
                          }
                          shared_except "scroll" "locked" "renametab" "renamepane" "entersearch" {
                              bind "s" { SwitchToMode "Scroll"; }
                          }
                          shared_except "session" "locked" "renametab" "renamepane" "entersearch" {
                              bind "o" { SwitchToMode "Session"; }
                          }
                          shared_except "tab" "locked" "renametab" "renamepane" "entersearch" {
                              bind "t" { SwitchToMode "Tab"; }
                          }
                          shared_except "move" "locked" "renametab" "renamepane" "entersearch" {
                              bind "m" { SwitchToMode "Move"; }
                          }
                      }
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
                    package = pkgs.emacs-pgtk;
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

                      (setq evil-want-C-u-scroll t)
                      (setq evil-want-keybinding nil)
                      (evil-mode 1)
                      (evil-set-undo-system 'undo-redo)
                      (setq key-chord-two-keys-delay 0.5)
                      (key-chord-define evil-insert-state-map "jk" 'evil-normal-state)
                      (evil-collection-init)
                      (key-chord-mode 1)

                      (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
                      (add-hook 'prog-mode-hook 'display-line-numbers-mode)
                      ;(load-theme 'dracula t)
                    '';
                    extraPackages = epkgs: with epkgs; [
                      evil key-chord magit proof-general
                      ement nov evil-collection
                      rainbow-delimiters
                      dracula-theme
                    ];
                  };
                  #services.pantalaimon = {
                    #package = pkgs.pantalaimon.overridePythonAttrs { doCheck = false; };
                    #enable = true;
                    #settings = {
                        #Default = {
                          #LogLevel = "Debug";
                          #SSL = true;
                        #};
                        #local-matrix = {
                          #Homeserver = "https://synapse.room409.xyz";
                          #ListenAddress = "127.0.0.1";
                          #ListenPort = "8009";
                        #};
                    #};
                  #};
                  #programs.iamb = {
                  #  enable = true;
                  #  settings = {
                  #    settings = {
                  #      image_preview = {};
                  #      username_display = "displayname";
                  #      sort = {
                  #        rooms = ["recent"];
                  #      };
                  #    };
                  #    profiles.miloignis = {
                  #      user_id = "@miloignis:synapse.room409.xyz";
                  #    };
                  #  };
                  #};
              })

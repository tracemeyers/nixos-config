# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Need the latest for i7dwarf
  boot.kernelPackages = pkgs.linuxPackages_testing;

  # EXPERIMENT - https://unix.stackexchange.com/a/620734
  # I've been having plasmashell lockups. When this happens I can't even run
  # sudo commands as they hang. Apparently sudo doesn't work if the network
  # stack goes down and it can't make dns calls. Try this for a while to see if
  # it resolves the sudo hang problem (the plasmashell problem probably won't
  # be affected).
  security.sudo.extraConfig = ''
    Defaults !fqdn
  '';

  networking.hostName = "i7dwarf"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;  # Easiest to use and most distros use this by default.
    dns = "systemd-resolved";
  };
  services.resolved = {
    enable = true;
    extraConfig = ''
      # https://man.archlinux.org/man/resolved.conf.5

      [Resolve]
      FallbackDNS=
      DNS=10.171.96.39#belcamp.lab
      Domains=~belcamp.lab
      DNS=10.171.96.39#protectv.local
      Domains=~protectv.local
    '';
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.extraHosts = ''
    52.86.120.81 staging
  '';

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the Plasma 5 Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager = {
    sddm.enable = true;
    defaultSession = "plasma5+i3+whatever";
    session = [
        {
            manage = "desktop";
            name = "plasma5+i3+whatever";
            start = ''exec env KDEWM=${pkgs.i3}/bin/i3 ${pkgs.plasma-workspace}/bin/startplasma-x11'';
        }
    ];
  };
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.windowManager.i3.enable = true;
  

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.bluetooth.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cat = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel" # Enable ‘sudo’ for the user.
    ];
    packages = with pkgs; [
      home-manager
    ];
    initialPassword = "todo";
  };

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cascadia-code
    chromium
    clang
    curl
    dig
    docker
    docker-compose
    firefox
    gcc
    i3
    ncdu
    neovim
    networkmanagerapplet
    source-code-pro
    tree
    ubuntu_font_family
    wget
    wireguard-tools
    xclip			# for neovim copying/pasting to system clipboard
    yakuake
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.nat.enable = true;
  networking.nat.externalInterface = "wlo1";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
    allowedUDPPorts = [ 51820 ];
  };
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
  networking.wg-quick.interfaces = let
    ext-iface = "wlo1";
    wg-iface = "wg0";
    wg-address = "192.168.111.102";
  in {
    ${wg-iface} = {
      address = [ "${wg-address}/24" ];
      listenPort = 51820;
      privateKeyFile = "/home/cat/wireguard-keys/private";

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      #postUp = ''
      #  ${pkgs.iptables}/bin/iptables -A FORWARD -i ${wg-iface} -j ACCEPT
      #  ${pkgs.iptables}/bin/iptables -A FORWARD -o ${wg-iface} -j ACCEPT
      #  ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${wg-address} -o ${ext-iface} -j MASQUERADE
      #'';

      #preDown = ''
      #  ${pkgs.iptables}/bin/iptables -D FORWARD -i ${wg-iface} -j ACCEPT
      #  ${pkgs.iptables}/bin/iptables -D FORWARD -o ${wg-iface} -j ACCEPT
      #  ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${wg-address} -o ${ext-iface} -j MASQUERADE
      #'';

      peers = [
        { # workdwarf
          publicKey = "VwIilFnB+WyUi692bcsq3jh3LbezXrjrWjcXEVo4bSI=";
          allowedIPs = [ "192.168.111.100/32" "10.0.0.0/8" ];
	  persistentKeepalive = 5;
        }
	{
	  # htpc
          publicKey = "JEYiDR0op110xB+bmXJIUNAccBgSwPL0FnUzesstxkU=";
	  endpoint = "192.168.1.100:51820";
          allowedIPs = [ "192.168.111.1/32" ];
	  persistentKeepalive = 5;
	}
      ];
    };
  };

  virtualisation.docker.enable = true;

  systemd.user.services.i3plasma = {
    enable = true;
    description = "i3plasma";

    wantedBy = ["plasma-workspace.target"];
    before = ["plasma-workspace.target"];

    serviceConfig               = {
      #Type      = "forking";
      #ExecStart = "exec ${pkgs.i3}/bin/i3";
      #ExecStart = "${pkgs.i3}/bin/i3";

      # Somehow this used to work w/o this. Then all of the sudden it stopped
      # and I have no idea why, but I also don't know why it worked before
      # either.
      # https://github.com/NixOS/nixpkgs/issues/7329
      #ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; ${pkgs.i3}/bin/i3'";
      ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.i3}/bin/i3'";
      Slice     = "session.slice";
      Restart   = "on-failure";
    };

    path = [
      pkgs.i3
      pkgs.networkmanagerapplet
    ];

    #environment = {
    #};
  };

  services.xserver.windowManager.i3.configFile = builtins.toFile "i3.config" ''
      # This file has been auto-generated by i3-config-wizard(1).
      # It will not be overwritten, so edit it as you like.
      #
      # Should you change your keyboard layout some time, delete
      # this file and re-run i3-config-wizard(1).
      #
      
      # i3 config file (v4)
      #
      # Please see https://i3wm.org/docs/userguide.html for a complete reference!
      
      set $mod Mod1
      
      # Font for window titles. Will also be used by the bar unless a different font
      # is used in the bar {} block below.
      font pango:monospace 9
      
      # This font is widely installed, provides lots of unicode glyphs, right-to-left
      # text rendering and scalability on retina/hidpi displays (thanks to pango).
      #font pango:DejaVu Sans Mono 8
      
      # Before i3 v4.8, we used to recommend this one as the default:
      # font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
      # The font above is very space-efficient, that is, it looks good, sharp and
      # clear in small sizes. However, its unicode glyph coverage is limited, the old
      # X core fonts rendering does not support right-to-left and this being a bitmap
      # font, it doesn’t scale on retina/hidpi displays.
      
      # Use Mouse+$mod to drag floating windows to their wanted position
      floating_modifier $mod
      
      # start a terminal
      bindsym $mod+Return exec konsole
      
      # kill focused window
      bindsym $mod+Shift+q kill
      
      # start dmenu (a program launcher)
      #bindsym $mod+d exec dmenu_run
      bindsym $mod+d exec rofi -show run
      # There also is the (new) i3-dmenu-desktop which only displays applications
      # shipping a .desktop file. It is a wrapper around dmenu, so you need that
      # installed.
      # bindsym $mod+d exec --no-startup-id i3-dmenu-desktop
      
      # change focus
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right
      
      # alternatively, you can use the cursor keys:
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right
      
      # move focused window
      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+j move down
      bindsym $mod+Shift+k move up
      bindsym $mod+Shift+l move right
      
      # alternatively, you can use the cursor keys:
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right
      
      # split in horizontal orientation
      #bindsym $mod+h split h
      
      # split in vertical orientation
      bindsym $mod+v split v
      
      # enter fullscreen mode for the focused container
      bindsym $mod+f fullscreen toggle
      
      # change container layout (stacked, tabbed, toggle split)
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split
      
      # toggle tiling / floating
      bindsym $mod+Shift+space floating toggle
      
      # change focus between tiling / floating windows
      bindsym $mod+space focus mode_toggle
      
      # focus the parent container
      bindsym $mod+a focus parent
      
      # focus the child container
      #bindsym $mod+d focus child
      
      # switch to workspace
      bindsym $mod+1 workspace 1
      bindsym $mod+2 workspace 2
      bindsym $mod+3 workspace 3
      bindsym $mod+4 workspace 4
      bindsym $mod+5 workspace 5
      bindsym $mod+6 workspace 6
      bindsym $mod+7 workspace 7
      bindsym $mod+8 workspace 8
      bindsym $mod+9 workspace 9
      bindsym $mod+0 workspace 10
      
      # move focused container to workspace
      bindsym $mod+Shift+1 move container to workspace 1
      bindsym $mod+Shift+2 move container to workspace 2
      bindsym $mod+Shift+3 move container to workspace 3
      bindsym $mod+Shift+4 move container to workspace 4
      bindsym $mod+Shift+5 move container to workspace 5
      bindsym $mod+Shift+6 move container to workspace 6
      bindsym $mod+Shift+7 move container to workspace 7
      bindsym $mod+Shift+8 move container to workspace 8
      bindsym $mod+Shift+9 move container to workspace 9
      bindsym $mod+Shift+0 move container to workspace 10
      
      # reload the configuration file
      bindsym $mod+Shift+c reload
      # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
      bindsym $mod+Shift+r restart
      # exit i3 (logs you out of your X session)
      #bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"
      
      # resize window (you can also use the mouse for that)
      mode "resize" {
              # These bindings trigger as soon as you enter the resize mode
      
              # Pressing left will shrink the window’s width.
              # Pressing right will grow the window’s width.
              # Pressing up will shrink the window’s height.
              # Pressing down will grow the window’s height.
              bindsym h resize grow width 10 px or 10 ppt
              bindsym k resize grow height 10 px or 10 ppt
              bindsym j resize shrink height 10 px or 10 ppt
              bindsym l resize shrink width 10 px or 10 ppt
      
              # same bindings, but for the arrow keys
              bindsym Left resize shrink width 10 px or 10 ppt
              bindsym Down resize grow height 10 px or 10 ppt
              bindsym Up resize shrink height 10 px or 10 ppt
              bindsym Right resize grow width 10 px or 10 ppt
      
              # back to normal: Enter or Escape
              bindsym Return mode "default"
              bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"
      
      bindsym $mod+shift+s sticky toggle
      
      ## Start i3bar to display a workspace bar (plus the system information i3status
      ## finds out, if available)
      #bar {
      ##        status_command i3status
      #    status_command SCRIPT_DIR=~/.config/i3blocks i3blocks
      #    #font pango:DejaVu Sans Mono 14
      #    font pango:monospace 12
      #}
      
      #exec /usr/bin/vmware-user
      #
      exec --no-startup-id deadd-notification-center
      #exec --no-startup-id compton --config ~/.config/compton.conf -b
      
      bindsym $mod+n exec ~/bin/notifications.sh
      
      for_window [class="Slack" floating] move container to workspace current
      
      #####################################
      # Plasma compatibility improvements
      for_window [window_role="pop-up"] floating enable
      for_window [window_role="task_dialog"] floating enable
      for_window [class="yakuake"] floating enable
      for_window [class="systemsettings"] floating enable
      for_window [class="plasmashell"] floating enable;
      for_window [class="Plasma"] floating enable; border none
      for_window [title="plasma-desktop"] floating enable; border none
      for_window [title="win7"] floating enable; border none
      for_window [class="krunner"] floating enable; border none
      for_window [class="Kmix"] floating enable; border none
      for_window [class="Klipper"] floating enable; border none
      for_window [class="Plasmoidviewer"] floating enable; border none
      for_window [class="(?i)*nextcloud*"] floating disable
      for_window [class="plasmashell" window_type="notification"] border none, move right 700px, move down 450px
      no_focus [class="plasmashell" window_type="notification"]
      # kill the desktop
      for_window [title="Desktop — Plasma"] kill; floating enable; border none
      # using plasma's logout screen instead of i3's
      bindsym $mod+Shift+e exec --no-startup-id qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout -1 -1 -1
      # Kill the bar
      bar {
          mode hide
      }

      for_window [title="Desktop — Plasma"] kill, floating enable, border none
      for_window [class="plasmashell"] floating enable
      for_window [class="Plasma"] floating enable, border none
      for_window [title="plasma-desktop"] floating enable, border none
      for_window [title="win7"] floating enable, border none
      for_window [class="krunner"] floating enable, border none
      for_window [class="Kmix"] floating enable, border none
      for_window [class="Klipper"] floating enable, border none
      for_window [class="Plasmoidviewer"] floating enable, border none
      for_window [class="(?i)*nextcloud*"] floating disable
      for_window [class="plasmashell" window_type="notification"] floating enable, border none, move right 700px, move down 450px
      no_focus [class="plasmashell" window_type="notification"] 
    '';

  home-manager.users.cat = { pkgs, ... }: {
    home.stateVersion = "22.11"; # REQUIRED!
    home.packages = with pkgs; [
      git
      # ...
    ];
    programs.bash.enable = true;
  };

  #home-manager.useUserPackages = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}


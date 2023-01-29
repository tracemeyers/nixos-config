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

  home-manager.users.cat = { pkgs, ... }: {
    home.stateVersion = "22.11"; # REQUIRED!
    home.packages = with pkgs; [
      git
      # ...
    ];
    programs.bash.enable = true;
  };

  #home-manager.useUserPackages = true;

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

  # TODO - try to set this up manually and then migrate it to nix. Otherwise a bit complicated to get right
  systemd.user.services.i3plasma = {
    enable = true;
    description                 = "i3plasma";

    wantedBy = ["plasma-workspace.target"];
    before = ["plasma-workspace.target"];

    serviceConfig               = {
      #Type      = "forking";
      #ExecStart = "exec ${pkgs.i3}/bin/i3";
      ExecStart = "${pkgs.i3}/bin/i3";
      Slice     = "session.slice";
      Restart   = "on-failure";
    };

    path = [
      pkgs.i3
      pkgs.networkmanagerapplet
    ];

    environment = {
    };
  };

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


{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cat";
  home.homeDirectory = "/home/cat";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    git
    powerline-go
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash.enable = true;

  programs.git = {
    enable = true;
    userName = "Trace Meyers";
    userEmail = "1397338+tracemeyers@users.noreply.github.com";
    aliases = {
      outgoing = "log --branches --not --remotes=origin --oneline";
    };
    extraConfig = {
    };

    includes = [
      {
        condition = "gitdir:~/dev/github.com";
        contents = {
          user = {
            email = "1397338+tracemeyers@users.noreply.github.com";
            name = "Trace Meyers";
          };
        };
      }
    ];
  };

  programs.powerline-go = {
    enable = true;
    modules = [
      "venv"
      "user"
      "host"
      "ssh"
      "cwd"
      "perms"
      "jobs"
    ];
    modulesRight = [
      "git"
      "hg"
      "exit"
    ];
    newline = true;
    settings = {
      #condensed = true;
      cwd-mode = "plain";
      hostname-only-if-ssh = true;
      static-prompt-indicator = true;
    };

    #extraUpdatePS1 = ''
    #  PS1="$(powerline-go -error $? -jobs $(jobs -p | wc -l))"
    #'';
  };
}

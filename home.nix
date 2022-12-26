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
    fd
    git
    go
    gopls
    # neovim # uncomment if not using nixos. there's probably a way to do this in nix...but effort :)
    nodePackages.bash-language-server
    powerline-go
    ripgrep
    shellcheck # bash script linter
    shfmt      # bash script formatter
    tree
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export EDITOR="nvim";
    '';
  };

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

  programs.go = {
    enable = true;
    goPath = "/dev/"; # relative to $HOME
  };

  programs.neovim = let
	  initlua = ''
			vim.api.nvim_command('colorscheme slate')
			vim.api.nvim_command('set nomousefocus')
			vim.api.nvim_command('set number')
			vim.api.nvim_command('set relativenumber')

      -- See all commands: https://github.com/nvim-telescope/telescope.nvim#pickers
      local telescope = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', telescope.find_files, {})
      vim.keymap.set('n', '<leader>fg', telescope.grep_string, {})
      vim.keymap.set('n', '<leader>fG', telescope.live_grep, {})
      vim.keymap.set('n', '<leader>fj', telescope.jumplist, {})
      vim.keymap.set('n', '<leader>fb', telescope.buffers, {})
      vim.keymap.set('n', '<leader>fh', telescope.help_tags, {})
      vim.keymap.set('n', '<leader>ftree', telescope.treesitter, {})

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local commonOpts = { buffer = args.buf, silent = true }

          -- when the lsp needs to be reinitialized for various reasons
          vim.keymap.set({'n'},
                         '<leader>lstop',
                         function() vim.lsp.stop_client(vim.lsp.get_active_clients()) end,
                         commonOpts)

          vim.keymap.set({'i'},
                         '<c-space>',
                         vim.lsp.buf.completion,
                         commonOpts)

          vim.keymap.set({'n', 'v'},
                         '<leader>lca',
                         vim.lsp.buf.code_action,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>ldef',
                         vim.lsp.buf.definition,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>ldocs',
                         vim.lsp.buf.document_symbol,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>lf',
                         vim.lsp.buf.format,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>lh',
                         vim.lsp.buf.hover,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>li',
                         vim.lsp.buf.implementation,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>lref',
                         vim.lsp.buf.references,
                         commonOpts)
          vim.keymap.set({'n', 'v'},
                         '<leader>lren',
                         vim.lsp.buf.rename,
                         commonOpts)

          --vim.keymap.set({'n', 'v'},
          --               '<leader>lcld',
          --               vim.lsp.codelens.display,
          --               { lenses: null })
        end
      })

      -- Bash Language Server
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'sh',
        callback = function()
          vim.lsp.start({
            name = 'bash-language-server',
            cmd = { 'bash-language-server', 'start' },
          })
        end,
      })

      -- Go Language Server (gopls)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'go',
        callback = function()
          vim.lsp.start({
            name = 'gpls',
            cmd = { 'gopls', '-remote=auto' },
            root_dir = vim.fs.dirname(vim.fs.find({'go.mod', '.git'}, { upward = true })[1]),
            on_attach = require("lsp-format").on_attach,
            settings = {
              -- TODO check if these are actually working...they don't seem to be on first blush
              gopls = {
                analyses = {
                  unusedparams = true,
                },
                staticcheck = true,
              },
            },
          })
        end,
      })

      function org_imports()
        local clients = vim.lsp.buf_get_clients()
        for _, client in pairs(clients) do
      
          local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
          params.context = {only = {"source.organizeImports"}}
      
          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 5000)
          for _, res in pairs(result or {}) do
            for _, r in pairs(res.result or {}) do
              if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
              else
                vim.lsp.buf.execute_command(r.command)
              end
            end
          end
        end
      end
      
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.go" },
        callback = vim.lsp.buf.format,
      })
      
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.go" },
        callback = org_imports,
      })

		'';
	in {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
		extraConfig = "lua << EOF\n" + initlua + "\nEOF";
		plugins = with pkgs.vimPlugins;
		let
			context-vim = pkgs.vimUtils.buildVimPlugin {
				name = "context-vim";
				src = pkgs.fetchFromGitHub {
					owner = "wellle";
					repo = "context.vim";
					rev = "e38496f1eb5bb52b1022e5c1f694e9be61c3714c";
					sha256 = "1iy614py9qz4rwk9p4pr1ci0m1lvxil0xiv3ymqzhqrw5l55n346";
				};
			};
		in [
			# left as example
			#context-vim

			bufexplorer

      { plugin = lsp-format-nvim;
        config = ''
          lua << EOF
          require("lsp-format").setup {}
          EOF
        '';
      }

      nerdtree

      # Using neovim 8's builtin
			# nvim-lspconfig

      # Instead of inlining the config we could do this:
      #     config = builtins.readFile(tree-lua.lua);
      {
        plugin = nvim-web-devicons;
        # https://github.com/nvim-tree/nvim-web-devicons#setup
        config = ''
          lua << EOF
          require'nvim-web-devicons'.setup {
            -- globally enable different highlight colors per icon (default to true)
            -- if set to false all icons will have the default icon's color
            color_icons = true;
            -- globally enable default icons (default to false)
            -- will get overriden by `get_icons` option
            default = true;
          }
          EOF
        '';
      }

			nvim-treesitter
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
        bash
        c
        go
        javascript
        python
      ]))

      ########################## telescope
      plenary-nvim
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        config = ''
          lua << EOF
          require('telescope').load_extension('fzf')
          EOF
        '';
      }

			vim-nix
			vim-sleuth
		]; # Only loaded if programs.neovim.extraConfig is set
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

  systemd.user.sessionVariables = {
    EDITOR = "nvim";
  };
}

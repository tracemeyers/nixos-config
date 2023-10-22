{ config, lib, pkgs, ... }:

let
  pkgsUnstable = import <nixpkgs-unstable> {
    config.allowUnfree = true;
  };
in
{
  nixpkgs.config.allowUnfree = true;

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
  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    chromium
    direnv
    fd
    firefox
    git
    git-crypt
    gnumake
    go
    golangci-lint-langserver
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    gopls
    gnupg
    gping
    jq
    k9s
    # temp
    kotlin-language-server
    kubectl
    lazygit
    libuuid
    meld
    mpv
    nerdfonts # required for nvim-web-devicons (use hack nerd font)
    # neovim # uncomment if not using nixos. there's probably a way to do this in nix...but effort :)
    nodejs-18_x
    pkgsUnstable.nodePackages.bash-language-server
    pkgsUnstable.nodePackages.eslint
    pkgsUnstable.nodePackages.prettier
    pkgsUnstable.nodePackages.pyright
    pkgsUnstable.nodePackages.typescript
    pkgsUnstable.nodePackages.typescript-language-server
    pkgsUnstable.nodePackages.yaml-language-server
    obs-studio
    openssl
    peek
    powerline-go
    pstree
    pwgen # devops-utils.git
    ripgrep
    rustdesk
    shellcheck # bash script linter
    shfmt      # bash script formatter
    slack
    steam-run
    terraform
    terraform-ls
    tree
    unzip
    vault
    yq
    pkgsUnstable.obsidian
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export EDITOR="nvim";
      source ~/.config/bash/thales.bashrc
      set -o vi

      export PATH=$PATH:$GOPATH/bin
    '';
    shellAliases = {
      cdk = "cd ~/dev/gitlab.protectv.local/ncryptify";
      ll = "ls -la";
      rg = "rg -g '!vendor' -g '!node_modules' -g '!.git'";
      rgv = "command rg";
      uuid = "uuidgen";
    };
  };

  programs.firefox = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Tracy Meyers";
    userEmail = "tracy.meyers@gmail.com";
    aliases = {
      outgoing = "log @{u}.. --oneline";
      outgoing-all = "log --branches --not --remotes=origin --oneline";
    };
    extraConfig = {
      url = {
        "git@gitlab.gemalto.com:" = {
          insteadOf = "https://gitlab.protectv.local";
        };
      };
    };

    includes = [
      {
        condition = "gitdir:~/dev/github.com/**";
        contents = {
          user = {
            email = "1397338+tracemeyers@users.noreply.github.com";
            name = "Trace Meyers";
          };
        };
      }
      {
        condition = "gitdir:~/dev/gitlab.protectv.local/**";
        contents = {
          user = {
            email = "tracy.meyers@thalesgroup.com";
            name = "Tracy Meyers";
          };
        };
      }
    ];
  };

  programs.go = {
    enable = true;
    goPath = "/dev/"; # relative to $HOME
    goPrivate = [ "gitlab.protectv.local" ];
  };

  programs.neovim = let
	  initlua = ''
            vim.api.nvim_command('colorscheme PaperColor')
            vim.api.nvim_command('set background=dark')
            vim.api.nvim_command('set mouse=')
            vim.api.nvim_command('set number')
            vim.api.nvim_command('set relativenumber')
            vim.api.nvim_command('set cursorline')
            vim.api.nvim_command('set laststatus=2')
            vim.api.nvim_command('set shiftwidth=4')
            vim.api.nvim_command('set tabstop=4')

            -- nvim-tree --
            local gheight = vim.api.nvim_list_uis()[1].height
            local gwidth = vim.api.nvim_list_uis()[1].width
            local height = 90
            local width = 60
            require("nvim-tree").setup({
              actions = {
                open_file = {
                  window_picker = {
                    enable = false, -- false means open the file in the window that nvim-tree was opened from
                  },
                },
              },
              view = {
                adaptive_size = true,
                float = {
                  enable = true,
                  quit_on_focus_loss = true,
                  open_win_config = {
                    relative = "editor",
                    border = "rounded",
                    width = width,
                    height = height,
                    row = gheight / 2 - height / 2,
                    col = gwidth / 2 - width / 2,
                  }
                }
              }
            })

            local treeapi = require('nvim-tree.api')
            vim.keymap.set("n", "<leader>ft", treeapi.tree.toggle)
            -- toggle isn't the best but it gets the job done
            vim.keymap.set("n", "<leader>ff", function() treeapi.tree.toggle({ find_file = true }) end)

            -- See all commands: https://github.com/nvim-telescope/telescope.nvim#pickers
            local telescope = require('telescope.builtin')
            vim.keymap.set('n', '<leader>tf', telescope.find_files, {})
            vim.keymap.set('n', '<leader>tg', telescope.grep_string, {})
            vim.keymap.set('n', '<leader>tG', telescope.live_grep, {})
            vim.keymap.set('n', '<leader>tj', telescope.jumplist, {})
            vim.keymap.set('n', '<leader>tb', telescope.buffers, {})
            vim.keymap.set('n', '<leader>th', telescope.help_tags, {})
            vim.keymap.set('n', '<leader>ttree', telescope.treesitter, {})
            vim.keymap.set('n', '<leader>tdef', telescope.lsp_definitions, {})
            vim.keymap.set('n', '<leader>tref', telescope.lsp_references, {})

            vim.api.nvim_create_autocmd('LspAttach', {
              callback = function(args)
                local commonOpts = { buffer = args.buf, silent = true }

                -- when the lsp needs to be reinitialized for various reasons
                vim.keymap.set({'n'},
                               '<leader>lstop',
                               function() vim.lsp.stop_client(vim.lsp.get_active_clients()) end,
                               commonOpts)

                vim.keymap.set({'i'}, '<c-space>', vim.lsp.buf.completion, commonOpts)

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
                               -- Instead of this...
                               -- vim.lsp.buf.format,
                               -- ...block tsserver from formatting because it
                               -- doesn't read .prettierrc. Instead we'll use 
                               -- null-ls to call lsp-format using prettier.
                               function() vim.lsp.buf.format{filter = function(client) return client.name ~= "typescript-language-server" end} end,
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
                               '<leader>lrer',
                               vim.lsp.buf.references,
                               commonOpts)
                vim.keymap.set({'n', 'v'},
                               '<leader>lren',
                               vim.lsp.buf.rename,
                               commonOpts)
                -- vim.keymap.set({'n', 'v'},
                --                '<leader>ldn',
                --                vim.lsp.diagnostic.goto_next,
                --                commonOpts)
                -- vim.keymap.set({'n', 'v'},
                --                '<leader>ldp',
                --                vim.lsp.diagnostic.goto_prev,
                --                commonOpts)

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
                  on_attach = require("lsp-format").on_attach,
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
                        nilness = true,
                        shadow = true,
                        useany = true,
                        unusedparams = true,
                        unusedvariable = true,
                        unusedwrite = true,
                      },
                      env = {
                        GOFLAGS = "-tags linux,gormv2"
                      },
                      staticcheck = true,
                    },
                  },
                  capabilities = require('cmp_nvim_lsp').default_capabilities()
                })
              end,
            })
            vim.api.nvim_create_autocmd('FileType', {
              pattern = 'go',
              callback = function()
                vim.lsp.start({
                  name = 'golangci-lint-langserver',
                  cmd = {'golangci-lint-langserver', '-debug'},
                  root_dir = vim.fs.dirname(vim.fs.find({'go.mod', '.git'}, { upward = true })[1]),
                  init_options = {
                    command = { "/home/cat/go/bin/golangci-lint", "run", "--out-format", "json", "--issues-exit-code=1" },
                  },
                  settings = {},
                  capabilities = require('cmp_nvim_lsp').default_capabilities()
                })
              end,
            })

            -- Source:
            -- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-1128949874
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

            -- Python Language Server
            vim.api.nvim_create_autocmd('FileType', {
              pattern = 'python',
              callback = function()
                vim.lsp.start({
                  name = 'pyright',
                  cmd = { "${pkgs.nodePackages.pyright}/bin/pyright-langserver", '--stdio' },
                  root_dir = vim.fs.dirname(vim.fs.find({'requirements.txt', '.git'}, { upward = true })[1]),
                  on_attach = require("lsp-format").on_attach,
                  settings = {
                    python = {
                      analysis = {
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "workspace",
                      },
                    },
                  },
                })
              end,
            })

            -- Terraform Language Server
            -- TODO NOT TESTED
            -- TODO NOT TESTED
            -- TODO NOT TESTED
            -- TODO NOT TESTED
            vim.api.nvim_create_autocmd('FileType', {
              pattern = 'terraform',
              callback = function()
                vim.lsp.start({
                  name = 'terraformls',
                  cmd = { 'terraform-ls', 'serve' },
                  root_dir = vim.fs.dirname(vim.fs.find({'.terraform', '.git'}, { upward = true })[1]),
                  on_attach = require("lsp-format").on_attach,
                })
              end,
            })
            vim.api.nvim_create_autocmd({"BufWritePre"}, {
              pattern = {"*.tf", "*.tfvars"},
              callback = vim.lsp.buf.format,
            })

            -- Typescript Language Server
            -- A nice example for overcoming some errors like typescript not being found:
            -- - https://github.com/ghostbuster91/dot-files/blob/nix/programs/neovim/default.nix#L30
            local tsserver_path = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server"
            local typescript_path = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib"
            vim.api.nvim_create_autocmd('FileType', {
              pattern = { 'javascript', 'typescript' },
              callback = function()
                vim.lsp.start({
                  name = 'typescript-language-server',
                  cmd = { tsserver_path, '--stdio' },
                  root_dir = vim.fs.dirname(vim.fs.find({'package.json', '.git'}, { upward = true })[1]),
                  --lsp-format doesn't use prettier. not sure how to get it to work
                  --on_attach = require("lsp-format").on_attach,
                  capabilities = require('cmp_nvim_lsp').default_capabilities(),
                  init_options = {
                    tsserver = {
                      path = typescript_path
                    }
                  }
                })
              end,
            })

            -- YAML Language Server
            vim.api.nvim_create_autocmd('FileType', {
              pattern = 'yaml',
              callback = function()
                vim.lsp.start({
                  name = 'yaml',
                  cmd = { 'yaml-language-server', '--stdio' },
                  on_attach = require("lsp-format").on_attach,
                })
              end,
            })

		'';
	in {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
		extraConfig = "lua << EOF\n" + initlua + "\nEOF";
    extraPackages = [
      pkgs.nodePackages.eslint
      pkgs.nodePackages.prettier
      pkgs.nodePackages.typescript
    ];
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

      { plugin = indent-blankline-nvim;
        config = ''
          lua << EOF
            require('indent_blankline').setup{
              show_current_context = true,
              show_current_context_start = true,
            }
          EOF
        '';
      }

      bufexplorer

      { plugin = gitsigns-nvim;
        config = ''
          lua << EOF
          -- https://github.com/lewis6991/gitsigns.nvim#usage
          require('gitsigns').setup {
            current_line_blame = true,
            current_line_blame_opts = {
              virt_text = true,
              virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
              delay = 200,
              ignore_whitespace = false,
            },
            current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> (<abbrev_sha>) - <summary>',
          }
          EOF
        '';
      }

      # Not available. How to manually do this?
      #{
      #  plugin = kotlin-language-server;
      #  config = ''
      #    lua << EOF
      #      require("kotlin-language-server").setup {}
      #    EOF
      #  '';
      #}

      { plugin = lsp-format-nvim;
        config = ''
          lua << EOF
          require("lsp-format").setup {}
          EOF
        '';
      }

      {
        plugin = lsp_signature-nvim;
        config = ''
          lua << EOF
            require'lsp_signature'.setup {
              -- https://github.com/ray-x/lsp_signature.nvim
            }
          EOF
        '';
      }

      {
        plugin = null-ls-nvim;
        config = ''
          lua << EOF
            local null_ls = require'null-ls'
            null_ls.setup {
              sources = {
                null_ls.builtins.formatting.prettier.with({
                  filetypes = {
                          "javascript","typescript",
                          "css","scss",
                          "html",
                          "json",
                          --"markdown",
                          --"md",
                  },
                }),
              },
              on_attach = require("lsp-format").on_attach,
            }
          EOF
        '';
      }

      # Attempting to use nvim-tree-lua
      # nerdtree

      {
        # TODO - need to confirm it works or not.
        plugin = nvim-lightbulb;
        config = ''
          lua << EOF
            autocmd = {enabled = true}
          EOF
        '';
      }

      {
        # TODO - need to confirm it works or not.
        plugin = nvim-code-action-menu;
        config = ''
          lua << EOF
          EOF
        '';
      }

      {
        plugin = nvim-cmp;
        config = ''
          lua << EOF
            vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

            -- https://vonheikemen.github.io/devlog/tools/setup-nvim-lspconfig-plus-nvim-cmp/
            local cmp = require('cmp')
            cmp.setup({
              mapping = {
                ['<c-space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({select = false}),
                ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
                ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
              },
              snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                  require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
              },
              sources = {
                {name = 'path', keyword_length = 1},
                {name = 'nvim_lsp', keyword_length = 1},
                {name = 'luasnip'},
                --{name = 'buffer', keyword_length = 3},
              },
              window = {
                documentation = cmp.config.window.bordered()
              },
            })

            -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline({ '/', '?' }, {
              mapping = cmp.mapping.preset.cmdline(),
              sources = {
                { name = 'buffer' }
              }
            })
            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
              mapping = cmp.mapping.preset.cmdline(),
              sources = cmp.config.sources({
                { name = 'path' }
              }, {
                { name = 'cmdline' }
              })
            })

            -- Set configuration for specific filetype.
            cmp.setup.filetype('gitcommit', {
              sources = cmp.config.sources({
                { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
              }, {
                { name = 'buffer' },
              })
            })

          EOF
        '';
      }
      {
        plugin = cmp-nvim-lsp;
        config = ''
          lua << EOF
            require('cmp_nvim_lsp')
          EOF
        '';
      }
      cmp-buffer
      cmp-cmdline
      cmp-git
      cmp-path
      luasnip
      cmp_luasnip

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

      nvim-tree-lua

      nvim-treesitter
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
        bash
        c
        dockerfile
        go
        html
        javascript
        json
        kotlin
        lua
        markdown
        python
        sql
        typescript
        yaml
      ]))
      {
        plugin = nvim-treesitter;
        config = ''
          lua << EOF
            require'nvim-treesitter.configs'.setup {
              highlight = {
                enable = true,
                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = false,
              },
              indent = {
                enable = true
              },
            }
          EOF
        '';
      }

      papercolor-theme

      {
        plugin = symbols-outline-nvim;
        config = ''
          lua << EOF
            require("symbols-outline").setup()
          EOF
        '';
      }

      ########################## telescope
      plenary-nvim # requirement
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        config = ''
          lua << EOF
          require('telescope').load_extension('fzf')
          EOF
        '';
      }

      {
        plugin = trouble-nvim;
        config = ''
          lua << EOF
            require("trouble").setup {
              -- your configuration comes here
              -- or leave it empty to use the default settings
              -- refer to the configuration section below
            }
          EOF
        '';
      }

      {
        plugin = vim-sneak;
        config = ''
          map f <Plug>Sneak_s
          map F <Plug>Sneak_S
          map t <Plug>Sneak_t
          map T <Plug>Sneak_T
        '';
      }

      vim-nix
      # Sleuth never worked for me with Go code. It always said this...
      #   noet sw=2 ff=unix fenc=utf-8 nobomb
      #vim-sleuth

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

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      modifier = "Mod1";
      terminal = "${pkgs.konsole}/bin/konsole";

      keybindings = let
        modifier = config.xsession.windowManager.i3.config.modifier;
      in lib.mkOptionDefault {
        #"${modifier}+Shift+q" = "kill";

        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        "${modifier}+Shift+greater" = "move workspace to output next";
        #"${modifier}+Ctrl+greater = "move workspace to output next";
        #bindsym $mod+Shift+greater move container to output right
        #bindsym $mod+Shift+less move container to output left

        "${modifier}+Shift+s" = "sticky toggle";
        "${modifier}+Shift+e" = "exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout -1 -1 -1";
        # Disabled to see if this fixes some instability in KDE plasmashell where it would lockup and could not be killed/restarted
        "${modifier}+d" = "exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.krunner /App display";
      };

      window.commands = [
        {
          command = "move container to workspace current";
          criteria = { class = "Slack"; floating = true; };
        }
      ];
    };
    extraConfig = ''
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

      # https://github.com/heckelson/i3-and-kde-plasma
      bindsym XF86AudioRaiseVolume exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut "increase_volume"
      bindsym XF86AudioLowerVolume exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut "decrease_volume"
      bindsym XF86AudioMute exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut "mute"
      bindsym XF86AudioMicMute exec --no-startup-id /run/current-system/sw/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut "mic_mute"


      # Documented in KDE knowledge base
      # TRACE - don't kill the desktop so we can add panel's as needed
      # The big drawback is the desktop initially takes over the whole
      # screen so you have to alt+right-mouse-click to shrink it.
      #for_window [title="Desktop — Plasma"] kill, floating enable, border none
      for_window [title="Desktop — Plasma"] floating enable, border none
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
      #
      # Custom ones
      #
      # Uncomment if this works better. Otherwise trying the documented one above.
      #for_window [class="plasmashell" window_type="notification"] border none, move right 700px, move down 450px
      for_window [window_role="pop-up"] floating enable
      for_window [window_role="task_dialog"] floating enable
      for_window [class="yakuake"] floating enable
      for_window [class="systemsettings"] floating enable
      no_focus [class="plasmashell" window_type="notification"]
      # Kill the bar
      bar {
          mode hide
      }

    '';
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  services.kdeconnect.enable = true;
}

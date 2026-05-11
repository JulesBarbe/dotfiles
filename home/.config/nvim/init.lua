-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- leader before plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

----------------------------------------------------------------------
-- options
----------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.undofile = true
vim.opt.swapfile = false

vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

vim.opt.clipboard = "unnamedplus"

----------------------------------------------------------------------
-- basic keymaps
----------------------------------------------------------------------
local map = vim.keymap.set

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- better window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- keep cursor centered on half-page jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- diagnostic navigation
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "<leader>e", vim.diagnostic.open_float)

----------------------------------------------------------------------
-- plugins
----------------------------------------------------------------------
require("lazy").setup({
  -- colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { flavour = "mocha" },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "bash", "json", "yaml", "toml", "markdown", "markdown_inline",
        "lua", "python", "javascript", "typescript", "tsx",
        "html", "css", "sql", "dockerfile", "git_rebase", "gitcommit",
      })

      local available_parsers = require("nvim-treesitter").get_available()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end

          local installed = require("nvim-treesitter").get_installed("parsers")
          if vim.tbl_contains(installed, language) then
            if not vim.treesitter.language.add(language) then return end
            vim.treesitter.start(buf, language)
            if vim.treesitter.query.get(language, "indents") then
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          elseif vim.tbl_contains(available_parsers, language) then
            require("nvim-treesitter").install(language):await(function()
              if not vim.treesitter.language.add(language) then return end
              vim.treesitter.start(buf, language)
              if vim.treesitter.query.get(language, "indents") then
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end)
          end
        end,
      })
    end,
  },

  -- fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer" },
    },
  },

  -- LSP
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      ensure_installed = { "lua_ls", "pyright", "ts_ls" },
    },
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- per-server config via neovim 0.11+ native API
      vim.lsp.config("*", { capabilities = capabilities })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local o = { buffer = ev.buf }
          map("n", "gd", vim.lsp.buf.definition, o)
          map("n", "gr", vim.lsp.buf.references, o)
          map("n", "K", vim.lsp.buf.hover, o)
          map("n", "<leader>rn", vim.lsp.buf.rename, o)
          map("n", "<leader>ca", vim.lsp.buf.code_action, o)
          map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, o)
        end,
      })
    end,
  },

  -- completion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- file explorer
  {
    "stevearc/oil.nvim",
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },

  -- git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- surround (cs, ds, ys)
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- auto-detect indent
  { "tpope/vim-sleuth" },

  -- comment toggling (gc)
  { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },

  -- which-key to discover keybindings
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
})

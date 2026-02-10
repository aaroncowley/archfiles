-- =========================
--  One-file "NvChad-ish" Neovim (portable init.lua)
--  Plugin mgmt: mini.deps (via mini.nvim)
-- =========================

-- -------------------------
-- Core options
-- -------------------------
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 200
vim.opt.timeoutlen = 400
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true
vim.opt.wrap = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- Disable netrw (so file tree plugins behave)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- -------------------------
-- Bootstrap mini.nvim
-- -------------------------
local data_dir = vim.fn.stdpath("data")
local mini_path = data_dir .. "/site/pack/deps/start/mini.nvim"

if vim.fn.isdirectory(mini_path) == 0 then
  vim.fn.system({
    "git", "clone", "--depth", "1",
    "https://github.com/echasnovski/mini.nvim",
    mini_path,
  })
end

vim.cmd("packadd mini.nvim")

local deps = require("mini.deps")
deps.setup({ path = { package = data_dir .. "/site/pack/deps" } })

local add = deps.add
local now = deps.now

-- -------------------------
-- Plugins (curated)
-- -------------------------
add({ source = "nvim-lua/plenary.nvim" })

-- Theme/UI
add({ source = "catppuccin/nvim", name = "catppuccin" })
add({ source = "nvim-lualine/lualine.nvim" })
add({ source = "folke/which-key.nvim" })
add({ source = "lewis6991/gitsigns.nvim" })

-- Navigation
add({ source = "nvim-tree/nvim-tree.lua" })
add({ source = "nvim-telescope/telescope.nvim" })

-- Syntax
add({
  source = "nvim-treesitter/nvim-treesitter",
  hooks = {
    post_checkout = function()
      -- Update parsers after plugin updates
      pcall(vim.cmd, "TSUpdate")
    end,
  },
})

-- LSP + Completion
add({ source = "hrsh7th/nvim-cmp" })
add({ source = "hrsh7th/cmp-nvim-lsp" })
add({ source = "L3MON4D3/LuaSnip" })
add({ source = "saadparwaiz1/cmp_luasnip" })

-- Editing niceties
add({ source = "windwp/nvim-autopairs" })
add({ source = "numToStr/Comment.nvim" })

-- -------------------------
-- Keymaps (NvChad-ish)
-- -------------------------
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help" })

map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprev<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- LSP keymaps on attach
local function lsp_on_attach(_, bufnr)
  local opts = { buffer = bufnr }
  map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
  map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
  map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
  map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
  map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end,
    vim.tbl_extend("force", opts, { desc = "Format" }))
end

-- -------------------------
-- Plugin configs (wrapped in deps.now)
-- -------------------------
now(function()
  -- Theme
  require("catppuccin").setup({
    flavour = "mocha",
    integrations = {
      gitsigns = true,
      telescope = true,
      treesitter = true,
      which_key = true,
      native_lsp = { enabled = true },
    },
  })
  vim.cmd.colorscheme("catppuccin")

  require("which-key").setup()
  require("gitsigns").setup()
  require("Comment").setup()
  require("nvim-autopairs").setup()

  require("lualine").setup({
    options = {
      theme = "catppuccin",
      section_separators = "",
      component_separators = "",
    },
  })

  require("nvim-tree").setup({
    view = { width = 34 },
    renderer = { icons = { show = { git = true, folder = true, file = true } } },
    filters = { dotfiles = false },
  })

  require("telescope").setup({
    defaults = {
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
      },
    },
  })

  -- Treesitter (defer + guard so first install doesn't explode)
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniDepsDone",
    callback = function()
      -- Only run if plugin is present on runtimepath
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("Treesitter not loaded yet. Restart nvim after :lua require('mini.deps').update()", vim.log.levels.WARN)
        return
      end
  
      configs.setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  })

end)

-- -------------------------
-- LSP setup
-- -------------------------
now(function()
  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  -- helper to apply common settings
  local function setup(server, cfg)
    cfg = cfg or {}
    cfg.capabilities = capabilities
    cfg.on_attach = lsp_on_attach
    vim.lsp.config(server, cfg)
    vim.lsp.enable(server)
  end

  -- Lua (install lua-language-server on Arch: sudo pacman -S lua-language-server)
  setup("lua_ls", {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
      },
    },
  })

  -- Examples (install servers with pacman; then uncomment):
  -- setup("pyright", {})
  -- setup("gopls", {})
  -- setup("rust_analyzer", {})
  -- setup("tsserver", {})  -- some distros call this tsserver / ts_ls; check :LspInfo
end)


-- -------------------------
-- Completion (nvim-cmp)
-- -------------------------
now(function()
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  cmp.setup({
    snippet = {
      expand = function(args) luasnip.lsp_expand(args.body) end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = {
      { name = "nvim_lsp" },
      { name = "luasnip" },
    },
  })
end)

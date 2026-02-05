-- ~/.config/nvim/init.lua
-- Neovim + Python (uv-aware) --------------------------------------------------
-- If you keep tools per-project, launch with:  uv run nvim
-- If you installed global tools with `uv tool install ...`, this works as-is.

-- Bootstrap lazy.nvim ---------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Basic UI/options ------------------------------------------------------------
vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.updatetime = 250
vim.o.signcolumn = "yes"
vim.o.clipboard = "unnamedplus"

-- Indent defaults: 2 spaces unless a filetype/plugin overrides
vim.o.expandtab   = true   -- use spaces
vim.o.tabstop     = 2      -- visual width of a <Tab>
vim.o.softtabstop = 2      -- how many spaces <Tab>/<BS> insert/delete
vim.o.shiftwidth  = 2      -- indentation size for >>, <<, ==, etc.
-- If you use a colorscheme, set it here (example):
-- vim.cmd.colorscheme("gruvbox")

-- Helper: uv-aware command/args -----------------------------------------------
local HAS_UV = (vim.fn.executable("uv") == 1)
local function make_cmd(tool, args_for_tool)
  -- Returns {command=..., args=...} using "uv run <tool> ..." if uv is present
  if HAS_UV then
    local args = { "run", tool }
    if args_for_tool then
      for _, a in ipairs(args_for_tool) do table.insert(args, a) end
    end
    return { command = "uv", args = args }
  else
    return { command = tool, args = args_for_tool or {} }
  end
end

-- Plugins ---------------------------------------------------------------------
require("lazy").setup({
  -- Core UX
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "nvim-treesitter/nvim-treesitter-textobjects" },
  { "lewis6991/gitsigns.nvim" },
  { "nvim-lualine/lualine.nvim" },
  { "numToStr/Comment.nvim" },
  { "folke/which-key.nvim" },
  { "windwp/nvim-autopairs" },

  -- LSP + Completion
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-buffer" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },

  -- LSP signature help
  { "hrsh7th/cmp-nvim-lsp-signature-help" },

  -- Format & Lint
  { "stevearc/conform.nvim" },
  { "mfussenegger/nvim-lint" },

  -- Debugging
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
  { "mfussenegger/nvim-dap-python" },

  -- Testing
  { "nvim-neotest/neotest" },
  { "nvim-neotest/neotest-python" },

  -- vim-surround
  { "tpope/vim-surround" },
  { "ThePrimeagen/refactoring.nvim", 
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
  },

  -- Theme
  { 
  "loctvl842/monokai-pro.nvim",
  lazy = false,            -- load during startup
  priority = 1000,         -- load before other UI plugins
  config = function()
    -- optional: pick a filter: "classic", "octagon", "pro", "machine", "ristretto", "spectrum"
    require("monokai-pro").setup({ filter = "ristretto" })
    vim.cmd.colorscheme("monokai-pro")
  end,
}

})

-- Telescope -------------------------------------------------------------------
require("telescope").setup({})
pcall(require("telescope").load_extension, "fzf")
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers,    { desc = "Buffers" })
vim.keymap.set("n", "<leader>fs", require("telescope.builtin").lsp_document_symbols, { desc = "Symbols" })

-- Treesitter ------------------------------------------------------------------
-- require("nvim-treesitter.configs").setup({
--   ensure_installed = { "python", "lua", "vim", "bash", "json", "markdown" },
--   highlight = { enable = true },
--   indent = { enable = true },
-- })
require("nvim-treesitter.configs").setup({
  ensure_installed = { "python", "lua", "vim", "bash", "json", "markdown" },
  highlight = { enable = true },
  indent = { enable = true },

  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- jump forward to nearest textobject
      include_surrounding_whitespace = false,
      keymaps = {
        -- Functions
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",

        -- Classes
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",

        -- Parameters/arguments
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      },
      selection_modes = {
        ["@function.outer"]  = "V",  -- linewise
        ["@class.outer"]     = "V",
      },
    },

    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
    },

    swap = {
      enable = true,
      swap_next = {
        ["<leader>a"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>A"] = "@parameter.inner",
      },
    },
  },
})

-- Refactoring -----------------------------------------------------------------
require('refactoring').setup({})

vim.keymap.set({ "n", "x" }, "<leader>re",
  function() return require('refactoring').refactor('Extract Function') end,
  { expr = true, desc = "Refactor: Extract function" })
vim.keymap.set({ "n", "x" }, "<leader>rf",
  function() return require('refactoring').refactor('Extract Function To File') end,
  { expr = true, desc = "Refactor: Extract function to file" })
vim.keymap.set({ "n", "x" }, "<leader>rv",
  function() return require('refactoring').refactor('Extract Variable') end,
  { expr = true, desc = "Refactor: Extract variable" })
vim.keymap.set({ "n", "x" }, "<leader>rI",
  function() return require('refactoring').refactor('Inline Function') end,
  { expr = true, desc = "Refactor: Inline function" })
vim.keymap.set({ "n", "x" }, "<leader>ri",
  function() return require('refactoring').refactor('Inline Variable') end,
  { expr = true, desc = "Refactor: Inline variable" })
vim.keymap.set({ "n", "x" }, "<leader>rbb",
  function() return require('refactoring').refactor('Extract Block') end,
  { expr = true, desc = "Refactor: Extract block" })
vim.keymap.set({ "n", "x" }, "<leader>rbf",
  function() return require('refactoring').refactor('Extract Block To File') end,
  { expr = true, desc = "Refactor: Extract block to file" })

-- Lualine, Gitsigns, Comment, WhichKey, Autopairs -----------------------------
require("lualine").setup({ options = { theme = "auto" } })
require("gitsigns").setup()
require("Comment").setup()
require("which-key").setup()
require("nvim-autopairs").setup()

-- Completion ------------------------------------------------------------------
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  }),
  sources = { { name = "nvim_lsp" }, { name = "nvim_lsp_signature_help" }, { name = "luasnip" }, { name = "path" }, { name = "buffer" } },
})

-- Mason + LSP -----------------------------------------------------------------
-- Capabilities + keymaps (unchanged)
local lsp_cap = require("cmp_nvim_lsp").default_capabilities()
local on_attach = function(_, bufnr)
  local nmap = function(keys, func, desc) vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc }) end
  nmap("gd", vim.lsp.buf.definition, "Go to definition")
  nmap("gr", require("telescope.builtin").lsp_references, "Find references")
  nmap("K",  vim.lsp.buf.hover, "Hover")
  nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
  nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
  nmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
  nmap("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
end

-- New-style config + enable (no require('lspconfig').xyz.setup)
vim.lsp.config('basedpyright', {
  capabilities = lsp_cap,
  on_attach = on_attach,
  settings = {
    basedpyright = {
      typeCheckingMode = "standard",          -- "strict" if you prefer
      disableOrganizeImports = true,          -- Ruff handles this
      analysis = { autoImportCompletions = false }, -- turning off spammy auto-import suggestions
    },
  },
})
vim.lsp.enable('basedpyright')

-- If you prefer plain Pyright:
-- require("lspconfig").pyright.setup({ capabilities = lsp_cap, on_attach = on_attach })

-- Conform (format on save) ----------------------------------------------------
-- Use Ruff (fix + format) then Black. Wrap with uv when available.
local black_spec = make_cmd("black", { "-" })
local ruff_fix_spec = make_cmd("ruff", { "check", '--select', 'I', "--fix", "--stdin-filename", "$FILENAME", "-" })
local ruff_fmt_spec = make_cmd("ruff", { "format", "-" })

require("conform").setup({
  formatters_by_ft = {
    python = { "ruff_fix", "ruff_format", "black" },
  },
  formatters = {
    black = { command = black_spec.command, args = black_spec.args, stdin = true },
    ruff_fix = { command = ruff_fix_spec.command, args = ruff_fix_spec.args, stdin = true },
    ruff_format = { command = ruff_fmt_spec.command, args = ruff_fmt_spec.args, stdin = true },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
    return { lsp_fallback = true, timeout_ms = 2000 }
  end,
})

-- add a command to format
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({
    lsp_fallback = true,
    async = true,
    timeout_ms = 2000,
  })
end, { desc = "Format buffer (no write)" })


-- nvim-lint (Ruff + mypy via uv when available) -------------------------------
local lint = require("lint")
lint.linters_by_ft = { python = { "ruff", "mypy" } }

-- Override built-ins to be uv-aware
lint.linters.ruff = vim.tbl_deep_extend("force", lint.linters.ruff or {}, {
  cmd = ruff_fix_spec.command, -- reuse ruff spec but without --fix and with stdout parse
  args = make_cmd("ruff", { "check", "--force-exclude", "--stdin-filename", function()
    return vim.api.nvim_buf_get_name(0)
  end, "-" }).args,
})
lint.linters.mypy = vim.tbl_deep_extend("force", lint.linters.mypy or {}, {
  cmd = make_cmd("mypy", {}).command,
  args = make_cmd("mypy", { "--show-column-numbers", "--hide-error-context", "--no-color-output", "--shadow-file",
    function() return vim.api.nvim_buf_get_name(0) end,
    function() return vim.api.nvim_buf_get_name(0) end, "-" }).args,
  stdin = true,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
  callback = function() require("lint").try_lint() end,
})

-- Debugging (DAP) -------------------------------------------------------------
local dap = require("dap")
local dapui = require("dapui")
dapui.setup()
-- Use the Python from PATH (works with `uv run nvim` or system/global)
require("dap-python").setup(vim.fn.exepath("python"))

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug UI" })

-- Testing (pytest via neotest) -----------------------------------------------
-- By default, use the Python on PATH. For per-project uv, start Neovim with `uv run nvim`.
local neotest = require("neotest")
neotest.setup({
  adapters = {
    require("neotest-python")({
      runner = "pytest",
      python = vim.fn.exepath("python"),
      dap = { justMyCode = true },
    }),
  },
})
vim.keymap.set("n", "<leader>tt", function() neotest.run.run() end, { desc = "Test: nearest" })
vim.keymap.set("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Test: file" })
vim.keymap.set("n", "<leader>to", function() neotest.output.open({ enter = true }) end, { desc = "Test: output" })
vim.keymap.set("n", "<leader>ts", function() neotest.summary.toggle() end, { desc = "Test: summary" })

-- Diagnostics UI --------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
  underline = true,
  update_in_insert = true,
})

-- Overlap an underlined error to see a message
local function show_line_diagnostics()
  -- scope="cursor" keeps it tight to what you're on; use "line" if you prefer
  vim.diagnostic.open_float(nil, {
    focus = false,
    scope = "cursor",
    close_events = { "CursorMoved", "CursorMovedI", "InsertLeave", "BufLeave" },
vim.keymap.set({"i", "n"}, "<C-_>", function()
  return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
         .. ":lua require('Comment.api').toggle.linewise.current()<CR>a"
end, { expr = true })
  })
end

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("diag_float", { clear = true }),
  callback = show_line_diagnostics,
})

-- Ctrl-fwd slash to comment a line in insert mode
vim.keymap.set({ "n", "i" }, "<M-d>", function()
  vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
end, { desc = "Show diagnostics at cursor" })

-- shortcuts to get back into normal mode
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

-- ~/.config/nvim/init.lua
-- Neovim 0.12-oriented config
-- Assumes Python tooling is available either:
--   1) on PATH, or
--   2) via `uv run nvim` so PATH resolves inside the project env.
--
-- Extra tooling to install for non-Python languages:
--   npm i -g vscode-langservers-extracted   -- jsonls
--   lemminx                                 -- XML LSP
--   clangd, clang-format                    -- C/C++
--   rust-analyzer, rustfmt                  -- Rust

-- Bootstrap lazy.nvim ----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic UI/options -------------------------------------------------------------
vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.updatetime = 250
vim.o.signcolumn = "yes"
vim.o.clipboard = "unnamedplus"

-- Helper: uv-aware command/args ------------------------------------------------
local HAS_UV = (vim.fn.executable("uv") == 1)

local function make_cmd(tool, args_for_tool)
  if HAS_UV then
    local args = { "run", tool }
    if args_for_tool then
      vim.list_extend(args, args_for_tool)
    end
    return { command = "uv", args = args }
  else
    return { command = tool, args = args_for_tool or {} }
  end
end

-- Plugins ----------------------------------------------------------------------
require("lazy").setup({
  -- Core UX
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { "benfowler/telescope-luasnip.nvim" },
  { "b0o/SchemaStore.nvim" },
  {
    "nvim-treesitter/nvim-treesitter",
    branch="main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      ts.install({
        "python",
        "lua",
        "vim",
        "bash",
        "json",
        "markdown",
        "xml",
        "c",
        "cpp",
        "rust",
        "typst",
      })

      local ts_lang_by_ft = {
        python = "python",
        lua = "lua",
        vim = "vim",
        bash = "bash",
        json = "json",
        jsonc = "json",
        markdown = "markdown",
        xml = "xml",
        xsd = "xml",
        xsl = "xml",
        xslt = "xml",
        svg = "xml",
        c = "c",
        cpp = "cpp",
        rust = "rust",
        typst = "typst",
      }

      local group = vim.api.nvim_create_augroup("treesitter_start", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = vim.tbl_keys(ts_lang_by_ft),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local lang = ts_lang_by_ft[ft]
          local ok = pcall(vim.treesitter.start, args.buf, lang)
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "MeanderingProgrammer/treesitter-modules.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          scope_incremental = "<Tab>",
          node_decremental = "<BS>",
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
          },
        },
        move = {
          set_jumps = true,
        },
        swap = {},
      })
    end,
  },
  { "lewis6991/gitsigns.nvim" },
  { "nvim-lualine/lualine.nvim" },
  { "numToStr/Comment.nvim" },
  { "folke/which-key.nvim" },
  { "windwp/nvim-autopairs" },
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      dependencies_bin = {
        tinymist = "tinymist",
        websocat = "websocat",
      },
    },
  },

  -- LSP + Completion
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-buffer" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },
  { "hrsh7th/cmp-nvim-lsp-signature-help" },

  -- Format & Lint
  { "stevearc/conform.nvim" },
  { "mfussenegger/nvim-lint" },

  -- Debugging
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
  { "mfussenegger/nvim-dap-python" },

  -- Testing
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-python",
    },
  },

  -- Misc
  { "tpope/vim-surround" },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "lewis6991/async.nvim",
    },
    lazy = false,
  },

  -- Theme
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup({ filter = "ristretto" })
      vim.cmd.colorscheme("monokai-pro")
    end,
  }
})

-- Telescope --------------------------------------------------------------------
require("telescope").setup({})
pcall(require("telescope").load_extension, "fzf")

vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fs", require("telescope.builtin").lsp_document_symbols, { desc = "Symbols" })
-- Search for snippets
vim.keymap.set("n", "<leader>fl", function()
  require("telescope").extensions.luasnip.luasnip({})
end, { desc = "Find snippets" })
-- Treesitter textobjects -------------------------------------------------------
local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")
local ts_swap = require("nvim-treesitter-textobjects.swap")

vim.keymap.set({ "x", "o" }, "af", function()
  ts_select.select_textobject("@function.outer", "textobjects")
end, { desc = "TS: around function" })

vim.keymap.set({ "x", "o" }, "if", function()
  ts_select.select_textobject("@function.inner", "textobjects")
end, { desc = "TS: inner function" })

vim.keymap.set({ "x", "o" }, "ac", function()
  ts_select.select_textobject("@class.outer", "textobjects")
end, { desc = "TS: around class" })

vim.keymap.set({ "x", "o" }, "ic", function()
  ts_select.select_textobject("@class.inner", "textobjects")
end, { desc = "TS: inner class" })

vim.keymap.set({ "x", "o" }, "aa", function()
  ts_select.select_textobject("@parameter.outer", "textobjects")
end, { desc = "TS: around parameter" })

vim.keymap.set({ "x", "o" }, "ia", function()
  ts_select.select_textobject("@parameter.inner", "textobjects")
end, { desc = "TS: inner parameter" })

vim.keymap.set({ "n", "x", "o" }, "]m", function()
  ts_move.goto_next_start("@function.outer", "textobjects")
end, { desc = "TS: next function start" })

vim.keymap.set({ "n", "x", "o" }, "]]", function()
  ts_move.goto_next_start("@class.outer", "textobjects")
end, { desc = "TS: next class start" })

vim.keymap.set({ "n", "x", "o" }, "[m", function()
  ts_move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "TS: previous function start" })

vim.keymap.set({ "n", "x", "o" }, "[[", function()
  ts_move.goto_previous_start("@class.outer", "textobjects")
end, { desc = "TS: previous class start" })

vim.keymap.set("n", "<leader>a", function()
  ts_swap.swap_next("@parameter.inner")
end, { desc = "TS: swap parameter next" })

vim.keymap.set("n", "<leader>A", function()
  ts_swap.swap_previous("@parameter.inner")
end, { desc = "TS: swap parameter previous" })

-- Refactoring ------------------------------------------------------------------
require("refactoring").setup({})

vim.keymap.set({ "n", "x" }, "<leader>re",
  function() return require("refactoring").refactor("Extract Function") end,
  { expr = true, desc = "Refactor: Extract function" }
)

vim.keymap.set({ "n", "x" }, "<leader>rf",
  function() return require("refactoring").refactor("Extract Function To File") end,
  { expr = true, desc = "Refactor: Extract function to file" }
)

vim.keymap.set({ "n", "x" }, "<leader>rv",
  function() return require("refactoring").refactor("Extract Variable") end,
  { expr = true, desc = "Refactor: Extract variable" }
)

vim.keymap.set({ "n", "x" }, "<leader>rI",
  function() return require("refactoring").refactor("Inline Function") end,
  { expr = true, desc = "Refactor: Inline function" }
)

vim.keymap.set({ "n", "x" }, "<leader>ri",
  function() return require("refactoring").refactor("Inline Variable") end,
  { expr = true, desc = "Refactor: Inline variable" }
)

vim.keymap.set({ "n", "x" }, "<leader>rbb",
  function() return require("refactoring").refactor("Extract Block") end,
  { expr = true, desc = "Refactor: Extract block" }
)

vim.keymap.set({ "n", "x" }, "<leader>rbf",
  function() return require("refactoring").refactor("Extract Block To File") end,
  { expr = true, desc = "Refactor: Extract block to file" }
)

-- Lualine, Gitsigns, Comment, WhichKey, Autopairs ------------------------------
require("lualine").setup({ options = { theme = "auto" } })
require("gitsigns").setup()
require("Comment").setup()
require("which-key").setup()
require("nvim-autopairs").setup()

-- Tab settings -----------------------------------------------------------------
-- 1. Set the global defaults (2 spaces)
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- 2. Define only the exceptions (the 4-space club)
local ft_overrides = {
  c = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
  cpp = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
  rust = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
}

-- 3. Apply overrides based on FileType
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(ft_overrides),
  callback = function(args)
    local opts = ft_overrides[vim.bo[args.buf].filetype]
    if opts then
      for k, v in pairs(opts) do
        vim.bo[args.buf][k] = v
      end
    end
  end,
})

-- Comment toggle mapping -------------------------------------------------------
vim.keymap.set("n", "<C-_>", function()
  require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment" })

vim.keymap.set("i", "<C-_>", function()
  return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    .. "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>A"
end, { expr = true, desc = "Toggle comment" })

-- Completion -------------------------------------------------------------------
local cmp = require("cmp")
local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
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
    { name = "nvim_lsp_signature_help" },
    { name = "luasnip" },
    { name = "path" },
    { name = "buffer" },
  },
})

-- LSP --------------------------------------------------------------------------
local lsp_cap = require("cmp_nvim_lsp").default_capabilities()

local hover_active = false

local on_attach = function(_, bufnr)
  local nmap = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  nmap("gd", vim.lsp.buf.definition, "Go to definition")
  nmap("gr", require("telescope.builtin").lsp_references, "Find references")

  nmap("K", function()
    hover_active = true
    vim.lsp.buf.hover({
      zindex = 60,
    })
  end, "Hover")

  nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
  nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
  nmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
  nmap("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
end

vim.lsp.config("basedpyright", {
  capabilities = lsp_cap,
  on_attach = on_attach,
  settings = {
    basedpyright = {
      typeCheckingMode = "standard",
      disableOrganizeImports = true,
      analysis = {
        autoImportCompletions = false,
      },
    },
  },
})

vim.lsp.config("jsonls", {
  capabilities = lsp_cap,
  on_attach = on_attach,
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

vim.lsp.config("lemminx", {
  capabilities = lsp_cap,
  on_attach = on_attach,
})

vim.lsp.config("clangd", {
  capabilities = lsp_cap,
  on_attach = on_attach,
})

vim.lsp.config("rust_analyzer", {
  capabilities = lsp_cap,
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {},
  },
})

for _, server in ipairs({
  "basedpyright",
  "jsonls",
  "lemminx",
  "clangd",
  "rust_analyzer",
}) do
  vim.lsp.enable(server)
end

-- Conform ----------------------------------------------------------------------
local black_spec = make_cmd("black", { "-" })
local ruff_fix_spec = make_cmd("ruff", {
  "check",
  "--select",
  "I",
  "--fix",
  "--stdin-filename",
  "$FILENAME",
  "-",
})
local ruff_fmt_spec = make_cmd("ruff", { "format", "-" })

require("conform").setup({
  formatters_by_ft = {
    python = { "ruff_fix", "ruff_format", "black" },

    xml = { "xmllint" },
    xsd = { "xmllint" },
    xsl = { "xmllint" },
    xslt = { "xmllint" },
    svg = { "xmllint" },

    c = { "clang-format" },
    cpp = { "clang-format" },

    rust = { "rustfmt" },
  },
  formatters = {
    black = {
      command = black_spec.command,
      args = black_spec.args,
      stdin = true,
    },
    ruff_fix = {
      command = ruff_fix_spec.command,
      args = ruff_fix_spec.args,
      stdin = true,
    },
    ruff_format = {
      command = ruff_fmt_spec.command,
      args = ruff_fmt_spec.args,
      stdin = true,
    },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return {
      lsp_format = "fallback",
      timeout_ms = 2000,
    }
  end,
})

vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({
    lsp_format = "fallback",
    async = true,
    timeout_ms = 2000,
  })
end, { desc = "Format buffer (no write)" })

-- nvim-lint --------------------------------------------------------------------
local lint = require("lint")

lint.linters_by_ft = {
  python = { "ruff", "mypy" },
}

lint.linters.ruff = vim.tbl_deep_extend("force", lint.linters.ruff or {}, {
  cmd = make_cmd("ruff", {}).command,
  args = make_cmd("ruff", {
    "check",
    "--force-exclude",
    "--stdin-filename",
    function()
      return vim.api.nvim_buf_get_name(0)
    end,
    "-",
  }).args,
  stdin = true,
})

lint.linters.mypy = vim.tbl_deep_extend("force", lint.linters.mypy or {}, {
  cmd = make_cmd("mypy", {}).command,
  args = make_cmd("mypy", {
    "--show-column-numbers",
    "--hide-error-context",
    "--no-color-output",
    "--shadow-file",
    function()
      return vim.api.nvim_buf_get_name(0)
    end,
    function()
      return vim.api.nvim_buf_get_name(0)
    end,
    "-",
  }).args,
  stdin = true,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

-- Debugging (DAP) --------------------------------------------------------------
local dap = require("dap")
local dapui = require("dapui")

dapui.setup()
require("dap-python").setup(vim.fn.exepath("python"))

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug UI" })

-- Testing (pytest via neotest) -------------------------------------------------
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

vim.keymap.set("n", "<leader>tt", function()
  neotest.run.run()
end, { desc = "Test: nearest" })

vim.keymap.set("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand("%"))
end, { desc = "Test: file" })

vim.keymap.set("n", "<leader>to", function()
  neotest.output.open({ enter = true })
end, { desc = "Test: output" })

vim.keymap.set("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Test: summary" })

-- Diagnostics UI ---------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = {
    zindex = 40,
  },
  underline = true,
  update_in_insert = true,
})

local function show_line_diagnostics()
  if hover_active then
    return
  end

  vim.diagnostic.open_float(nil, {
    focus = false,
    scope = "cursor",
    zindex = 40,
    close_events = { "CursorMoved", "CursorMovedI", "InsertLeave", "BufLeave" },
  })
end

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
  callback = function()
    hover_active = false
  end,
})

vim.keymap.set({ "n", "i" }, "<M-d>", function()
  vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
end, { desc = "Show diagnostics at cursor" })

-- Insert-mode escape shortcuts -------------------------------------------------
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

-- Sd to docstring a selection in Python (using nvim-surround)
vim.g.surround_100 = '"""\r"""'

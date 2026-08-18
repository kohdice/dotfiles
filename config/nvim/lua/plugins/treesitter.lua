return {
  -- Parser management, highlighting, and indentation
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Programmatic parser installation (replaces ensure_installed)
      local ensure = {
        "bash",
        "c",
        "cmake",
        "css",
        "diff",
        "go",
        "gomod",
        "gosum",
        "graphql",
        "hcl",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "rust",
        "sql",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "zig",
      }
      require("nvim-treesitter").install(ensure)

      -- Scratch-like buffers never hold source worth parsing. Deny-list rather
      -- than allow-list: diffview gives its revision buffers buftype=nowrite,
      -- and those must highlight like the file they are diffed against
      local skip_buftypes = {
        nofile = true,
        prompt = true,
        quickfix = true,
        terminal = true,
      }

      -- Enable highlighting via the built-in API. The parser/large-file guard
      -- is shared with after/indent/<ft>.lua so both make the same decision
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("my-treesitter", { clear = true }),
        desc = "Start treesitter highlighting",
        callback = function(args)
          local buf = args.buf
          if skip_buftypes[vim.bo[buf].buftype] then
            return
          end
          local lang = require("utils.treesitter").usable_lang(buf)
          if not lang then
            return
          end
          pcall(vim.treesitter.start, buf, lang)
        end,
      })
    end,
  },

  -- Textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = { set_jumps = true },
      })

      local move = require("nvim-treesitter-textobjects.move")
      local map = function(lhs, fn, query, desc)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          fn(query, "textobjects")
        end, { desc = desc })
      end

      -- ]c/[c shadow the built-in diff-mode jump-to-change, so fall back
      -- to it in diff windows (same pattern as the gitsigns mappings)
      local class_map = function(lhs, fn, desc)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          if vim.wo.diff then
            vim.cmd.normal({ lhs, bang = true })
            return
          end
          fn("@class.outer", "textobjects")
        end, { desc = desc })
      end

      map("]f", move.goto_next_start, "@function.outer", "Next function start")
      class_map("]c", move.goto_next_start, "Next class start")
      map("]a", move.goto_next_start, "@parameter.inner", "Next parameter start")
      map("]F", move.goto_next_end, "@function.outer", "Next function end")
      map("]C", move.goto_next_end, "@class.outer", "Next class end")
      map("]A", move.goto_next_end, "@parameter.inner", "Next parameter end")
      map("[f", move.goto_previous_start, "@function.outer", "Prev function start")
      class_map("[c", move.goto_previous_start, "Prev class start")
      map("[a", move.goto_previous_start, "@parameter.inner", "Prev parameter start")
      map("[F", move.goto_previous_end, "@function.outer", "Prev function end")
      map("[C", move.goto_previous_end, "@class.outer", "Prev class end")
      map("[A", move.goto_previous_end, "@parameter.inner", "Prev parameter end")
    end,
  },

  -- Context display
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Auto close/rename HTML tags
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}

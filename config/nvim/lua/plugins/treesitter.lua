return {
  -- Parser management, highlighting, and indentation
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

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

      -- Enable highlighting via built-in API with large file guard
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf = args.buf
          local max_filesize = 100 * 1024
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return
          end
          if vim.b[buf] and vim.b[buf].large_file then
            return
          end
          pcall(vim.treesitter.start, buf)
        end,
      })

      -- Enable treesitter-based indentation
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
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

      map("]f", move.goto_next_start, "@function.outer", "Next function start")
      map("]c", move.goto_next_start, "@class.outer", "Next class start")
      map("]a", move.goto_next_start, "@parameter.inner", "Next parameter start")
      map("]F", move.goto_next_end, "@function.outer", "Next function end")
      map("]C", move.goto_next_end, "@class.outer", "Next class end")
      map("]A", move.goto_next_end, "@parameter.inner", "Next parameter end")
      map("[f", move.goto_previous_start, "@function.outer", "Prev function start")
      map("[c", move.goto_previous_start, "@class.outer", "Prev class start")
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

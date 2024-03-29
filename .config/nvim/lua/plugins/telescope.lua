return {
  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-file-browser.nvim'

    },
    config = function()
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`

      local telescope = require('telescope')
      local actions = require('telescope.actions')
      local builtin = require('telescope.builtin')

      local function telescope_buffer_dir()
        return vim.fn.expand('%:p:h')
      end

      local fb_actions = require 'telescope'.extensions.file_browser.actions

      telescope.setup {
        defaults = {
          mappings = {
            n = {
              ['q'] = actions.close
            },
          },
        },
        extensions = {
          file_browser = {
            theme = 'dropdown',
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
              -- your custom insert mode mappings
              ['i'] = {
                ['<C-w>'] = function() vim.cmd('normal vbd') end,
              },
              ['n'] = {
                -- your custom normal mode mappings
                ['N'] = fb_actions.create,
                ['h'] = fb_actions.goto_parent_dir,
                ['/'] = function()
                  vim.cmd('startinsert')
                end
              },
            },
          },
        },
      }

      telescope.load_extension('file_browser')

      vim.keymap.set('n', ';f',
        function()
          builtin.find_files({
            no_ignore = false,
            hidden = true
          })
        end,
        { desc = 'Find Files' }
      )
      vim.keymap.set('n', ';r',
        function()
          builtin.live_grep()
        end,
        { desc = 'Search by Grep' }
      )
      vim.keymap.set('n', '\\\\',
        function()
          builtin.buffers()
        end,
        { desc = 'Find existing buffers' }
      )
      vim.keymap.set('n', ';t',
        function()
          builtin.help_tags()
        end,
      { desc = 'Search Help' }
      )
      vim.keymap.set('n', ';;',
        function()
         builtin.resume()
        end
      )
      vim.keymap.set('n', ';e',
        function()
          builtin.diagnostics()
        end,
        { desc = 'Search Diagnostics' }
      )
      vim.keymap.set('n', 'sf',
        function()
          telescope.extensions.file_browser.file_browser({
            path = '%:p:h',
            cwd = telescope_buffer_dir(),
            respect_gitignore = false,
            hidden = true,
            grouped = true,
            previewer = false,
            initial_mode = 'normal',
            layout_config = { height = 40 }
          })
        end,
        { desc = 'Search Files' }
      )
      vim.keymap.set('n', '<leader>sw',
        function ()
          builtin.grep_string()
        end,
        { desc = 'Search current Word' }
      )
      vim.keymap.set('n', '<leader>?',
        function ()
         builtin.oldfiles()
        end,
        { desc = 'Find recently opened files' }
      )
      vim.keymap.set('n', '<leader>/',
        function()
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = true,
          })
        end,
        { desc = 'Fuzzily search in current buffer' }
      )
      vim.keymap.set('n', '<leader>gf',
        function ()
          builtin.git_files()
        end,
        { desc = 'Search Git Files' }
      )
    end
  }
}

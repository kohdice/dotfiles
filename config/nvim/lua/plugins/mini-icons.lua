require("mini.icons").setup()
-- lualine looks up nvim-web-devicons by module name; serve that API from
-- mini.icons instead of installing a second icon set
require("mini.icons").mock_nvim_web_devicons()

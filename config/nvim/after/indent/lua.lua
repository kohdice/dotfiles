-- Must live in after/indent/, not after/ftplugin/: the filetypeindent autocmd
-- is registered after filetypeplugin, so indent/<ft>.vim runs later and would
-- overwrite an 'indentexpr' set from an ftplugin (:h ftplugin, :h indent.txt).
require("utils.treesitter").set_indentexpr()

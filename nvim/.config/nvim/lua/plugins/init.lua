return {
  {
    'nvim-telescope/telescope.nvim',
     config = function()
      require "configs.telescope",
  },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
   	opts = {
      ensure_installed = {
  	    "vim", "lua", "vimdoc",
        "html", "css"
      },
    },
  },
}

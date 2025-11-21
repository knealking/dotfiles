return {
  "nvim-mini/mini.surround",
  opts = {
    mappings = {
      add = "<leader>sa", -- Add surrounding in Normal and Visual modes
      delete = "<leader>sd", -- Delete surrounding
      find = "gsf", -- Find surrounding (to the right)
      find_left = "gsF", -- Find surrounding (to the left)
      highlight = "gsh", -- Highlight surrounding
      replace = "gsr", -- Replace surrounding
      update_n_lines = "gsn", -- Update `n_lines`
    },
  },
}

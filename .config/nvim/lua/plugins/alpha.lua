return {
  "goolord/alpha-nvim",
  opts = function(_, dashboard)
    local logo = [[
  _   _  _____ _____  _   _ ________  ___
  | \ | ||  ___|  _  || | | |_   _|  \/  |
  |  \| || |__ | | | || | | | | | | .  . |
  | . ` ||  __|| | | || | | | | | | |\/| |
  | |\  || |___\ \_/ /\ \_/ /_| |_| |  | |
  \_| \_/\____/ \___/  \___/ \___/\_|  |_/
  ]]

    dashboard.section.header.val = vim.split(logo, "\n")
  end,
}

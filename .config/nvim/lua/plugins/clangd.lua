return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Ensure mason installs the server
      clangd = {
        -- overwrite default clangd settings
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--compile-commands-dir=/code/.clang-build",
          "--function-arg-placeholders",
          "--completion-style=detailed",
          "--fallback-style=Google",
          "--header-insertion=iwyu",
          "--j=4",
          "--malloc-trim",
          "--pch-storage=memory",
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
      },
    },
  },
}

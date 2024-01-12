local utils = require "astronvim.utils"
local js_based_languages = {
  "typescript",
  "javascript",
  "typescriptreact",
  "javascriptreact",
}

return {
  "mfussenegger/nvim-dap",
  optional = true,
  depepndencies = {
    {
      "microsoft/vscode-js-debug",
      -- After install, build it and rename the dist directory to out
      build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
      version = "1.*",
    },
    {
      "mxsdev/nvim-dap-vscode-js",
      opts = {
        debugger_path = vim.fn.resolve(vim.fn.stdpath "data" .. "/lazy/vscode-js-debug"),
        adapters = {
          "chrome",
          "pwa-node",
          "pwa-chrome",
          "pwa-msedge",
          "pwa-extensionHost",
          "node-terminal",
        },
      },
    },
    "mxsdev/nvim-dap-vscode-js",
  },
  config = function()
    local dap = require "dap"
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          require("mason-registry").get_package("js-debug-adapter"):get_install_path()
            .. "/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      },
    }
    local dap_config = {
      -- Debug single nodejs files
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
      },
      -- Debug nodejs processes (make sure to add --inspect when you run the process)
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require("dap.utils").pick_process,
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
      },
      -- Debug web applications (client side)
      {
        type = "pwa-chrome",
        request = "launch",
        name = "Launch & Debug Chrome",
        url = function()
          local co = coroutine.running()
          return coroutine.create(function()
            vim.ui.input({
              prompt = "Enter URL: ",
              default = "http://localhost:3000",
            }, function(url)
              if url == nil or url == "" then
                return
              else
                coroutine.resume(co, url)
              end
            end)
          end)
        end,
        webRoot = vim.fn.getcwd(),
        protocol = "inspector",
        sourceMaps = true,
        userDataDir = false,
      },
    }

    for _, language in ipairs(js_based_languages) do
      if not dap.configurations[language] then
        dap.configurations[language] = dap_config
      else
        dap.configurations[language] = dap_config
        utils.extend_tbl(dap.configurations[language], dap_config)
      end
    end
  end,
}

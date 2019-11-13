package = "ALGUI"
version = "scm-1"
source = {
  url = "git://github.com/ImagicTheCat/ALGUI",
}

description = {
  summary = "GUI Lua library",
  detailed = [[
Abstract Lua Graphical User Interface is a Lua library which aims to be an embeddable, flexible and simple GUI system.
  ]],
  homepage = "https://github.com/ImagicTheCat/ALGUI",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.4"
}

build = {
  type = "builtin",
  modules = {
    ["ALGUI.GUI"] = "src/GUI.lua",
    ["ALGUI.Renderer"] = "src/Renderer.lua",
    ["ALGUI.Widget"] = "src/Widget.lua",
    ["ALGUI.ext.GUI"] = "src/ext/GUI.lua",
    ["ALGUI.ext.Renderer"] = "src/ext/Renderer.lua"
  }
}

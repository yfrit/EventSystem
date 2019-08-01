package = "EventSystem"
version = "scm-1"
source = {
   url = "git+https://github.com/yfrit/EventSystem.git"
}
description = {
   summary = "Generic LUA event based system.",
   homepage = "https://github.com/yfrit/EventSystem",
   license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["EventSystem.Event"] = "Event.lua",
      ["EventSystem.EventListener"] = "EventListener.lua",
   }
}

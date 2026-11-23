-- Modular Studio loader. The single-file distribution embeds these exact modules.
local Studio=require(script.Studio)
local app=Studio.start()
app.scope:on(script.Destroying,function() app:destroy() end)

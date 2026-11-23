-- Modular Studio loader; also usable in the standalone bundle.
local Studio=require(script.Studio)
-- Reload safely: destroying the old studio triggers its own scope cleanup.
local players=game:GetService("Players")
local me=players.LocalPlayer
assert(me,"AETHER requires a client player")
local pg=me:WaitForChild("PlayerGui",15)
assert(pg,"AETHER requires PlayerGui")
local previous=pg:FindFirstChild("AetherFullStudio")
if previous then previous:Destroy() end

local app=Studio.start(me)
-- A standalone loadstring may have no script Instance in its environment.
-- In a native LocalScript, destroying the script also tears down the session.
if typeof(script)=="Instance" then
 local ok,signal=pcall(function() return script.Destroying end)
 if ok and typeof(signal)=="RBXScriptSignal" then
  app.scope:on(signal,function() app:destroy() end)
 end
end

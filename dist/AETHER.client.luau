-- AETHER compatibility entry point for the previous loadstring URL.
-- Requires a client runtime exposing game:HttpGet and loadstring.
-- Uses the single-file bundle from this repository; no custom executor APIs.
local url="https://raw.githubusercontent.com/0wertyx/AETHER-Luau/main/AetherFull.client.luau"
if not game:IsLoaded() then game.Loaded:Wait() end
assert(type(loadstring)=="function","AETHER: this runtime does not expose loadstring")
local ok,body=pcall(function() return game:HttpGet(url) end)
assert(ok and type(body)=="string" and #body>1000,"AETHER: could not fetch standalone bundle: "..tostring(body))
local fn,err=loadstring(body)
assert(fn,"AETHER: could not compile standalone bundle: "..tostring(err))
return fn()

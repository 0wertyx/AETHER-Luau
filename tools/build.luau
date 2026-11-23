-- Development-only packager, run from project root: lune run tools/build
local fs=require("@lune/fs");local process=require("@lune/process")
local function read(name) return fs.readFile("src/"..name..".luau") end
local modules={"Util","Schema","Symbol","Avatar","World","View","Hud","Cues","Controls","Storage","Pages","Studio"}
local chunks={"-- AETHER Full · standalone native Roblox LocalScript\nlocal factories,cache={},{}\nlocal function use(n) if cache[n]==nil then cache[n]=factories[n]() end;return cache[n] end\n"}
for _,n in modules do local src=read(n):gsub("require%(script%.Parent%.(%w+)%)",'use("%1")');table.insert(chunks,'factories["'..n..'"]=function()\n'..src..'\nend\n') end
table.insert(chunks,(read("Start.client"):gsub("require%(script%.Studio%)",'use("Studio")')));local bundle=table.concat(chunks)
local function esc(s) return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;")) end
local function item(class,name,props,children) return '<Item class="'..class..'"><Properties><string name="Name">'..esc(name)..'</string>'..(props or '')..'</Properties>'..(children or '')..'</Item>' end
local function scriptItem(class,name,code,children) return item(class,name,'<ProtectedString name="Source">'..esc(code)..'</ProtectedString>',children) end
local function xml(children) return '<roblox version="4">'..children..'</roblox>' end
local server=scriptItem("Script","AetherProfiles",read("Profiles.server"),scriptItem("ModuleScript","Schema",read("Schema")))
local client=scriptItem("LocalScript","AetherFull",bundle)
local pad=item("SpawnLocation","Spawn",'<bool name="Anchored">true</bool><bool name="Neutral">true</bool><bool name="AllowTeamChangeOnTouch">false</bool><Vector3 name="size"><X>10</X><Y>1</Y><Z>10</Z></Vector3>')
local function place(clientItem,extra,marker)
 return xml(item("Workspace","Workspace",nil,pad..(marker and item("Folder",marker) or ''))..item("StarterPlayer","StarterPlayer",nil,item("StarterPlayerScripts","StarterPlayerScripts",nil,clientItem))..item("ServerScriptService","ServerScriptService",nil,server..scriptItem("Script","Atrium",read("Demo.server"))..(extra or '')))
end
if not fs.isDir("dist") then fs.writeDir("dist") end
fs.writeFile("dist/AetherFull.client.luau",bundle);fs.writeFile("dist/AetherClient.rbxmx",xml(client));fs.writeFile("dist/AetherProfiles.rbxmx",xml(server));fs.writeFile("dist/AETHER.rbxlx",place(client));print("AETHER: standalone place, client, server model and single-file LocalScript generated.")
if process.args[1]=="smoke" then
 local path=assert(process.args[2],"test directory");local nonce=assert(process.args[3]);assert(nonce:match("^AetherFullTest%x+$"),"Expected fixture nonce");local testClient=bundle..'\n'..fs.readFile('tests/client.luau'):gsub('FIXTURE_NONCE',nonce)
 local testServer=scriptItem("Script","Fixture",(fs.readFile('tests/server.luau'):gsub('FIXTURE_NONCE',nonce)));fs.writeFile(path.."/"..nonce..".rbxlx",place(scriptItem("LocalScript","AetherFull",testClient),testServer,nonce))
 local pluginCode=fs.readFile('tests/runner.luau'):gsub('FIXTURE_NONCE',nonce);fs.writeFile(path.."/"..nonce..".rbxmx",xml(scriptItem("Script",nonce,pluginCode)));print("Fixture generated: "..nonce)
end

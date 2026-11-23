-- Pure Luau/Lune test: the serialized bank is the boundary shared by GUI, import and server.
local S=require("../src/Schema");local json=require("@lune/serde")
local bank=S.blank();bank.settings.wings=true;bank.settings.hpX=42;bank.settings.players["-2"]={label="Scout",shape="Compass",color="AA88FF"};bank.profiles.Demo=S.copy(bank.settings)
local count=0;for kind,presets in S.presets do for name,data in presets do assert(S.asset({version=1,kind=kind,name=name,data=data}));count+=1 end end
bank.assets.Wing={version=1,kind="Wings",name="Wing",data=S.capture(bank.settings,"Wings")};local restored=S.bank(json.decode("json",json.encode("json",bank)));assert(restored.profiles.Demo.hpX==42 and restored.assets.Wing.data.wings and restored.settings.players['-2'].shape=='Compass');restored.settings.players['-2'].label='New';assert(restored.profiles.Demo.players['-2'].label=='Scout')
for _,bad in {{version=4},{version=1,settings={fov=200},profiles={},assets={}},{version=1,settings={unexpected=1},profiles={},assets={}},{version=1,settings={},profiles={},assets={x={version=1,name="x",kind="Fonts",data={camera=true}}}}} do assert(not pcall(S.bank,bad),"Bad input was accepted") end
print(string.format("Schema/JSON passed · %d settings, %d built-in assets, %d shapes",#S.order,count,#S.shapes))

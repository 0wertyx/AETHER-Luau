-- The ORIGINAL AETHER desktop icons are 32 PNG images of 224 x 224.
-- Make one 8x4 atlas from assets/icons and upload it as a Roblox image asset.
-- The atlas is included separately for importing; Roblox cannot draw GitHub PNG URLs directly.
local U=require(script.Parent.Util)
local I={}
I.TILE=224
I.columns=8
I.order={
 "Home","Dashboard","HUD","Fonts","Themes","World_FX","Indicators","Simulator",
 "Workshop","Downloads","Plugins","Extensions","AI_Assistant","Music","Media","Games",
 "Console","Logs","Settings","Profile","Health","Performance","Update","About",
 "Tests","Debug","Bridge","Launch","Files","Assets","Cloud","Favorites"
}
I.tabs={
 Dashboard="Dashboard",HUD="HUD",Character="Profile",Wings="Favorites",
 Halos="AI_Assistant",Neon="Themes",Ambient="World_FX",Indicators="Indicators",
 Cursor="Assets",Camera="Media",Fonts="Fonts",Simulator="Simulator",
 Scripts="Console",Workshop="Workshop",Profiles="Cloud",Diagnostics="Debug"
}
local lookup={}
for index,name in I.order do lookup[name]=index-1 end
function I.new(button,tab)
 local visual=U.new("ImageLabel",{
  Name="AetherDesktopIcon",BackgroundTransparency=1,Active=false,Selectable=false,
  Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(5,4),
  ScaleType=Enum.ScaleType.Crop,Visible=false,ZIndex=button.ZIndex+1
 },button)
 local iconOnly=button:GetAttribute("AETHERIconOnly")==true
 if iconOnly then visual.Position=UDim2.new(.5,-12,.5,-12) end
 local name=I.tabs[tab] or tab
 local index=lookup[name]
 if index then visual.ImageRectOffset=Vector2.new(index%8*I.TILE,math.floor(index/8)*I.TILE) end
 visual.ImageRectSize=Vector2.new(I.TILE,I.TILE)
 local self={visual=visual,button=button,last=""}
 function self:sync(asset)
  asset=tostring(asset or ""):match("^%d+$") or ""
  if asset==self.last then return end
  self.last=asset
  local ready=asset~="" and index~=nil
  visual.Visible=ready
  visual.Image=if ready then "rbxassetid://"..asset else ""
  if iconOnly then
   button.Text=if ready then "" else tostring(button:GetAttribute("AETHERText") or "")
  else
   button.TextXAlignment=if ready then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center
   button.TextSize=if ready then 11 else 13
  end
 end
 return self
end
return I

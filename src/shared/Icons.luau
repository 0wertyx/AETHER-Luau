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
-- Native line-art icons provide a reliable offline fallback for every tab.
-- Coordinates are normalized to a 24 by 24 icon, independent of display size.
local drawings={
 Dashboard={{3,3,10,3,10,10,3,10,3,3},{14,3,21,3,21,10,14,10,14,3},{3,14,10,14,10,21,3,21,3,14},{14,14,21,14,21,21,14,21,14,14}},
 HUD={{2,4,22,4,22,20,2,20,2,4},{5,7,11,7,11,11,5,11,5,7},{5,16,19,16},{15,8,19,8}},
 Profile={{12,3,16,5,17,9,14,12,10,12,7,9,8,5,12,3},{4,21,4,18,8,15,16,15,20,18,20,21}},
 Favorites={{12,2,15,9,22,9,17,14,19,21,12,17,5,21,7,14,2,9,9,9,12,2}},
 AI_Assistant={{12,2,15,9,22,12,15,15,12,22,9,15,2,12,9,9,12,2},{19,2,19,6},{17,4,21,4}},
 Themes={{12,2,21,7,21,16,12,22,3,16,3,7,12,2},{12,6,15,12,12,18,9,12,12,6}},
 World_FX={{3,19,9,10,13,15,17,8,22,19,3,19},{6,4,9,4},{7.5,2.5,7.5,5.5}},
 Indicators={{12,2,22,21,12,16,2,21,12,2}},
 Assets={{4,2,18,2,21,5,21,22,4,22,4,2},{8,7,17,7},{8,12,17,12},{8,17,14,17}},
 Media={{3,6,15,6,15,18,3,18,3,6},{15,10,21,6,21,18,15,14}},
 Fonts={{3,21,10,3,13,3,21,21},{6,14,18,14}},
 Simulator={{12,2,22,7,22,17,12,22,2,17,2,7,12,2},{2,7,12,12,22,7},{12,12,12,22}},
 Console={{2,4,22,4,22,20,2,20,2,4},{5,8,9,12,5,16},{12,16,18,16}},
 Workshop={{3,5,21,5,21,21,3,21,3,5},{8,5,8,2,16,2,16,5},{3,11,21,11},{10,10,14,10,14,13,10,13,10,10}},
 Cloud={{4,18,2,15,4,10,8,10,9,5,14,3,18,6,19,10,22,12,22,16,19,18,4,18}},
 Debug={{7,7,17,7,19,10,19,17,15,21,9,21,5,17,5,10,7,7},{8,7,6,3},{16,7,18,3},{2,11,5,11},{19,11,22,11},{2,16,5,16},{19,16,22,16},{12,8,12,20}},
}
local function lineArt(button,name,iconOnly)
 local root=U.frame(button,"NativeIcon",nil,UDim2.fromOffset(20,20),nil,1)
 root.Active=false;root.Interactable=false;root.ZIndex=button.ZIndex+1
 root.Position=if iconOnly then UDim2.new(.5,-10,.5,-10) else UDim2.new(0,7,.5,-10)
 local color=Color3.fromRGB(231,216,255)
 for _,path in drawings[name] or drawings.Assets do
  for j=1,#path-2,2 do
   local x,y=path[j],path[j+1];local dx,dy=path[j+2]-x,path[j+3]-y
   local edge=U.frame(root,"Stroke",UDim2.fromScale((x+dx*.5)/24,(y+dy*.5)/24),UDim2.new(math.sqrt(dx*dx+dy*dy)/24,0,0,1.6),color,0)
   edge.AnchorPoint=Vector2.new(.5,.5);edge.Rotation=math.deg(math.atan2(dy,dx));edge.Active=false;edge.Interactable=false;edge.ZIndex=root.ZIndex
   U.corner(edge,2)
  end
 end
 return root
end
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
 local native=lineArt(button,name,iconOnly)
 local self={visual=visual,button=button,native=native,last=nil}
 local function refresh()
  local ready=self.last~=nil and self.last~="" and index~=nil and visual.IsLoaded
  visual.Visible=ready
  native.Visible=not ready
  if iconOnly then
   button.Text=""
  else
   button.TextXAlignment=Enum.TextXAlignment.Right
   button.TextSize=11
  end
  button.TextColor3=Color3.fromRGB(241,234,255)
 end
 visual:GetPropertyChangedSignal("IsLoaded"):Connect(refresh)
 function self:sync(asset)
  asset=tostring(asset or ""):match("^%d+$") or ""
  if asset~=self.last then
   self.last=asset
   visual.Image=if asset~="" and index~=nil then "rbxassetid://"..asset else ""
  end
  refresh()
 end
 self:sync("")
 return self
end
return I

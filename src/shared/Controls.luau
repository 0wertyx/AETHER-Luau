local StarterGui=game:GetService("StarterGui");local Input=game:GetService("UserInputService");local Tween=game:GetService("TweenService");local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Icons=require(script.Parent.Icons)
local Constellation=require(script.Parent.Constellation)
local UI={};UI.__index=UI
local bg=Color3.fromRGB(19,16,32);local dim=Color3.fromRGB(173,163,197);local soft=Color3.fromRGB(43,35,60)
local function chevron(parent)
 local glyph=U.frame(parent,"Chevron",UDim2.fromScale(.5,.5),UDim2.fromOffset(18,12),nil,1)
 glyph.AnchorPoint=Vector2.new(.5,.5);glyph.Active=false;glyph.Interactable=false;glyph.ZIndex=parent.ZIndex+1
 for i=1,2 do
  local line=U.frame(glyph,"Stroke"..i,UDim2.new(.5,if i==1 then -3 else 3,.5,0),UDim2.fromOffset(9,2),Color3.fromRGB(231,217,255),0)
  line.AnchorPoint=Vector2.new(.5,.5);line.Rotation=if i==1 then 45 else -45
  line.Active=false;line.Interactable=false;line.ZIndex=glyph.ZIndex;U.corner(line,2)
 end
 return glyph
end
local searchSections={
 {"Dashboard","THEMES"},
 {"Dashboard","CONSTELLATION COLORS"},
 {"Dashboard","MOTION"},
 {"HUD","TOP PANEL"},
 {"HUD","HUD MOTION"},
 {"HUD","HEART GRADIENT"},
 {"HUD","Edit HUD on screen"},
 {"HUD","Reset panel position"},
 {"Character","AETHER MOTION STUDIO V12.14"},
 {"Character","HALO COLLECTION"},
 {"Character","WING COLLECTION"},
 {"Character","EFFECT COLLECTION"},
 {"Character","EFFECT SETTINGS"},
 {"Character","Disable all halos"},
 {"Ambient","AMBIENT COLLECTION"},
 {"Ambient","AMBIENT SETTINGS"},
 {"Ambient","STARFALL COLORS"},
 {"Indicators","PER-PLAYER OVERRIDE"},
 {"Indicators","Assign current shape"},
 {"Indicators","Remove override"},
 {"Indicators","UserId or simulator ID"},
 {"Indicators","Label override"},
 {"Indicators","Override hex"},
 {"Cursor","TRAIL COLORS"},
 {"Interaction","AETHER PEER VISUALS"},
 {"Interaction","AIR REDIRECTION"},
 {"Interaction","CAMERA"},
 {"Interaction","CUSTOM LOCK / KEYBIND"},
 {"Interaction","SHIFT-LOCK / RETICLE"},
 {"Interaction","LIVE INPUT DISPLAY"},
 {"Interaction","WALLHOP HELPER"},
 {"Volleyball","VOLLEYBALL MODIFIERS / BETA"},
 {"Volleyball","BALL HITBOX EXPANDER / BETA"},
 {"Volleyball","BALL TOUCH INFO"},
 {"Volleyball","SHOT ARC / BETA"},
 {"Volleyball","TRAJECTORY ESP / BETA"},
 {"Volleyball","DIRECTION ESP / BETA"},
 {"Volleyball","JINKO STYLE / LOCAL PREVIEW"},
 {"Volleyball","CURVE SPECIAL / EXPERIMENT"},
 {"Volleyball","AUTO PLAY / BETA"},
 {"Volleyball","CONSECUTIVE TOUCH / BETA"},
 {"Volleyball","SPIKE CAMERA"},
 {"Volleyball","AUTO TILT / BETA"},
 {"Volleyball","AIR REDIRECTION"},
 {"Volleyball","Restore original values"},
 {"Volleyball","Toggle Ball Expander"},
 {"Volleyball","Show Hitbox"},
 {"Volleyball","Show last hitter"},
 {"Volleyball","Shot Arc"},
 {"Volleyball","Auto"},
 {"Volleyball","Spike"},
 {"Volleyball","Set"},
 {"Volleyball","Serve"},
 {"Volleyball","Toggle Trajectory ESP"},
 {"Volleyball","Toggle Direction ESP"},
 {"Volleyball","Toggle Jinko preview"},
 {"Volleyball","Toggle local Curve test"},
 {"Volleyball","Auto Set"},
 {"Volleyball","Auto Spike"},
 {"Volleyball","Auto Dive"},
 {"Volleyball","Auto Serve"},
 {"Volleyball","Repeat touch test"},
 {"Volleyball","Free zone"},
 {"Volleyball","Court center"},
 {"Volleyball","Off"},
 {"Volleyball","Ground prediction"},
 {"Volleyball","Auto Jump"},
 {"Volleyball","Anti-out guard"},
 {"Volleyball","Auto detect court"},
 {"Volleyball","Corner A"},
 {"Volleyball","Corner B"},
 {"Volleyball","Corner C"},
 {"Volleyball","Toggle Auto Tilt"},
 {"Volleyball","Clear court"},
 {"Volleyball","Correct edges"},
 {"Volleyball","Aim center"},
 {"Volleyball","Aim left"},
 {"Volleyball","Aim right"},
 {"Volleyball","Ball size factor (>=1)"},
 {"Volleyball","Curve input strength (0–1)"},
 {"Fonts","Search native typefaces"},
 {"Simulator","WORLD PREVIEW"},
 {"Simulator","Use simulator"},
 {"Simulator","Use game"},
 {"Simulator","Damage −25"},
 {"Simulator","Heal +25"},
 {"Simulator","Respawn"},
 {"Simulator","Add player"},
 {"Simulator","Move players"},
 {"Simulator","Clear players"},
 {"Simulator","Apply virtual vitals"},
 {"Simulator","Set virtual HP"},
 {"Simulator","Virtual max HP"},
 {"List","ROBLOX PLAYER LIST"},
 {"List","Toggle native player list"},
 {"Updates","LIVE UPDATE CENTER"},
 {"Updates","UPDATE LIST"},
 {"Updates","Test update"},
 {"Updates","Check updates"},
 {"Updates","Rollback"},
 {"Diagnostics","SESSION"},
 {"Diagnostics","Refresh"},
 {"Diagnostics","Clear log"},
 {"Diagnostics","Reset settings"},
 {"Diagnostics","Session events"},
 {"Volleyball","BlockPower"},
 {"Volleyball","BumpPower"},
 {"Volleyball","DashPower"},
 {"Volleyball","DiveSpeed"},
 {"Volleyball","DrawPower"},
 {"Volleyball","JumpPower"},
 {"Volleyball","ServePower"},
 {"Volleyball","SetPower"},
 {"Volleyball","Speed"},
 {"Profiles","Save new"},
 {"Profiles","Load"},
 {"Profiles","Update selected"},
 {"Profiles","Rename"},
 {"Profiles","Duplicate"},
 {"Profiles","Delete"},
 {"Profiles","Save now"},
 {"Profiles","Reload bank"},
 {"Profiles","Export bank"},
 {"Profiles","Import bank"},
 {"Scripts","AETHER Lua"},
 {"Scripts","Luau draft"},
 {"Scripts","Template"},
 {"Scripts","Complete symbol"},
 {"Scripts","Select source"},
 {"Scripts","Check"},
 {"Wings","Wing styles"},
 {"Halos","Halo styles"},
 {"Neon","Neon motion"},
 {"Character","Walk animation"},
 {"Character","Pose preview"},
}
-- Native GUI at rest: CanvasGroup is only a short-lived fade compositor.
-- Restore direct descendants at full opacity so text, glyphs and ViewportFrames
-- do not keep rendering into a potentially downsampled offscreen surface.
local function transition(root,q)
 local group=root:FindFirstChild("AETHERTransitionSurface")
 if q>=.99999 then
  if group then
   for _,child in group:GetChildren() do child.Parent=root end
   group:Destroy()
  end
  return
 end
 if not group then
  group=U.new("CanvasGroup",{Name="AETHERTransitionSurface",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=1-q},root)
 end
 for _,child in root:GetChildren() do
  if child~=group and child:IsA("GuiObject") then child.Parent=group end
 end
 group.GroupTransparency=1-q
end
function UI.new(app,gui,scope)
 local self=setmetatable({app=app,gui=gui,scope=scope,syncs={},icons={},tab="Dashboard",opened=true,seq=0,menuProgress=0,pageProgress=0,navHover={},navAmount={}},UI)
 self.stage=U.frame(gui,"StudioArea",nil,nil,nil,1)
 -- The backdrop is deliberately not a fullscreen CanvasGroup: each particle fades separately.
 self.screenFX=U.frame(self.stage,"MenuScreenEffects",nil,nil,nil,1)
 self.screenFX.Active=false;self.screenFX.Interactable=false
 self.screenFX.Visible=false
 self.screenDim=U.frame(self.screenFX,"Veil",nil,nil,Color3.fromRGB(19,12,38),1)
 self.screenDim.Active=false;self.screenDim.Interactable=false
 self.stars={}
 for i=1,48 do
  local root=U.frame(self.screenFX,"Particle"..i,nil,UDim2.fromOffset(12,12),nil,1)
  root.Active=false;root.Interactable=false;root.AnchorPoint=Vector2.new(.5,.5)
  local bars={}
  for j=1,4 do
   local line=U.frame(root,"Ray",UDim2.fromScale(.5,.5),UDim2.fromScale(1,.13),Color3.new(1,1,1),1)
   line.AnchorPoint=Vector2.new(.5,.5);line.Active=false;line.Interactable=false;line.Rotation=(j-1)*45;U.corner(line,9);bars[j]=line
  end
  local dot=U.frame(root,"Core",UDim2.fromScale(.5,.5),UDim2.fromScale(.5,.5),Color3.new(1,1,1),1)
  dot.AnchorPoint=Vector2.new(.5,.5);dot.Active=false;dot.Interactable=false;U.corner(dot,99)
  self.stars[i]={root=root,bars=bars,dot=dot}
 end
 self.top,self.topRim,self.topButtons=U.topPanel(self.stage)
 self.updateChip=U.label(self.top,"v1.0.0",10)
 self.updateChip.TextXAlignment=Enum.TextXAlignment.Center;self.updateChip.Active=false;self.updateChip.Interactable=false
 U.corner(self.updateChip,8)
 self.updateChip.Name="LiveVersion"
 self.updateChip.AnchorPoint=Vector2.new(.5,0)
 self.updateChip.Position=UDim2.new(.5,0,1,6)
 self.updateChip.Size=UDim2.fromOffset(112,22)
 self.updateChip.TextSize=10;self.updateChip.ZIndex=self.top.ZIndex+2
 self.updateChip.BackgroundColor3=bg;self.updateChip.BackgroundTransparency=.15
 self.updateRim=U.stroke(self.updateChip,Color3.fromRGB(166,138,255),.45)
 local coreOriginal,coreApplied={},{}
 scope:add(function()
  for kind,original in coreOriginal do pcall(function() if StarterGui:GetCoreGuiEnabled(kind)==coreApplied[kind] then StarterGui:SetCoreGuiEnabled(kind,original) end end) end
 end)
 function self:togglePlayerList()
  local kind=Enum.CoreGuiType.PlayerList
  local enabled=StarterGui:GetCoreGuiEnabled(kind)
  if coreOriginal[kind]==nil then coreOriginal[kind]=enabled end
  StarterGui:SetCoreGuiEnabled(kind,not enabled);coreApplied[kind]=not enabled
  self:message(if enabled then "Roblox player list hidden" else "Roblox player list enabled")
 end
 self.panel=U.new("Frame",{Name="Studio",BackgroundColor3=bg,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,Active=true},self.stage);U.corner(self.panel,17);self.outline=U.stroke(self.panel,Color3.fromRGB(159,127,230),.3)
 self.panelBackground=U.frame(self.panel,"GlassBackground",nil,nil,Color3.new(1,1,1),.035);self.panelBackground.Active=false;self.panelBackground.Interactable=false;self.panelBackground.ZIndex=1;U.corner(self.panelBackground,17)
 self.backgroundGradient=U.gradient(self.panelBackground,bg,Color3.fromRGB(39,30,58),82)
 self.geoLayer=U.frame(self.panel,"GeometryBackground",UDim2.fromOffset(3,3),UDim2.new(1,-6,1,-6),nil,1)
 self.geoLayer.ClipsDescendants=true;self.geoLayer.Active=false;self.geoLayer.ZIndex=1
 self.constellation=Constellation.new(self.geoLayer)
 self.header=U.frame(self.panel,"Titlebar",nil,UDim2.new(1,0,0,46),nil,1);self.header.Active=true;self.brand=U.label(self.header,"A E T H E R",18,UDim2.fromOffset(16,2),UDim2.fromOffset(135,40));self.tag=U.label(self.header,"",10,UDim2.fromOffset(147,3),UDim2.new(1,-190,0,40));self.tag.TextColor3=dim
 self.close=U.button(self.header,"×");self.close.Modal=false;self.close.Size=UDim2.fromOffset(33,29);self.close.Position=UDim2.new(1,-43,0,8);scope:on(self.close.Activated,function() self:show(false) end)
 self.dockPicker=U.button(self.header,"←");self.dockPicker.Size=UDim2.fromOffset(32,29);self.dockPicker.Position=UDim2.new(1,-79,0,8);self.dockPicker.TextSize=18
 local sides={"Left","Right","Top","Bottom","Floating"}
 scope:on(self.dockPicker.Activated,function()
  self.app:set("menuDock",sides[(table.find(sides,self.app.s.menuDock) or 0)%#sides+1])
 end)
 self.grip=U.button(self.panel,"◢");self.grip.Name="ResizeGrip";self.grip.Size=UDim2.fromOffset(26,26);self.grip.TextSize=18;self.grip.ZIndex=6;self.grip.BackgroundTransparency=.42
 self.tag.Size=UDim2.new(1,-231,0,40)
 self.place=U.label(self.panel,"PLACE  /  "..tostring(game.PlaceId),10,nil,nil);self.place.TextColor3=dim
 self.nav=U.new("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3},self.panel);self.navList=U.new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},self.nav)
 self.pageBox=U.new("Frame",{Name="PageArea",BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},self.panel);self.status=U.label(self.panel,"",11,UDim2.new(0,16,1,-28),UDim2.new(1,-32,0,22));self.status.TextColor3=dim
 self.buttons={};for i,name in {"Dashboard","HUD","Character","Wings","Halos","Neon","Ambient","Indicators","Cursor","Interaction","Volleyball","Fonts","Simulator","Scripts","Profiles","Updates","List","Diagnostics"} do local b=U.button(self.nav,name);b.Name=name;b.LayoutOrder=i;self.buttons[name]=b;self.icons[name]=Icons.new(b,if name=="Volleyball" then "Interaction" else name);scope:on(b.Activated,function() if self.opened and os.clock()>=(self.tabInputAfter or 0) then self:open(name) end end);scope:on(b.MouseEnter,function() self.navHover[name]=true end);scope:on(b.MouseLeave,function() self.navHover[name]=false end) end
 self.search=U.new("TextBox",{Name="FunctionSearch",Text="",PlaceholderText="Search functions...",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(241,234,255),PlaceholderColor3=dim,BackgroundColor3=soft,BorderSizePixel=0},self.panel)
 U.corner(self.search,8);U.new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},self.search)
 self.searchResults=U.new("ScrollingFrame",{Name="FunctionSearchResults",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,Visible=false},self.panel)
 U.new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},self.searchResults)
 self.searchPool={}
 self.searchIndex={}
 for _,name in {"Dashboard","HUD","Character","Wings","Halos","Neon","Ambient","Indicators","Cursor","Interaction","Volleyball","Fonts","Simulator","Scripts","Profiles","Updates","List","Diagnostics"} do
  table.insert(self.searchIndex,{tab=name,label=name,term=name:lower()})
 end
 for _,k in S.order do
  local d=S.defs[k]
  if type(d)~="table" or type(d.group)~="string" or k=="robloxRail" or k=="railCustom" or k=="railX" or k=="railY" then continue end
  local tab=if d.group=="Theme" or d.group=="Motion" then "Dashboard" elseif d.group=="Camera" then "Interaction" else d.group
  if not self.buttons[tab] then continue end
  local label=if type(d.label)=="string" and d.label~="" then d.label elseif k=="players" then "Per-player override" else tostring(k)
  table.insert(self.searchIndex,{tab=tab,label=label,key=k,term=(label.." "..tostring(k).." "..tab):lower()})
 end
 for _,item in searchSections do
  table.insert(self.searchIndex,{tab=item[1],label=item[2],term=(item[2].." "..item[1]):lower()})
 end
 self.bindActions={}
 self.bindRows={}
 self.bindPanel=U.frame(self.stage,"KeybindHUD",UDim2.fromOffset(30,110),UDim2.fromOffset(220,70),bg,.18)
 self.bindPanel.ZIndex=20;self.bindPanel.Active=false;U.corner(self.bindPanel,12)
 self.bindRim=U.stroke(self.bindPanel,Color3.fromRGB(166,138,255),.4)
 local bindTitle=U.label(self.bindPanel,"KEYBINDS",11,UDim2.fromOffset(12,5),UDim2.new(1,-24,0,22));bindTitle.ZIndex=21
 self.bindList=U.new("ScrollingFrame",{Name="AssignedKeys",Position=UDim2.fromOffset(8,29),Size=UDim2.new(1,-16,1,-35),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ZIndex=21},self.bindPanel)
 U.new("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},self.bindList)
 self.bindEmpty=U.label(self.bindList,"No keybinds assigned",11,nil,UDim2.new(1,0,0,25));self.bindEmpty.ZIndex=22;self.bindEmpty.LayoutOrder=999
 self.quickOpen=false
 self.quickArrow=U.button(self.top,"")
 self.quickArrow.Name="VolleyballDropdown";self.quickArrow.AnchorPoint=Vector2.new(.5,0)
 self.quickArrow.Size=UDim2.fromOffset(36,24);self.quickArrow.Position=UDim2.new(.5,0,1,32)
 self.top.ZIndex=25;self.topButtons[1].ZIndex=26;self.updateChip.ZIndex=27;self.quickArrow.ZIndex=27
 self.quickGlyph=chevron(self.quickArrow)
 self.quick=U.new("Frame",{Name="VolleyballQuickPanel",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,1,58),Size=UDim2.fromOffset(324,380),BackgroundColor3=bg,BackgroundTransparency=.10,BorderSizePixel=0,Visible=false,Active=true,ZIndex=28},self.top)
 U.corner(self.quick,13);self.quickRim=U.stroke(self.quick,Color3.fromRGB(166,138,255),.3)
 local title=U.label(self.quick,"VOLLEYBALL / MODULES",12,UDim2.fromOffset(12,5),UDim2.new(1,-88,0,22));title.ZIndex=29
 local edit=U.button(self.quick,"EDIT HUD");edit.Name="EditWidgetPositions";edit.Size=UDim2.fromOffset(68,23);edit.Position=UDim2.new(1,-76,0,5);edit.TextSize=10;edit.ZIndex=30
 scope:on(edit.Activated,function() if self.quickOpen and not self.app.editingHUD then self.app:editHUD(true,"Volleyball",true) end end)
 self.quickScroll=U.new("ScrollingFrame",{Name="QuickFunctions",Position=UDim2.fromOffset(8,32),Size=UDim2.new(1,-16,1,-60),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ZIndex=29},self.quick)
 U.new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},self.quickScroll)
 self.quickStatus=U.label(self.quick,"Tap a module to expand",10,UDim2.new(0,10,1,-24),UDim2.new(1,-20,0,20))
 self.quickStatus.ZIndex=29
 self.quickExpanded={}
 scope:add(function() if self.quickPage then self.quickPage:clear();self.quickPage=nil end end)
 scope:on(self.quickArrow.Activated,function()
  if not self.app.volleyball or self.app.editingHUD then return end
  local on=not self.quickOpen
  if on and self.opened then self:show(false) end
  self:setQuick(on)
 end)
 scope:on(self.search:GetPropertyChangedSignal("Text"),function() self:refreshSearch() end)
 function self:layout()
  local sz=self.stage.AbsoluteSize
  if sz.X<2 or sz.Y<2 then self.layoutPending=true;return end
  self.layoutPending=false;self.layoutViewport=sz
  local s=self.app.s;local draft=self.menuDraft
  local side=if draft then draft.side else s.menuDock
  local narrow=sz.X<740
  local left=12
  local top=if narrow then 92 else 62
  local bottom=if narrow then 126 else 76
  if sz.Y<420 then top=12;bottom=12 end
  local maxW=math.max(1,math.min(1600,sz.X-left-14))
  local maxH=math.max(1,math.min(1200,sz.Y-top-bottom))
  local w=math.clamp(if draft then draft.w else s.menuWidth,math.min(280,maxW),maxW)
  local h=math.clamp(if draft then draft.h else s.menuHeight,math.min(260,maxH),maxH)
  local x,y
  if draft and draft.xy then
   x=draft.xy.X;y=draft.xy.Y
  elseif side=="Left" then
   x=left;y=top+math.max(0,maxH-h)*.5
  elseif side=="Right" then
   x=sz.X-w-14;y=top+math.max(0,maxH-h)*.5
  elseif side=="Top" then
   x=(sz.X-w)*.5;y=top
  elseif side=="Bottom" then
   x=(sz.X-w)*.5;y=sz.Y-h-bottom
  else
   x=(sz.X-w)*s.menuFloatX/100;y=(sz.Y-h)*s.menuFloatY/100
  end
  self.xy=Vector2.new(math.clamp(x,0,math.max(0,sz.X-w)),math.clamp(y,0,math.max(0,sz.Y-h)))
  self.panel.Size=UDim2.fromOffset(w,h);self.panel.Position=UDim2.fromOffset(self.xy.X,self.xy.Y)
  self.layoutSide=side;self.panelExtent=Vector2.new(w,h)
  self.dockPicker.Text=({Left="←",Right="→",Top="↑",Bottom="↓",Floating="◇"})[side] or "◇"
  self.grip.Visible=s.menuResize
  self.grip.Position=if side=="Right" then UDim2.new(0,4,1,-30) elseif side=="Bottom" then UDim2.fromOffset(4,4) else UDim2.new(1,-30,1,-30)
  self.grip.Text=if side=="Right" then "◣" elseif side=="Bottom" then "◤" else "◢"
  self.brand.Position=UDim2.fromOffset(if side=="Bottom" and s.menuResize then 34 else 16,2)
  self.brand.Size=UDim2.fromOffset(if side=="Bottom" and s.menuResize then 111 else 135,40)
  self.top.Size=UDim2.fromOffset(math.min(136,math.max(90,sz.X-24)),38)
  self.top.Position=UDim2.new(.5,0,0,if narrow then 48 else 12)
  for _,spec in {{self.top,"top"}} do
   local panel,key=spec[1],spec[2]
   if s[key.."Custom"] and not (s[key.."X"]==0 and s[key.."Y"]==0) then
    panel.AnchorPoint=Vector2.zero
    panel.Position=UDim2.fromOffset(math.max(0,sz.X-panel.Size.X.Offset)*s[key.."X"]/100,math.max(0,sz.Y-panel.Size.Y.Offset)*s[key.."Y"]/100)
   else
    panel.AnchorPoint=if key=="top" then Vector2.new(.5,0) else Vector2.new(0,.5)
   end
  end
  self.place.Position=UDim2.fromOffset(12,48);self.place.Size=UDim2.new(1,-24,0,17)
  self.nav.Position=UDim2.fromOffset(10,69);self.nav.Size=UDim2.new(1,-20,0,37)
  self.navList.FillDirection=Enum.FillDirection.Horizontal
  self.nav.AutomaticCanvasSize=Enum.AutomaticSize.X;self.nav.ScrollingDirection=Enum.ScrollingDirection.X
  for _,b in self.buttons do b.Size=UDim2.fromOffset(106,32) end
  self.search.Position=UDim2.fromOffset(10,111);self.search.Size=UDim2.new(1,-20,0,30)
  self.pageBox.Position=UDim2.fromOffset(10,148);self.pageBox.Size=UDim2.new(1,-20,1,-179)
  self.searchResults.Position=self.pageBox.Position;self.searchResults.Size=self.pageBox.Size
  self.quick.Size=UDim2.fromOffset(math.min(324,math.max(140,sz.X-24)),math.min(math.clamp(sz.Y*.58,120,440),math.max(120,sz.Y-24)))
  self.layoutKey=table.concat({s.menuDock,s.menuWidth,s.menuHeight,s.menuFloatX,s.menuFloatY,tostring(s.menuResize),tostring(s.topCustom),s.topX,s.topY},":")
 end
 function self:finishMenuDrag(point,resize)
  local s=self.app.s;local d=self.menuDraft
  if not d then return end
  local sz=self.stage.AbsoluteSize;local size=self.panelExtent;local xy=self.xy
  self.menuDraft=nil
  local patch={}
  if resize then
   patch.menuWidth=math.clamp(math.round(size.X),280,1600)
   patch.menuHeight=math.clamp(math.round(size.Y),260,1200)
  else
   local side="Floating"
   local distances={Left=point.X-self.stage.AbsolutePosition.X,Right=sz.X-(point.X-self.stage.AbsolutePosition.X),Top=point.Y-self.stage.AbsolutePosition.Y,Bottom=sz.Y-(point.Y-self.stage.AbsolutePosition.Y)}
   local best=65
   for _,edge in {"Left","Right","Top","Bottom"} do
    if distances[edge]<best then best=distances[edge];side=edge end
   end
   if side=="Floating" then
    local left=12
    local margins={Left=math.abs(xy.X-left),Right=math.abs(sz.X-size.X-14-xy.X),Top=math.abs(xy.Y-(if sz.X<740 then 92 else 62)),Bottom=math.abs(sz.Y-size.Y-(if sz.X<740 then 126 else 76)-xy.Y)}
    best=26
    for _,edge in {"Left","Right","Top","Bottom"} do
     if margins[edge]<best then best=margins[edge];side=edge end
    end
   end
   patch.menuDock=side
   patch.menuFloatX=math.clamp(math.round(100*xy.X/math.max(1,sz.X-size.X)),0,100)
   patch.menuFloatY=math.clamp(math.round(100*xy.Y/math.max(1,sz.Y-size.Y)),0,100)
  end
  self.app:patch(patch);self:layout()
 end
 local function moveStart(input)
  if not self.app.s.menuDrag or self.drag or not self.opened then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  if input.Position.X>self.header.AbsolutePosition.X+self.header.AbsoluteSize.X-84 then return end
  if not self.xy or not self.panelExtent then return end
  local origin=self.xy;local size=self.panelExtent
  self:begin(input,function(point,start)
   self.menuDraft={side="Floating",w=size.X,h=size.Y,xy=origin+point-start}
   self:layout()
  end,origin)
  if self.drag then self.drag.finish=function(point) self:finishMenuDrag(point,false) end end
 end
 scope:on(self.header.InputBegan,moveStart)
 self.brand.Active=true;self.tag.Active=true
 scope:on(self.brand.InputBegan,moveStart);scope:on(self.tag.InputBegan,moveStart)
 scope:on(self.grip.InputBegan,function(input)
  if not self.app.s.menuResize or self.drag or not self.opened then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  if not self.xy or not self.panelExtent then return end
  local side=self.app.s.menuDock;local size=self.panelExtent;local origin=self.xy
  self:begin(input,function(point,start)
   local delta=point-start
   local w=math.max(280,size.X+delta.X*(if side=="Right" or side=="Bottom" then -1 else 1))
   local h=math.max(260,size.Y+delta.Y*(if side=="Bottom" then -1 else 1))
   self.menuDraft={side=side,w=w,h=h,xy=if side=="Floating" then origin else nil}
   self:layout()
  end,origin)
  if self.drag then self.drag.finish=function(point) self:finishMenuDrag(point,true) end end
 end)
 scope:on(self.stage:GetPropertyChangedSignal("AbsoluteSize"),function() self:layout() end);self:layout()
 scope:on(Input.InputChanged,function(i) local d=self.drag;if d and (i==d.i or d.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement) then d.fn(Vector2.new(i.Position.X,i.Position.Y),d.start,d.origin) end end)
 scope:on(Input.InputEnded,function(i) if self.drag and (self.drag.i==i or self.drag.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseButton1) then local d=self.drag;self.drag=nil;if d.finish then d.finish(Vector2.new(i.Position.X,i.Position.Y)) end end end)
 scope:on(Input.WindowFocusReleased,function() self.drag=nil;if self.menuDraft then self.menuDraft=nil;self:layout() end end);scope:add(function() if self.page then self.page:clear() end;Icons.clear() end);return self
end
function UI:animateBackground(t)
 if self.layoutPending or self.layoutViewport~=self.stage.AbsoluteSize then self:layout() end
 local s=self.app.s
 local dt=math.clamp(t-(self.motionAt or t-1/60),0,.1)
 self.motionAt=t
 local immediate=s.reduce or s.menuTransition=="Off"
 local duration=math.max(.06,s.duration/1000*100/s.speed)
 local target=if self.opened then 1 else 0
 local step=dt/duration
 if immediate then self.menuProgress=target
 else self.menuProgress=math.clamp(self.menuProgress+step*(if self.opened then 1 else -1),0,1) end
 self.panel.Visible=self.opened or self.menuProgress>0
 local q=U.ease(self.menuProgress,s.ease)
 transition(self.panel,if self.panel.Visible then q else 1)
 local strength=s.menuAnimStrength/100
 if self.xy then
  local dx,dy=0,0
  local side=self.layoutSide or s.menuDock
  local distance=(1-q)*(.65+.35*strength)
  if not immediate and s.menuTransition~="Fade" and not self.menuDraft then
   local extent=self.panelExtent or self.panel.AbsoluteSize;local sz=self.stage.AbsoluteSize
   if side=="Left" then dx=-(self.xy.X+extent.X+8)*distance
   elseif side=="Right" then dx=(sz.X-self.xy.X+8)*distance
   elseif side=="Top" then dy=-(self.xy.Y+extent.Y+8)*distance
   elseif side=="Bottom" then dy=(sz.Y-self.xy.Y+8)*distance
   else dy=18*strength*(1-q) end
  end
  self.panel.Position=UDim2.fromOffset(math.round(self.xy.X+dx),math.round(self.xy.Y+dy))
 end
 local accent=U.hex(s.accent)
 local secondary=U.hex(s.secondary)
 local editingAux=self.app.editingHUD and self.app.hudEditMode=="Volleyball"
 self.top.Visible=s.topCapsule or editingAux
 self.quickArrow.Visible=self.app.volleyball~=nil and not self.app.editingHUD
 self.quick.Visible=editingAux or (self.quickOpen and s.topCapsule and not self.app.editingHUD)
 self.bindPanel.Visible=editingAux or (not self.opened and not self.app.editingHUD and self.app.mode=="Game" and s.keybindWidget)
 self.bindRim.Color=accent
 if self.bindPanel.Visible and t>=(self.bindRefreshAt or 0) then self.bindRefreshAt=t+.3;self:refreshBindPanel() end
 if self.quick.Visible and self.quickAdapter and t>=(self.quickRefreshAt or 0) then
  self.quickRefreshAt=t+.25
  for _,refresh in self.quickAdapter.syncs do pcall(refresh) end
 end
 local live=self.app.liveUpdate
 if live then
  local unread=live.unread==true
  local version=live.version..(if (live.testCount or 0)>0 and live.isTest then " · TEST "..tostring(live.testCount) else "")
  local text=if unread then "v"..version.."  |  VERSION UPDATED  |  CHECK UPDATE LIST" else "v"..version
  if self.updateChip.Text~=text then self.updateChip.Text=text end
  local width=if unread then math.min(370,math.max(150,self.stage.AbsoluteSize.X-24)) else math.min(180,math.max(90,#text*7+20))
  self.updateChip.Size=UDim2.fromOffset(width,if unread then 28 else 22)
  self.updateChip.BackgroundColor3=if unread then accent:Lerp(Color3.fromRGB(22,17,35),.65) else Color3.fromRGB(24,20,40)
  self.updateRim.Color=accent
  self.updateRim.Transparency=if unread then .15 else .55
 end
 self.topRim.Color=accent;self.quickRim.Color=accent
 local below=6+self.updateChip.Size.Y.Offset+4
 self.quickArrow.Position=UDim2.new(.5,0,1,below)
 self:layoutAuxWidgets(below)
 self.topButtons[1].TextColor3=U.hex(s.uiFontColor or "F1E6FF")
 local visible=s.screenParticles and q>.001
 self.screenFX.Visible=visible
 if visible then
  local motion=if s.reduce then 0 else t*s.menuMotion/100
  local alpha=q*s.screenParticleOpacity/100
  self.screenDim.BackgroundTransparency=1-alpha*.12
  local style=s.screenParticleStyle
  for index,particle in self.stars do
   local active=index<=s.screenParticleCount
   particle.root.Visible=active
   if not active then continue end
   local kind=if style=="Mixed" then ({"Stars","Dust","Diamonds"})[index%3+1] else style
   local phase=motion*.64+index*1.73
   local twinkle=if s.reduce then .7 else .54+.46*math.sin(phase)
   local size=(if kind=="Dust" then 3+index%4 else 7+index%10)*( .82+.18*twinkle)
   particle.root.Size=UDim2.fromOffset(math.max(2,math.round(size)),math.max(2,math.round(size)))
   particle.root.Position=UDim2.fromScale(.03+((index*.618)%1)*.94+math.sin(phase*.43)*.014,(index*.381+1-motion*.012)%1)
   particle.root.Rotation=if kind=="Diamonds" then 45+motion*4 elseif kind=="Stars" then motion*5+index*19 else 0
   local color=accent:Lerp(secondary,(index%7)/6)
   particle.dot.BackgroundColor3=color
   particle.dot.BackgroundTransparency=1-alpha*twinkle*.65
   particle.dot.Size=if kind=="Diamonds" then UDim2.fromScale(.65,.65) else UDim2.fromScale(.45,.45)
   for j,bar in particle.bars do
    bar.Visible=kind=="Stars"
    if bar.Visible then
     bar.Size=UDim2.fromOffset(math.max(1,math.round(size*(if j%2==1 then 1 else .63))),math.max(1,math.round(size*.13)))
     bar.BackgroundColor3=color;bar.BackgroundTransparency=1-alpha*twinkle*.77
    end
   end
  end
 end
 if not self.panel.Visible then return end
 local tm=if s.reduce then 0 else t*s.speed/100
 self.outline.Color=accent:Lerp(U.hex(s.secondary),if s.reduce or not s.navGlow then 0 else .18+.15*math.sin(tm*1.6))
 self.outline.Transparency=1-math.clamp(s.rim/100*(if s.reduce or not s.navGlow then 1 else .85+.15*math.sin(tm*1.8)),0,1)
 self.outline.Transparency=1-(1-self.outline.Transparency)*q
 self.outline.Thickness=if s.reduce or not s.navGlow then 1 else 1.2+.3*math.sin(tm*1.6)
 self.pageProgress=if immediate or not s.tabTransition then 1 else math.min(1,self.pageProgress+dt/math.max(.06,duration*.72))
 local pageQ=U.ease(self.pageProgress,s.ease)
 transition(self.pageBox,pageQ)
 if self.sc and self.sc.Parent then self.sc.Position=UDim2.fromOffset((1-pageQ)*12*strength,0) end
 for name,b in self.buttons do
  local desired=if name==self.tab then 1 elseif self.navHover[name] then .45 else 0
  local amount=self.navAmount[name] or 0
  local k=if s.reduce or not s.navGlow then 1 else 1-math.exp(-dt*15)
  amount+=(desired-amount)*k
  self.navAmount[name]=amount
  b.BackgroundColor3=soft:Lerp(accent:Lerp(bg,.42),amount)
 end
 self.geoLayer.Visible=s.menuGeometry and self.panel.Visible
 if self.geoLayer.Visible then self.constellation:step(dt,s) end
end
function UI:begin(i,fn,origin) if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end;local v=Vector2.new(i.Position.X,i.Position.Y);self.drag={i=i,start=v,fn=fn,origin=origin};fn(v,v,origin) end
function UI:show(on)
 if on then self:setQuick(false) end
 if not on and self.opened then
  self.lastClosedTab=self.tab
  self.lastClosedPage=self.sc
  self.lastClosedScroll=self.sc and self.sc.CanvasPosition or nil
  self.tabInputAfter=os.clock()+.45;self.shortcutBlockUntil=os.clock()+.65
 elseif on and not self.opened then
  self.tabInputAfter=math.max(self.tabInputAfter or 0,os.clock()+.18);self.shortcutBlockUntil=os.clock()+.65
  if self.lastClosedTab==self.tab and self.lastClosedPage==self.sc and self.sc and self.sc.Parent and self.lastClosedScroll then
   self.sc.CanvasPosition=self.lastClosedScroll
  end
 end
 self.opened=on
 self.panel.Interactable=on
 if on then self.panel.Visible=true end
 self.drag=nil
 if self.menuDraft then self.menuDraft=nil;self:layout() end
 if self.app.s.reduce or self.app.s.menuTransition=="Off" then
  self.menuProgress=if on then 1 else 0
  transition(self.panel,1)
  self.panel.Visible=on
 end
 if self.app.onMenu then self.app:onMenu(on) end
end
function UI:message(s) self.status.Text=s end
-- Ignore click-through shortcuts during the close transition, but keep intentional shortcuts.
function UI:openShortcut(tab,explicit)
 if not explicit and (self.opened or self.quickOpen or os.clock()<(self.shortcutBlockUntil or 0)) then return end
 if os.clock()<(self.tabInputAfter or 0) then return end
 self:open(tab)
end
-- Reuse the canonical Volleyball renderer. The small adapter only changes layout.
local quickSwitches={
 ["BALL HITBOX EXPANDER / BETA"]={function(v) return v.ballRadius.enabled end,function(v) v:toggleBallRadius() end,"Toggle Ball Expander"},
 ["BALL TOUCH INFO"]={function(v) return v.ballTouchInfo.enabled end,function(v) v:toggleBallTouchInfo() end,"Show last hitter"},
 ["SHOT ARC / BETA"]={function(v) return v.shotArc.enabled end,function(v) v:toggleShotArc() end,"Shot Arc"},
 ["TRAJECTORY ESP / BETA"]={function(v) return v.trajectory.enabled end,function(v) v:toggleTrajectory() end,"Toggle Trajectory ESP"},
 ["DIRECTION ESP / BETA"]={function(v) return v.jinkoDirection.enabled end,function(v) v:toggleJinkoDirection() end,"Toggle Direction ESP"},
 ["JINKO STYLE / LOCAL PREVIEW"]={function(v) return v.styleEnabled end,function(v) v:toggleStyle() end,"Toggle Jinko preview"},
 ["CURVE SPECIAL / EXPERIMENT"]={function(v) return v.curveEnabled end,function(v) v:toggleCurve() end,"Toggle local Curve test"},
 ["CONSECUTIVE TOUCH / BETA"]={function(v) return v.repeatTouch.enabled end,function(v) v:toggleRepeatTouch() end,"Repeat touch test"},
 ["AUTO TILT / BETA"]={function(v) return v.auto end,function(v) v:toggleAuto() end},
}
function UI:bindMap()
 return self.app.bank.keybinds or {}
end
function UI:registerBind(id,label,invoke,read)
 self.bindActions[id]={label=label,invoke=invoke,read=read}
end
function UI:startBind(id)
 self.captureBind=if self.captureBind==id then nil else id
 self.quickStatus.Text=if self.captureBind then "Press key · Esc cancel · Backspace clear" else "Binding cancelled"
 if self.quickAdapter then self.quickAdapter:sync() end
end
function UI:assignBind(id,key)
 local nextMap=table.clone(self:bindMap())
 if key then
  if key==S.menuKey(self.app.s) or key==self.app.s.lockKey then self.quickStatus.Text="Reserved menu / lock key";return false end
  for other,bound in nextMap do
   if other~=id and bound==key then self.quickStatus.Text="Key already assigned: "..key;return false end
  end
 end
 nextMap[id]=key
 self.app.bank.keybinds=nextMap
 self.captureBind=nil
 self.app:dirty()
 if self.app.store then self.app.store:save() end
 self.quickStatus.Text=if key then "Assigned "..key else "Keybind cleared"
 self:refreshBindPanel()
 if self.quickAdapter then self.quickAdapter:sync() end
 return true
end
function UI:handleQuickKey(input,processed)
 if input.UserInputType~=Enum.UserInputType.Keyboard then return false end
 local key=input.KeyCode.Name
 if self.captureBind then
  if key=="Escape" then self.captureBind=nil;self.quickStatus.Text="Binding cancelled"
  elseif key=="Backspace" or key=="Delete" then self:assignBind(self.captureBind,nil)
  elseif key~="Unknown" and not Input:GetFocusedTextBox() then self:assignBind(self.captureBind,key) end
  if self.quickAdapter then self.quickAdapter:sync() end
  return true
 end
 if processed or Input:GetFocusedTextBox() or self.opened or self.app.editingHUD or self.app.bindingLockKey or self.app.mode~="Game" or game:GetService("GuiService").MenuIsOpen then return false end
 if key==S.menuKey(self.app.s) or key==self.app.s.lockKey then return false end
 local id
 for action,bound in self:bindMap() do if bound==key then id=action;break end end
 if not id then return false end
 if not self.quickAdapter then
  local ok,err=pcall(self.buildQuick,self)
  if not ok then
   if self.quickPage then self.quickPage:clear();self.quickPage=nil end
   self.quickAdapter=nil;table.clear(self.bindActions);self.app:log("Keybind",err)
   return true
  end
  self.quickAdapter.opened=self.quickOpen
 end
 local action=self.bindActions[id]
 if not action then return true end
 local now=os.clock()
 if self.lastBindKey==key and now-(self.lastBindAt or 0)<.18 then return true end
 self.lastBindKey=key;self.lastBindAt=now
 local before,generation=self.app:moduleSnapshot(),self.app.moduleGeneration
 local ok,err=pcall(action.invoke)
 self.app:recordModuleChanges(before,generation)
 if not ok then self.app:log("Keybind",err);self.quickStatus.Text=tostring(err):sub(-100) end
 self:refreshBindPanel()
 return true
end
function UI:layoutAuxWidgets(below)
 local s=self.app.s
 local vp=self.stage.AbsoluteSize
 if vp.X<2 or vp.Y<2 then return end
 local top=self.top.AbsolutePosition-self.stage.AbsolutePosition
 local function position(key,p,defaultX,defaultY,origin)
  local w,h=p.Size.X.Offset,p.Size.Y.Offset
  local maxX,maxY=math.max(0,vp.X-w),math.max(0,vp.Y-h)
  local x,y=defaultX,defaultY
  if s[key.."Custom"] then x=maxX*s[key.."X"]/100;y=maxY*s[key.."Y"]/100 end
  p.AnchorPoint=Vector2.zero
  p.Position=UDim2.fromOffset(math.round(math.clamp(x,0,maxX)-origin.X),math.round(math.clamp(y,0,maxY)-origin.Y))
 end
 position("keybind",self.bindPanel,30,110,Vector2.zero)
 local width=self.quick.Size.X.Offset
 position("quick",self.quick,top.X+self.top.AbsoluteSize.X*.5-width*.5,top.Y+self.top.AbsoluteSize.Y+below+26,top)
end
function UI:refreshBindPanel()
 local entries={}
 for id,key in self:bindMap() do
  local action=self.bindActions[id]
  local label=if action then action.label else (id:match(".*|(.+)$") or id)
  local state=""
  if action and action.read then
   local ok,value=pcall(action.read)
   if ok then state=if value==true then " · ON" elseif value==false then " · OFF" else "" end
  end
  table.insert(entries,{key=key,label=label,state=state})
 end
 table.sort(entries,function(a,b) return if a.key==b.key then a.label<b.label else a.key<b.key end)
 local shown=math.min(9,math.max(1,#entries))
 self.bindPanel.Size=UDim2.fromOffset(math.min(230,math.max(140,self.stage.AbsoluteSize.X*.3)),math.min(35+shown*27,math.max(62,self.stage.AbsoluteSize.Y-24)))
 self.bindEmpty.Visible=#entries==0
 for i,item in entries do
  local row=self.bindRows[i]
  if not row then
   local f=U.frame(self.bindList,"Bind_"..i,nil,UDim2.new(1,-3,0,24),soft,.45);f.ZIndex=22;f.LayoutOrder=i;U.corner(f,5)
   local k=U.label(f,"",10,UDim2.fromOffset(5,0),UDim2.fromOffset(64,24));k.TextColor3=Color3.fromRGB(200,170,255);k.ZIndex=23
   local l=U.label(f,"",11,UDim2.fromOffset(71,0),UDim2.new(1,-75,1,0));l.ZIndex=23
   row={f=f,k=k,l=l};self.bindRows[i]=row
  end
  row.f.Visible=true;row.k.Text="["..item.key.."]";row.l.Text=item.label..item.state
 end
 for i=#entries+1,#self.bindRows do self.bindRows[i].f.Visible=false end
end
function UI:buildQuick()
 table.clear(self.bindActions)
 if self.quickPage then self.quickPage:clear() end
 local page=U.scope();self.quickPage=page
 local owner=self
 local q=setmetatable({app=self.app,page=page,opened=true,seq=0,syncs={},controlKeys={},colorKeys={},tab="Volleyball"},UI)
 self.quickAdapter=q
 local sectionCount=0
 local current
 local function depth(root,z)
  if root:IsA("GuiObject") then root.ZIndex=z end
  for _,obj in root:GetDescendants() do if obj:IsA("GuiObject") then obj.ZIndex=z+1 end end
 end
 function q:message(msg) owner.quickStatus.Text=tostring(msg) end
 function q:sync()
  for _,fn in self.syncs do
   local ok,err=pcall(fn)
   if not ok then owner.quickStatus.Text=tostring(err):sub(-120) end
  end
  owner:sync()
 end
 function q:row(h,name)
  assert(current,"Quick section missing")
  self.seq+=1
  local f=U.frame(current.body,name or "Row",nil,UDim2.new(1,-4,0,h),soft,.47)
  f.LayoutOrder=self.seq;f.ZIndex=32;U.corner(f,8)
  current.height+=h+(if current.rows>0 then 5 else 0);current.rows+=1
  current.body.Size=UDim2.new(1,-12,0,current.height)
  current.layout()
  page:on(f.DescendantAdded,function(obj) if obj:IsA("GuiObject") then obj.ZIndex=33 end end)
  return f
 end
 function q:addBind(id,label,invoke,read)
  owner:registerBind(id,label,invoke,read)
  local row=self:row(28,"BindRow")
  local text=U.label(row,"Bind · "..label,10,UDim2.fromOffset(6,0),UDim2.new(1,-90,1,0));text.ZIndex=33
  local b=U.button(row,"Bind");b.Size=UDim2.fromOffset(78,24);b.Position=UDim2.new(1,-82,0,2);b.ZIndex=34;b.TextSize=11
  self:watch(function()
   b.Text=if owner.captureBind==id then "PRESS KEY" else (owner:bindMap()[id] or "Bind")
   b.BackgroundColor3=if owner.captureBind==id then Color3.fromRGB(112,76,170) else bg
  end)
  page:on(b.Activated,function() owner:startBind(id) end)
 end
 function q:title(str)
  if self.fieldTitle then return UI.title(self,str) end
  sectionCount+=1
  local card=page:add(U.frame(owner.quickScroll,"Module_"..sectionCount,nil,UDim2.new(1,-5,0,34),soft,.35))
  card.LayoutOrder=sectionCount;card.ZIndex=30;U.corner(card,8)
  local header=U.button(card,"");header.Name="ExpandModule";header.Size=UDim2.new(1,0,0,34);header.ZIndex=31
  local spec=quickSwitches[str]
  local title=U.label(header,str:gsub(" / BETA",""):gsub(" / EXPERIMENT",""):gsub(" / LOCAL PREVIEW",""),11,UDim2.fromOffset(9,0),UDim2.new(1,if spec then -91 else -32,1,0))
  title.ZIndex=32;title.Active=false;title.Interactable=false
  local expander=U.frame(header,"ArrowHolder",UDim2.new(1,-28,.5,-10),UDim2.fromOffset(24,20),nil,1);expander.ZIndex=32;expander.Active=false;expander.Interactable=false
  local glyph=chevron(expander)
  local body=U.frame(card,"Settings",UDim2.fromOffset(6,39),UDim2.new(1,-12,0,0),nil,1);body.ZIndex=31
  U.new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},body)
  local section={body=body,height=0,rows=0,name=str,spec=spec,expanded=owner.quickExpanded[str]==true}
  function section.layout()
   body.Visible=section.expanded
   card.Size=UDim2.new(1,-5,0,if section.expanded then 44+section.height else 34)
   glyph.Rotation=if section.expanded then 180 else 0
  end
  page:on(header.Activated,function()
   section.expanded=not section.expanded;owner.quickExpanded[str]=section.expanded;section.layout()
  end)
  if spec then
   local switch=U.button(card,"OFF")
   switch.Size=UDim2.fromOffset(48,26);switch.Position=UDim2.new(1,-82,0,4);switch.ZIndex=34;switch.TextSize=11
   local function refresh()
    local vb=owner.app.volleyball;local enabled=vb and spec[1](vb)==true
    switch.Text=if enabled then "ON" else "OFF"
    switch.BackgroundColor3=if enabled then Color3.fromRGB(98,68,150) else bg
   end
   self:watch(refresh)
   page:on(switch.Activated,function() self:action(function() spec[2](owner.app.volleyball);self:sync() end) end)
  end
  current=section;self.sc=body;section.layout()
  if spec then
   local label=title.Text
   self:addBind(str.."|"..label,label,function() spec[2](owner.app.volleyball);self:sync() end,function() return spec[1](owner.app.volleyball)==true end)
  end
  return title
 end
 function q:box(label,initial,h,commit)
  self.fieldTitle=true
  local result=UI.box(self,label,initial,h,commit)
  self.fieldTitle=false
  return result
 end
 function q:begin(input,fn,origin)
  return owner:begin(input,fn,origin)
 end
 function q:control(k)
  if self.controlKeys[k] then return end
  UI.control(self,k)
  local d=S.defs[k]
  if d and d.kind=="bool" and current then
   local label=d.label or k
   self:addBind(current.name.."|"..label,label,function() self.app:set(k,not self.app.s[k]);self:sync() end,function() return self.app.s[k]==true end)
  end
 end
 function q:chips(items,fn,cols,selected)
  if current and current.spec and #items==1 and items[1]==current.spec[3] then return end
  UI.chips(self,items,fn,cols,selected)
  for _,item in items do
   local label=tostring(item)
   local id=current.name.."|"..label
   local read=if selected then function() return selected()==item end else nil
   self:addBind(id,label,function() fn(item);self:sync() end,read)
  end
 end
 -- Full Volleyball content, including all nested fields and status callbacks.
 self.app:page("Volleyball",q)
 q:sync()
end
function UI:setQuick(on)
 self.quickOpen=on==true
 if not self.quickOpen then self.captureBind=nil end
 self.quick.Visible=self.quickOpen and self.app.s.topCapsule
 self.quickGlyph.Rotation=if self.quickOpen then 180 else 0
 if self.quickOpen then
  if not self.quickAdapter then
   local ok,err=pcall(self.buildQuick,self)
   if not ok then
    if self.quickPage then self.quickPage:clear();self.quickPage=nil end
    self.quickAdapter=nil;table.clear(self.bindActions);self.quickStatus.Text="Menu error: "..tostring(err):sub(-100)
    self.app:log("Quick menu",err)
   end
  else self.quickAdapter.opened=true;self.quickAdapter:sync() end
 elseif self.quickAdapter then self.quickAdapter.opened=false end
end
local function searchMatch(text,words)
 for _,word in words do if not text:find(word,1,true) then return false end end
 return true
end
function UI:refreshSearch()
 if not self.search or not self.searchResults then return end
 local q=self.search.Text:lower():match("^%s*(.-)%s*$")
 local words=string.split(q," ")
 local has=q~=""
 self.searchResults.Visible=has
 self.pageBox.Visible=not has
 if not has then return end
 local matches,seen={},{}
 for _,item in self.searchIndex do
  if self.buttons[item.tab] and searchMatch(item.term,words) then
   local id=item.tab.."|"..item.label:lower()
   if not seen[id] then
    seen[id]=true
    local label=item.label:lower()
    local rank=if label==q then 0 elseif label:find(q,1,true)==1 then 1 elseif label:find(q,1,true) then 2 else 3
    table.insert(matches,{item=item,rank=rank})
   end
  end
 end
 table.sort(matches,function(a,b) if a.rank~=b.rank then return a.rank<b.rank end;return a.item.label<b.item.label end)
 for i=1,math.min(60,#matches) do
  local b=self.searchPool[i]
  if not b then
   b=U.button(self.searchResults,"");b.Size=UDim2.new(1,-8,0,34);b.TextXAlignment=Enum.TextXAlignment.Left
   U.new("UIPadding",{PaddingLeft=UDim.new(0,10)},b)
   self.searchPool[i]=b
   self.scope:on(b.Activated,function() local item=self.searchTargets and self.searchTargets[i];if item then self:jumpTo(item) end end)
  end
  b.Visible=true;b.LayoutOrder=i;b.Text=matches[i].item.label.."  ·  "..matches[i].item.tab
 end
 self.searchTargets={}
 for i=1,math.min(60,#matches) do self.searchTargets[i]=matches[i].item end
 if not self.searchEmpty then
  self.searchEmpty=U.label(self.searchResults,"No functions found",12,nil,UDim2.new(1,-8,0,34));self.searchEmpty.LayoutOrder=999
 end
 self.searchEmpty.Visible=#matches==0
 for i=math.min(60,#matches)+1,#self.searchPool do self.searchPool[i].Visible=false end
 self.searchResults.CanvasPosition=Vector2.zero
end
function UI:jumpTo(item)
 self:setQuick(false)
 self.search:ReleaseFocus();self.search.Text=""
 self:open(item.tab)
 local sc=self.sc
 if not sc then return end
 local label=item.label:lower()
 local function findRow()
  for _,row in sc:GetChildren() do
   if not row:IsA("GuiObject") then continue end
   if item.key and row.Name==item.key then return row end
   for _,obj in row:GetDescendants() do
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
     if obj.Text:lower()==label or obj.Name:lower()==label then return row end
    end
   end
  end
  return nil
 end
 task.defer(function()
  game:GetService("RunService").Heartbeat:Wait()
  if self.sc~=sc or not sc.Parent then return end
  local row=findRow()
  if row then
   local y=row.AbsolutePosition.Y-sc.AbsolutePosition.Y+sc.CanvasPosition.Y
   sc.CanvasPosition=Vector2.new(0,math.clamp(y-6,0,math.max(0,sc.AbsoluteCanvasSize.Y-sc.AbsoluteWindowSize.Y)))
  end
 end)
end
function UI:open(tab)
 if tab=="Camera" then tab="Interaction" end
 if self.search then self.search.Text="" end
 self.app.bindingLockKey=false
 if not self.buttons[tab] then return end;self:show(true);self.drag=nil;if self.page then self.page:clear() end;self.app.preview=nil;self.page=U.scope();self.syncs={};self.controlKeys={};self.colorKeys={};self.seq=0;self.tab=tab
 self.pageProgress=if self.app.s.reduce or not self.app.s.tabTransition or self.app.s.menuTransition=="Off" then 1 else 0
 transition(self.pageBox,U.ease(self.pageProgress,self.app.s.ease))
 local sc=self.page:add(U.new("ScrollingFrame",{Name="Page_"..tab,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=dim,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},self.pageBox));U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sc);self.sc=sc
 self:title(tab:upper().."   /   AETHER STUDIO");self.app:page(tab,self);self:sync()
end
function UI:row(h,name) self.seq+=1;local f=U.frame(self.sc,name or "Row",nil,UDim2.new(1,-8,0,h),soft,.47);f.LayoutOrder=self.seq;U.corner(f,8);return f end
function UI:title(str) local f=self:row(26,"Heading");f.BackgroundTransparency=1;local n=U.label(f,str,13);n.TextColor3=U.hex(self.app.s.accent);self.titleLabel=n;return n end
function UI:note(str,h) local f=self:row(h or 36,"Note");f.BackgroundTransparency=1;local l=U.label(f,str,12);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextColor3=dim;l:SetAttribute("AETHERMuted",true);return l end
function UI:watch(fn) table.insert(self.syncs,fn);fn() end
function UI:sync()
 if not self.panel.Parent then return end
 local st=self.app.s
 self.backgroundGradient.Color=ColorSequence.new(U.hex(st.constellationBgA),U.hex(st.constellationBgB))
 self.backgroundGradient.Rotation=st.constellationAngle
 local layoutKey=table.concat({st.menuDock,st.menuWidth,st.menuHeight,st.menuFloatX,st.menuFloatY,tostring(st.menuResize),tostring(st.topCustom),st.topX,st.topY},":")
 if self.layoutKey~=layoutKey and not self.menuDraft then self:layout() end
 local primary=U.hex(st.uiFontColor or "F1E6FF")
 local muted=U.hex(st.uiMutedColor or "ADA3C5")
 self.brand.TextColor3=U.hex(st.accent)
 self.outline.Color=self.brand.TextColor3
 self.tag.Text=self.app.mode.." / "..(self.app.liveUpdate and self.app.liveUpdate.version or "LIVE 1.0")
 self.tag.TextColor3=muted
 self.status.TextColor3=muted
 for _,asset in self.icons do asset:sync(st.iconAtlas,st.iconAtlasTile) end
 for _,f in self.syncs do f() end
 -- Only recolor editor controls, not HUD/3D previews or their own palette.
 for _,obj in self.panel:GetDescendants() do
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
   if obj==self.brand or obj==self.tag or obj==self.status then continue end
   if obj:GetAttribute("AETHERKeepFontColor") then continue end
   local holder=obj.Parent
   local skip=false
   while holder and holder~=self.panel do
    if holder.Name=="LivePreview" or holder.Name=="RigPreview"
      or holder.Name=="CursorPreview" or holder.Name=="ShapeGallery" then
     skip=true;break
    end
    if S.defs[holder.Name] and S.defs[holder.Name].kind=="color" and obj:IsA("TextLabel") then
     skip=true;break
    end
    holder=holder.Parent
   end
   if skip then continue end
   if obj:IsA("TextLabel") and obj.Parent and obj.Parent.Name=="Heading" then
    obj.TextColor3=U.hex(st.accent)
   elseif obj:GetAttribute("AETHERMuted") then
    obj.TextColor3=muted
   else
    obj.TextColor3=primary
   end
  end
 end
end
function UI:action(fn)
 local before,generation=self.app:moduleSnapshot(),self.app.moduleGeneration
 local ok,err=pcall(fn)
 self.app:recordModuleChanges(before,generation)
 if not ok then self.app:log("Error",tostring(err));self:message(tostring(err):sub(-150)) end
end
function UI:chips(items,fn,cols,selected)
 cols=cols or 3;for start=1,#items,cols do local row=self:row(33,"Actions");row.BackgroundTransparency=1;for j=0,math.min(cols-1,#items-start) do local item=items[start+j];local b=U.button(row,item);b.Name=item;b.Size=UDim2.new(1/cols,-4,1,0);b.Position=UDim2.fromScale(j/cols,0);self.page:on(b.Activated,function() self:action(function() fn(item) end) end);if selected then self:watch(function() b.BackgroundColor3=if selected()==item then Color3.fromRGB(98,68,150) else soft end) end end end
end
function UI:box(label,initial,h,commit)
 self:title(label);local r=self:row(h or 34,"Field");local t=U.new("TextBox",{Name=label,Size=UDim2.new(1,-12,1,-4),Position=UDim2.fromOffset(6,2),ClearTextOnFocus=false,MultiLine=(h or 0)>45,TextWrapped=(h or 0)>45,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=if (h or 0)>45 then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,BackgroundTransparency=1,Text=initial or "",PlaceholderText=label,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(232,222,255)},r);if commit then self.page:on(t.FocusLost,function() self:action(function() commit(t.Text) end) end) end;return t
end
function UI:control(k)
 self.controlKeys=self.controlKeys or {}
 if self.controlKeys[k] then return end
 self.controlKeys[k]=true
 local d=S.defs[k];local app=self.app;local a=d.kind;if a=="players" then return end
 if a=="text" or a=="asset" then local box=self:box(d.label,tostring(app.s[k]),32,function(v) app:set(k,v) end);self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end end);return end
 local row=self:row(if a=="number" or a=="angle" then 48 else 34,k);local label=U.label(row,d.label,12,UDim2.fromOffset(9,0),UDim2.new(.57,0,0,30));label.TextColor3=Color3.fromRGB(219,210,234)
 if a=="bool" or a=="choice" then local b=U.button(row,"");b.Name="Value";b.Position=UDim2.new(.58,0,0,3);b.Size=UDim2.new(.42,-6,1,-6);self.page:on(b.Activated,function() if a=="bool" then app:set(k,not app.s[k]) else app:set(k,d.min[(table.find(d.min,app.s[k]) or 0)%#d.min+1]) end end);self:watch(function() b.Text=if a=="bool" then (if app.s[k] then "ON" else "OFF") else tostring(app.s[k]).."  ›";b.BackgroundColor3=if a=="bool" and not app.s[k] then Color3.fromRGB(48,45,59) else Color3.fromRGB(84,61,118) end);return end
 local box=U.new("TextBox",{Name="Value",Position=UDim2.new(.6,0,0,3),Size=UDim2.new(.4,-7,0,23),BackgroundColor3=bg,ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=12,Text="",BorderSizePixel=0},row);U.corner(box,6)
 self.page:on(box.FocusLost,function() self:action(function() app:set(k,if a=="angle" then assert(tonumber(box.Text),"Enter a finite angle") elseif a=="number" then math.clamp(math.round(assert(tonumber(box.Text),"Enter a number")),d.min,d.max) else (box.Text:gsub("^#",""))) end);self:sync() end)
 if a=="color" then self:watch(function() if not box:IsFocused() then box.Text="#"..app.s[k] end;label.TextColor3=U.hex(app.s[k]) end);return end
 local hit=U.new("TextButton",{Name="Slider",Position=UDim2.fromOffset(10,26),Size=UDim2.new(1,-20,0,21),BackgroundTransparency=1,Text="",AutoButtonColor=false},row);local track=U.frame(hit,"Track",UDim2.fromScale(0,.37),UDim2.new(1,0,0,5),bg);U.corner(track,4);local fill=U.frame(track,"Fill",nil,nil,U.hex(app.s.accent));U.corner(fill,4);local dot=U.frame(fill,"Thumb",UDim2.fromScale(1,.5),UDim2.fromOffset(11,11),Color3.fromRGB(237,225,255));dot.AnchorPoint=Vector2.new(.5,.5);U.corner(dot,9)
 self.page:on(hit.InputBegan,function(i) self:begin(i,function(pos) local t=math.clamp((pos.X-hit.AbsolutePosition.X)/math.max(1,hit.AbsoluteSize.X),0,1);app:set(k,math.round(d.min+t*(d.max-d.min))) end) end)
 self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end;fill.Size=UDim2.fromScale(math.clamp((app.s[k]-d.min)/(d.max-d.min),0,1),1);fill.BackgroundColor3=U.hex(app.s.accent) end)
end
function UI:colorPicker(k)
 self.colorKeys=self.colorKeys or {}
 if self.colorKeys[k] then return end
 self.colorKeys[k]=true
 local app=self.app
 self:control(k)
 local row=self:row(188,"SquareColorPicker")
 local field=U.new("TextButton",{Name="SaturationValue",Position=UDim2.fromOffset(9,8),Size=UDim2.fromOffset(170,170),BackgroundColor3=Color3.new(1,0,0),Text="",AutoButtonColor=false,BorderSizePixel=0},row)
 U.corner(field,8)
 local white=U.frame(field,"Saturation",nil,nil,Color3.new(1,1,1),0);white.Active=false
 U.corner(white,8);U.new("UIGradient",{Transparency=NumberSequence.new(0,1)},white)
 local black=U.frame(field,"Value",nil,nil,Color3.new(),0);black.Active=false
 U.corner(black,8);U.new("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0)},black)
 local marker=U.frame(field,"Marker",nil,UDim2.fromOffset(12,12),Color3.new(1,1,1),1);marker.AnchorPoint=Vector2.new(.5,.5);U.corner(marker,10);U.stroke(marker,Color3.new(1,1,1),0)
 local hue=U.new("TextButton",{Name="Hue",Position=UDim2.fromOffset(190,8),Size=UDim2.fromOffset(22,170),BackgroundColor3=Color3.new(1,1,1),Text="",AutoButtonColor=false,BorderSizePixel=0},row)
 U.corner(hue,8)
 local keys={}
 for i=0,6 do keys[#keys+1]=ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1)) end
 U.new("UIGradient",{Rotation=90,Color=ColorSequence.new(keys)},hue)
 local hm=U.frame(hue,"HueMarker",nil,UDim2.new(1,6,0,3),Color3.new(1,1,1));hm.AnchorPoint=Vector2.new(.5,.5);U.stroke(hm,Color3.new(),.3)
 local h,s,v=U.hex(app.s[k]):ToHSV();local last=app.s[k]
 local function commit()
  local next=Color3.fromHSV(h,s,v):ToHex():upper()
  last=next
  if app.s[k]~=next then app:set(k,next) else self:sync() end
 end
 self.page:on(field.InputBegan,function(i) self:begin(i,function(pos)
  s=math.clamp((pos.X-field.AbsolutePosition.X)/math.max(1,field.AbsoluteSize.X),0,1)
  v=1-math.clamp((pos.Y-field.AbsolutePosition.Y)/math.max(1,field.AbsoluteSize.Y),0,1);commit()
 end) end)
 self.page:on(hue.InputBegan,function(i) self:begin(i,function(pos)
  h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/math.max(1,hue.AbsoluteSize.Y),0,1);commit()
 end) end)
 self:watch(function()
  if last~=app.s[k] then last=app.s[k];h,s,v=U.hex(last):ToHSV() end
  field.BackgroundColor3=Color3.fromHSV(h,1,1);marker.Position=UDim2.fromScale(s,1-v);hm.Position=UDim2.fromScale(.5,h)
 end)
end
function UI:group(g,skip) for _,k in S.order do if S.defs[k].group==g and not(skip and skip[k]) then self:control(k) end end end
return UI
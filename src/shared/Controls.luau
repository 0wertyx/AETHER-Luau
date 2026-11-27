local StarterGui=game:GetService("StarterGui");local Input=game:GetService("UserInputService");local Tween=game:GetService("TweenService");local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Icons=require(script.Parent.Icons)
local Constellation=require(script.Parent.Constellation)
local UI={};UI.__index=UI
local bg=Color3.fromRGB(19,16,32);local dim=Color3.fromRGB(173,163,197);local soft=Color3.fromRGB(43,35,60)
local branches={
 {name="Main",tabs={"Dashboard","Profiles","Diagnostics"}},
 {name="Visuals",tabs={"Character","Wings","Halos","Ambient","Indicators","Cursor"}},
 {name="Utility",tabs={"Interaction","Volleyball"}},
 {name="Interface",tabs={"Interface","HUD","Fonts"}},
}
local tabBranch={}
for _,branch in branches do for _,tab in branch.tabs do tabBranch[tab]=branch.name end end
local function glassSurface(frame,s)
 local tint=U.hex(s.uiPanelColor)
 local highlight=U.hex(s.uiSpecularColor)
 local reflection=s.uiReflection/100
 frame.BackgroundColor3=Color3.new(1,1,1)
 frame.BackgroundTransparency=1-s.uiGlassOpacity/100
 local grad=frame:FindFirstChild("LiquidTint") or U.new("UIGradient",{Name="LiquidTint",Rotation=90},frame)
 grad.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,tint:Lerp(highlight,.19*reflection)),
  ColorSequenceKeypoint.new(.15,tint:Lerp(highlight,.06*reflection)),
  ColorSequenceKeypoint.new(.66,tint:Lerp(Color3.fromRGB(5,6,16),.30)),
  ColorSequenceKeypoint.new(1,tint:Lerp(highlight,.10*reflection))
 })
 local rim=frame:FindFirstChildOfClass("UIStroke") or U.stroke(frame,U.hex(s.uiStrokeColor),.4,1)
 rim.Color=U.hex(s.uiStrokeColor);rim.Thickness=1.15;rim.Transparency=1-s.rim/100
 local edge=rim:FindFirstChild("LiquidEdge") or U.new("UIGradient",{Name="LiquidEdge",Rotation=90},rim)
 edge.Color=ColorSequence.new(highlight,U.hex(s.uiStrokeColor))
 edge.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.03),NumberSequenceKeypoint.new(.23,.62),
  NumberSequenceKeypoint.new(.74,.78),NumberSequenceKeypoint.new(1,.15)
 })
end
local function workspacePrefix(s) return "ws"..s.workspaceMode end
local function layoutKey(s)
 local prefix=workspacePrefix(s)
 local values={s.topX,s.topY,tostring(s.topCustom),s.topScale,tostring(s.layoutCustom),s.layoutX,s.layoutY,s.layoutW,s.layoutH,s.navWidth,s.workspaceMode}
 for _,node in {"Root","Main","Visuals","Utility","Interface","Page"} do
  values[#values+1]=s[prefix..node.."X"];values[#values+1]=s[prefix..node.."Y"]
 end
 return table.concat(values,":")
end
local function workspaceOffset(self,node)
 local draft=self.workspaceNodeDraft
 if draft and draft.node==node then return draft.offset end
 local s=self.app.s;local prefix=workspacePrefix(s)..node
 return Vector2.new(s[prefix.."X"],s[prefix.."Y"])
end
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
 {"HUD","Edit HUD on screen"},
 {"HUD","Reset panel position"},
 {"Character","AETHER MOTION STUDIO V12.14"},
 {"Halos","HALO COLLECTION"},
 {"Wings","WING COLLECTION"},
 {"Halos","Disable all halos"},
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
 {"Wings","Wing styles"},
 {"Halos","Halo styles"},
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
 -- Fullscreen hub: one static star field, not 48 animated multi-part particles.
 self.stars={}
 self.top,self.topRim,self.topButtons=U.topPanel(self.stage)
 self.topHit=U.new("TextButton",{Name="OpenAether",Text="",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,AutoButtonColor=false,Modal=false,ZIndex=27},self.top)
 scope:on(self.topHit.Activated,function() if not self.app.editingHUD and not self.app.stopping then self:show(not self.opened) end end)
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
 self.panel=U.new("Frame",{Name="Studio",BackgroundColor3=bg,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,Active=true},self.stage)
 self.panelBackground=U.frame(self.panel,"GlassBackground",nil,nil,Color3.new(1,1,1),.025);self.panelBackground.Active=false;self.panelBackground.Interactable=false;self.panelBackground.ZIndex=1
 self.backgroundGradient=U.gradient(self.panelBackground,bg,Color3.fromRGB(39,30,58),82)
 self.geoLayer=U.frame(self.panel,"GeometryBackground",UDim2.fromOffset(0,0),UDim2.fromScale(1,1),nil,1)
 self.geoLayer.ClipsDescendants=true;self.geoLayer.Active=false;self.geoLayer.ZIndex=1
 self.starField=U.frame(self.geoLayer,"DistantStars",nil,nil,nil,1);self.starField.Active=false;self.starField.Interactable=false
 for i=1,36 do
  local r=if i%7==0 then 3 else 2
  local dot=U.frame(self.starField,"Star",UDim2.fromScale((i*.6180339)%1,(i*.4142135)%1),UDim2.fromOffset(r,r),Color3.fromRGB(221,207,255),.37+(i%5)*.10)
  dot.AnchorPoint=Vector2.new(.5,.5);dot.Active=false;dot.Interactable=false;U.corner(dot,8)
 end
 self.constellationLayer=U.frame(self.geoLayer,"ConstellationLinks",nil,nil,nil,1);self.constellationLayer.Active=false;self.constellationLayer.Interactable=false
 self.constellation=Constellation.new(self.constellationLayer)
 self.backdropHit=U.new("TextButton",{Name="CloseOnBackground",Text="",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2,Modal=false},self.panel)
 self.header=U.frame(self.panel,"Titlebar",nil,UDim2.new(1,0,0,46),nil,1);self.header.Active=false;self.header.BackgroundColor3=Color3.fromRGB(28,23,48);self.header.BackgroundTransparency=.19;U.corner(self.header,24);U.stroke(self.header,Color3.fromRGB(192,158,255),.55);self.brand=U.label(self.header,"AETHER   VISUALS   HUB",20,UDim2.fromOffset(16,2),UDim2.fromOffset(135,40));self.tag=U.label(self.header,"",10,UDim2.fromOffset(147,3),UDim2.new(1,-190,0,40));self.tag.TextColor3=dim
 self.dockPicker=U.button(self.header,"←");self.dockPicker.Size=UDim2.fromOffset(32,29);self.dockPicker.Position=UDim2.new(1,-79,0,8);self.dockPicker.TextSize=18
 local sides={"Left","Right","Top","Bottom","Floating"}
 scope:on(self.dockPicker.Activated,function()
  self.app:set("menuDock",sides[(table.find(sides,self.app.s.menuDock) or 0)%#sides+1])
 end)
 self.grip=U.button(self.panel,"◢");self.grip.Name="ResizeGrip";self.grip.Size=UDim2.fromOffset(26,26);self.grip.TextSize=18;self.grip.ZIndex=6;self.grip.BackgroundTransparency=.42
 self.tag.Size=UDim2.new(1,-231,0,40)
 self.place=U.label(self.panel,"PLACE  /  "..tostring(game.PlaceId),10,nil,nil);self.place.TextColor3=dim
 self.nav=U.frame(self.panel,"BranchNavigation",nil,nil,nil,1)
 self.navList=U.new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},self.nav)
 self.branchStack=U.frame(self.panel,"OpenBranches",nil,nil,nil,1);self.branchStack.ZIndex=3
 self.pageBox=U.new("Frame",{Name="PageArea",BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},self.panel)
 self.status=U.label(self.panel,"",11,UDim2.new(0,16,1,-28),UDim2.new(1,-32,0,22));self.status.TextColor3=dim
 self.buttons={};self.branchCards={};self.branchButtons={}
 for order,branch in branches do
  local name=branch.name
  local button=U.button(self.nav,name);button.Name=name;button.LayoutOrder=order;button.TextXAlignment=Enum.TextXAlignment.Left;button.TextSize=16
  U.new("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,8)},button)
  local arrow=chevron(button);arrow.Position=UDim2.new(1,-14,.5,0)
  self.branchButtons[name]={button=button,arrow=arrow}
  local card=U.frame(self.branchStack,name.."Branch",nil,UDim2.new(1,0,0,0),nil,1)
  card.LayoutOrder=order;card.ClipsDescendants=true;card.Visible=false;U.corner(card,16)
  local title=U.label(card,name:upper(),12,UDim2.fromOffset(12,3),UDim2.new(1,-24,0,24));title:SetAttribute("AETHERMuted",true)
  local record={frame=card,title=title,tabs=branch.tabs,buttons={},expanded=false,revision=0}
  self.branchCards[name]=record
  for index,tab in branch.tabs do
   local b=U.button(card,tab);b.Name=tab;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextSize=13
   U.new("UIPadding",{PaddingLeft=UDim.new(0,12)},b)
   self.buttons[tab]=b;record.buttons[index]=b
   scope:on(b.Activated,function() if self.opened and os.clock()>=(self.tabInputAfter or 0) then self:open(tab) end end)
   scope:on(b.MouseEnter,function() self.navHover[tab]=true end)
   scope:on(b.MouseLeave,function() self.navHover[tab]=false end)
  end
  scope:on(button.Activated,function()
   if not self.opened or self.layoutEditing then return end
   self.app:set("branch"..name,not self.app.s["branch"..name])
  end)
 end
 function self:refreshBranches(immediate)
  if not self.branchRowH then return end
  local st=self.app.s
  local stackY=0
  for _,branch in branches do
   local r=self.branchCards[branch.name];local b=self.branchButtons[branch.name]
   local open=st["branch"..branch.name]==true
   local height=self.branchTitleH+#r.tabs*self.branchRowH+6
   local offset=workspaceOffset(self,branch.name)
   local position=UDim2.fromOffset(offset.X,stackY+offset.Y)
   if open then stackY+=height+10 end
   r.title.Size=UDim2.new(1,-24,0,self.branchTitleH-3)
   for i,tab in r.buttons do
    tab.Position=UDim2.fromOffset(6,self.branchTitleH+(i-1)*self.branchRowH)
    tab.Size=UDim2.new(1,-12,0,math.max(1,self.branchRowH-3))
    tab.TextSize=math.clamp(self.branchRowH-9,10,14)
   end
   b.button.BackgroundColor3=U.hex(if open then st.uiHoverColor else st.uiButtonColor)
   if immediate or open~=r.expanded or r.height~=height or r.targetPosition~=position then
    r.expanded=open;r.height=height;r.targetPosition=position;r.revision+=1
    local revision=r.revision
    if r.tween then r.tween:Cancel();r.tween=nil end
    if r.arrowTween then r.arrowTween:Cancel();r.arrowTween=nil end
    if open then r.frame.Visible=true end
    local size=UDim2.new(1,0,0,if open then height else 0)
    if immediate or st.reduce then
     r.frame.Size=size;r.frame.Position=position;r.frame.Visible=open;b.arrow.Rotation=if open then 0 else -90
    else
     local info=TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
     r.tween=Tween:Create(r.frame,info,{Size=size,Position=position});r.tween:Play()
     r.arrowTween=Tween:Create(b.arrow,info,{Rotation=if open then 0 else -90});r.arrowTween:Play()
     if not open then task.delay(.23,function() if r.frame.Parent and r.revision==revision and not r.expanded then r.frame.Visible=false end end) end
    end
   end
  end
 end
 self.search=U.new("TextBox",{Name="FunctionSearch",Text="",PlaceholderText="Search functions...",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(241,234,255),PlaceholderColor3=dim,BackgroundColor3=soft,BorderSizePixel=0},self.panel)
 U.corner(self.search,8);U.new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},self.search)
 self.navGlass=U.frame(self.panel,"TabRailGlass",nil,nil,Color3.fromRGB(25,20,45),.53);U.corner(self.navGlass,18);U.stroke(self.navGlass,Color3.fromRGB(184,151,243),.68);self.navGlass.Active=false;self.navGlass.Interactable=false
 self.nav.ZIndex=4
 self.contentGlass=U.frame(self.panel,"ContentGlass",nil,nil,Color3.fromRGB(25,20,45),.55);U.corner(self.contentGlass,18);U.stroke(self.contentGlass,Color3.fromRGB(184,151,243),.68);self.contentGlass.Active=false;self.contentGlass.Interactable=false
 self.pageBox.ZIndex=3;self.search.ZIndex=4
 self.searchResults=U.new("ScrollingFrame",{Name="FunctionSearchResults",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,Visible=false},self.panel)
 U.new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},self.searchResults)
 self.searchResults.ZIndex=3
 self.header.ZIndex=3;self.navGlass.ZIndex=3;self.contentGlass.ZIndex=3;self.status.ZIndex=3
 self.layoutMove=U.button(self.panel,"MOVE GUI");self.layoutMove.ZIndex=8;self.layoutMove.Visible=false
 self.layoutResize=U.button(self.panel,"RESIZE");self.layoutResize.ZIndex=8;self.layoutResize.Visible=false
 self.layoutDone=U.button(self.panel,"DONE");self.layoutDone.ZIndex=8;self.layoutDone.Visible=false
 scope:on(self.layoutDone.Activated,function() self:editLayout(false) end)
 self.pageBox.Active=true;self.header.Active=true
 -- The camera transforms a shared canvas. Header and view controls stay in screen space.
 self.workspace=U.frame(self.panel,"InfiniteWorkspace",UDim2.fromScale(.5,.5),UDim2.fromOffset(1,1),nil,1)
 self.workspace.AnchorPoint=Vector2.new(.5,.5);self.workspace.Active=false;self.workspace.ZIndex=3
 self.workspaceScale=U.new("UIScale",{Scale=1},self.workspace)
 -- Screen-space paths retain sharp, constant pixel width at every workspace zoom.
 self.workspaceLinks=U.frame(self.panel,"NodeConnections",nil,UDim2.fromScale(1,1),nil,1)
 self.workspaceLinks.Active=false;self.workspaceLinks.Interactable=false;self.workspaceLinks.ZIndex=2
 self.linkPool={};self.portPool={}
 local nativePaths=true
 for i=1,5 do
  local path
  local ok=pcall(function()
   path=Instance.new("Path2D");path.Name="NodeWire";path.Thickness=2;path.ZIndex=2;path.Visible=false;path.Parent=self.workspaceLinks
  end)
  if not ok then
   if path then path:Destroy() end
   nativePaths=false;break
  end
  self.linkPool[i]=path
 end
 if not nativePaths then
  for _,path in self.linkPool do path:Destroy() end
  table.clear(self.linkPool)
 end
 self.nativeWorkspacePaths=nativePaths
 for i=1,10 do
  local port=U.frame(self.workspaceLinks,"NodePort",nil,UDim2.fromOffset(7,7),Color3.new(1,1,1),.06)
  port.AnchorPoint=Vector2.new(.5,.5);port.Active=false;port.Interactable=false;port.ZIndex=2;port.Visible=false;U.corner(port,9);self.portPool[i]=port
 end
 for _,obj in {self.navGlass,self.nav,self.branchStack,self.contentGlass,self.pageBox,self.search,self.searchResults,self.status,self.layoutMove,self.layoutResize,self.layoutDone} do obj.Parent=self.workspace end
 self.rootDrag=U.button(self.workspace,"AETHER / MOVE");self.rootDrag.ZIndex=5;self.rootDrag.TextSize=11
 self.pageDrag=U.button(self.workspace,"MOVE PANEL");self.pageDrag.ZIndex=5;self.pageDrag.TextSize=11
 self.modeBar=U.frame(self.panel,"WorkspaceModes",nil,UDim2.fromOffset(320,30),nil,.5)
 self.modeBar.AnchorPoint=Vector2.new(.5,0);self.modeBar.ZIndex=12;U.corner(self.modeBar,14)
 self.modeButtons={}
 for i,mode in {"GUI","Nodes"} do
  local b=U.button(self.modeBar,if mode=="GUI" then "GUI VIEW" else "NODE VIEW")
  b.Position=UDim2.new((i-1)*.4,4,0,3);b.Size=UDim2.new(.4,-5,1,-6);b.ZIndex=13;b.TextSize=11;self.modeButtons[mode]=b
  scope:on(b.Activated,function()
   if self.app.s.workspaceMode==mode then return end
   self:finishWorkspaceNode();self:commitWorkspaceCamera();self.drag=nil;self.workspacePan=nil
   self.app:set("workspaceMode",mode)
  end)
 end
 self.homeButton=U.button(self.modeBar,"HOME");self.homeButton.Position=UDim2.new(.8,2,0,3);self.homeButton.Size=UDim2.new(.2,-6,1,-6);self.homeButton.ZIndex=13;self.homeButton.TextSize=10
 scope:on(self.homeButton.Activated,function() self:resetWorkspace(Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift)) end)
 local function inside(obj,pos)
  if not obj or not obj.Visible then return false end
  local a,b=obj.AbsolutePosition,obj.AbsoluteSize
  return pos.X>=a.X and pos.X<=a.X+b.X and pos.Y>=a.Y and pos.Y<=a.Y+b.Y
 end
 -- Only two consecutive, nearby background activations close the hub.
 local function isBackground(pos)
  for _,obj in {self.header,self.modeBar,self.navGlass,self.nav,self.search,self.contentGlass,self.pageBox,self.searchResults,self.status,self.rootDrag,self.pageDrag,self.layoutMove,self.layoutResize,self.layoutDone} do
   if inside(obj,pos) then return false end
  end
  for _,r in self.branchCards do if inside(r.frame,pos) then return false end end
  return true
 end
 scope:on(Input.InputBegan,function(input)
  if not self.backgroundTap then return end
  local kind=input.UserInputType
  if kind~=self.backgroundTap.kind or not isBackground(Vector2.new(input.Position.X,input.Position.Y)) then self.backgroundTap=nil end
 end)
 scope:on(self.backdropHit.Activated,function(input)
  if not self.opened or self.drag or self.workspacePan or self.layoutEditing or os.clock()<(self.tabInputAfter or 0) then self.backgroundTap=nil;return end
  if not input or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
  local pos=Vector2.new(input.Position.X,input.Position.Y)
  if not isBackground(pos) then self.backgroundTap=nil;return end
  local now=os.clock();local previous=self.backgroundTap
  if previous and previous.kind==input.UserInputType and now-previous.time<=.35 and (pos-previous.pos).Magnitude<=24 then
   self.backgroundTap=nil;self:show(false)
  else
   self.backgroundTap={time=now,pos=pos,kind=input.UserInputType}
  end
 end)
 self.searchPool={}
 self.searchIndex={}
 self.fullscreen=true
 for name in self.buttons do
  table.insert(self.searchIndex,{tab=name,label=name,term=name:lower()})
 end
 for _,k in S.order do
  local d=S.defs[k]
  if type(d)~="table" or type(d.group)~="string" or k:match("^ws[GN]") or k=="hp" or k:match("^hp[A-Z]") or k:match("^heart") or k=="hudShine" or k=="hudReaction" or k=="compact" or k=="robloxRail" or k=="railCustom" or k=="railX" or k=="railY" then continue end
  local tab=if d.group=="Theme" or d.group=="Motion" then "Interface" elseif d.group=="Camera" then "Interaction" else d.group
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
 function self:layoutCatalog()
  if not self.sc or not self.sc.Parent then return end
  if not self.catalogHost or not self.catalogHost.Parent then
   self.sc.Position=UDim2.fromOffset(10,10);self.sc.Size=UDim2.new(1,-20,1,-20)
   return
  end
  local w=self.pageBox.Size.X.Offset
  if w<2 then w=math.max(1,self.stage.AbsoluteSize.X-180) end
  if w>=650 then
   local right=math.clamp(math.floor(w*.43),280,560)
   self.catalogHost.Position=UDim2.fromOffset(0,0);self.catalogHost.Size=UDim2.new(1,-right-12,1,0)
   self.sc.Position=UDim2.new(1,-right,0,0);self.sc.Size=UDim2.new(0,right,1,0)
  else
   self.catalogHost.Position=UDim2.fromOffset(0,0);self.catalogHost.Size=UDim2.new(1,0,.49,-6)
   self.sc.Position=UDim2.new(0,0,.49,6);self.sc.Size=UDim2.new(1,0,.51,-6)
  end
 end
 function self:workspaceCamera()
  if self.workspaceCameraDraft then return self.workspaceCameraDraft end
  local s=self.app.s;local prefix=workspacePrefix(s)
  return {zoom=s[prefix.."Zoom"]/100,pan=Vector2.new(s[prefix.."PanX"],s[prefix.."PanY"])}
 end
 function self:applyWorkspaceCamera()
  local state=self:workspaceCamera()
  local position=UDim2.new(.5,state.pan.X*state.zoom,.5,state.pan.Y*state.zoom)
  if self.workspaceScale.Scale~=state.zoom then self.workspaceScale.Scale=state.zoom end
  if self.workspace.Position~=position then self.workspace.Position=position end
 end
 function self:commitWorkspaceCamera()
  local state=self.workspaceCameraDraft
  if not state then return end
  self.workspaceCameraDraft=nil;self.workspaceCameraRevision=(self.workspaceCameraRevision or 0)+1
  local prefix=workspacePrefix(self.app.s)
  self.app:patch({[prefix.."Zoom"]=math.clamp(math.round(state.zoom*100),35,180),[prefix.."PanX"]=math.clamp(math.round(state.pan.X),-1000000,1000000),[prefix.."PanY"]=math.clamp(math.round(state.pan.Y),-1000000,1000000)})
 end
 function self:applyWorkspaceNode(node,offset)
  self.workspaceNodeDraft={node=node,offset=Vector2.new(math.clamp(offset.X,-1000000,1000000),math.clamp(offset.Y,-1000000,1000000)),mode=self.app.s.workspaceMode}
  if node=="Root" or node=="Page" then self:layout() else self:refreshBranches(true) end
 end
 function self:finishWorkspaceNode(discard)
  local draft=self.workspaceNodeDraft
  self.workspaceNodeInertia=nil;self.workspaceNodeDraft=nil
  if not draft then return end
  if not discard then
   local prefix="ws"..draft.mode..draft.node
   self.app:patch({[prefix.."X"]=math.round(draft.offset.X),[prefix.."Y"]=math.round(draft.offset.Y)})
  end
  self:layout()
 end
 function self:stepWorkspaceNode(dt)
  local slide=self.workspaceNodeInertia
  if not slide then return end
  if not self.opened or self.app.s.reduce or self.app.s.workspaceMode~=slide.mode then self:finishWorkspaceNode();return end
  local step=math.min(dt,math.max(0,.32-slide.elapsed))
  local decay=math.exp(-12*step)
  slide.offset+=slide.velocity*((1-decay)/12)
  slide.velocity*=decay;slide.elapsed+=step
  self:applyWorkspaceNode(slide.node,slide.offset)
  if slide.elapsed>=.32 or slide.velocity.Magnitude*self.workspaceScale.Scale<12 then self:finishWorkspaceNode() end
 end
 function self:resetWorkspace(all)
  self:finishWorkspaceNode(all)
  self.workspaceCameraDraft=nil;self.workspaceCameraRevision=(self.workspaceCameraRevision or 0)+1;self.workspaceNodeDraft=nil;self.workspacePan=nil;self.drag=nil
  local prefix=workspacePrefix(self.app.s)
  local patch={[prefix.."Zoom"]=100,[prefix.."PanX"]=0,[prefix.."PanY"]=0}
  if all then
   for _,node in {"Root","Main","Visuals","Utility","Interface","Page"} do patch[prefix..node.."X"]=0;patch[prefix..node.."Y"]=0 end
  end
  self.app:patch(patch)
 end
 function self:updateWorkspaceLinks()
  local s=self.app.s
  self.workspaceLinks.Visible=s.workspaceMode=="Nodes"
  if not self.workspaceLinks.Visible then self.workspaceLinkKey=nil;return end
  local origin=self.workspaceLinks.AbsolutePosition
  local color=U.hex(s.accent);local lineIndex,portIndex=0,0
  local function point(obj,x,y)
   return obj.AbsolutePosition-origin+Vector2.new(obj.AbsoluteSize.X*x,obj.AbsoluteSize.Y*y)
  end
  local function port(p)
   portIndex+=1;local obj=self.portPool[portIndex];if not obj then return end
   obj.Position=UDim2.fromOffset(p.X,p.Y);obj.BackgroundColor3=color;obj.Visible=true
  end
  local function wire(a,b)
   local curve=math.max(35,math.abs(b.X-a.X)*.45)
   port(a);port(b)
   if self.nativeWorkspacePaths then
    lineIndex+=1;local path=self.linkPool[lineIndex]
    path.Color3=color
    path:SetControlPoints({
     Path2DControlPoint.new(UDim2.fromOffset(a.X,a.Y),UDim2.new(),UDim2.fromOffset(curve,0)),
     Path2DControlPoint.new(UDim2.fromOffset(b.X,b.Y),UDim2.fromOffset(-curve,0),UDim2.new())
    })
    path.Visible=true
    return
   end
   -- Compatibility fallback: adaptive subdivision with overlapping strokes.
   local p1=a+Vector2.new(curve,0);local p2=b-Vector2.new(curve,0)
   local prev=a;local steps=math.clamp(math.ceil(((p1-a).Magnitude+(p2-p1).Magnitude+(b-p2).Magnitude)/12),24,96)
   for i=1,steps do
    local t=i/steps;local v=1-t
    local nextPoint=a*v^3+p1*(3*v*v*t)+p2*(3*v*t*t)+b*t^3
    local delta=nextPoint-prev;local middle=(prev+nextPoint)*.5
    lineIndex+=1;local line=self.linkPool[lineIndex]
    if not line then
     line=U.frame(self.workspaceLinks,"LinkSegment",nil,UDim2.fromOffset(1,2),color,0)
     line.AnchorPoint=Vector2.new(.5,.5);line.Active=false;line.Interactable=false;line.ZIndex=2
     self.linkPool[lineIndex]=line
    end
    line.Position=UDim2.fromOffset(middle.X,middle.Y);line.Size=UDim2.fromOffset(math.max(2,delta.Magnitude+2),2)
    line.Rotation=math.deg(math.atan2(delta.Y,delta.X));line.BackgroundColor3=color;line.Visible=true
    prev=nextPoint
   end
  end
  local pairsToDraw={}
  for _,branch in branches do
   local r=self.branchCards[branch.name]
   if r.frame.Visible and r.frame.AbsoluteSize.Y>4 then pairsToDraw[#pairsToDraw+1]={point(self.branchButtons[branch.name].button,1,.5),point(r.frame,0,.5)} end
  end
  local selected=self.buttons[self.tab];local group=tabBranch[self.tab]
  if selected and group and self.branchCards[group].frame.Visible and self.pageBox.Visible then pairsToDraw[#pairsToDraw+1]={point(selected,1,.5),point(self.pageBox,0,.08)} end
  local signature={s.accent}
  for _,pair in pairsToDraw do for _,v in pair do signature[#signature+1]=v.X;signature[#signature+1]=v.Y end end
  local key=table.concat(signature,":")
  if self.workspaceLinkKey==key then return end
  self.workspaceLinkKey=key
  for _,pair in pairsToDraw do wire(pair[1],pair[2]) end
  for i=lineIndex+1,#self.linkPool do self.linkPool[i].Visible=false end
  for i=portIndex+1,#self.portPool do self.portPool[i].Visible=false end
 end
 function self:workspacePageVisible()
  if not self.opened or not self.pageBox.Visible then return false end
  local p=self.pageBox.AbsolutePosition;local size=self.pageBox.AbsoluteSize;local a=self.stage.AbsolutePosition;local b=a+self.stage.AbsoluteSize
  return self.workspaceScale.Scale>=.45 and p.X+size.X>a.X and p.Y+size.Y>a.Y and p.X<b.X and p.Y<b.Y
 end
 function self:layout()
  local sz=self.stage.AbsoluteSize
  if sz.X<2 or sz.Y<2 then self.layoutPending=true;return end
  self.layoutPending=false;self.layoutViewport=sz
  local s=self.app.s
  self.xy=Vector2.zero;self.panelExtent=sz;self.layoutSide="Fullscreen"
  self.panel.Size=UDim2.fromScale(1,1);self.panel.Position=UDim2.fromOffset(0,0)
  self.grip.Visible=false;self.dockPicker.Visible=false;self.place.Visible=false
  self.header.AnchorPoint=Vector2.new(.5,0);self.header.Position=UDim2.new(.5,0,0,math.max(12,math.round(sz.Y*.045)))
  self.header.Size=UDim2.fromOffset(math.min(720,math.max(160,sz.X-24)),46)
  self.modeBar.Position=UDim2.new(.5,0,0,math.max(12,math.round(sz.Y*.045))+51)
  self.modeBar.Size=UDim2.fromOffset(math.min(320,sz.X-16),30)
  self.workspace.Size=UDim2.fromOffset(sz.X,sz.Y);self:applyWorkspaceCamera()
  self.brand.Position=UDim2.fromOffset(10,0);self.brand.Size=UDim2.new(1,-20,1,0);self.brand.TextXAlignment=Enum.TextXAlignment.Center
  self.brand.TextSize=if sz.X<500 then 14 else 20
  self.brand.Font=Enum.Font.Code;self.tag.Visible=false
  local narrow=sz.X<840
  local pad=if narrow then 8 else 22
  local gap=if narrow then 8 else 14
  local draft=self.layoutDraft or s
  local custom=draft.layoutCustom
  local fullW=math.max(1,sz.X-2*pad)
  local fullH=math.max(60,sz.Y-160)
  local workW=math.min(fullW,math.max(math.min(fullW,440),math.round(fullW*(if custom then draft.layoutW else 86)/100)))
  local workH=math.min(fullH,math.max(math.min(fullH,280),math.round(fullH*(if custom then draft.layoutH else 78)/100)))
  local x=pad+math.round((fullW-workW)*(if custom then draft.layoutX else 50)/100)
  local y=130+math.round((fullH-workH)*(if custom then draft.layoutY else 50)/100)
  local rail=math.min(math.round(workW*.23),if narrow then 92 else draft.navWidth)
  local branchW=math.min(math.round(workW*.24),if narrow then 128 else 202)
  local contentX=x+rail+branchW+2*gap
  local bodyW=math.max(1,workW-rail-branchW-2*gap)
  local bodyH=math.max(1,workH-44)
  self.layoutBounds={x=x,y=y,w=workW,h=workH,fullW=fullW,fullH=fullH,pad=pad}
  local buttonH=math.min(54,math.max(22,math.floor((workH-38)/4)))
  local railH=buttonH*4+40
  local rootOffset=workspaceOffset(self,"Root");local rootX,rootY=x+rootOffset.X,y+rootOffset.Y
  self.navGlass.Position=UDim2.fromOffset(rootX,rootY);self.navGlass.Size=UDim2.fromOffset(rail,railH)
  self.nav.Position=UDim2.fromOffset(rootX+7,rootY+8);self.nav.Size=UDim2.fromOffset(math.max(1,rail-14),math.max(1,railH-16))
  self.rootDrag.Position=UDim2.fromOffset(rootX,rootY-30);self.rootDrag.Size=UDim2.fromOffset(rail,26)
  for _,b in self.branchButtons do
   b.button.Size=UDim2.new(1,0,0,buttonH)
   b.button.TextSize=if narrow then 12 else 16
  end
  self.branchStack.Position=UDim2.fromOffset(x+rail+gap,y)
  self.branchStack.Size=UDim2.fromOffset(branchW,workH)
  self.branchTitleH=math.clamp(math.floor(workH/20),10,24)
  self.branchRowH=math.clamp(math.floor((workH-4*(self.branchTitleH+6)-30)/14),8,36)
  self:refreshBranches(true)
  local pageOffset=workspaceOffset(self,"Page");local pageX,pageY=contentX+pageOffset.X,y+pageOffset.Y
  self.pageDrag.Position=UDim2.fromOffset(pageX,pageY-30);self.pageDrag.Size=UDim2.fromOffset(bodyW,26);self.pageDrag.Text=self.tab:upper().." / MOVE PANEL"
  self.search.Position=UDim2.fromOffset(pageX,pageY);self.search.Size=UDim2.fromOffset(bodyW,32)
  self.search.BackgroundTransparency=.53
  self.contentGlass.Position=UDim2.fromOffset(pageX,pageY+42);self.contentGlass.Size=UDim2.fromOffset(bodyW,bodyH)
  local isCatalog=self.catalogHost~=nil and self.catalogHost.Parent~=nil
  self.contentGlass.Visible=not isCatalog or self.searchResults.Visible
  self.pageBox.Position=self.contentGlass.Position;self.pageBox.Size=self.contentGlass.Size
  self.searchResults.Position=self.pageBox.Position;self.searchResults.Size=self.pageBox.Size
  self.status.Position=UDim2.fromOffset(pageX,pageY+workH+5);self.status.Size=UDim2.fromOffset(bodyW,21)
  self.layoutMove.Position=UDim2.fromOffset(x,math.max(55,y-34));self.layoutMove.Size=UDim2.fromOffset(100,28)
  self.layoutDone.Position=UDim2.fromOffset(x+workW-74,math.max(55,y-34));self.layoutDone.Size=UDim2.fromOffset(74,28)
  self.layoutResize.Position=UDim2.fromOffset(x+workW-74,y+workH-28);self.layoutResize.Size=UDim2.fromOffset(74,28)
  self.layoutMove.Visible=self.layoutEditing==true;self.layoutDone.Visible=self.layoutEditing==true;self.layoutResize.Visible=self.layoutEditing==true
  self.top.Size=UDim2.fromOffset(math.min(math.round(136*s.topScale/100),math.max(90,sz.X-24)),math.round(38*s.topScale/100))
  self.top.Position=UDim2.new(.5,0,0,if narrow then 48 else 12)
  if s.topCustom and not (s.topX==0 and s.topY==0) then
   self.top.AnchorPoint=Vector2.zero
   self.top.Position=UDim2.fromOffset(math.max(0,sz.X-self.top.Size.X.Offset)*s.topX/100,math.max(0,sz.Y-self.top.Size.Y.Offset)*s.topY/100)
  else self.top.AnchorPoint=Vector2.new(.5,0) end
  self.quick.Size=UDim2.fromOffset(math.min(324,math.max(140,sz.X-24)),math.min(math.clamp(sz.Y*.58,120,440),math.max(120,sz.Y-24)))
  self.layoutKey=layoutKey(s)
  self:layoutCatalog()
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
  if self.fullscreen or not self.app.s.menuDrag or self.drag or not self.opened then return end
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
 function self:editLayout(on)
  self:finishWorkspaceNode();self.layoutEditing=on==true;self.layoutDraft=nil;self.drag=nil;self:layout()
  if not on and self.app.store then self.app.store:save() end
 end
 local function beginLayout(input,resize)
  if not self.layoutEditing or self.drag then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  local b=self.layoutBounds;if not b then return end
  local origin=Vector2.new(input.Position.X,input.Position.Y)
  local function calc(pos)
   local delta=(pos-origin)/self.workspaceScale.Scale
   local w=if resize then math.clamp(b.w+delta.X,b.fullW*.50,b.fullW*.98) else b.w
   local h=if resize then math.clamp(b.h+delta.Y,b.fullH*.40,b.fullH*.95) else b.h
   local x=if resize then b.x else b.x+delta.X
   local y=if resize then b.y else b.y+delta.Y
   local next=table.clone(self.app.s);next.layoutCustom=true
   next.layoutW=math.clamp(math.round(w/b.fullW*100),50,98);next.layoutH=math.clamp(math.round(h/b.fullH*100),40,95)
   next.layoutX=math.clamp(math.round((x-b.pad)/math.max(1,b.fullW-w)*100),0,100)
   next.layoutY=math.clamp(math.round((y-130)/math.max(1,b.fullH-h)*100),0,100)
   self.layoutDraft=next;self:layout()
  end
  self:begin(input,calc)
  if self.drag then self.drag.finish=function(pos)
   calc(pos);local next=self.layoutDraft;self.layoutDraft=nil
   if next then self.app:patch({layoutCustom=true,layoutX=next.layoutX,layoutY=next.layoutY,layoutW=next.layoutW,layoutH=next.layoutH}) end
   self:layout()
  end end
 end
 scope:on(self.layoutMove.InputBegan,function(i) beginLayout(i,false) end)
 scope:on(self.layoutResize.InputBegan,function(i) beginLayout(i,true) end)
 local function beginWorkspaceNode(input,node)
  if not self.opened or self.drag or self.workspacePan then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  self:finishWorkspaceNode()
  local origin=Vector2.new(input.Position.X,input.Position.Y);local old=workspaceOffset(self,node);local zoom=self.workspaceScale.Scale
  local lastPos,lastAt=origin,os.clock()
  local velocity=Vector2.zero
  local function calc(pos)
   local now=os.clock()
   if pos~=lastPos then
    local dt=math.max(1/240,now-lastAt)
    local measured=(pos-lastPos)/dt
    local cap=650
    if measured.Magnitude>cap then measured=measured.Unit*cap end
    velocity=velocity:Lerp(measured,1-math.exp(-dt*32))
    lastPos=pos;lastAt=now
   end
   self:applyWorkspaceNode(node,old+(pos-origin)/zoom)
  end
  self:begin(input,calc)
  if self.drag then self.drag.finish=function(pos)
   calc(pos)
   local next=self.workspaceNodeDraft.offset
   local idle=os.clock()-lastAt
   local releaseVelocity=velocity*math.exp(-idle*25)
   if not self.app.s.reduce and idle<.10 and (pos-origin).Magnitude>=6 and releaseVelocity.Magnitude>=80 then
    self.workspaceNodeInertia={node=node,mode=self.app.s.workspaceMode,offset=next,velocity=releaseVelocity/zoom,elapsed=0}
   else
    self:finishWorkspaceNode()
   end
  end end
 end
 scope:on(self.rootDrag.InputBegan,function(i) beginWorkspaceNode(i,"Root") end)
 scope:on(self.pageDrag.InputBegan,function(i) beginWorkspaceNode(i,"Page") end)
 for name,r in self.branchCards do
  r.title.Active=true
  scope:on(r.title.InputBegan,function(i) beginWorkspaceNode(i,name) end)
 end
 scope:on(Input.InputBegan,function(i)
  if not self.opened or Input:GetFocusedTextBox() then return end
  if i.KeyCode==Enum.KeyCode.Home then self:resetWorkspace(Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift));return end
  if i.UserInputType~=Enum.UserInputType.MouseButton3 or self.drag then return end
  local state=self:workspaceCamera()
  self.backgroundTap=nil
  self.workspacePan={origin=Vector2.new(i.Position.X,i.Position.Y),pan=state.pan,zoom=state.zoom}
 end)
 scope:on(Input.InputChanged,function(i)
  if not self.opened then return end
  local pan=self.workspacePan
  if pan and i.UserInputType==Enum.UserInputType.MouseMovement then
   local delta=Vector2.new(i.Position.X,i.Position.Y)-pan.origin
   self.workspaceCameraDraft={zoom=pan.zoom,pan=pan.pan+delta/pan.zoom};self:applyWorkspaceCamera();return
  end
  if i.UserInputType~=Enum.UserInputType.MouseWheel or self.drag or pan then return end
  local ctrl=Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)
  local pos=Input:GetMouseLocation()
  if not ctrl then
   for _,obj in {self.pageBox,self.searchResults,self.search,self.header,self.modeBar,self.navGlass} do if inside(obj,pos) then return end end
   for _,r in self.branchCards do if inside(r.frame,pos) then return end end
  end
  local state=self:workspaceCamera();local zoom=math.clamp(state.zoom*1.12^i.Position.Z,.35,1.8)
  if zoom==state.zoom then return end
  local center=self.stage.AbsolutePosition+self.stage.AbsoluteSize*.5
  local delta=pos-center
  local next=state.pan+delta/zoom-delta/state.zoom
  self.backgroundTap=nil
  self.workspaceCameraDraft={zoom=zoom,pan=next};self:applyWorkspaceCamera()
  self.workspaceCameraRevision=(self.workspaceCameraRevision or 0)+1;local rev=self.workspaceCameraRevision
  task.delay(.25,function() if self.workspace.Parent and rev==self.workspaceCameraRevision and not self.workspacePan then self:commitWorkspaceCamera() end end)
 end)
 scope:on(Input.InputEnded,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton3 and self.workspacePan then self.workspacePan=nil;self:commitWorkspaceCamera() end
 end)
 scope:on(self.pageBox:GetPropertyChangedSignal("Size"),function() self:layoutCatalog() end)
 scope:on(self.stage:GetPropertyChangedSignal("AbsoluteSize"),function() self:layout() end);self:layout()
 scope:on(Input.InputChanged,function(i) local d=self.drag;if d and (i==d.i or d.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement) then d.fn(Vector2.new(i.Position.X,i.Position.Y),d.start,d.origin) end end)
 scope:on(Input.InputEnded,function(i) if self.drag and (self.drag.i==i or self.drag.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseButton1) then local d=self.drag;self.drag=nil;if d.finish then d.finish(Vector2.new(i.Position.X,i.Position.Y)) end end end)
 scope:on(Input.WindowFocusReleased,function() self.backgroundTap=nil;self.drag=nil;self.workspacePan=nil;self:finishWorkspaceNode();self:commitWorkspaceCamera();if self.menuDraft then self.menuDraft=nil end;self:layout() end);scope:add(function() if self.page then self.page:clear() end;Icons.clear() end);return self
end
function UI:animateBackground(t)
 if self.layoutPending or self.layoutViewport~=self.stage.AbsoluteSize then self:layout() end
 local s=self.app.s
 local dt=math.clamp(t-(self.motionAt or t-1/60),0,.1)
 self.motionAt=t
 self:stepWorkspaceNode(dt)
 local immediate=s.reduce or s.menuTransition=="Off"
 local duration=if not self.opened then .24 else math.max(.06,s.duration/1000*100/s.speed)
 local target=if self.opened then 1 else 0
 local step=dt/duration
 if immediate then self.menuProgress=target
 else self.menuProgress=math.clamp(self.menuProgress+step*(if self.opened then 1 else -1),0,1) end
 local wasVisible=self.panel.Visible
 self.panel.Visible=self.opened or self.menuProgress>0
 local q=U.ease(self.menuProgress,s.ease)
 if self.panel.Visible or wasVisible then transition(self.panel,if self.panel.Visible then q else 1) end
 local strength=s.menuAnimStrength/100
 if self.xy and not self.fullscreen then
  local dx,dy=0,0
  local side=self.layoutSide or s.menuDock
  local distance=(1-q)*(.65+.35*strength)
  if self.opened and not immediate and s.menuTransition~="Fade" and not self.menuDraft then
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
 self.top.Visible=(s.topCapsule and not self.panel.Visible) or editingAux
 self.quickArrow.Visible=self.app.volleyball~=nil and not self.app.editingHUD
 self.quick.Visible=editingAux or (self.quickOpen and s.topCapsule and not self.app.editingHUD)
 self.bindPanel.Visible=editingAux or (not self.opened and not self.app.editingHUD and self.app.mode=="Game" and s.keybindWidget)
 self.bindRim.Color=U.hex(s.uiStrokeColor)
 if self.bindPanel.Visible and t>=(self.bindRefreshAt or 0) then self.bindRefreshAt=t+.3;self:refreshBindPanel() end
 if self.quick.Visible and self.quickAdapter and t>=(self.quickRefreshAt or 0) then
  self.quickRefreshAt=t+.25
  for _,refresh in self.quickAdapter.syncs do pcall(refresh) end
 end
 self.updateChip.Visible=false
 self.topRim.Color=U.hex(s.uiStrokeColor);self.quickRim.Color=U.hex(s.uiStrokeColor)
 local below=6
 self.quickArrow.Position=UDim2.new(.5,0,1,below)
 self:layoutAuxWidgets(below)
 self.topButtons[1].TextColor3=U.hex(s.uiFontColor or "F1E6FF")
 local visible=s.screenParticles and q>.001
 local decorDt=(self.decorElapsed or 0)+dt
 self.decorElapsed=decorDt
 local decorDue=decorDt>=1/20 or self.decorSettings~=s or self.lastDecorVisible~=visible
 if decorDue then self.decorElapsed=0;self.decorSettings=s;self.lastDecorVisible=visible end
 self.screenFX.Visible=false
 self.starField.Visible=visible
 if not self.panel.Visible then return end
 local tm=if s.reduce then 0 else t*s.speed/100
 self.pageProgress=if immediate or not s.tabTransition then 1 else math.min(1,self.pageProgress+dt/math.max(.06,duration*.72))
 local pageQ=U.ease(self.pageProgress,s.ease)
 transition(self.pageBox,pageQ)
 -- Full-screen content stays anchored; no per-tab position animation.
 -- Links follow rendered geometry every frame, independently of background effects.
 self:updateWorkspaceLinks()
 if decorDue or self.navDirty then
 self.navDirty=false
 for name,b in self.buttons do
  local desired=if name==self.tab then 1 elseif self.navHover[name] then .45 else 0
  local amount=self.navAmount[name] or 0
  local k=if s.reduce or not s.navGlow then 1 else 1-math.exp(-math.max(dt,decorDt)*15)
  amount+=(desired-amount)*k
  self.navAmount[name]=amount
  b.BackgroundColor3=U.hex(s.uiButtonColor):Lerp(U.hex(s.uiHoverColor),amount)
 end
 end
 self.geoLayer.Visible=(s.menuGeometry or s.screenParticles) and self.panel.Visible
 self.constellationLayer.Visible=s.menuGeometry
 if self.geoLayer.Visible and s.menuGeometry and decorDue then self.constellation:step(math.min(.1,decorDt),s) end
end
function UI:begin(i,fn,origin) if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end;self.backgroundTap=nil;if self.workspaceNodeInertia then self:finishWorkspaceNode() end;local v=Vector2.new(i.Position.X,i.Position.Y);self.drag={i=i,start=v,fn=fn,origin=origin};fn(v,v,origin) end
function UI:show(on)
 self.backgroundTap=nil
 if on then self:setQuick(false) end
 if not on then self.workspacePan=nil;self:finishWorkspaceNode();self:commitWorkspaceCamera() end
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
 if not on then self.layoutEditing=false;self.layoutDraft=nil;self.layoutMove.Visible=false;self.layoutResize.Visible=false;self.layoutDone.Visible=false end
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
 self.contentGlass.Visible=has or not (self.catalogHost and self.catalogHost.Parent)
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
local visualTabs={Halos=true,Wings=true,Ambient=true}
function UI:open(tab)
 if tab=="Camera" then tab="Interaction" end
 if self.search then self.search.Text="" end
 self.app.bindingLockKey=false
 if not self.buttons[tab] then return end
 self:show(true);self.drag=nil
 local branch=tabBranch[tab]
 if self.app.store and branch and not self.app.s["branch"..branch] then self.app:set("branch"..branch,true) end
 if self.page then self.page:clear() end
 self.app.preview=nil;self.page=U.scope();self.syncs={};self.controlKeys={};self.colorKeys={};self.seq=0;self.tab=tab
 self.catalogHost=nil;self.editorAdapter=nil;self.themeDirty=true;self.navDirty=true
 local owner=self;self.page:add(function() if owner.editorAdapter then owner.editorAdapter.page:clear();owner.editorAdapter=nil end end)
 self.pageProgress=1
 transition(self.pageBox,1)
 local sc=self.page:add(U.new("ScrollingFrame",{Name="Page_"..tab,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=dim,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},self.pageBox))
 U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sc);self.sc=sc
 if visualTabs[tab] then
  self.catalogHost=self.page:add(U.frame(self.pageBox,"VisualCatalog",nil,nil,Color3.fromRGB(24,19,43),.49));U.corner(self.catalogHost,17);U.stroke(self.catalogHost,Color3.fromRGB(181,145,244),.64)
  sc.BackgroundColor3=Color3.fromRGB(25,20,44);sc.BackgroundTransparency=.49;U.corner(sc,16)
  U.new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,4)},sc)
 else self:title(tab:upper().."   /   AETHER VISUALS HUB") end
 self:layout();self.app:page(tab,self);self:sync()
 if self.app.store and self.app.s.lastPage~=tab then self.app:set("lastPage",tab) end
end
-- A dedicated short-lived editor scope keeps grid cards and navigation intact.
function UI:makeCatalogEditor()
 if self.editorAdapter then self.editorAdapter.page:clear() end
 local owner=self
 local editor=setmetatable({app=self.app,page=U.scope(),syncs={},seq=0,controlKeys={},colorKeys={},tab=self.tab},UI)
 local holder=editor.page:add(U.new("Frame",{Name="SelectedEffectEditor",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},self.sc))
 U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},holder)
 editor.sc=holder
 function editor:sync() owner:sync() end
 function editor:begin(...) owner:begin(...) end
 function editor:message(msg) owner:message(msg) end
 function editor:open(tab) owner:open(tab) end
 self.editorAdapter=editor
 self.themeDirty=true
 return editor
end
function UI:row(h,name) self.seq+=1;local f=U.frame(self.sc,name or "Row",nil,UDim2.new(1,-8,0,h),U.hex(self.app.s.uiRowColor),.62);f:SetAttribute("AETHERControlRow",true);f.LayoutOrder=self.seq;U.corner(f,8);return f end
function UI:title(str) local f=self:row(26,"Heading");f.BackgroundTransparency=1;local n=U.label(f,str,13);n.TextColor3=U.hex(self.app.s.accent);self.titleLabel=n;return n end
function UI:note(str,h) local f=self:row(h or 36,"Note");f.BackgroundTransparency=1;local l=U.label(f,str,12);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextColor3=dim;l:SetAttribute("AETHERMuted",true);return l end
function UI:watch(fn) table.insert(self.syncs,fn);fn() end
function UI:sync()
 if not self.panel.Parent then return end
 local st=self.app.s
 local space=Color3.fromRGB(7,9,22)
 self.backgroundGradient.Color=ColorSequence.new(U.hex(st.constellationBgA):Lerp(space,.64),U.hex(st.constellationBgB):Lerp(space,.53))
 self.backgroundGradient.Rotation=st.constellationAngle
 local key=layoutKey(st)
 if self.layoutKey~=key and not self.menuDraft and not self.layoutDraft then self:layout() end
 self:refreshBranches(false)
 self:applyWorkspaceCamera()
 self.workspaceLinks.Visible=st.workspaceMode=="Nodes"
 for mode,b in self.modeButtons do b.BackgroundColor3=U.hex(if mode==st.workspaceMode then st.uiHoverColor else st.uiButtonColor) end
 local primary=U.hex(st.uiFontColor or "F1E6FF")
 local muted=U.hex(st.uiMutedColor or "ADA3C5")
 self.brand.TextColor3=U.hex(st.accent)
 self.tag.Text="AETHER / VISUALS"
 self.tag.TextColor3=muted
 self.status.TextColor3=muted
 local iconKey=tostring(st.iconAtlas)..":"..tostring(st.iconAtlasTile)
 if self.iconKey~=iconKey then self.iconKey=iconKey;for _,asset in self.icons do asset:sync(st.iconAtlas,st.iconAtlasTile) end;self:layout() end
 for _,f in self.syncs do f() end
 if self.editorAdapter then for _,f in self.editorAdapter.syncs do f() end end
 local themeKey=table.concat({st.accent,st.uiFontColor,st.uiMutedColor,st.uiPanelColor,st.uiButtonColor,st.uiHoverColor,st.uiRowColor,st.uiStrokeColor,st.uiSpecularColor,st.uiGlassOpacity,st.uiReflection,st.rim},":")
 if not self.themeDirty and self.themeKey==themeKey then return end
 self.themeDirty=false;self.themeKey=themeKey
 for _,frame in {self.navGlass,self.contentGlass,self.header,self.top,self.quick,self.bindPanel,self.modeBar,self.catalogHost,self.catalogHost and self.sc} do if frame then glassSurface(frame,st) end end
 for _,r in self.branchCards do glassSurface(r.frame,st) end
 self.search.BackgroundColor3=U.hex(st.uiRowColor)
 self.quickArrow.BackgroundColor3=U.hex(st.uiButtonColor)
 self.rootDrag.BackgroundColor3=U.hex(st.uiButtonColor);self.pageDrag.BackgroundColor3=U.hex(st.uiButtonColor);self.homeButton.BackgroundColor3=U.hex(st.uiButtonColor)
 for _,obj in {self.layoutMove,self.layoutResize,self.layoutDone} do obj.BackgroundColor3=U.hex(st.uiHoverColor) end
 -- Only recolor editor controls, not HUD/3D previews or their own palette.
 for _,obj in self.panel:GetDescendants() do
  if obj:IsA("Frame") and obj:GetAttribute("AETHERControlRow") and obj.BackgroundTransparency<1 then obj.BackgroundColor3=U.hex(st.uiRowColor) end
  if obj:IsA("TextButton") and obj:GetAttribute("AETHERThemeButton") then obj.BackgroundColor3=U.hex(st.uiButtonColor) end
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
   if obj==self.brand or obj==self.tag or obj==self.status then continue end
   if obj:GetAttribute("AETHERKeepFontColor") then continue end
   local holder=obj.Parent
   local skip=false
   while holder and holder~=self.panel do
    if holder.Name=="EffectThumbnail" or holder.Name=="LivePreview" or holder.Name=="RigPreview"
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
 cols=cols or 3;for start=1,#items,cols do local row=self:row(33,"Actions");row.BackgroundTransparency=1;for j=0,math.min(cols-1,#items-start) do local item=items[start+j];local b=U.button(row,item);b:SetAttribute("AETHERThemeButton",not selected);b.BackgroundColor3=U.hex(self.app.s.uiButtonColor);b.Name=item;b.Size=UDim2.new(1/cols,-4,1,0);b.Position=UDim2.fromScale(j/cols,0);self.page:on(b.Activated,function() self:action(function() fn(item) end) end);if selected then self:watch(function() b.BackgroundColor3=U.hex(if selected()==item then self.app.s.uiHoverColor else self.app.s.uiButtonColor) end) end end end
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
 if a=="bool" or a=="choice" then local b=U.button(row,"");b.Name="Value";b.Position=UDim2.new(.58,0,0,3);b.Size=UDim2.new(.42,-6,1,-6);self.page:on(b.Activated,function() if a=="bool" then app:set(k,not app.s[k]) else app:set(k,d.min[(table.find(d.min,app.s[k]) or 0)%#d.min+1]) end end);self:watch(function() b.Text=if a=="bool" then (if app.s[k] then "ON" else "OFF") else tostring(app.s[k]).."  ›";b.BackgroundColor3=U.hex(if a=="bool" and not app.s[k] then app.s.uiButtonColor else app.s.uiHoverColor) end);return end
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
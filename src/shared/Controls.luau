local StarterGui=game:GetService("StarterGui");local Input=game:GetService("UserInputService");local Tween=game:GetService("TweenService");local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Icons=require(script.Parent.Icons)
local Constellation=require(script.Parent.Constellation)
local UI={};UI.__index=UI
local bg=Color3.fromRGB(19,16,32);local dim=Color3.fromRGB(173,163,197);local soft=Color3.fromRGB(43,35,60)
local branches={
 {name="Main",tabs={"Dashboard","Profiles","Diagnostics"}},
 {name="Visuals",tabs={"Character","Wings","Halos","Ambient","Indicators","Cursor"}},
 {name="Utility",tabs={"Interaction","Volleyball"}},
 {name="Interface",tabs={"Interface","Clock","FPS","Top Panel","Input Display","Reticle","Keybinds","Quick Menu","Practice Display","Fonts"}},
}
local tabBranch={}
for _,branch in branches do for _,tab in branch.tabs do tabBranch[tab]=branch.name end end
local function glassSurface(frame,s,role)
 local tint,opacity,edgeColor,edgeAlpha,edgeWidth=U.blockStyle(s,role or "Page",U.hex(s.uiPanelColor),1-s.uiGlassOpacity/100,U.hex(s.uiStrokeColor),1-s.rim/100,1.15)
 local highlight=U.hex(s.uiSpecularColor)
 local reflection=s.uiReflection/100
 frame.BackgroundColor3=Color3.new(1,1,1)
 frame.BackgroundTransparency=opacity
 local grad=frame:FindFirstChild("LiquidTint") or U.new("UIGradient",{Name="LiquidTint",Rotation=90},frame)
 grad.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,tint:Lerp(highlight,.19*reflection)),
  ColorSequenceKeypoint.new(.15,tint:Lerp(highlight,.06*reflection)),
  ColorSequenceKeypoint.new(.66,tint:Lerp(Color3.fromRGB(5,6,16),.30)),
  ColorSequenceKeypoint.new(1,U.appearanceColor(s,role or "Page","GradientEnd",tint:Lerp(highlight,.10*reflection)))
 })
 frame:SetAttribute("AETHERAppearanceRole",role or "Page")
 local rim=frame:FindFirstChildOfClass("UIStroke") or U.stroke(frame,U.hex(s.uiStrokeColor),.4,1)
 rim.Color=edgeColor;rim.Thickness=edgeWidth;rim.Transparency=edgeAlpha;rim.Enabled=edgeWidth>0 and edgeAlpha<1
 local edge=rim:FindFirstChild("LiquidEdge") or U.new("UIGradient",{Name="LiquidEdge",Rotation=90},rim)
 edge.Color=ColorSequence.new(highlight,edgeColor);edge.Enabled=not s["appearance"..(role or "Page").."Custom"]
 edge.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.03),NumberSequenceKeypoint.new(.23,.62),
  NumberSequenceKeypoint.new(.74,.78),NumberSequenceKeypoint.new(1,.15)
 })
end
-- Cache keys may contain numbers, strings and boolean settings.
local function scalarKey(values)
 local encoded=table.create(#values)
 for i,v in ipairs(values) do
  local raw=tostring(v)
  encoded[i]=tostring(#raw)..":"..raw
 end
 return table.concat(encoded,"|")
end
local function workspacePrefix(s) return "ws"..s.workspaceMode end
local function layoutKey(s)
 local prefix=workspacePrefix(s)
 local values={s.topX,s.topY,tostring(s.topCustom),s.topScale,tostring(s.layoutCustom),s.layoutX,s.layoutY,s.layoutW,s.layoutH,s.navWidth,s.workspaceMode}
 values[#values+1]=tostring(s[prefix.."AppearanceCustom"]);values[#values+1]=tostring(s[prefix.."PreviewCustom"])
 for _,node in {"Root","Main","Visuals","Utility","Interface","Page","Appearance","Preview"} do
  values[#values+1]=s[prefix..node.."X"];values[#values+1]=s[prefix..node.."Y"]
 end
 return scalarKey(values)
end
local function workspaceOffset(self,node)
 local draft=self.workspaceNodeDraft
 if draft and draft.node==node then return draft.offset end
 local s=self.app.s;local prefix=workspacePrefix(s)..node
 if node=="Preview" and not s[prefix.."Custom"] then
  local y=0
  for _,branch in branches do if s["branch"..branch.name] then y+=(self.branchTitleH or 24)+#branch.tabs*(self.branchRowH or 30)+16 end end
  return Vector2.new((self.branchStack and self.branchStack.Size.X.Offset or 202)+28,y)
 end
 if node=="Appearance" and not s[prefix.."Custom"] then
  local y=0
  for _,branch in branches do
   if s["branch"..branch.name] then y+=(self.branchTitleH or 24)+#branch.tabs*(self.branchRowH or 30)+16 end
  end
  return Vector2.new(0,y)
 end
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
 {"Top Panel","TOP PANEL"},
 {"Interface","WIDGET TRANSITIONS"},
 {"Interface","Edit HUD on screen"},
 {"Top Panel","Reset panel position"},
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
 -- Workspace owns keyboard actions while open. Do not interfere with text entry or Roblox menus.
 local actions=game:GetService("ContextActionService")
 local guiService=game:GetService("GuiService")
 local keyboardAction="AETHER_WorkspaceKeyboard_"..game:GetService("HttpService"):GenerateGUID(false)
 local afkPlayer=game:GetService("Players").LocalPlayer
 function self:setWorkspaceKeyboard(on)
  if on==self.workspaceKeyboardLocked then return end
  if on then
   local ok,err=pcall(function()
    actions:BindActionAtPriority(keyboardAction,function()
     if self.app.stopping or not self.opened or guiService.MenuIsOpen or Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
     return Enum.ContextActionResult.Sink
    end,false,Enum.ContextActionPriority.High.Value+1000,Enum.UserInputType.Keyboard)
   end)
   if not ok then self.app:log("Workspace input",tostring(err));return end
   self.workspaceKeyboardLocked=true
   -- Disabling the standard controller also clears movement held before the menu opened.
   -- Restore only a controller observed to be enabled before we disabled it.
   pcall(function()
    local scripts=afkPlayer and afkPlayer:FindFirstChild("PlayerScripts")
    local module=scripts and scripts:FindFirstChild("PlayerModule")
    if not module or not module:IsA("ModuleScript") then return end
    local controls=require(module):GetControls()
    if controls and controls.controlsEnabled==true and self.workspaceKeyboardLocked and self.opened then
     controls:Disable();self.workspaceDisabledControls=controls
    end
   end)
  else
   actions:UnbindAction(keyboardAction);self.workspaceKeyboardLocked=false
   local controls=self.workspaceDisabledControls;self.workspaceDisabledControls=nil
   if controls then pcall(function() controls:Enable() end) end
  end
 end
 scope:add(function() self:setWorkspaceKeyboard(false) end)
 -- Session-only full-screen AFK view, independent of the node canvas.
 self.afkEnabled=false;self.afkCommand="";self.afkTarget=false;self.afkProgress=0
 self.afkScreen=U.new("TextButton",{Name="AFKScreen",Text="",AutoButtonColor=false,Active=true,Modal=false,Visible=false,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=100},self.stage)
 self.afkGradient=U.gradient(self.afkScreen,Color3.fromRGB(9,8,17),Color3.fromRGB(27,20,43),90)
 local pattern=U.frame(self.afkScreen,"BackgroundPattern",nil,nil,nil,1)
 pattern.Active=false;pattern.Interactable=false;pattern.ClipsDescendants=true;pattern.ZIndex=1
 self.afkImage=U.new("ImageLabel",{Name="CustomBackground",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ImageTransparency=1,ScaleType=Enum.ScaleType.Crop,Visible=false,Active=false,Interactable=false},pattern)
 self.afkDecor={}
 local function addDecor(style,frame,stroke,alpha)
  frame.Active=false;frame.Interactable=false;frame.Visible=false
  self.afkDecor[#self.afkDecor+1]={style=style,frame=frame,stroke=stroke,alpha=alpha}
 end
 for i=1,36 do
  local r=if i%7==0 then 3 else 2
  local dot=U.frame(pattern,"AFKStar",UDim2.fromScale((i*.6180339)%1,(i*.4142135)%1),UDim2.fromOffset(r,r),Color3.new(1,1,1),1)
  dot.AnchorPoint=Vector2.new(.5,.5);U.corner(dot,8)
  addDecor("Stars",dot,nil,.35+(i%5)*.12)
 end
 for i=1,19 do
  local v=U.frame(pattern,"GridVertical",UDim2.fromScale(i/20,0),UDim2.new(0,1,1,0),Color3.new(1,1,1),1)
  addDecor("Grid",v,nil,.35)
 end
 for i=1,11 do
  local h=U.frame(pattern,"GridHorizontal",UDim2.fromScale(0,i/12),UDim2.new(1,0,0,1),Color3.new(1,1,1),1)
  addDecor("Grid",h,nil,.35)
 end
 for i=1,5 do
  local ring=U.frame(pattern,"Orbit",UDim2.fromScale(.5,.5),UDim2.fromScale(.23+i*.17,.23+i*.17),nil,1)
  ring.AnchorPoint=Vector2.new(.5,.5);U.new("UIAspectRatioConstraint",{AspectRatio=1,DominantAxis=Enum.DominantAxis.Height},ring);U.new("UICorner",{CornerRadius=UDim.new(.5,0)},ring)
  addDecor("Orbits",ring,U.stroke(ring,Color3.new(1,1,1),1,1),.65-i*.06)
 end
 self.afkBrand=U.label(self.afkScreen,"A E T H E R",14,UDim2.new(.5,0,.5,-100),UDim2.new(1,-24,0,24))
 self.afkBrand.AnchorPoint=Vector2.new(.5,.5);self.afkBrand.TextXAlignment=Enum.TextXAlignment.Center;self.afkBrand.ZIndex=2
 self.afkTitle=U.label(self.afkScreen,"AFK",46,UDim2.fromScale(.5,.5),UDim2.new(1,-24,0,68))
 self.afkTitle.AnchorPoint=Vector2.new(.5,.5);self.afkTitle.TextXAlignment=Enum.TextXAlignment.Center;self.afkTitle.ZIndex=2
 self.afkDetail=U.label(self.afkScreen,"",14,UDim2.new(.5,0,.5,54),UDim2.new(1,-32,0,42))
 self.afkDetail.AnchorPoint=Vector2.new(.5,.5);self.afkDetail.TextXAlignment=Enum.TextXAlignment.Center;self.afkDetail.TextWrapped=true;self.afkDetail.ZIndex=2
 self.afkBack=U.button(self.afkScreen,"RETURN TO WORKSPACE")
 self.afkBack.AnchorPoint=Vector2.new(.5,.5);self.afkBack.Position=UDim2.new(.5,0,.5,122);self.afkBack.Size=UDim2.fromOffset(210,38)
 self.afkBack.TextSize=12;self.afkBack.ZIndex=3;self.afkBack.AutoButtonColor=false
 self.afkBackRim=U.stroke(self.afkBack,Color3.fromRGB(183,151,240),1)
 function self:applyAFKTheme()
  local s=self.app.s
  local parts={s.afkBackground,s.afkBgA,s.afkBgB,s.afkPatternColor,s.afkBrandColor,s.afkTitleColor,s.afkDetailColor,s.afkButtonColor,s.afkButtonText,s.afkButtonEdge,s.afkImageTint,s.afkGradientAngle,s.afkPatternOpacity,s.afkImageOpacity,s.afkImageAsset}
  for _,role in {"AFK","AFKButton"} do for _,suffix in {"Custom","Color","Transparency","Edge","EdgeTransparency","EdgeWidth"} do parts[#parts+1]=tostring(s["appearance"..role..suffix]) end end
  for _,role in {"AFK","AFKButton"} do for _,extra in S.appearanceExtras[role] do parts[#parts+1]=tostring(s[extra.key]);parts[#parts+1]=tostring(s[extra.flag]) end end
  local key=scalarKey(parts)
  if self.afkThemeKey==key then return end
  self.afkThemeKey=key
  local a,b=U.hex(if s.appearanceAFKCustom then s.appearanceAFKColor else s.afkBgA),U.appearanceColor(s,"AFK","GradientEnd",U.hex(s.afkBgB))
  self.afkGradient.Color=ColorSequence.new(a,if s.afkBackground=="Solid" then a else b)
  self.afkGradient.Rotation=s.afkGradientAngle
  self.afkBrand.TextColor3=U.hex(s.afkBrandColor);self.afkTitle.TextColor3=U.hex(s.afkTitleColor);self.afkDetail.TextColor3=U.hex(s.afkDetailColor)
  local button,_,edge,_,width=U.blockStyle(s,"AFKButton",U.hex(s.afkButtonColor),.12,U.hex(s.afkButtonEdge),.45,1)
  self.afkBack.BackgroundColor3=button;self.afkBack.TextColor3=U.appearanceText(s,"AFKButton",false,U.hex(s.afkButtonText));self.afkBackRim.Color=edge;self.afkBackRim.Thickness=width
  local _,_,screenEdge,screenAlpha,screenWidth=U.blockStyle(s,"AFK",U.hex(s.afkBgA),0,U.hex(s.afkButtonEdge),1,1)
  local rim=self.afkScreen:FindFirstChildOfClass("UIStroke") or U.stroke(self.afkScreen,screenEdge,1,screenWidth)
  rim.Color=screenEdge;rim.Thickness=screenWidth;rim.Enabled=screenWidth>0 and screenAlpha<1
  self.afkImage.ImageColor3=U.hex(s.afkImageTint)
  self.afkImage.Image=if s.afkBackground=="Image" and s.afkImageAsset~="" then "rbxassetid://"..s.afkImageAsset else ""
  self.afkImage.Visible=s.afkBackground=="Image" and s.afkImageAsset~=""
  local color=U.hex(s.afkPatternColor)
  for _,p in self.afkDecor do
   p.frame.Visible=p.style==s.afkBackground
   if p.stroke then p.stroke.Color=color else p.frame.BackgroundColor3=color end
  end
  self.afkLastAlpha=nil
 end
 function self:paintAFK(alpha)
  if self.afkLastAlpha==alpha then return end
  self.afkLastAlpha=alpha
  local s=self.app.s
  local _,screenAlpha,_,screenEdgeAlpha=U.blockStyle(s,"AFK",U.hex(s.afkBgA),0,U.hex(s.afkButtonEdge),1,1)
  local _,buttonAlpha,_,edgeAlpha,edgeWidth=U.blockStyle(s,"AFKButton",U.hex(s.afkButtonColor),.12,U.hex(s.afkButtonEdge),.45,1)
  self.afkScreen.BackgroundTransparency=1-alpha*(1-screenAlpha)
  local rim=self.afkScreen:FindFirstChildOfClass("UIStroke");if rim then rim.Transparency=1-alpha*(1-screenEdgeAlpha) end
  for _,label in {self.afkBrand,self.afkTitle,self.afkDetail,self.afkBack} do label.TextTransparency=1-alpha end
  self.afkBack.BackgroundTransparency=1-alpha*(1-buttonAlpha)
  self.afkBackRim.Transparency=1-alpha*(1-edgeAlpha);self.afkBackRim.Enabled=edgeWidth>0 and edgeAlpha<1
  self.afkImage.ImageTransparency=1-alpha*s.afkImageOpacity/100
  for _,p in self.afkDecor do
   if p.frame.Visible then
    local transparency=1-alpha*s.afkPatternOpacity/100*p.alpha
    if p.stroke then p.stroke.Transparency=transparency else p.frame.BackgroundTransparency=transparency end
   end
  end
 end
 function self:stepAFK(dt)
  if not self.afkScreen.Visible then return end
  local s=self.app.s
  local target=if self.afkTarget then 1 else 0
  local delta=dt/math.max(.1,s.afkFadeMs/1000)
  if s.reduce then self.afkProgress=target
  elseif self.afkProgress<target then self.afkProgress=math.min(target,self.afkProgress+delta)
  elseif self.afkProgress>target then self.afkProgress=math.max(target,self.afkProgress-delta) end
  self:paintAFK(U.ease(self.afkProgress,"Sine"))
  if not self.afkTarget and self.afkProgress<=0 then
   self.afkScreen.Visible=false;self.afkScreen.Modal=false;self.afkScreen.Interactable=false
   if self.panel then self.panel.Interactable=self.opened end
  end
 end
 local function afkFailure(message,err)
  self.afkEnabled=false;self.afkVirtualUser=nil
  self.afkDetail.Text=message
  self.app:log("AFK",tostring(err or message))
 end
 function self:setAFK(on,preview)
  self.afkEnabled=false;self.afkVirtualUser=nil;self.afkCommand=""
  self.afkTarget=on==true
  self.afkBack.Interactable=self.afkTarget
  if not on then
   self.afkScreen.Modal=self.opened and self.afkScreen.Visible
   self.afkScreen.Interactable=self.opened and self.afkScreen.Visible
   if self.app.s.reduce then self:stepAFK(0) end
   return
  end
  self:applyAFKTheme();self:paintAFK(U.ease(self.afkProgress,"Sine"))
  self.afkScreen.Visible=true;self.afkScreen.Interactable=true;self.afkScreen.Modal=true
  if self.panel then self.panel.Interactable=false end
  self.drag=nil;self.workspacePan=nil;self:finishWorkspaceNode();self:clearWorkspaceSparks();self:commitWorkspaceCamera()
  if self.app.s.reduce then self:stepAFK(0) end
  if preview then self.afkDetail.Text="Appearance preview";return end
  if not afkPlayer or self.app.mode~="Game" then afkFailure("AFK unavailable outside game mode");return end
  local ok,err=pcall(function()
   self.afkVirtualUser=game:GetService("VirtualUser")
   self.afkVirtualUser:CaptureController()
  end)
  if not ok then afkFailure("Anti-AFK unavailable: input access denied",err);return end
  self.afkEnabled=true;self.afkDetail.Text="Anti-AFK enabled"
 end
 scope:on(self.afkBack.Activated,function() self:setAFK(false) end)
 if afkPlayer then
  scope:on(afkPlayer.Idled,function()
   if not self.afkEnabled or self.app.stopping then return end
   local ok,err=pcall(function()
    self.afkVirtualUser:CaptureController()
    self.afkVirtualUser:ClickButton2(Vector2.zero)
   end)
   if not ok then afkFailure("Anti-AFK stopped: input access denied",err) end
  end)
 end
 scope:add(function() self.afkEnabled=false;self.afkVirtualUser=nil end)
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
   b.button.BackgroundColor3=if st.appearanceNavButtonCustom then U.hex(st.appearanceNavButtonColor):Lerp(U.hex(st.uiHoverColor),if open then .32 else 0) else U.hex(if open then st.uiHoverColor else st.uiButtonColor)
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
  if self.layoutAppearance then self:layoutAppearance() end
 end
 self.search=U.new("TextBox",{Name="FunctionSearch",Text="",PlaceholderText="Search functions...",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(241,234,255),PlaceholderColor3=dim,BackgroundColor3=soft,BorderSizePixel=0},self.panel)
 U.corner(self.search,8);U.new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},self.search)
 self.navGlass=U.frame(self.panel,"TabRailGlass",nil,nil,Color3.fromRGB(25,20,45),.53);U.corner(self.navGlass,18);U.stroke(self.navGlass,Color3.fromRGB(184,151,243),.68);self.navGlass.Active=false;self.navGlass.Interactable=false
 self.nav.ZIndex=4
 self.contentGlass=U.frame(self.panel,"ContentGlass",nil,nil,Color3.fromRGB(25,20,45),.55);U.corner(self.contentGlass,18);U.stroke(self.contentGlass,Color3.fromRGB(184,151,243),.68);self.contentGlass.Active=false;self.contentGlass.Interactable=false
 self.pageBox.ZIndex=3;self.search.ZIndex=4
 self.searchResults=U.new("ScrollingFrame",{Name="FunctionSearchResults",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Never,ScrollBarThickness=4,Visible=false},self.panel)
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
 -- Fixed screen-space pool: no new GUI instances or tweens during a slide.
 self.slideSparkLayer=U.frame(self.panel,"WorkspaceSlideSparks",nil,UDim2.fromScale(1,1),nil,1)
 self.slideSparkLayer.Active=false;self.slideSparkLayer.Interactable=false;self.slideSparkLayer.ZIndex=8
 self.slideSparkPool={};self.slideSparkCursor=0;self.slideSparkActive=0
 for i=1,24 do
  local spark=U.frame(self.slideSparkLayer,"SlideSpark",nil,UDim2.fromOffset(6,2),Color3.new(1,1,1),0)
  spark.AnchorPoint=Vector2.new(.5,.5);spark.Active=false;spark.Interactable=false;spark.ZIndex=8;spark.Visible=false
  U.corner(spark,2)
  self.slideSparkPool[i]={frame=spark,age=0,life=0}
 end
 self.linkPool={};self.portPool={}
 -- Use pooled GUI segments for all wires. Path2D can lose its rendered
 -- geometry after a CanvasGroup fade or a change of the viewport.
 self.workspaceLinks.ClipsDescendants=true
 for i=1,14 do
  local port=U.frame(self.workspaceLinks,"NodePort",nil,UDim2.fromOffset(7,7),Color3.new(1,1,1),.06)
  port.AnchorPoint=Vector2.new(.5,.5);port.Active=false;port.Interactable=false;port.ZIndex=2;port.Visible=false;U.corner(port,9);self.portPool[i]=port
 end
 for _,obj in {self.navGlass,self.nav,self.branchStack,self.contentGlass,self.pageBox,self.search,self.searchResults,self.status,self.layoutMove,self.layoutResize,self.layoutDone} do obj.Parent=self.workspace end
 -- Drag headers are inset hit targets inside a single continuous glass silhouette.
 local function integratedHeader(text)
  local b=U.button(self.workspace,text)
  b.ZIndex=5;b.TextSize=11;b.BackgroundTransparency=1;b.AutoButtonColor=false
  b:SetAttribute("AETHERThemeButton",false)
  local rule=U.frame(b,"HeaderDivider",UDim2.new(0,5,1,0),UDim2.new(1,-10,0,1),Color3.new(1,1,1),.82)
  rule.ZIndex=5;rule.Active=false;rule.Interactable=false
  return b
 end
 self.rootDrag=integratedHeader("AETHER / MOVE")
 self.pageDrag=integratedHeader("MOVE PANEL")
 -- Independent glass node with its own saved position in both workspaces.
 self.appearancePanel=U.frame(self.branchStack,"AppearanceSamples",nil,UDim2.new(1,0,0,0),nil,1)
 self.appearancePanel.ZIndex=4;self.appearancePanel.Visible=false
 U.corner(self.appearancePanel,16)
 self.appearancePanel.Active=true
 self.appearanceDrag=U.label(self.appearancePanel,"APPEARANCE / MOVE",11,UDim2.fromOffset(9,4),UDim2.new(1,-18,0,24))
 self.appearanceDrag.ZIndex=6;self.appearanceDrag.Active=true;self.appearanceDrag.TextXAlignment=Enum.TextXAlignment.Center
 local rule=U.frame(self.appearancePanel,"HeaderDivider",UDim2.fromOffset(9,29),UDim2.new(1,-18,0,1),Color3.new(1,1,1),.82)
 rule.ZIndex=5;rule.Active=false;rule.Interactable=false
 self.appearanceSamples={}
 local all=U.button(self.appearancePanel,"ALL SETTINGS");self.appearanceAll=all;all.Size=UDim2.new(1,-16,0,25);all.Position=UDim2.fromOffset(8,36);all.ZIndex=5;all.TextSize=10
 scope:on(all.Activated,function() self:open("Interface") end)
 for i,d in S.appearance do
  local b=U.button(self.appearancePanel,d[2]);b.Name="Style_"..d[1];b.ZIndex=5;b.TextSize=10;b.AutoButtonColor=false
  b.Position=UDim2.new(((i-1)%2)*.5,if i%2==1 then 8 else 2,0,67+math.floor((i-1)/2)*29)
  b.Size=UDim2.new(.5,-10,0,25);b.TextTruncate=Enum.TextTruncate.AtEnd
  b:SetAttribute("AETHERKeepFontColor",true);b:SetAttribute("AETHERThemeButton",false)
  U.stroke(b,Color3.new(1,1,1),1)
  self.appearanceSamples[d[1]]=b
  scope:on(b.Activated,function() if self.opened then self:open("Interface",d[1]) end end)
 end
 self.appearancePanel.Size=UDim2.new(1,0,0,72+math.ceil(#S.appearance/2)*29)
 self.stylePreview=U.frame(self.branchStack,"StylePreviewNode",nil,UDim2.fromOffset(500,338),nil,1)
 self.stylePreview.ZIndex=4;self.stylePreview.Visible=false;self.stylePreview.Active=true;U.corner(self.stylePreview,16)
 self.stylePreviewDrag=U.label(self.stylePreview,"LIVE PREVIEW / MOVE",11,UDim2.fromOffset(10,4),UDim2.new(1,-20,0,26))
 self.stylePreviewDrag.ZIndex=6;self.stylePreviewDrag.Active=true;self.stylePreviewDrag.TextXAlignment=Enum.TextXAlignment.Center
 local previewRule=U.frame(self.stylePreview,"HeaderDivider",UDim2.fromOffset(10,31),UDim2.new(1,-20,0,1),Color3.new(1,1,1),.82)
 previewRule.ZIndex=5;previewRule.Interactable=false
 self.stylePreviewName=U.label(self.stylePreview,"ROOT NODE",13,UDim2.fromOffset(12,37),UDim2.new(1,-24,0,22))
 self.stylePreviewName.ZIndex=5
 self.stylePreviewStage=U.frame(self.stylePreview,"AppearancePreviewStage",UDim2.fromOffset(10,65),UDim2.new(1,-20,1,-100),Color3.fromRGB(68,64,80),0)
 self.stylePreviewStage.ZIndex=5;self.stylePreviewStage.ClipsDescendants=true;U.corner(self.stylePreviewStage,12)
 U.gradient(self.stylePreviewStage,Color3.fromRGB(85,77,100),Color3.fromRGB(28,28,43),45)
 -- The neutral background makes transparent fills visible. Samples never invoke actions.
 for i=1,7 do
  local line=U.frame(self.stylePreviewStage,"Guide",UDim2.fromScale(i/8,0),UDim2.new(0,1,1,0),Color3.new(1,1,1),.93)
  line.ZIndex=6;line.Interactable=false
 end
 for i=1,3 do
  local line=U.frame(self.stylePreviewStage,"Guide",UDim2.fromScale(0,i/4),UDim2.new(1,0,0,1),Color3.new(1,1,1),.93)
  line.ZIndex=6;line.Interactable=false
 end
 self.stylePreviewContent=U.frame(self.stylePreviewStage,"SampleContent",nil,nil,nil,1)
 self.stylePreviewContent.ZIndex=7;self.stylePreviewContent.Interactable=false
 self.stylePreviewInfo=U.label(self.stylePreview,"",10,UDim2.new(0,12,1,-28),UDim2.new(1,-24,0,20));self.stylePreviewInfo.ZIndex=5
 function self:layoutAppearance()
  local visible=self.branchCards.Interface.expanded
  self.appearancePanel.Visible=visible;self.stylePreview.Visible=visible
  local pos=workspaceOffset(self,"Appearance")
  self.appearancePanel.Position=UDim2.fromOffset(pos.X,pos.Y)
  local previewPos=workspaceOffset(self,"Preview")
  self.stylePreview.Position=UDim2.fromOffset(previewPos.X,previewPos.Y)
 end
 function self:refreshStylePreview()
  local s=self.app.s
  local id=self.appearanceSelection or self.stylePreviewRole or "Root"
  local d=S.appearanceById[id] or S.appearanceById.Root
  self.stylePreviewRole=d[1];id=d[1]
  self.stylePreviewName.Text=U.tr(s,d[2]:upper())
  local c,t,e,et,w=U.appearanceSample(s,d)
  self.stylePreviewInfo.Text=string.format("#%s · %d%% transparent  /  EDGE %.1f px · %d%% transparent",c:ToHex():upper(),math.round(t*100),w,math.round(et*100))
  local parts={id,s.language,s.secondary,s.moduleAccentColor,s.fontGradient,s.fontA,s.fontB,s.font,s.fontAsset,s.weight,s.uiFontColor,s.uiMutedColor,s.uiPanelColor,s.uiGlassOpacity,s.uiStrokeColor,s.uiSpecularColor,s.uiReflection,s.rim,s.uiButtonColor,s.uiHoverColor,s.uiRowColor,s.clockGlass,s.fpsGlass,s.clockText,s.fpsText,s.glassColor,s.glass,s.moduleTextColor,s.moduleMutedColor,s.modulePanelColor,s.moduleRowColor,s.moduleToggleOnColor,s.moduleToggleOffColor,s.moduleStrokeColor,s.moduleBackgroundOpacity,s.afkBgA,s.afkBgB,s.afkBackground,s.afkGradientAngle,s.afkTitleColor,s.afkBrandColor,s.afkDetailColor,s.afkButtonColor,s.afkButtonText,s.afkButtonEdge,s.afkPatternColor,s.afkPatternOpacity,s.afkImageAsset,s.afkImageOpacity,s.afkImageTint,s.inputColor}
  for _,role in S.appearance do
   local p="appearance"..role[1]
   for _,suffix in {"Custom","Color","Transparency","Edge","EdgeTransparency","EdgeWidth"} do parts[#parts+1]=tostring(s[p..suffix]) end
   for _,extra in S.appearanceExtras[role[1]] do parts[#parts+1]=tostring(s[extra.key]);parts[#parts+1]=tostring(s[extra.flag]) end
  end
  local key=scalarKey(parts)
  if key==self.stylePreviewKey then return end
  local host=self.stylePreviewContent
  -- Reuse sample geometry for slider changes; rebuild only when the selected kind changes.
  if self.stylePreviewBuilt~=id then
   host:ClearAllChildren();self.stylePreviewBuilt=nil;self.stylePreviewPaint={}
   local function block(parent,role,name,x,y,width,height,radius)
    local f=U.frame(parent,name,UDim2.fromOffset(x,y),UDim2.fromOffset(width,height),nil,1)
    f.ZIndex=parent.ZIndex+1;f.Interactable=false;U.corner(f,radius or 10)
    f:SetAttribute("AETHERAppearanceRole",role)
    table.insert(self.stylePreviewPaint,{frame=f,role=role})
    return f
   end
   local function label(parent,text,x,y,width,height,size,colorKey)
    local l=U.label(parent,U.tr(s,text),size,UDim2.fromOffset(x,y),UDim2.fromOffset(width,height))
    l.ZIndex=parent.ZIndex+1;l.Interactable=false;l.TextXAlignment=Enum.TextXAlignment.Center;l:SetAttribute("AETHERKeepFontColor",true)
    table.insert(self.stylePreviewPaint,{label=l,sourceText=text,colorKey=colorKey or "uiFontColor",role=parent:GetAttribute("AETHERAppearanceRole") or id,muted=colorKey=="uiMutedColor" or colorKey=="moduleMutedColor" or y>=40 and (id=="Clock" or id=="FPS")})
    return l
   end
   local function centerBox(role,width,height)
    local f=block(host,role,"Sample",0,0,width,height,14)
    f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5)
    return f
   end
   if id=="Clock" or id=="FPS" then
    local f=centerBox(id,190,86)
    label(f,if id=="Clock" then "12:00" else "120 FPS",12,9,166,39,27,if id=="Clock" then "clockText" else "fpsText")
    label(f,if id=="Clock" then "AETHER · TIME" else "PERFORMANCE",10,51,170,22,12,if id=="Clock" then "clockText" else "fpsText")
    if id=="FPS" then
     local dot=U.frame(f,"StatusDot",UDim2.fromOffset(14,16),UDim2.fromOffset(8,8),U.hex(s.secondary),0);dot.ZIndex=f.ZIndex+1;U.corner(dot,8);dot.Interactable=false
     table.insert(self.stylePreviewPaint,{tintFrame=dot,colorKey="secondary"})
    end
   elseif id=="Input" then
    local f=U.frame(host,"Keyboard",UDim2.fromScale(.5,.5),UDim2.fromOffset(230,156),nil,1);f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=8
    for _,v in {{"W",83,4,58},{"SHIFT",146,4,76},{"A",20,55,58},{"S",83,55,58},{"D",146,55,58},{"SPACE",20,106,184}} do
     local k=block(f,"Input","Key",v[2],v[3],v[4],44,8);label(k,v[1],0,0,v[4],44,13)
     if v[1]=="W" then table.insert(self.stylePreviewPaint,{tintFrame=k,colorKey="inputColor"}) end
    end
   elseif id=="Quick" or id=="QuickRow" or id=="QuickOn" or id=="QuickOff" then
    local f=centerBox("Quick",300,184)
    label(f,"MODULES / PREVIEW",8,4,284,24,12,"moduleTextColor")
    local accentMark=U.frame(f,"Accent",UDim2.fromOffset(12,27),UDim2.fromOffset(276,2),U.hex(s.moduleAccentColor),0);accentMark.ZIndex=f.ZIndex+1;accentMark.Interactable=false
    table.insert(self.stylePreviewPaint,{tintFrame=accentMark,colorKey="moduleAccentColor"})
    for i,name in {"Example module","Visual setting","Sample toggle"} do
     local row=block(f,"QuickRow","ModuleRow",10,31+(i-1)*46,280,39,8)
     label(row,name,6,0,174,39,12,"moduleTextColor")
     local sw=block(row,if i==2 then "QuickOff" else "QuickOn","State",202,6,61,27,8)
     label(sw,if i==2 then "OFF" else "ON",0,0,61,27,11,"moduleTextColor")
    end
   elseif id=="AFK" or id=="AFKButton" then
    local f=centerBox("AFK",390,212);f.ClipsDescendants=true
    local pattern=U.frame(f,"Pattern",nil,nil,nil,1);pattern.ZIndex=f.ZIndex+1;pattern.Interactable=false
    local pic=U.new("ImageLabel",{Name="Picture",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Crop,ZIndex=pattern.ZIndex,Interactable=false},pattern)
    self.stylePreviewAFKPicture=pic
    self.stylePreviewAFKStars={};self.stylePreviewAFKGrid={};self.stylePreviewAFKOrbits={}
    for i=1,9 do
     local v=U.frame(pattern,"Grid",UDim2.fromScale(i/10,0),UDim2.new(0,1,1,0),nil,1);v.ZIndex=pattern.ZIndex;v.Interactable=false;table.insert(self.stylePreviewAFKGrid,v)
    end
    for i=1,5 do
     local v=U.frame(pattern,"Grid",UDim2.fromScale(0,i/6),UDim2.new(1,0,0,1),nil,1);v.ZIndex=pattern.ZIndex;v.Interactable=false;table.insert(self.stylePreviewAFKGrid,v)
    end
    for i=1,4 do
     local v=U.frame(pattern,"Orbit",UDim2.fromScale(.5,.5),UDim2.fromOffset(38+i*50,38+i*50),nil,1);v.AnchorPoint=Vector2.new(.5,.5);v.ZIndex=pattern.ZIndex;v.Interactable=false;U.new("UICorner",{CornerRadius=UDim.new(.5,0)},v)
     table.insert(self.stylePreviewAFKOrbits,{frame=v,stroke=U.stroke(v,Color3.new(1,1,1),1,1)})
    end
    for i=1,24 do
     local dot=U.frame(pattern,"Star",UDim2.fromScale((i*.618)%1,(i*.413)%1),UDim2.fromOffset(2,2),Color3.new(1,1,1),0);dot.ZIndex=pattern.ZIndex;U.corner(dot,2);self.stylePreviewAFKStars[i]=dot
    end
    label(f,"A E T H E R",0,28,390,22,12,"afkBrandColor")
    label(f,"AFK",0,57,390,52,38,"afkTitleColor")
    label(f,"Appearance preview",0,111,390,23,13,"afkDetailColor")
    local b=block(f,"AFKButton","Return",100,153,190,34,10);label(b,"RETURN TO WORKSPACE",0,0,190,34,11,"afkButtonText")
   elseif id=="Keybind" or id=="Wallhop" then
    local f=centerBox(id,265,110)
    label(f,if id=="Keybind" then "KEYBINDS" else "PRACTICE DISPLAY",8,6,249,25,13)
    label(f,if id=="Keybind" then "No keybinds assigned" else "READY",8,40,249,30,18)
    label(f,"Preview only",8,78,249,20,11,"uiMutedColor")
   elseif id=="Top" or id=="Dock" or id=="Header" then
    local f=centerBox(id,if id=="Header" then 340 else 194,52)
    label(f,"A E T H E R",0,0,f.Size.X.Offset,52,16)
   elseif id=="Search" or id=="NavButton" or id=="TabButton" or id=="Row" or id=="Button" then
    local f=centerBox(id,270,48)
    label(f,if id=="Search" then "Search functions..." elseif id=="Row" then "Example setting" else d[2],10,0,250,48,15,if id=="Search" then "uiMutedColor" else "uiFontColor")
   elseif id=="Modes" then
    local f=centerBox(id,330,48)
    for i,text in {"GUI VIEW","NODE VIEW","HOME"} do
     local b=block(f,"Button","Option",6+(i-1)*108,7,102,34,8);label(b,text,0,0,102,34,11)
    end
   else
    local f=centerBox(id,300,204)
    label(f,d[2]:upper(),8,4,284,24,13)
    for i,text in {"Appearance","Example setting","Interface option"} do
     local b=block(f,if id=="Root" then "NavButton" elseif id=="Page" then "Row" else "TabButton","Example",12,33+(i-1)*53,276,43,9)
     label(b,text,0,0,276,43,14)
    end
   end
  end
  local glassRoles={Root=true,Appearance=true,Preview=true,Main=true,Visuals=true,Utility=true,Interface=true,Page=true,Header=true,Modes=true,Catalog=true,Top=true,Keybind=true}
  for _,p in self.stylePreviewPaint do
   if p.tintFrame then p.tintFrame.BackgroundColor3=U.hex(s[p.colorKey])
   elseif p.label then
    p.label.Text=U.tr(s,p.sourceText);p.label.TextColor3=U.appearanceText(s,p.role,p.muted,U.hex(s[p.colorKey]));p.label.FontFace=U.font(s)
    if p.role=="Clock" or p.role=="FPS" then
     local flag="appearance"..p.role..(if p.muted then "Muted" else "Text").."Custom"
     local gradient=p.label:FindFirstChildOfClass("UIGradient") or U.gradient(p.label,U.hex(s.fontA),U.hex(s.fontB),0)
     gradient.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB));gradient.Enabled=s.fontGradient and not s[flag]
     if gradient.Enabled then p.label.TextColor3=Color3.new(1,1,1) end
    end
   else
    local role=p.role;local spec=S.appearanceById[role]
    local fill,alpha,edge,edgeAlpha,width=U.appearanceSample(s,spec)
    if glassRoles[role] then glassSurface(p.frame,s,role)
    else
     p.frame.BackgroundColor3=fill;p.frame.BackgroundTransparency=alpha
     local rim=p.frame:FindFirstChildOfClass("UIStroke") or U.stroke(p.frame,edge,edgeAlpha,width)
     rim.Color=edge;rim.Transparency=edgeAlpha;rim.Thickness=width;rim.Enabled=width>0 and edgeAlpha<1
     if role=="AFK" then
      p.frame.BackgroundColor3=Color3.new(1,1,1)
      local grad=p.frame:FindFirstChildOfClass("UIGradient") or U.gradient(p.frame,fill,fill)
      grad.Color=ColorSequence.new(fill,if s.afkBackground=="Solid" then fill else U.appearanceColor(s,"AFK","GradientEnd",U.hex(s.afkBgB)));grad.Rotation=s.afkGradientAngle
     elseif role=="Clock" or role=="FPS" or role=="Dock" or role=="Quick" then
      p.frame.BackgroundColor3=Color3.new(1,1,1)
      local grad=p.frame:FindFirstChildOfClass("UIGradient") or U.gradient(p.frame,fill,fill)
      grad.Color=ColorSequence.new(fill,U.appearanceColor(s,role,"GradientEnd",fill:Lerp(Color3.fromRGB(17,16,30),.5)));grad.Rotation=90
     end
    end
   end
  end
  if id=="AFK" or id=="AFKButton" then
   local pic=self.stylePreviewAFKPicture
   pic.Visible=s.afkBackground=="Image" and s.afkImageAsset~=""
   pic.Image=if pic.Visible then "rbxassetid://"..s.afkImageAsset else ""
   pic.ImageColor3=U.hex(s.afkImageTint);pic.ImageTransparency=1-s.afkImageOpacity/100
   for _,dot in self.stylePreviewAFKStars do dot.Visible=s.afkBackground=="Stars";dot.BackgroundColor3=U.hex(s.afkPatternColor);dot.BackgroundTransparency=1-s.afkPatternOpacity/100 end
   for _,line in self.stylePreviewAFKGrid do line.Visible=s.afkBackground=="Grid";line.BackgroundColor3=U.hex(s.afkPatternColor);line.BackgroundTransparency=1-.35*s.afkPatternOpacity/100 end
   for _,ring in self.stylePreviewAFKOrbits do ring.frame.Visible=s.afkBackground=="Orbits";ring.stroke.Color=U.hex(s.afkPatternColor);ring.stroke.Transparency=1-.55*s.afkPatternOpacity/100 end
  end
  self.stylePreviewBuilt=id;self.stylePreviewKey=key
 end
 function self:refreshAppearanceSamples()
  local s=self.app.s
  for _,d in S.appearance do
   local b=self.appearanceSamples[d[1]]
   local c,t,e,et,w=U.appearanceSample(s,d)
   b.BackgroundColor3=c;b.BackgroundTransparency=t
   local rim=b:FindFirstChildOfClass("UIStroke")
   rim.Color=e;rim.Transparency=et;rim.Thickness=w;rim.Enabled=w>0 and et<1
   b.TextColor3=U.hex(if d[1]=="Quick" or d[1]:sub(1,5)=="Quick" then s.moduleTextColor elseif d[1]=="Clock" then s.clockText elseif d[1]=="FPS" then s.fpsText elseif d[1]=="AFK" then s.afkTitleColor elseif d[1]=="AFKButton" then s.afkButtonText else s.uiFontColor)
   b.Text=(if self.appearanceSelection==d[1] then "› " else "")..U.tr(s,d[2])
  end
 end
 self.modeBar=U.frame(self.panel,"WorkspaceModes",nil,UDim2.fromOffset(320,30),nil,.5)
 self.modeBar.AnchorPoint=Vector2.new(.5,0);self.modeBar.ZIndex=12;U.corner(self.modeBar,14)
 self.modeButtons={}
 for i,mode in {"GUI","Nodes"} do
  local b=U.button(self.modeBar,if mode=="GUI" then "GUI VIEW" else "NODE VIEW")
  b.Position=UDim2.new((i-1)*.4,4,0,3);b.Size=UDim2.new(.4,-5,1,-6);b.ZIndex=13;b.TextSize=11;self.modeButtons[mode]=b
  scope:on(b.Activated,function()
   if self.app.s.workspaceMode==mode then return end
   self:finishWorkspaceNode();self:clearWorkspaceSparks();self:commitWorkspaceCamera();self.drag=nil;self.workspacePan=nil
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
  for _,obj in {self.header,self.modeBar,self.navGlass,self.nav,self.search,self.contentGlass,self.pageBox,self.searchResults,self.status,self.rootDrag,self.pageDrag,self.layoutMove,self.layoutResize,self.layoutDone,self.appearancePanel,self.stylePreview} do
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
  if not self.opened or self.afkScreen.Visible or self.drag or self.workspacePan or self.layoutEditing or os.clock()<(self.tabInputAfter or 0) then self.backgroundTap=nil;return end
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
  local tab=if d.group=="Theme" or d.group=="Motion" or d.group=="HUD" then "Interface" elseif d.group=="Camera" then "Interaction" else d.group
  if k=="clockGlass" or k=="clockText" or k:match("^clock") then tab="Clock"
  elseif k=="fpsGlass" or k=="fpsText" or k:match("^profile") then tab="FPS"
  elseif k:match("^top") then tab="Top Panel"
  elseif k:match("^input") then tab="Input Display"
  elseif k:match("^cross") or k:match("^reticle") or k=="lockReticle" then tab="Reticle"
  elseif k:match("^keybind") then tab="Keybinds"
  elseif k:match("^quick") or k:match("^module") then tab="Quick Menu"
  elseif k:match("^wallhop") then tab="Practice Display" end
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
 self.quickOpen=false;self.quickProgress=0
 self.quickArrow=U.button(self.top,"")
 self.quickArrow.Name="VolleyballDropdown";self.quickArrow.AnchorPoint=Vector2.new(.5,0)
 self.quickArrow.Size=UDim2.fromOffset(36,24);self.quickArrow.Position=UDim2.new(.5,0,1,32)
 self.top.ZIndex=25;self.topButtons[1].ZIndex=26;self.updateChip.ZIndex=27;self.quickArrow.ZIndex=27
 self.quickGlyph=chevron(self.quickArrow)
 self.quick=U.new("Frame",{Name="VolleyballQuickPanel",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,1,58),Size=UDim2.fromOffset(324,380),BackgroundColor3=bg,BackgroundTransparency=.10,BorderSizePixel=0,Visible=false,Active=true,ZIndex=28},self.top)
 U.corner(self.quick,13);self.quickRim=U.stroke(self.quick,Color3.fromRGB(166,138,255),.3)
 self.quickGradient=U.gradient(self.quick,Color3.new(1,1,1),Color3.new(1,1,1),90)
 self.quick.BackgroundColor3=Color3.new(1,1,1)
 local title=U.label(self.quick,"VOLLEYBALL / MODULES",12,UDim2.fromOffset(12,5),UDim2.new(1,-88,0,22));title.ZIndex=29
 local edit=U.button(self.quick,"EDIT HUD");edit.Name="EditWidgetPositions";edit.Size=UDim2.fromOffset(68,23);edit.Position=UDim2.new(1,-76,0,5);edit.TextSize=10;edit.ZIndex=30
 scope:on(edit.Activated,function() if self.quickOpen and not self.app.editingHUD then self.app:editHUD(true,"Volleyball",true) end end)
 self.quickScroll=U.new("ScrollingFrame",{Name="QuickFunctions",Position=UDim2.fromOffset(8,32),Size=UDim2.new(1,-16,1,-60),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ZIndex=29},self.quick)
 U.new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},self.quickScroll)
 self.quickStatus=U.label(self.quick,"Tap a module to expand",10,UDim2.new(0,10,1,-24),UDim2.new(1,-20,0,20))
 self.quickStatus.ZIndex=29;self.quickStatus:SetAttribute("AETHERMuted",true)
 self.quickExpanded={}
 function self:applyQuickTheme()
  local s=self.app.s
  local panel,_,edge,_,width=U.blockStyle(s,"Quick",U.hex(s.modulePanelColor),1-s.moduleBackgroundOpacity/100,U.hex(s.moduleStrokeColor),.3,1)
  local row,accent=U.hex(s.moduleRowColor),U.hex(s.moduleAccentColor)
  local primary,muted=U.hex(s.moduleTextColor),U.hex(s.moduleMutedColor)
  self.quickRim.Thickness=width;self.quickRim.Enabled=width>0
  local on,off=U.hex(s.moduleToggleOnColor),U.hex(s.moduleToggleOffColor)
  self.quick.BackgroundColor3=Color3.new(1,1,1)
  self.quickGradient.Color=ColorSequence.new(panel:Lerp(edge,.06),U.appearanceColor(s,"Quick","GradientEnd",panel:Lerp(Color3.new(),.16)))
  self.quickRim.Color=edge;self.quickArrow.BackgroundColor3=row
  self.quickScroll.ScrollBarImageColor3=edge
  for _,line in self.quickGlyph:GetChildren() do if line:IsA("Frame") then line.BackgroundColor3=primary end end
  for _,obj in self.quick:GetDescendants() do
   local role=obj:GetAttribute("AETHERQuickRole")
   if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
    if not obj:GetAttribute("AETHERKeepFontColor") then
     local holder=obj.Parent
     local isColorValue=holder and S.defs[holder.Name] and S.defs[holder.Name].kind=="color" and obj:IsA("TextLabel")
     if not isColorValue then
      local isMuted=obj:GetAttribute("AETHERMuted") or obj==self.quickStatus
      local textRole=if role=="Switch" or obj.Text=="ON" or obj.Text=="OFF" then (if obj.Text=="ON" then "QuickOn" else "QuickOff") elseif obj.Name=="ExpandModule" or (holder and holder:GetAttribute("AETHERQuickRole")=="Row") then "QuickRow" else "Quick"
      obj.TextColor3=U.appearanceText(s,textRole,isMuted,U.appearanceText(s,"Quick",isMuted,if isMuted then muted else primary))
     end
    end
    if obj:IsA("TextButton") and obj.BackgroundTransparency<1 then
     if role=="Switch" or obj.Text=="ON" or obj.Text=="OFF" then
     local enabled=obj.Text=="ON"
     U.applyBlock(obj,s,if enabled then "QuickOn" else "QuickOff",if enabled then on else off,0,U.hex(s.moduleStrokeColor),1,1)
    
     elseif role=="Bind" then obj.BackgroundColor3=if obj.Text=="PRESS KEY" then accent else off
     elseif obj.Name=="ExpandModule" then U.applyBlock(obj,s,"QuickRow",row,0,U.hex(s.moduleStrokeColor),1,1)
     elseif obj.BackgroundColor3==U.hex(s.uiHoverColor) then obj.BackgroundColor3=accent
     else obj.BackgroundColor3=row end
    elseif obj:IsA("TextBox") and obj.BackgroundTransparency<1 then obj.BackgroundColor3=off end
   elseif obj:IsA("Frame") then
    if role=="Row" and obj.BackgroundTransparency<1 then U.applyBlock(obj,s,"QuickRow",row,.47,U.hex(s.moduleStrokeColor),1,1)
    elseif role=="Card" then obj.BackgroundColor3=panel
    elseif obj.Name=="Track" then obj.BackgroundColor3=off
    elseif obj.Name=="Fill" then obj.BackgroundColor3=accent
    elseif obj.Name=="Thumb" or (obj.Parent and obj.Parent.Name=="Chevron") then obj.BackgroundColor3=primary end
   elseif obj:IsA("UIStroke") and obj~=self.quickRim then
    if obj.Parent and obj.Parent:IsA("TextButton") then
     local button=obj.Parent
     local r=if button.Text=="ON" then "QuickOn" elseif button.Text=="OFF" then "QuickOff" elseif button.Name=="ExpandModule" then "QuickRow" else nil
     if not r or not s["appearance"..r.."Custom"] then obj.Color=edge end
    end
   end
  end
 end
 function self:stepQuick(dt,editingAux)
  local s=self.app.s
  local want=editingAux or (self.quickOpen and s.topCapsule and not self.app.editingHUD)
  local target=if want then 1 else 0
  local prev=self.quickProgress
  local step=dt/math.max(.08,s.moduleFadeMs/1000)
  if s.reduce or editingAux then self.quickProgress=target
  elseif prev<target then self.quickProgress=math.min(target,prev+step)
  elseif prev>target then self.quickProgress=math.max(target,prev-step) end
  local alpha=U.ease(self.quickProgress,"Sine")
  self.quick.Visible=want or self.quickProgress>0
  self.quick.Interactable=want and not editingAux
  local _,transparency,_,edgeTransparency,width=U.blockStyle(s,"Quick",U.hex(s.modulePanelColor),1-s.moduleBackgroundOpacity/100,U.hex(s.moduleStrokeColor),.3,1)
  self.quick.BackgroundTransparency=1-alpha*(1-transparency)
  self.quickRim.Transparency=1-alpha*(1-edgeTransparency);self.quickRim.Enabled=width>0 and edgeTransparency<1
  if self.quickProgress>0 and self.quickProgress<1 then
   transition(self.quick,alpha)
  elseif prev~=self.quickProgress or self.quick:FindFirstChild("AETHERTransitionSurface") then
   transition(self.quick,1)
  end
 end
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
 -- Keep scroll content in logical workspace units, not screen pixels.
 -- AutomaticCanvasSize under an ancestor UIScale can double-scale the list.
 function self:syncWorkspaceCanvas(sc)
  if not sc or not sc.Parent then return end
  local list=sc:FindFirstChildOfClass("UIListLayout")
  if not list then return end
  local z=math.max(.01,self.workspaceScale.Scale)
  local h=list.AbsoluteContentSize.Y/z
  local padding=sc:FindFirstChildOfClass("UIPadding")
  if padding then
   h+=padding.PaddingTop.Offset+padding.PaddingBottom.Offset+(padding.PaddingTop.Scale+padding.PaddingBottom.Scale)*sc.AbsoluteSize.Y/z
  end
  local size=UDim2.fromOffset(0,math.max(0,math.ceil(h)))
  if sc.CanvasSize~=size then sc.CanvasSize=size end
 end
 function self:freezeWorkspaceScroll()
  local oldZoom=math.max(.01,self.workspaceScale.Scale)
  if not self.scrollFreeze then
   self.scrollFreeze={}
   for _,sc in {self.sc,self.searchResults} do
    if sc and sc.Parent then
     local range=math.max(0,sc.AbsoluteCanvasSize.Y-sc.AbsoluteWindowSize.Y)
     self.scrollFreeze[sc]={logicalY=sc.CanvasPosition.Y/oldZoom,atBottom=range>0 and sc.CanvasPosition.Y>=range-1}
     sc.ScrollingEnabled=false
    end
   end
  end
  self.scrollFreezeFrames=3
 end
 function self:stepWorkspaceScroll()
  local frozen=self.scrollFreeze
  local ctrl=Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)
  local touch=Input:GetLastInputType()==Enum.UserInputType.Touch
  local pos=Input:GetMouseLocation()
  for _,sc in {self.sc,self.searchResults} do
   if sc and sc.Parent then
    self:syncWorkspaceCanvas(sc)
    local saved=frozen and frozen[sc]
    local parentVisible=sc~=self.sc or self.pageBox.Visible
    local enabled=self.opened and not self.afkScreen.Visible and parentVisible and sc.Visible and not frozen and not self.workspacePan and not self.drag and not ctrl and (touch or inside(sc,pos))
    if sc.ScrollingEnabled~=enabled then sc.ScrollingEnabled=enabled end
    if saved then
     local maxY=math.max(0,sc.AbsoluteCanvasSize.Y-sc.AbsoluteWindowSize.Y)
     local y=if saved.atBottom then maxY else math.clamp(saved.logicalY*self.workspaceScale.Scale,0,maxY)
     local position=Vector2.new(0,y)
     if sc.CanvasPosition~=position then sc.CanvasPosition=position end
    end
   end
  end
  if frozen then
   self.scrollFreezeFrames-=1
   if self.scrollFreezeFrames<=0 then self.scrollFreeze=nil end
  end
 end
 function self:applyWorkspaceCamera()
  local state=self:workspaceCamera()
  local position=UDim2.new(.5,state.pan.X*state.zoom,.5,state.pan.Y*state.zoom)
  if self.workspaceScale.Scale~=state.zoom then
   self:freezeWorkspaceScroll()
   self.workspaceScale.Scale=state.zoom
  end
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
  if node=="Appearance" or node=="Preview" then self:layoutAppearance() elseif node=="Root" or node=="Page" then self:layout() else self:refreshBranches(true) end
 end
 function self:finishWorkspaceNode(discard)
  local draft=self.workspaceNodeDraft
  self.workspaceNodeInertia=nil;self.workspaceNodeDraft=nil
  if not draft then return end
  if not discard then
   local prefix="ws"..draft.mode..draft.node
   local patch={[prefix.."X"]=math.round(draft.offset.X),[prefix.."Y"]=math.round(draft.offset.Y)}
   if draft.node=="Appearance" or draft.node=="Preview" then patch[prefix.."Custom"]=true end
   self.app:patch(patch)
  end
  self:layout()
 end
 function self:clearWorkspaceSparks()
  if self.slideSparkActive==0 then return end
  for _,p in self.slideSparkPool do p.life=0;p.frame.Visible=false end
  self.slideSparkActive=0
 end
 function self:emitWorkspaceSparks(slide,count)
  if self.app.s.reduce or not self.opened then return end
  local speed=slide.velocity.Magnitude*self.workspaceScale.Scale
  if speed<65 then return end
  local target=if slide.node=="Root" then self.rootDrag elseif slide.node=="Page" then self.pageDrag elseif slide.node=="Appearance" then self.appearanceDrag elseif slide.node=="Preview" then self.stylePreviewDrag else self.branchCards[slide.node].title
  if not target or not target.Visible or not target.Parent.Visible then return end
  local direction=slide.velocity.Unit
  local tangent=Vector2.new(-direction.Y,direction.X)
  local half=target.AbsoluteSize*.5
  local edgeDistance=math.min(half.X/math.max(.001,math.abs(direction.X)),half.Y/math.max(.001,math.abs(direction.Y)))
  local edge=target.AbsolutePosition+half-self.slideSparkLayer.AbsolutePosition-direction*(edgeDistance+3)
  local color=U.hex(self.app.s.accent):Lerp(Color3.new(1,1,1),.68)
  for i=1,count do
   self.slideSparkCursor=self.slideSparkCursor%#self.slideSparkPool+1
   local p=self.slideSparkPool[self.slideSparkCursor]
   if p.life<=0 then self.slideSparkActive+=1 end
   p.age=0;p.life=.13+math.random()*.12
   p.position=edge+tangent*((math.random()-.5)*math.min(16,half.Magnitude))
   p.velocity=-direction*(42+math.random()*70)+tangent*((math.random()-.5)*100)
   p.length=5+math.random()*6
   local f=p.frame
   f.Position=UDim2.fromOffset(p.position.X,p.position.Y)
   f.Size=UDim2.fromOffset(p.length,2)
   f.Rotation=math.deg(math.atan2(p.velocity.Y,p.velocity.X))
   f.BackgroundColor3=color;f.BackgroundTransparency=.08;f.Visible=true
  end
 end
 function self:stepWorkspaceSparks(dt)
  if self.slideSparkActive==0 then return end
  if not self.opened or self.app.s.reduce then self:clearWorkspaceSparks();return end
  for _,p in self.slideSparkPool do
   if p.life>0 then
    p.age+=dt
    if p.age>=p.life then
     p.life=0;p.frame.Visible=false;self.slideSparkActive-=1
    else
     local q=p.age/p.life
     p.position+=p.velocity*dt
     p.velocity*=math.exp(-5*dt)
     p.frame.Position=UDim2.fromOffset(p.position.X,p.position.Y)
     p.frame.Size=UDim2.fromOffset(math.max(1,p.length*(1-q)),math.max(1,2*(1-q)))
     p.frame.BackgroundTransparency=.08+.92*q
    end
   end
  end
 end
 function self:stepWorkspaceNode(dt)
  local slide=self.workspaceNodeInertia
  if not slide then return end
  if not self.opened or self.app.s.reduce or self.app.s.workspaceMode~=slide.mode then self:finishWorkspaceNode();return end
  local step=math.min(dt,math.max(0,.52-slide.elapsed))
  local decay=math.exp(-7.2*step)
  slide.offset+=slide.velocity*((1-decay)/7.2)
  slide.velocity*=decay;slide.elapsed+=step
  self:applyWorkspaceNode(slide.node,slide.offset)
  if slide.elapsed>=slide.sparkAt then
   slide.sparkAt=slide.elapsed+.045
   self:emitWorkspaceSparks(slide,2)
  end
  if slide.elapsed>=.52 or slide.velocity.Magnitude*self.workspaceScale.Scale<10 then self:finishWorkspaceNode() end
 end
 function self:resetWorkspace(all)
  self:finishWorkspaceNode(all);self:clearWorkspaceSparks()
  self.workspaceCameraDraft=nil;self.workspaceCameraRevision=(self.workspaceCameraRevision or 0)+1;self.workspaceNodeDraft=nil;self.workspacePan=nil;self.drag=nil
  local prefix=workspacePrefix(self.app.s)
  local patch={[prefix.."Zoom"]=100,[prefix.."PanX"]=0,[prefix.."PanY"]=0}
  if all then
   for _,node in {"Root","Main","Visuals","Utility","Interface","Page","Appearance","Preview"} do patch[prefix..node.."X"]=0;patch[prefix..node.."Y"]=0 end
   patch[prefix.."AppearanceCustom"]=false;patch[prefix.."PreviewCustom"]=false
  end
  self.app:patch(patch)
 end
 function self:updateWorkspaceLinks()
  local s=self.app.s
  self.workspaceLinks.Visible=s.workspaceMode=="Nodes"
  if not self.workspaceLinks.Visible then self.workspaceLinkKey=nil;return end
  local origin=self.workspaceLinks.AbsolutePosition
  local color=U.hex(s.accent):Lerp(Color3.new(1,1,1),.35);local lineIndex,portIndex=0,0
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
   -- Screen-space cubic segments remain visible across panning, zooming and fades.
   local p1=a+Vector2.new(curve,0);local p2=b-Vector2.new(curve,0)
   local prev=a;local steps=math.clamp(math.ceil(((p1-a).Magnitude+(p2-p1).Magnitude+(b-p2).Magnitude)/10),24,96)
   local bounds=self.workspaceLinks.AbsoluteSize
   for i=1,steps do
    local t=i/steps;local v=1-t
    local nextPoint=a*v^3+p1*(3*v*v*t)+p2*(3*v*t*t)+b*t^3
    local delta=nextPoint-prev;local middle=(prev+nextPoint)*.5
    local minX,maxX=math.min(prev.X,nextPoint.X),math.max(prev.X,nextPoint.X)
    local minY,maxY=math.min(prev.Y,nextPoint.Y),math.max(prev.Y,nextPoint.Y)
    prev=nextPoint
    if maxX< -3 or minX>bounds.X+3 or maxY< -3 or minY>bounds.Y+3 then continue end
    lineIndex+=1;local line=self.linkPool[lineIndex]
    if not line then
     line=U.frame(self.workspaceLinks,"LinkSegment",nil,UDim2.fromOffset(1,2),color,0)
     line.AnchorPoint=Vector2.new(.5,.5);line.Active=false;line.Interactable=false;line.ZIndex=2
     self.linkPool[lineIndex]=line
    end
    line.Position=UDim2.fromOffset(middle.X,middle.Y);line.Size=UDim2.fromOffset(math.max(2,delta.Magnitude+2),2)
    line.Rotation=math.deg(math.atan2(delta.Y,delta.X));line.BackgroundColor3=color;line.BackgroundTransparency=0;line.Visible=true
   end
  end
  local pairsToDraw={}
  for _,branch in branches do
   local r=self.branchCards[branch.name]
   if r.frame.Visible and r.frame.AbsoluteSize.Y>4 then
    local source=point(self.branchButtons[branch.name].button,1,.5)
    local outerRight=point(self.navGlass,1,0).X
    pairsToDraw[#pairsToDraw+1]={Vector2.new(outerRight,source.Y),point(r.frame,0,.5)}
   end
  end
  local selected=self.buttons[self.tab];local group=tabBranch[self.tab]
  if selected and group and self.branchCards[group].frame.Visible and self.pageBox.Visible then
   local source=point(selected,1,.5)
   local outerRight=point(self.branchCards[group].frame,1,0).X
   local destination=point(self.pageBox,0,.08)
   pairsToDraw[#pairsToDraw+1]={Vector2.new(outerRight,source.Y),Vector2.new(point(self.contentGlass,0,0).X,destination.Y)}
  end
  if self.appearancePanel.Visible and self.branchCards.Interface.frame.Visible then
   pairsToDraw[#pairsToDraw+1]={point(self.branchCards.Interface.frame,1,.90),point(self.appearancePanel,0,.035)}
  end
  if self.appearancePanel.Visible and self.stylePreview.Visible then
   pairsToDraw[#pairsToDraw+1]={point(self.appearancePanel,1,.06),point(self.stylePreview,0,.08)}
  end
  local bounds=self.workspaceLinks.AbsoluteSize
  local signature={s.accent,bounds.X,bounds.Y}
  for _,pair in pairsToDraw do for _,v in pair do signature[#signature+1]=v.X;signature[#signature+1]=v.Y end end
  local key=scalarKey(signature)
  if self.workspaceLinkKey==key then return end
  for _,pair in pairsToDraw do wire(pair[1],pair[2]) end
  self.workspaceLinkKey=key
  for i=lineIndex+1,#self.linkPool do self.linkPool[i].Visible=false end
  for i=portIndex+1,#self.portPool do self.portPool[i].Visible=false end
 end
 function self:workspacePageVisible()
  if not self.opened or self.afkScreen.Visible or not self.pageBox.Visible then return false end
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
  self.navGlass.Position=UDim2.fromOffset(rootX,rootY-30);self.navGlass.Size=UDim2.fromOffset(rail,railH+30)
  self.nav.Position=UDim2.fromOffset(rootX+7,rootY+8);self.nav.Size=UDim2.fromOffset(math.max(1,rail-14),math.max(1,railH-16))
  self.rootDrag.Position=UDim2.fromOffset(rootX+7,rootY-25);self.rootDrag.Size=UDim2.fromOffset(math.max(1,rail-14),25)
  for _,b in self.branchButtons do
   b.button.Size=UDim2.new(1,0,0,buttonH)
   b.button.TextSize=if narrow then 12 else 16
  end
  self.branchStack.Position=UDim2.fromOffset(x+rail+gap,y)
  self.branchStack.Size=UDim2.fromOffset(branchW,workH)
  self.branchTitleH=math.clamp(math.floor(workH/20),10,24)
  self.branchRowH=math.clamp(math.floor((workH-4*(self.branchTitleH+6)-30)/21),24,36)
  self:refreshBranches(true)
  local pageOffset=workspaceOffset(self,"Page");local pageX,pageY=contentX+pageOffset.X,y+pageOffset.Y
  local inset=math.min(8,math.floor((bodyW-1)/2))
  local innerW=math.max(1,bodyW-2*inset)
  self.pageDrag.Position=UDim2.fromOffset(pageX+inset,pageY-25);self.pageDrag.Size=UDim2.fromOffset(innerW,25);self.pageDrag.Text=U.tr(s,self.tab:upper()).." / "..U.tr(s,"MOVE PANEL")
  self.search.Position=UDim2.fromOffset(pageX+inset,pageY+4);self.search.Size=UDim2.fromOffset(innerW,30)
  self.search.BackgroundTransparency=if s.appearanceSearchCustom then s.appearanceSearchTransparency/100 else .53
  self.contentGlass.Position=UDim2.fromOffset(pageX,pageY-30);self.contentGlass.Size=UDim2.fromOffset(bodyW,bodyH+72)
  self.contentGlass.Visible=true
  self.pageBox.Position=UDim2.fromOffset(pageX+inset,pageY+42);self.pageBox.Size=UDim2.fromOffset(innerW,math.max(1,bodyH-8))
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
  if not self.opened or self.afkScreen.Visible or self.drag or self.workspacePan then return end
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
   local releaseVelocity=velocity*(1.25*math.exp(-idle*25))
   if not self.app.s.reduce and idle<.10 and (pos-origin).Magnitude>=6 and releaseVelocity.Magnitude>=65 then
    self.workspaceNodeInertia={node=node,mode=self.app.s.workspaceMode,offset=next,velocity=releaseVelocity/zoom,elapsed=0,sparkAt=.045}
    self:emitWorkspaceSparks(self.workspaceNodeInertia,4)
   else
    self:finishWorkspaceNode()
   end
  end end
 end
 scope:on(self.rootDrag.InputBegan,function(i) beginWorkspaceNode(i,"Root") end)
 scope:on(self.pageDrag.InputBegan,function(i) beginWorkspaceNode(i,"Page") end)
 scope:on(self.appearanceDrag.InputBegan,function(i) beginWorkspaceNode(i,"Appearance") end)
 scope:on(self.stylePreviewDrag.InputBegan,function(i) beginWorkspaceNode(i,"Preview") end)
 for name,r in self.branchCards do
  r.title.Active=true
  scope:on(r.title.InputBegan,function(i) beginWorkspaceNode(i,name) end)
 end
 scope:on(Input.InputBegan,function(i,processed)
  if not self.opened or Input:GetFocusedTextBox() or guiService.MenuIsOpen then self.afkCommand="";return end
  if i.UserInputType==Enum.UserInputType.Keyboard then
   if self.layoutEditing or self.app.editingHUD or self.app.stopping or self.app.bindingLockKey or self.captureBind or Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl) or Input:IsKeyDown(Enum.KeyCode.LeftAlt) or Input:IsKeyDown(Enum.KeyCode.RightAlt) then
    self.afkCommand=""
   else
    local now=os.clock()
    if now-(self.afkKeyAt or 0)>1.2 then self.afkCommand="" end
    local key=i.KeyCode
    local letter=if key==Enum.KeyCode.A then "A" elseif key==Enum.KeyCode.F then "F" elseif key==Enum.KeyCode.K then "K" else ""
    local localizedOk,localized=pcall(function() return Input:GetStringForKeyCode(key) end)
    if localizedOk then
     if localized=="а" or localized=="А" then letter="A"
     elseif localized=="ф" or localized=="Ф" then letter="F"
     elseif localized=="к" or localized=="К" then letter="K" end
    end
    if letter=="" then self.afkCommand=""
    else
     self.afkCommand=(self.afkCommand..letter):sub(-3)
     self.afkKeyAt=now
     if self.afkCommand=="AFK" then self:setAFK(not self.afkTarget);return end
    end
   end
  end
  if self.afkScreen.Visible then return end
  if i.KeyCode==Enum.KeyCode.Home then self:resetWorkspace(Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift));return end
  if i.UserInputType~=Enum.UserInputType.MouseButton3 or self.drag then return end
  local state=self:workspaceCamera()
  self.backgroundTap=nil
  self.workspacePan={origin=Vector2.new(i.Position.X,i.Position.Y),pan=state.pan,zoom=state.zoom}
 end)
 scope:on(Input.InputChanged,function(i)
  if not self.opened or self.afkScreen.Visible then return end
  local pan=self.workspacePan
  if pan and i.UserInputType==Enum.UserInputType.MouseMovement then
   local delta=Vector2.new(i.Position.X,i.Position.Y)-pan.origin
   self.workspaceCameraDraft={zoom=pan.zoom,pan=pan.pan+delta/pan.zoom};self:applyWorkspaceCamera();return
  end
  if i.UserInputType~=Enum.UserInputType.MouseWheel or self.drag or pan then return end
  local ctrl=Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)
  local pos=Input:GetMouseLocation()
  if not ctrl then
   for _,obj in {self.pageBox,self.searchResults,self.search,self.header,self.modeBar,self.navGlass,self.contentGlass,self.rootDrag,self.pageDrag,self.appearancePanel,self.stylePreview} do if inside(obj,pos) then return end end
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
 scope:on(Input.WindowFocusReleased,function() self.afkCommand="";self.backgroundTap=nil;self.drag=nil;self.workspacePan=nil;self:finishWorkspaceNode();self:commitWorkspaceCamera();if self.menuDraft then self.menuDraft=nil end;self:layout() end);scope:add(function() if self.page then self.page:clear() end;Icons.clear() end);return self
end
function UI:animateBackground(t)
 if self.layoutPending or self.layoutViewport~=self.stage.AbsoluteSize then self:layout() end
 local s=self.app.s
 local dt=math.clamp(t-(self.motionAt or t-1/60),0,.1)
 self.motionAt=t
 self:stepWorkspaceScroll()
 self:stepAFK(dt)
 self:stepWorkspaceSparks(dt)
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
 self:stepQuick(dt,editingAux)
 self.bindPanel.Visible=editingAux or (not self.opened and not self.app.editingHUD and self.app.mode=="Game" and s.keybindWidget)
 if self.bindPanel.Visible and t>=(self.bindRefreshAt or 0) then self.bindRefreshAt=t+.3;self:refreshBindPanel() end
 if self.quick.Visible and self.quickAdapter and t>=(self.quickRefreshAt or 0) then
  self.quickRefreshAt=t+.25
  for _,refresh in self.quickAdapter.syncs do pcall(refresh) end
  self:applyQuickTheme()
 end
 self.updateChip.Visible=false
 local below=6
 self.quickArrow.Position=UDim2.new(.5,0,1,below)
 self:layoutAuxWidgets(below)
 self.topButtons[1].TextColor3=U.appearanceText(s,"Top",false,U.hex(s.uiFontColor or "F1E6FF"))
 local visible=s.screenParticles and q>.001
 local decorDt=(self.decorElapsed or 0)+dt
 self.decorElapsed=decorDt
 local decorDue=decorDt>=1/20 or self.decorSettings~=s or self.lastDecorVisible~=visible
 if decorDue then self.decorElapsed=0;self.decorSettings=s;self.lastDecorVisible=visible end
 self.screenFX.Visible=false
 self.starField.Visible=visible
 if not self.panel.Visible or self.afkScreen.Visible then return end
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
  b.BackgroundColor3=U.hex(if s.appearanceTabButtonCustom then s.appearanceTabButtonColor else s.uiButtonColor):Lerp(U.hex(s.uiHoverColor),amount*(if s.appearanceTabButtonCustom then .35 else 1))
 end
 end
 self.geoLayer.Visible=(s.menuGeometry or s.screenParticles) and self.panel.Visible
 self.constellationLayer.Visible=s.menuGeometry
 if self.geoLayer.Visible and s.menuGeometry and decorDue then self.constellation:step(math.min(.1,decorDt),s) end
end
function UI:begin(i,fn,origin) if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end;self.backgroundTap=nil;if self.workspaceNodeInertia then self:finishWorkspaceNode() end;local v=Vector2.new(i.Position.X,i.Position.Y);self.drag={i=i,start=v,fn=fn,origin=origin};fn(v,v,origin) end
function UI:show(on)
 self.afkCommand=""
 self.backgroundTap=nil
 if on then self:setQuick(false) end
 if not on then self.workspacePan=nil;self:finishWorkspaceNode();self:clearWorkspaceSparks();self:commitWorkspaceCamera() end
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
 if not on and self.afkScreen.Visible then self:setAFK(false) end
 self:setWorkspaceKeyboard(on)
 if not on then self.layoutEditing=false;self.layoutDraft=nil;self.layoutMove.Visible=false;self.layoutResize.Visible=false;self.layoutDone.Visible=false end
 self.panel.Interactable=on and not self.afkScreen.Visible
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
  row.k.TextColor3=U.appearanceText(self.app.s,"Keybind",true,Color3.fromRGB(200,170,255));row.l.TextColor3=U.appearanceText(self.app.s,"Keybind",false,U.hex(self.app.s.uiFontColor))
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
  owner:sync();owner:applyQuickTheme()
 end
 function q:row(h,name)
  assert(current,"Quick section missing")
  self.seq+=1
  local f=U.frame(current.body,name or "Row",nil,UDim2.new(1,-4,0,h),soft,.47)
  f.LayoutOrder=self.seq;f.ZIndex=32;f:SetAttribute("AETHERQuickRole","Row");U.corner(f,8)
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
  local b=U.button(row,"Bind");b:SetAttribute("AETHERQuickRole","Bind");b.Size=UDim2.fromOffset(78,24);b.Position=UDim2.new(1,-82,0,2);b.ZIndex=34;b.TextSize=11
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
  card.LayoutOrder=sectionCount;card.ZIndex=30;card:SetAttribute("AETHERQuickRole","Card");U.corner(card,8)
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
   local switch=U.button(card,"OFF");switch:SetAttribute("AETHERQuickRole","Switch")
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
 if self.quickOpen and self.app.s.topCapsule then self.quick.Visible=true end
 self.quick.Interactable=self.quickOpen
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
 self:applyQuickTheme()
end
local function searchMatch(text,words)
 for _,word in words do if not text:find(word,1,true) then return false end end
 return true
end
function UI:refreshSearch()
 if not self.search or not self.searchResults then return end
 local q=U.lowerText(self.search.Text):match("^%s*(.-)%s*$")
 local words=string.split(q," ")
 local has=q~=""
 self.searchResults.Visible=has
 self.pageBox.Visible=not has
 self.contentGlass.Visible=true
 if not has then return end
 local matches,seen={},{}
 for _,item in self.searchIndex do
  if self.buttons[item.tab] and searchMatch(item.term.." "..U.lowerText(U.tr(self.app.s,item.label).." "..U.tr(self.app.s,item.tab)),words) then
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
  b.Visible=true;b.LayoutOrder=i;b.Text=U.tr(self.app.s,matches[i].item.label).."  ·  "..U.tr(self.app.s,matches[i].item.tab)
 end
 self.searchTargets={}
 for i=1,math.min(60,#matches) do self.searchTargets[i]=matches[i].item end
 if not self.searchEmpty then
  self.searchEmpty=U.label(self.searchResults,U.tr(self.app.s,"No functions found"),12,nil,UDim2.new(1,-8,0,34));self.searchEmpty.LayoutOrder=999
 end
 self.searchEmpty.Visible=#matches==0
 for i=math.min(60,#matches)+1,#self.searchPool do self.searchPool[i].Visible=false end
 if self.scrollFreeze then self.scrollFreeze[self.searchResults]=nil end
 self:syncWorkspaceCanvas(self.searchResults)
 self.searchResults.CanvasPosition=Vector2.zero
end
function UI:jumpTo(item)
 self:setQuick(false)
 self.search:ReleaseFocus();self.search.Text=""
 self:open(item.tab,item.key and S.appearanceBySetting[item.key])
 local sc=self.sc
 if not sc then return end
 local label=item.label:lower()
 local function findRow()
  for _,row in sc:GetChildren() do
   if not row:IsA("GuiObject") then continue end
   if item.key and row.Name==item.key then return row end
   for _,obj in row:GetDescendants() do
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
     if obj.Text:lower()==label or obj.Name:lower()==label or obj:GetAttribute("AETHERSourceText")==item.label then return row end
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
   self:syncWorkspaceCanvas(sc)
   if self.scrollFreeze then self.scrollFreeze[sc]=nil end
   local y=row.AbsolutePosition.Y-sc.AbsolutePosition.Y+sc.CanvasPosition.Y
   sc.CanvasPosition=Vector2.new(0,math.clamp(y-6,0,math.max(0,sc.AbsoluteCanvasSize.Y-sc.AbsoluteWindowSize.Y)))
  end
 end)
end
local visualTabs={Halos=true,Wings=true,Ambient=true}
function UI:open(tab,appearance)
 if tab=="HUD" then tab="Clock" end
 self.appearanceSelection=if tab=="Interface" and S.appearanceById[appearance] then appearance else nil
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
 local sc=self.page:add(U.new("ScrollingFrame",{Name="Page_"..tab,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=dim,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Never},self.pageBox))
 U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sc);self.sc=sc
 if visualTabs[tab] then
  self.catalogHost=self.page:add(U.frame(self.pageBox,"VisualCatalog",nil,nil,Color3.fromRGB(24,19,43),.49));U.corner(self.catalogHost,17);U.stroke(self.catalogHost,Color3.fromRGB(181,145,244),.64)
  sc.BackgroundColor3=Color3.fromRGB(25,20,44);sc.BackgroundTransparency=.49;U.corner(sc,16)
  U.new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,4)},sc)
 else self:title(tab:upper().."   /   AETHER VISUALS HUB") end
 self:layout();self.app:page(tab,self);self:sync();self:syncWorkspaceCanvas(sc)
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
function UI:title(str) local f=self:row(26,"Heading");f.BackgroundTransparency=1;local n=U.label(f,U.tr(self.app.s,str),13);n:SetAttribute("AETHERSourceText",str);n.TextColor3=U.hex(self.app.s.accent);self.titleLabel=n;return n end
function UI:note(str,h) local f=self:row(h or 36,"Note");f.BackgroundTransparency=1;local l=U.label(f,U.tr(self.app.s,str),12);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextColor3=dim;l:SetAttribute("AETHERMuted",true);return l end
function UI:watch(fn) table.insert(self.syncs,fn);fn() end
function UI:sync()
 if not self.panel.Parent then return end
 self:applyAFKTheme();self:applyQuickTheme()
 local st=self.app.s
 if self.displayLanguage~=st.language then
  self.displayLanguage=st.language;self.themeDirty=true
  for name,r in self.branchButtons do r.button.Text=U.tr(st,name) end
  for name,r in self.branchCards do r.title.Text=U.tr(st,name:upper()) end
  for tab,b in self.buttons do b.Text=U.tr(st,tab) end
  for mode,b in self.modeButtons do b.Text=U.tr(st,if mode=="GUI" then "GUI VIEW" else "NODE VIEW") end
  self.homeButton.Text=U.tr(st,"HOME");self.rootDrag.Text=U.tr(st,"AETHER / MOVE")
  self.appearanceDrag.Text=U.tr(st,"APPEARANCE / MOVE");self.stylePreviewDrag.Text=U.tr(st,"LIVE PREVIEW / MOVE")
  self.appearanceAll.Text=U.tr(st,"ALL SETTINGS");self.search.PlaceholderText=U.tr(st,"Search functions...")
  self.afkBack.Text=U.tr(st,"RETURN TO WORKSPACE");self.bindEmpty.Text=U.tr(st,"No keybinds assigned")
  if self.searchEmpty then self.searchEmpty.Text=U.tr(st,"No functions found") end
  self:refreshAppearanceSamples()
  self.pageDrag.Text=U.tr(st,self.tab:upper()).." / "..U.tr(st,"MOVE PANEL")
 end
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
 local themeParts={st.language,st.accent,st.uiFontColor,st.uiMutedColor,st.uiPanelColor,st.uiButtonColor,st.uiHoverColor,st.uiRowColor,st.uiStrokeColor,st.uiSpecularColor,st.uiGlassOpacity,st.uiReflection,st.rim,st.clockGlass,st.fpsGlass,st.clockText,st.fpsText,st.glassColor,st.glass,st.inputColor,st.modulePanelColor,st.moduleRowColor,st.moduleStrokeColor,st.moduleTextColor,st.moduleToggleOnColor,st.moduleToggleOffColor,st.moduleBackgroundOpacity,st.afkBgA,st.afkTitleColor,st.afkButtonColor,st.afkButtonText,st.afkButtonEdge,self.appearanceSelection or ""}
 for _,d in S.appearance do
  local p="appearance"..d[1]
  for _,suffix in {"Custom","Color","Transparency","Edge","EdgeTransparency","EdgeWidth"} do themeParts[#themeParts+1]=tostring(st[p..suffix]) end
  for _,extra in S.appearanceExtras[d[1]] do themeParts[#themeParts+1]=tostring(st[extra.key]);themeParts[#themeParts+1]=tostring(st[extra.flag]) end
 end
 if self.stylePreview.Visible then
  local ok,err=pcall(self.refreshStylePreview,self)
  if not ok then
   self.stylePreviewKey=nil;self.stylePreviewBuilt=nil
   if self.stylePreviewError~=tostring(err) then self.stylePreviewError=tostring(err);self.app:log("Appearance preview",self.stylePreviewError) end
  else self.stylePreviewError=nil end
 end
 local themeKey=scalarKey(themeParts)
 if not self.themeDirty and self.themeKey==themeKey then return end
 self.themeDirty=false;self.themeKey=themeKey
 for _,entry in {{self.navGlass,"Root"},{self.appearancePanel,"Appearance"},{self.stylePreview,"Preview"},{self.contentGlass,"Page"},{self.header,"Header"},{self.top,"Top"},{self.bindPanel,"Keybind"},{self.modeBar,"Modes"},{self.catalogHost,"Catalog"},{self.catalogHost and self.sc,"Catalog"}} do if entry[1] then glassSurface(entry[1],st,entry[2]) end end
 for id,r in self.branchCards do glassSurface(r.frame,st,id) end
 self:refreshAppearanceSamples()
 self.stylePreview.HeaderDivider.BackgroundColor3=U.hex(st.uiStrokeColor)
 self.appearancePanel.HeaderDivider.BackgroundColor3=U.hex(st.uiStrokeColor)
 local edge=U.hex(st.uiStrokeColor)
 self.search:SetAttribute("AETHERAppearanceRole","Search");self.search.PlaceholderColor3=U.appearanceText(st,"Search",false,muted)
 U.applyBlock(self.search,st,"Search",U.hex(st.uiRowColor),.53,edge,1,1.15)
 for id,r in self.branchButtons do
  r.button:SetAttribute("AETHERAppearanceRole","NavButton")
  U.applyBlock(r.button,st,"NavButton",U.hex(if st["branch"..id] then st.uiHoverColor else st.uiButtonColor),0,edge,1,1.15)
 end
 for id,b in self.buttons do b:SetAttribute("AETHERAppearanceRole","TabButton");U.applyBlock(b,st,"TabButton",U.hex(if id==self.tab then st.uiHoverColor else st.uiButtonColor),0,edge,1,1.15) end
 for _,header in {self.rootDrag,self.pageDrag} do
  header.BackgroundTransparency=1;header.HeaderDivider.BackgroundColor3=U.hex(st.uiStrokeColor)
 end
 self.homeButton.BackgroundColor3=U.hex(st.uiButtonColor)
 for _,obj in {self.layoutMove,self.layoutResize,self.layoutDone} do obj.BackgroundColor3=U.hex(st.uiHoverColor) end
 -- Only recolor editor controls, not HUD/3D previews or their own palette.
 for _,obj in self.panel:GetDescendants() do
  if obj:IsA("Frame") and obj:GetAttribute("AETHERControlRow") and (obj.BackgroundTransparency<1 or obj:GetAttribute("AETHERStyledRow")) then
   if not obj:GetAttribute("AETHERStyledRow") then obj:SetAttribute("AETHERStyledRow",true);obj:SetAttribute("AETHERBaseAlpha",obj.BackgroundTransparency) end
   obj:SetAttribute("AETHERAppearanceRole","Row")
   U.applyBlock(obj,st,"Row",U.hex(st.uiRowColor),obj:GetAttribute("AETHERBaseAlpha"),edge,1,1.15)
  end
  if obj:IsA("TextButton") and obj:GetAttribute("AETHERThemeButton") then obj:SetAttribute("AETHERAppearanceRole","Button");U.applyBlock(obj,st,"Button",U.hex(st.uiButtonColor),0,edge,1,1.15) end
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
   if obj==self.brand or obj==self.tag or obj==self.status then continue end
   if obj:GetAttribute("AETHERKeepFontColor") then continue end
   local holder=obj.Parent
   local textRole=obj:GetAttribute("AETHERAppearanceRole")
   local skip=false
   while holder and holder~=self.panel do
    textRole=textRole or holder:GetAttribute("AETHERAppearanceRole")
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
    obj.TextColor3=U.appearanceText(st,textRole or "Page",true,muted)
   else
    obj.TextColor3=U.appearanceText(st,textRole or "Page",false,primary)
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
 cols=cols or 3;for start=1,#items,cols do local row=self:row(33,"Actions");row.BackgroundTransparency=1;for j=0,math.min(cols-1,#items-start) do local item=items[start+j];local b=U.button(row,U.tr(self.app.s,item));b:SetAttribute("AETHERSourceText",item);b:SetAttribute("AETHERThemeButton",not selected);b.BackgroundColor3=U.hex(self.app.s.uiButtonColor);b.Name=item;b.Size=UDim2.new(1/cols,-4,1,0);b.Position=UDim2.fromScale(j/cols,0);self.page:on(b.Activated,function() self:action(function() fn(item) end) end);if selected then self:watch(function() b.BackgroundColor3=U.hex(if selected()==item then self.app.s.uiHoverColor else self.app.s.uiButtonColor) end) end end end
end
function UI:box(label,initial,h,commit)
 self:title(label);local r=self:row(h or 34,"Field");local t=U.new("TextBox",{Name=label,Size=UDim2.new(1,-12,1,-4),Position=UDim2.fromOffset(6,2),ClearTextOnFocus=false,MultiLine=(h or 0)>45,TextWrapped=(h or 0)>45,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=if (h or 0)>45 then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,BackgroundTransparency=1,Text=initial or "",PlaceholderText=U.tr(self.app.s,label),Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(232,222,255)},r);if commit then self.page:on(t.FocusLost,function() self:action(function() commit(t.Text) end) end) end;return t
end
-- Appearance edits must commit the override and its value together. Explicitly
-- disabling Individual style still restores the shared theme.
local function writeEditorValue(app,k,value)
 local role=S.appearanceBySetting[k]
 if role then
  local flag=S.appearanceExtraFlags[k] or ("appearance"..role.."Custom")
  if k~=flag then
   local normalized=S.value(k,value)
   if not app.s[flag] or app.s[k]~=normalized then
    app:patch({[flag]=true,[k]=normalized})
   end
   return
  end
 end
 app:set(k,value)
end
function UI:control(k)
 self.controlKeys=self.controlKeys or {}
 if self.controlKeys[k] then return end
 self.controlKeys[k]=true
 local d=S.defs[k];local app=self.app;local a=d.kind;if a=="players" then return end
 if a=="text" or a=="asset" then local box=self:box(d.label,tostring(app.s[k]),32,function(v) app:set(k,v) end);self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end end);return end
 local row=self:row(if a=="number" or a=="angle" then 48 else 34,k);local label=U.label(row,U.tr(app.s,d.label),12,UDim2.fromOffset(9,0),UDim2.new(.57,0,0,30));label.TextColor3=Color3.fromRGB(219,210,234)
 if a=="bool" or a=="choice" then local b=U.button(row,"");b.Name="Value";b.Position=UDim2.new(.58,0,0,3);b.Size=UDim2.new(.42,-6,1,-6);self.page:on(b.Activated,function() if a=="bool" then app:set(k,not app.s[k]) else app:set(k,d.min[(table.find(d.min,app.s[k]) or 0)%#d.min+1]);if k=="language" then self:open(self.tab,self.appearanceSelection) end end end);self:watch(function() b.Text=if a=="bool" then (if app.s[k] then "ON" else "OFF") else U.tr(app.s,tostring(app.s[k])).."  ›";b.BackgroundColor3=U.hex(if a=="bool" and not app.s[k] then app.s.uiButtonColor else app.s.uiHoverColor) end);return end
 local box=U.new("TextBox",{Name="Value",Position=UDim2.new(.6,0,0,3),Size=UDim2.new(.4,-7,0,23),BackgroundColor3=bg,ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=12,Text="",BorderSizePixel=0},row);U.corner(box,6)
 self.page:on(box.FocusLost,function() self:action(function() writeEditorValue(app,k,if a=="angle" then assert(tonumber(box.Text),"Enter a finite angle") elseif a=="number" then math.clamp(math.round(assert(tonumber(box.Text),"Enter a number")),d.min,d.max) else (box.Text:gsub("^#",""))) end);self:sync() end)
 if a=="color" then self:watch(function() if not box:IsFocused() then box.Text="#"..app.s[k] end;label.TextColor3=U.hex(app.s[k]) end);return end
 local hit=U.new("TextButton",{Name="Slider",Position=UDim2.fromOffset(10,26),Size=UDim2.new(1,-20,0,21),BackgroundTransparency=1,Text="",AutoButtonColor=false},row);local track=U.frame(hit,"Track",UDim2.fromScale(0,.37),UDim2.new(1,0,0,5),bg);U.corner(track,4);local fill=U.frame(track,"Fill",nil,nil,U.hex(app.s.accent));U.corner(fill,4);local dot=U.frame(fill,"Thumb",UDim2.fromScale(1,.5),UDim2.fromOffset(11,11),Color3.fromRGB(237,225,255));dot.AnchorPoint=Vector2.new(.5,.5);U.corner(dot,9)
 self.page:on(hit.InputBegan,function(i) self:begin(i,function(pos) local t=math.clamp((pos.X-hit.AbsolutePosition.X)/math.max(1,hit.AbsoluteSize.X),0,1);writeEditorValue(app,k,math.round(d.min+t*(d.max-d.min))) end) end)
 self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end;fill.Size=UDim2.fromScale(math.clamp((app.s[k]-d.min)/(d.max-d.min),0,1),1);fill.BackgroundColor3=U.hex(app.s.accent) end)
end
function UI:colorPicker(k,alphaKey)
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
  if S.appearanceBySetting[k] then writeEditorValue(app,k,next)
  elseif app.s[k]~=next then app:set(k,next) else self:sync() end
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
 if alphaKey and S.defs[alphaKey] then self:control(alphaKey) end
end
function UI:group(g,skip) for _,k in S.order do if S.defs[k].group==g and not(skip and skip[k]) then self:control(k) end end end
return UI
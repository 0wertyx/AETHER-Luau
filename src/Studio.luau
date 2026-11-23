local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Tags=game:GetService("CollectionService")
local Http=game:GetService("HttpService") -- local JSON/UUID utilities only
local U=require(script.Parent.Util);local S=require(script.Parent.Schema)
local UI=require(script.Parent.Controls);local Pages=require(script.Parent.Pages)
local Hud=require(script.Parent.Hud);local Avatar=require(script.Parent.Avatar)
local View=require(script.Parent.View);local World=require(script.Parent.World)
local Store=require(script.Parent.Storage);local Cues=require(script.Parent.Cues)
local Studio={};Studio.__index=Studio
local empty=table.freeze({})

function Studio:log(kind,msg)
 if #self.logs>=60 then table.remove(self.logs,1) end
 table.insert(self.logs,os.date("%H:%M:%S").."  "..kind.."  "..tostring(msg):sub(1,190))
 if self.ui then self.ui:message(tostring(msg):sub(1,150)) end
end
function Studio:dirty() if self.store then self.store:edit() end end
function Studio:effective()
 self.look=self.s
 if self.cue and next(self.cue.overrides) then self.look=table.clone(self.s);for k,v in self.cue.overrides do self.look[k]=v end end
 self.world:apply(self.look)
end
function Studio:patch(values)
 local nextS=table.clone(self.s);local changed=false
 for k,v in values do local clean=S.value(k,v);if self.s[k]~=clean then nextS[k]=clean;changed=true end end
 if not changed then return end
 if values.cue~=nil and self.cue then self:stopCue() end
 self.s=nextS;self.bank.settings=nextS;self:effective();self:dirty();self.ui:sync()
end
function Studio:set(k,v) self:patch({[k]=v}) end
function Studio:replace(settings)
 local clean=S.settings(settings);self:stopCue();self.s=clean;self.bank.settings=clean;self:effective();self:dirty();self.ui:sync()
end
function Studio:library(bank)
 local clean=S.bank(bank);assert(#Http:JSONEncode(clean)<=110000,"Bank exceeds 110 KB")
 self.bank.profiles=clean.profiles;self.bank.assets=clean.assets;self:dirty()
end
function Studio:restore(bank)
 local clean=S.bank(bank);self:stopCue();self.bank=clean;self.s=clean.settings;self.selection=nil;self:effective();self.ui:sync()
 if self.ui.opened and (self.ui.tab=="Profiles" or self.ui.tab=="Workshop" or self.ui.tab=="Scripts") then self.ui:open(self.ui.tab) end
end
function Studio:page(tab,ui) Pages.render(self,tab,ui) end
function Studio:drag(i,k,node,view)
 if self.s.locked then return end
 local ox,oy=self.s[k.."X"],self.s[k.."Y"];local travel=view.AbsoluteSize-node.AbsoluteSize
 self.ui:begin(i,function(pos,start) local d=pos-start;self:patch({[k.."X"]=math.clamp(math.round(ox+d.X*100/math.max(1,travel.X)),0,100),[k.."Y"]=math.clamp(math.round(oy+d.Y*100/math.max(1,travel.Y)),0,100)}) end)
end
function Studio:stopCue()
 if self.cue then self.cue:stop();self.cue=nil;self:effective() end
 if self.frame then self.frame.widgets=empty end
end
function Studio:event(action,changed)
 if not self.cue or not self.frame.hp then return end
 local ok,err=pcall(self.cue.event,self.cue,action,self.frame.hp,self.frame.max,changed)
 if not ok then self:stopCue();self:log("Script",err);self.ui:sync();return end
 self:effective();self.frame.widgets=self.cue.widgets
end
function Studio:runCue()
 self:stopCue();self.cue=Cues.start(self.s.cue,table.clone(self.grants));self:effective();self.frame.widgets=self.cue.widgets;self:event("start",true)
 if self.cue then self:log("Script","HUD program running") end
end
function Studio:vitals(action)
 local f=self.frame;local hp,mx,gen
 if self.mode=="Game" then local h=self.hum;if h and h.Parent and h.MaxHealth>0 then hp=math.clamp(h.Health,0,h.MaxHealth);mx=h.MaxHealth end;gen="game:"..self.generation
 else hp,mx,gen=self.sim.hp,self.sim.max,"sim:"..self.sim.gen end
 local old=f.hp;local changed=f.gen~=gen or old~=hp or f.max~=mx;local respawn=(f.gen~=gen or old==0) and hp and hp>0
 f.hp,f.max,f.gen,f.mode=hp,mx,gen,self.mode;f.name=if self.mode=="Game" then self.me.DisplayName else "Virtual player"
 if changed then self:event(if respawn then "respawn" elseif old and hp and hp<old then "damage" elseif old and hp and hp>old then "heal" else action or "health",true)
  if self.hud then self.hud:vitals(self.look,f,0);if self.preview and self.preview.hud then self.preview.hud:vitals(self.look,f,0) end end
 end
end
function Studio:character(char)
 if self.charScope then self.charScope:clear() end;if self.humScope then self.humScope:clear();self.humScope=nil end
 self.avatar:clear();self.view:releaseCamera();self.char=char;self.hum=nil;self.generation+=1
 local cs=U.scope();self.charScope=cs
 local function bind()
  if self.dead or self.char~=char then return end
  local h=char and char:FindFirstChildOfClass("Humanoid");if h==self.hum then return end
  if self.humScope then self.humScope:clear() end;self.hum=h;local hs=U.scope();self.humScope=hs
  if h then local function change() if self.dead or self.hum~=h then return end;self:vitals();if h.Health<=0 then self.avatar:clear();self.view:releaseCamera() end end
   hs:on(h.HealthChanged,change);hs:on(h:GetPropertyChangedSignal("MaxHealth"),change);hs:on(h.Died,change)
  end;self:vitals()
 end
 if char then cs:on(char.ChildAdded,bind);cs:on(char.ChildRemoved,bind);bind() end;self:vitals()
end
function Studio:modeSet(mode)
 assert(mode=="Game" or mode=="Simulator","Unknown source");if self.mode==mode then return end;self.mode=mode;self.nextScan=0;self.frame.targets={};self.hud:clearMarkers();if self.preview and self.preview.hud then self.preview.hud:clearMarkers() end
 self:vitals("source");self.ui:sync();self:log("Source",mode)
end
function Studio:simVitals(hp,mx,action)
 assert(type(mx)=="number" and mx>=1 and mx<=100000 and hp>=0 and hp<=mx,"Invalid vitals");self.sim.hp=hp;self.sim.max=mx;if action=="respawn" then self.sim.gen+=1 end;self:vitals(action)
end
function Studio:simulate(action)
 self:modeSet("Simulator");local f=self.sim
 if action=="Damage −25" then self:simVitals(math.max(0,f.hp-25),f.max,"damage") elseif action=="Heal +25" then if f.hp>0 then self:simVitals(math.min(f.max,f.hp+25),f.max,"heal") end
 elseif action=="Respawn" then self:simVitals(f.max,f.max,"respawn") elseif action=="Clear players" then table.clear(f.players);self:event("clear",false)
 elseif action=="Add player" then assert(#f.players<12,"12 virtual players maximum");local n=f.next;f.next+=1;table.insert(f.players,{id=n,x=self.rng:NextNumber(-1,1),y=self.rng:NextNumber(-1,1)});self:event("add",false)
 elseif action=="Move players" then for _,p in f.players do p.x=self.rng:NextNumber(-1,1);p.y=self.rng:NextNumber(-1,1) end;self:event("move",false) end
 self:log("Simulator",action)
end
function Studio:scan(camera)
 local origin=if self.char and self.char:FindFirstChild("HumanoidRootPart") then self.char.HumanoidRootPart.Position else camera.CFrame.Position
 local candidates={};local function add(id,label,part,head,player)
  if not part or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then return end;local d=(part.Position-origin).Magnitude;if d>self.s.reach then return end
  table.insert(candidates,{id=tostring(id),label=label,part=part,head=head,d=d,player=player})
 end
 for _,p in Players:GetPlayers() do local ch=p.Character;if p~=self.me and p:GetAttribute("AetherShareBearing")==true and ch then add(p.UserId,p.DisplayName,ch:FindFirstChild("HumanoidRootPart"),ch:FindFirstChild("Head"),p) end end
 for _,part in Tags:GetTagged("AetherBeacon") do if part:IsA("BasePart") then local id=self.beaconIds[part];if not id then self.nextBeacon-=1;id=self.nextBeacon;self.beaconIds[part]=id end;add(id,part.Name,part,part,nil) end end
 table.sort(candidates,function(a,b) return a.d<b.d end);self.candidates={};for i=1,math.min(12,#candidates) do self.candidates[i]=candidates[i] end
end
function Studio:targets(t)
 local s=self.look;local out=self.frame.targets;table.clear(out);local seen={};local cam=workspace.CurrentCamera
 if self.mode=="Simulator" then if s.indicators or s.nearby then for _,p in self.sim.players do local x,y=p.x,p.y;table.insert(out,{id=tostring(p.id),label="P"..p.id,x=x,y=y,visible=y<0 and math.abs(x)<-y,distance=math.sqrt(x*x+y*y)*180}) end end
 elseif cam and (s.indicators or s.nearby) then
  if t>=self.nextScan then self:scan(cam);self.nextScan=t+.4 end;local vs=cam.ViewportSize
  for _,p in self.candidates do local part=p.part;if not part.Parent or p.player and (not p.player.Character or not part:IsDescendantOf(p.player.Character) or p.player:GetAttribute("AetherShareBearing")~=true) or not p.player and not Tags:HasTag(part,"AetherBeacon") then continue end
   local localPos=cam.CFrame:PointToObjectSpace(part.Position);local projected,visible=cam:WorldToViewportPoint(part.Position);local x,y
   if localPos.Z<-.001 then x=projected.X/math.max(1,vs.X)-.5;y=projected.Y/math.max(1,vs.Y)-.5 else x=localPos.X/math.max(1,vs.X);y=(math.abs(localPos.Z)-localPos.Y)/math.max(1,vs.Y) end
   local dist=localPos.Magnitude;if dist>s.reach then continue end;table.insert(out,{id=p.id,label=p.label,x=x,y=y,visible=visible,distance=dist})
   if s.nearby and p.head and p.head.Parent and dist<=125 then seen[p.id]=true;local bb=self.plates[p.id];if not bb then bb=U.new("BillboardGui",{Name="Nameplate",Size=UDim2.fromOffset(154,24),AlwaysOnTop=false,MaxDistance=125,StudsOffsetWorldSpace=Vector3.new(0,2.4,0)},self.namesFolder);U.label(bb,"",13).Name="Title";bb.Title.TextXAlignment=Enum.TextXAlignment.Center;self.plates[p.id]=bb end;bb.Adornee=p.head;local o=s.players[p.id];bb.Title.Text=if o and o.label~="" then o.label else p.label;bb.Title.TextColor3=U.hex(if o then o.color else s.arrowA);bb.Title.TextStrokeTransparency=.3 end
  end
 end
 for id,bb in self.plates do if not seen[id] then bb:Destroy();self.plates[id]=nil end end
end
function Studio:step(dt)
 local s=self.look;local t=os.clock();self.view:step(s,self.hum,self.ui.opened,dt,t);self.acc+=dt;if self.acc<1/30 then return end;local d=math.min(.2,self.acc);self.acc=0
 self:targets(t);self.hud:step(s,self.frame,d);self.avatar:step(if self.hum and self.hum.Health>0 then self.char else nil,s,t)
 if self.preview and self.ui.opened then local p=self.preview;if p.hud then p.hud:step(s,self.frame,d) elseif p.avatar then p.avatar:step(p.rig,s,t) elseif p.cursor then
  local image=s.cursorShape=="Image";p.image.Visible=image and s.image~="";p.image.Image=if image and s.image~="" then "rbxassetid://"..s.image else "";p.cursor.root.Visible=not image;local size=UDim2.fromOffset(s.cursorSize,s.cursorSize);p.image.Size=size;p.cursor.root.Size=size
  if not image then p.cursor:shape(s.cursorShape,60);local h=if s.reduce then 0 else (t*s.cursorSpeed*.001)%1;p.cursor:paint(if s.cursorRainbow then Color3.fromHSV(h,.6,1) else U.hex(s.cursorA),if s.cursorRainbow then Color3.fromHSV((h+.25)%1,.58,1) else U.hex(s.cursorB),s.cursorGlow,8) end
 end end
 if t>=self.nextStatus then self.nextStatus=t+.6;self.store:tick(t);if self.store.status~=self.lastStatus then self.lastStatus=self.store.status;self.ui:message(self.lastStatus) end end
end
function Studio:destroy()
 if self.dead then return end;self.dead=true;Run:UnbindFromRenderStep(self.binding);if self.cue then self.cue:stop() end
 if self.charScope then self.charScope:clear() end;if self.humScope then self.humScope:clear() end;self.scope:clear();self.preview=nil;self.candidates={};self.plates={}
end
function Studio.start(me)
 assert(Run:IsClient(),"AETHER needs a client");me=me or Players.LocalPlayer;local pg=me:WaitForChild("PlayerGui",15);assert(pg,"PlayerGui unavailable");assert(not pg:FindFirstChild("AetherFullStudio"),"AETHER is already mounted")
 local self=setmetatable({scope=U.scope(),me=me,bank=S.blank(),mode="Game",hudTab="hp",libraryKind="Theme",grants={},logs={},generation=0,nextStatus=0,nextScan=0,acc=0,plates={},candidates={},beaconIds=setmetatable({},{__mode="k"}),nextBeacon=-10000000,rng=Random.new(),binding="AetherFull_"..Http:GenerateGUID(false),frame={mode="Game",name=me.DisplayName,targets={},widgets=empty},sim={hp=100,max=100,gen=1,next=4,players={{id=1,x=-.9,y=.2},{id=2,x=.87,y=.54},{id=3,x=.2,y=.88}}}},Studio)
 self.s=self.bank.settings;self.look=self.s
 local ok,err=xpcall(function()
  local function layer(name,order,inset) return self.scope:add(U.new("ScreenGui",{Name=name,ResetOnSpawn=false,DisplayOrder=order,IgnoreGuiInset=inset,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)) end
  self.gui=layer("AetherFullStudio",40,false);local hudGui=layer("AetherFullHUD",30,true);local pointerGui=layer("AetherFullPointer",45,true)
  self.surface=U.frame(hudGui,"Viewport",nil,nil,nil,1);self.surface.ClipsDescendants=true;local mouse=U.frame(pointerGui,"PointerArea",nil,nil,nil,1)
  self.namesFolder=self.scope:add(U.new("Folder",{Name="AetherFullNameplates"},pg));self.avatar=Avatar.new(workspace,false);self.world=World.new();self.view=View.new(me,mouse);self.scope:add(function() self.avatar:clear();self.world:clear();self.view:destroy() end)
  self.ui=UI.new(self,self.gui,self.scope);self.hud=Hud.new(self.scope,self.surface,false,function(tab) self.ui:open(tab) end,function(i,k,n,v) self:drag(i,k,n,v) end)
  self.store=Store.new(self,self.scope);self.ui:open("Dashboard");self:character(me.Character);self.scope:on(me.CharacterAdded,function(c) self:character(c) end);self.scope:on(me.CharacterRemoving,function(c) if self.char==c then self:character(nil) end end)
  self.scope:on(Input.InputBegan,function(i,used) if used or Input:GetFocusedTextBox() then return end;if i.KeyCode==Enum.KeyCode.RightShift then self.ui:show(not self.ui.opened) elseif i.KeyCode==Enum.KeyCode.LeftAlt then self:patch({camera=true,cameraMode="Follow",lock=not self.s.lock}) end end)
  self.scope:on(self.gui.Destroying,function() self:destroy() end);self.scope:on(me.AncestryChanged,function(_,parent) if not parent then self:destroy() end end)
  Run:BindToRenderStep(self.binding,Enum.RenderPriority.Camera.Value+2,function(dt) if self.dead then return end;local worked,why=xpcall(self.step,debug.traceback,self,dt);if not worked then warn("AETHER runtime: "..why);self:destroy() end end)
  self:log("Startup","Game HUD ready · RightShift opens Studio")
 end,debug.traceback)
 if not ok then self:destroy();error(err,0) end;return self
end
return Studio

-- Local rendering of cosmetics voluntarily shared through the current experience server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Schema=require(script.Parent.Schema)
local Avatar=require(script.Parent.Avatar)
local Motion=require(script.Parent.WalkMotion)
local Studio=require(script.Parent.MotionStudio)
local Props=require(script.Parent.PreviewProps)
local P={};P.__index=P
local function same(a,b)
 if not a or not b then return false end
 for k,v in a do if b[k]~=v then return false end end
 for k,v in b do if a[k]~=v then return false end end
 return true
end
local quality={Low={radius=90,count=4,hz=15,pose=15},Balanced={radius=160,count=8,hz=30,pose=30},High={radius=240,count=12,hz=60,pose=60}}
function P.new(player,scope)
 local self=setmetatable({player=player,scope=scope,peers={},active={},status="Peer visuals OFF",sendAt=0,selectAt=0,linkAt=0,lastHeartbeat=0},P)
 scope:add(function() self:close() end)
 return self
end
function P:drop(player)
 local entry=self.peers[player]
 if not entry then return end
 if entry.fx then entry.fx:clear();entry.motion:destroy();entry.props:clear();entry.fx=nil end
 self.peers[player]=nil
end
function P:reset()
 for player in self.peers do self:drop(player) end
 table.clear(self.active)
end
function P:close()
 if self.link and self.enabled then pcall(function() self.link:FireServer("leave") end) end
 if self.connection then self.connection:Disconnect();self.connection=nil end
 self.link=nil;self.joined=false;self.enabled=false;self.sent=nil;self.pending=nil;self.lastSettings=nil;self.lastPublished=nil;self:reset()
end
function P:connect(remote)
 self:close()
 self.link=remote
 self.connection=remote.OnClientEvent:Connect(function(op,who,packet)
  if not self.enabled then return end
  if op=="ready" then self.joined=true;return end
  if op=="remove" then self:drop(who);return end
  if op~="update" or typeof(who)~="Instance" or not who:IsA("Player") or who==self.player or who.Parent~=Players then return end
  local ok,settings=pcall(Schema.peerSettings,packet)
  if not ok then return end
  local entry=self.peers[who]
  if not entry then entry={};self.peers[who]=entry end
  entry.settings=settings;entry.config=Studio.runtimeSettings(settings);entry.packet=packet
  self.selectAt=0
 end)
end
function P:select(q)
 local camera=workspace.CurrentCamera
 local pos=camera and camera.CFrame.Position
 local candidates={}
 for player,entry in self.peers do
  if player.Parent~=Players then self:drop(player);continue end
  local char=player.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if pos and root and hum and hum.Health>0 then
   local distance=(root.Position-pos).Magnitude
   if distance<q.radius then candidates[#candidates+1]={entry=entry,char=char,hum=hum,distance=distance} end
  end
 end
 table.sort(candidates,function(a,b) return a.distance<b.distance end)
 table.clear(self.active)
 local chosen={}
 for i=1,math.min(q.count,#candidates) do
  local c=candidates[i];local entry=c.entry;chosen[entry]=true
  if not entry.fx then
   entry.fx=Avatar.new(workspace,false);entry.fx.peer=true
   entry.motion=Motion.new(true);entry.props=Props.new(workspace,true);entry.nextFX=0
  end
  if entry.char~=c.char then
   entry.fx:clear();entry.motion:bind(c.char);entry.props:clear();entry.char=c.char;entry.nextFX=0
  end
  entry.motion.peerPoseHz=if c.distance>q.radius*.6 then math.min(15,q.pose) else q.pose
  entry.hum=c.hum;entry.hz=if c.distance>q.radius*.6 then math.min(15,q.hz) else q.hz
  self.active[#self.active+1]=entry
 end
 for _,entry in self.peers do
  if entry.fx and not chosen[entry] then
   entry.fx:clear();entry.motion:destroy();entry.props:clear();entry.fx=nil;entry.char=nil
  end
 end
end
function P:step(s,gameMode,localMotion,dt)
 local now=os.clock()
 if not s.peerVisuals or not gameMode then
  if self.link then self:close() end
  self.status="Peer visuals OFF";return
 end
 if self.link and self.link.Parent~=RS then self:close() end
 if not self.link then
  if now<self.linkAt then return end
  self.linkAt=now+2
  local remote=RS:FindFirstChild("AetherPeerVisualsV1")
  if not remote or not remote:IsA("RemoteEvent") then self.status="Peer relay unavailable in this place";return end
  self:connect(remote)
 end
 self.enabled=true
 if now>=self.sendAt then
  self.sendAt=now+.35
  local track=localMotion.replicatedTrack
  local published=track~=nil and track.IsPlaying and track.Length>0
  local physical=localMotion.physicalLift~=nil
  if self.lastSettings~=s or self.lastPublished~=published or self.lastPhysical~=physical then
   self.lastSettings=s;self.lastPublished=published;self.lastPhysical=physical
   local ok,packet=pcall(Schema.capturePeer,s,published,physical)
   if ok then self.pending=packet end
  end
  if self.pending and (not self.joined or not same(self.sent,self.pending) or now-self.lastHeartbeat>=8) then
   self.link:FireServer("share",self.pending);self.sent=self.pending;self.lastHeartbeat=now
  end
 end
 local q=quality[s.peerQuality] or quality.Balanced
 if now>=self.selectAt or self.lastQuality~=q then self.selectAt=now+.4;self.lastQuality=q;self:select(q) end
 local t=workspace:GetServerTimeNow()
 for _,entry in self.active do
  if now>=entry.nextFX and entry.fx and entry.char and entry.char.Parent then
   entry.nextFX=now+1/entry.hz
   local ok=pcall(function()
    entry.fx:step(entry.char,entry.settings,t)
    local cfg=entry.config
    if cfg and cfg.props and entry.settings.walkAnimation and not entry.settings.reduce then entry.props:update(entry.char,cfg.style,(if entry.settings.peerPublished then t else entry.motion.liveTime)*4,entry.hum:GetState()) else entry.props:clear() end
   end)
   if not ok then entry.fx:clear();entry.props:clear();entry.nextFX=now+1 end
  end
 end
 local count=0;for _ in self.peers do count+=1 end
 self.status=if self.joined then string.format("PEERS · %d connected / %d rendered",count,#self.active) else "Connecting to place relay..."
end
function P:restore()
 for _,entry in self.active do if entry.fx then entry.motion:restoreLive() end end
end
function P:animate(dt)
 for _,entry in self.active do
  if entry.fx and entry.char and entry.char.Parent then
   local ok=pcall(entry.motion.liveStep,entry.motion,entry.char,entry.settings,dt)
   if not ok then entry.motion:restoreLive() end
  end
 end
end
return P

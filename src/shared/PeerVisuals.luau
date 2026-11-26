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
local function validAngle(n)
 return type(n)=="number" and n==n and n>=-360 and n<=360
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
 self.link=nil;self.joined=false;self.enabled=false;self.sent=nil;self.pending=nil;self.lastSettings=nil;self.lastPublished=nil;self.lastPhysical=nil;self.ackMode=false;self.tiltMode=false;self.tiltAt=0;self.tiltX=0;self.tiltZ=0;self.lastAck=0;self.lastHeartbeat=0;self.sendAt=0;self.selectAt=0;self.linkAt=0;self:reset()
end
function P:connect(remote)
 self:close()
 self.link=remote;self.enabled=true;self.connectAt=os.clock()
 self.connection=remote.OnClientEvent:Connect(function(op,who,packet,poseCharacter)
  if not self.enabled or self.link~=remote then return end
  if op=="ready" then self.joined=true;self.lastAck=os.clock();self.ackMode=who==2 or who==3;self.tiltMode=who==3;return end
  if op=="remove" then self:drop(who);return end
  if typeof(who)~="Instance" or not who:IsA("Player") or who==self.player or who.Parent~=Players then return end
  if op=="tilt" then
   local entry=self.peers[who]
   if entry and poseCharacter and who.Character==poseCharacter and type(packet)=="table" and validAngle(packet.x) and validAngle(packet.z) then
    entry.tilt=Vector2.new(math.rad(packet.x),math.rad(packet.z));entry.tiltAt=os.clock();entry.tiltCharacter=poseCharacter
   end
   return
  end
  if op~="update" then return end
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
  self.linkAt=0;self.status="Peer visuals OFF";return
 end
 if self.link and (self.link.Parent~=RS or (not self.joined and now-self.connectAt>=8) or (self.joined and self.ackMode and now-self.lastAck>=20)) then
  self:close();self.linkAt=now+2;self.status="Relay connection lost · retrying";return
 end
 if not self.link then
  if now<self.linkAt then return end
  self.linkAt=now+2
  local remote=RS:FindFirstChild("AetherPeerVisualsV1")
  if not remote or not remote:IsA("RemoteEvent") then self.status="Not connected · place relay not installed";return end
  local ok=pcall(self.connect,self,remote)
  if not ok then self:close();self.linkAt=now+2;self.status="Relay connection failed · retrying";return end
 end
 if now>=self.sendAt then
  self.sendAt=now+(if self.joined then .35 else 1)
  local track=localMotion.replicatedTrack
  local published=track~=nil and track.IsPlaying and track.Length>0
  local physical=localMotion.physicalLift~=nil
  if self.lastSettings~=s or self.lastPublished~=published or self.lastPhysical~=physical then
   local ok,packet=pcall(Schema.capturePeer,s,published,physical)
   if ok then self.pending=packet;self.lastSettings=s;self.lastPublished=published;self.lastPhysical=physical
   else self.pending=nil;self.status="Cannot encode cosmetics · retrying";return end
  end
  if self.pending and (not self.joined or not same(self.sent,self.pending) or now-self.lastHeartbeat>=8) then
   local ok=pcall(function() self.link:FireServer("share",self.pending) end)
   if not ok then self:close();self.linkAt=now+2;self.status="Relay send failed · retrying";return end
   self.sent=self.pending;self.lastHeartbeat=now
  end
 end
 -- Share only quantized cosmetic joint angles, not movement inputs or physics.
 if self.joined and self.tiltMode and now>=(self.tiltAt or 0) then
  self.tiltAt=now+.1
  local angles=localMotion.airTiltAngles
  local x,z=0,0
  local char=self.player.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not s.reduce and s.airControl and char and hum and hum.Health>0 and not hum.Sit and localMotion.character==char and typeof(angles)=="Vector2" then
   x=math.clamp(math.round(math.deg(angles.X)),-360,360)
   z=math.clamp(math.round(math.deg(angles.Y)),-360,360)
  end
  if x~=0 or z~=0 or self.tiltX~=0 or self.tiltZ~=0 then
   local ok=pcall(function() self.link:FireServer("tilt",{x=x,z=z}) end)
   if not ok then self:close();self.linkAt=now+2;self.status="Relay send failed · retrying";return end
  end
  self.tiltX=x;self.tiltZ=z
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
   local ok=pcall(function()
    entry.motion:liveStep(entry.char,entry.settings,dt)
    local hum=entry.hum
    local fresh=entry.tiltCharacter==entry.char and entry.tiltAt and os.clock()-entry.tiltAt<=.6
    local target=if fresh and hum and hum.Health>0 and not hum.Sit and not entry.settings.reduce then entry.tilt else Vector2.zero
    entry.motion:applyPeerAirTilt(entry.char,target,dt)
   end)
   if not ok then entry.motion:restoreLive() end
  end
 end
end
return P

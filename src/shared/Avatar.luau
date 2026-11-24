local U=require(script.Parent.Util)
local A={};A.__index=A

-- Cosmetic, anchored geometry. The character's own joints, collision and animations
-- are never modified by this module. All FX are local to the AETHER client.
local function part(parent,name,size,shape,neon)
 return U.new("Part",{
  Name=name,Size=size or Vector3.one,
  Shape=shape or Enum.PartType.Block,
  Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
  CastShadow=false,Material=if neon==false then Enum.Material.SmoothPlastic else Enum.Material.Neon
 },parent)
end
local function is(style,...)
 for _,v in {...} do if style==v then return true end end
 return false
end
local wingFigures={["Prism Wings"]=3,["Triad Wings"]=3,["Hex Wings"]=6,["Star Wings"]=10,["Orbital Wings"]=16,["Diamond Wings"]=4}
local haloFigures={Triangle=3,Square=4,Pentagon=5,Hexagon=6,Octagon=8,Star=10,["Double Diamond"]=4,Infinity=40}
local function outlinePoint(index,sides,radius,star,phase)
 local angle=phase+index/sides*math.pi*2
 local r=radius*(if star and index%2==1 then .48 else 1)
 return Vector3.new(math.cos(angle)*r,math.sin(angle)*r,0)
end
local function segment(p,a,b,thick)
 local d=b-a
 if d.Magnitude<.001 then p.Transparency=1;return end
 p.Transparency=0
 p.Size=Vector3.new(thick,thick,d.Magnitude)
 p.CFrame=CFrame.lookAt((a+b)*.5,b)
end
local function config(detail)
 if detail=="Balanced" then return 8,5,24,12
 elseif detail=="Ultra" then return 15,9,48,32
 else return 11,7,36,24 end
end
function A.new(parent,preview)
 return setmetatable({
  parent=parent,preview=preview,feathers={},trims={},beads={},ornaments={},
  parts={},frames={},geoWings={},geoHalos={},key="",paintAt=-1,walk=0,phase=0,lastAt=nil
 },A)
end
function A:clear()
 if self.scope then self.scope:clear();self.scope=nil end
 self.root=nil;self.highlight=nil;self.emitter=nil;self.trail=nil;self.light=nil
 self.key="";self.char=nil;self.lastAt=nil;self.walk=0;self.phase=0
 table.clear(self.feathers);table.clear(self.trims);table.clear(self.beads)
 table.clear(self.ornaments);table.clear(self.parts);table.clear(self.frames);table.clear(self.geoWings);table.clear(self.geoHalos)
end
function A:add(partInstance)
 table.insert(self.parts,partInstance)
 return partInstance
end
function A:bind(char,body,head,s)
 local wdetail=s.wingDetail or "High";local hdetail=s.haloDetail or "High"
 local key=table.concat({tostring(s.wings),s.wingStyle,wdetail,
  tostring(s.halo),s.haloStyle,hdetail,tostring(s.neon),tostring(s.aura),tostring(s.trail)},"/")
 if not (char and body and head) or not(s.wings or s.halo or s.neon or s.aura or s.trail) then
  if self.root then self:clear() end;return
 end
 if self.key==key and self.char==char then return end
 self:clear()
 self.key=key;self.char=char;self.scope=U.scope()
 self.root=self.scope:add(U.new("Folder",{Name="AetherAvatarFX"},self.parent))
 self.paintAt=-1
 if s.wings and wingFigures[s.wingStyle] then
  local sides=wingFigures[s.wingStyle]
  local count=if wdetail=="Ultra" then 5 elseif wdetail=="Balanced" then 3 else 4
  for _,side in {-1,1} do
   for tier=1,count do
    local edges={}
    for i=1,sides do edges[i]=self:add(part(self.root,"GeometricWingEdge",Vector3.one,Enum.PartType.Block,true)) end
    local gem=self:add(part(self.root,"GeometricWingCore",Vector3.one,Enum.PartType.Ball,true))
    table.insert(self.geoWings,{side=side,tier=tier,count=count,edges=edges,gem=gem,sides=sides})
   end
  end
 elseif s.wings then
  local primary,secondary=config(wdetail)
  for _,side in {-1,1} do
   for layer,count in {primary,secondary} do
    for index=1,count do
     local sharp=is(s.wingStyle,"Blade","Crystal","Storm","Frost")
     local core=self:add(part(self.root,"FeatherBody",Vector3.one,if sharp then Enum.PartType.Block else Enum.PartType.Ball,false))
     local vein=self:add(part(self.root,"FeatherVein",Vector3.one,Enum.PartType.Block,true))
     local tip=nil
     if index%3==1 then tip=self:add(part(self.root,"FeatherGlimmer",Vector3.one,Enum.PartType.Ball,true)) end
     table.insert(self.feathers,{core=core,vein=vein,tip=tip,index=index,count=count,side=side,layer=layer})
    end
   end
   -- Tiny ornamentation along the base makes the feathers read as attached wings.
   for i=1,5 do
    local p=self:add(part(self.root,"WingFiligree",Vector3.one,Enum.PartType.Ball,true))
    table.insert(self.trims,{p=p,side=side,index=i})
   end
  end
 end
 if s.halo and haloFigures[s.haloStyle] then
  local sides=haloFigures[s.haloStyle]
  if s.haloStyle=="Infinity" then sides=if hdetail=="Balanced" then 24 elseif hdetail=="Ultra" then 48 else 40 end
  for ring=1,(if s.haloStyle=="Double Diamond" then 2 else 1) do
   local edges={}
   for i=1,sides do edges[i]=self:add(part(self.root,"GeometricHaloEdge",Vector3.one,Enum.PartType.Block,true)) end
   table.insert(self.geoHalos,{ring=ring,edges=edges,sides=sides})
  end
  for i=1,math.min(sides,8) do
   local p=self:add(part(self.root,"HaloOrbitGem",Vector3.one,Enum.PartType.Block,true))
   table.insert(self.ornaments,{p=p,index=i,count=math.min(sides,8)})
  end
 elseif s.halo then
  local _,_,outer,inner=config(hdetail)
  local second=is(s.haloStyle,"Binary","Double Ring","Solar","Lunar","Orbitals","Prism","Eclipse","Lotus")
  for ring,count in {outer,if second then inner else 0} do
   for index=1,count do
    local p=self:add(part(self.root,"HaloSegment",Vector3.one,Enum.PartType.Block,true))
    table.insert(self.beads,{p=p,ring=ring,index=index,count=count})
   end
  end
  local ornaments=if hdetail=="Ultra" then 16 elseif hdetail=="Balanced" then 8 else 12
  for i=1,ornaments do
   local style=s.haloStyle
   local p=self:add(part(self.root,"HaloGem",Vector3.one,if is(style,"Starfall","Lotus","Comet") then Enum.PartType.Ball else Enum.PartType.Block,true))
   table.insert(self.ornaments,{p=p,index=i,count=ornaments})
  end
 end
 if s.neon then self.highlight=U.new("Highlight",{Name="Neon",Adornee=char,DepthMode=Enum.HighlightDepthMode.Occluded},self.root) end
 if not self.preview and (s.neon or s.aura or s.trail) then
  local a=self.scope:add(U.new("Attachment",{Name="AetherEmitter",Position=Vector3.new(0,.5,.5)},body))
  if s.neon then self.light=U.new("PointLight",{Range=9,Shadows=false},a) end
  if s.aura then self.emitter=U.new("ParticleEmitter",{
   Name="Aura",Texture="rbxasset://textures/particles/sparkles_main.dds",
   Lifetime=NumberRange.new(.55,1.3),Speed=NumberRange.new(.8,2.5),
   SpreadAngle=Vector2.new(80,80),LightEmission=.9,
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.18),NumberSequenceKeypoint.new(1,0)})
  },a) end
  if s.trail then
   local b=self.scope:add(U.new("Attachment",{Name="AetherTrailEnd",Position=Vector3.new(0,-.65,.5)},body))
   self.trail=U.new("Trail",{Name="AetherTrail",Attachment0=a,Attachment1=b,
    LightEmission=.85,MinLength=.08,FaceCamera=true,
    Transparency=NumberSequence.new(.15,1)},a)
  end
 end
end
local function wingMetrics(style,v,layer)
 local broad=is(style,"Sylph","Butterfly","Petal")
 local long=is(style,"Phoenix","Storm","Celestial","Royal")
 local dark=is(style,"Raven","Dusk","Eclipse")
 local folded=is(style,"Crystal","Blade","Frost")
 local spread=(.55+2.65*v)*(if broad then .94 else 1)
 local y=if broad then .18+math.sin(v*math.pi)*.84
  elseif long then .05+v*1.07
  elseif dark then .12-v*.58
  elseif folded then .12+v*.52
  else .2+v*.78
 local length=if broad then 1.18-v*.2
  elseif long then 2.1-v*.55
  elseif dark then 1.2+v*.82
  elseif folded then 1.48-v*.48
  else 1.72-v*.69
 local width=if broad then .39 elseif folded then .18 else .27
 if layer==2 then
  spread=spread*.68
  y-=.38
  length*=.61
  width*=.79
 end
 return spread,y,length,width
end
function A:step(char,s,t)
 local body=char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
 local head=char and char:FindFirstChild("Head")
 self:bind(char,body,head,s);if not self.root then return end
 local dt=math.clamp(t-(self.lastAt or t),0,.08);self.lastAt=t
 local hum=char:FindFirstChildOfClass("Humanoid")
 local running=if hum then hum.MoveDirection.Magnitude else 0
 if self.preview and s.walkAnimation then running=1 end
 if hum and (hum.Health<=0 or hum.Sit) then running=0 end
 local smooth=1-math.exp(-dt*9)
 self.walk+=(math.clamp(running,0,1)-self.walk)*smooth
 local speed=if hum then math.clamp(hum.WalkSpeed/16,.55,2) else 1
 self.phase+=dt*(7.7*speed)
 local walk=self.walk
 local time=if s.reduce then 0 else t
 if s.reduce then walk=0 end
 local walkPower=(s.walkIntensity or 65)/100
 local wingWalk=if s.wingWalk==false then 0 else walk*walkPower
 local haloWalk=if s.haloWalk==false then 0 else walk*walkPower
 local scale=s.wingSpan/100*math.clamp(body.Size.X/2,.65,1.5)
 local beat=math.sin(time*s.wingBeat*.032)*.17
 local gait=math.sin(self.phase)*wingWalk
 local bob=math.abs(math.sin(self.phase))*haloWalk
 local mount=body.CFrame*CFrame.new(0,.17,body.Size.Z*.6+.08)
 local function submit(p,cf)
  p.CFrame=cf
 end
 for _,f in self.feathers do
  local v=(f.index-1)/math.max(f.count-1,1)
  local span,y,length,width=wingMetrics(s.wingStyle,v,f.layer)
  local side=f.side
  local rhythm=beat+gait*(.12+.16*v)
  local sweep=math.rad(s.wingSweep)
  local fold=side*(sweep*.25-wingWalk*.12)
  local drift=math.sin(time*1.6+f.index*.51+f.layer)*.055*(if s.reduce then 0 else 1)
  local orientation=mount*CFrame.Angles(0,side*(rhythm-sweep)+fold,0)
    *CFrame.new(side*(.32+span)*scale,(y+drift)*scale,(if f.layer==1 then .23 else .34)*scale)
    *CFrame.Angles(.12+wingWalk*.13,side*.06,-side*(.35+v*.72+gait*.11))
  local len=length*scale
  local thick=(if f.layer==1 then .16 else .12)*scale
  local size=Vector3.new(width*scale,len,thick)
  f.core.Size=size
  submit(f.core,orientation*CFrame.new(0,len*.24,0))
  local veinLength=len*.85
  f.vein.Size=Vector3.new(math.max(.025,len*.035),veinLength,math.max(.035,thick*.35))
  submit(f.vein,orientation*CFrame.new(0,len*.24,thick*.43))
  if f.tip then
   f.tip.Size=Vector3.new(width*.32*scale,width*.32*scale,.09*scale)
   submit(f.tip,orientation*CFrame.new(0,len*.73,thick*.18))
  end
 end
 for _,f in self.geoWings do
  local v=(f.tier-1)/math.max(1,f.count-1)
  local phase=time*(s.wingBeat/100)*.72+f.tier*.42
  local drift=if s.reduce then 0 else math.sin(phase)*.12
  local basis=mount*CFrame.Angles(0,f.side*(beat+gait*.18-math.rad(s.wingSweep)*.35),0)
   *CFrame.new(f.side*(.85+v*2.35)*scale,(.05+v*.75+drift)*scale,.35*scale)
   *CFrame.Angles(.1+drift,f.side*.18,-f.side*(.38+v*.65))
  local radius=(.83-v*.31)*scale*(1+drift*.24)
  local spin=if s.reduce then 0 else f.side*phase*.55
  local function point(i)
   local p=outlinePoint(i,f.sides,radius,s.wingStyle=="Star Wings",spin)
   if s.wingStyle=="Prism Wings" then p=Vector3.new(p.X,p.Y,p.Y*.28) end
   if s.wingStyle=="Triad Wings" then p=Vector3.new(p.X*.75,p.Y*1.35,0) end
   return basis:PointToWorldSpace(p)
  end
  local previous=point(0)
  for i,p in f.edges do local nextPoint=point(i);segment(p,previous,nextPoint,.055*scale);previous=nextPoint end
  f.gem.Size=Vector3.one*(.12+.025*math.sin(phase))*scale
  f.gem.CFrame=basis*CFrame.Angles(phase*.5,phase*.7,0)
 end
 for _,f in self.trims do
  local v=(f.index-1)/4
  local a=mount*CFrame.Angles(0,f.side*(beat+gait*.15-math.rad(s.wingSweep)),0)
  f.p.Size=Vector3.new(.09,.09,.09)*scale
  submit(f.p,a*CFrame.new(f.side*(.38+v*1.65)*scale,(-.19+v*.3)*scale,.42*scale))
 end
 local haloY=s.haloHeight/100+.07
  +math.sin(time*1.8)*.045
  +bob*.11
 local hRadius=s.haloRadius/100
 for _,g in self.geoHalos do
  local spin=time*s.haloSpin*.012*(if g.ring==2 then -1 else 1)
  local r=hRadius*(if g.ring==2 then .65 else 1)
  local basis=head.CFrame*CFrame.new(0,haloY+(g.ring-1)*.12,0)*CFrame.Angles(.12+math.sin(time*.7)*.12,spin+(g.ring-1)*math.pi/4,0)
  local function point(i)
   local angle=i/g.sides*math.pi*2
   if s.haloStyle=="Infinity" then return basis:PointToWorldSpace(Vector3.new(math.sin(angle)*r*1.2,math.sin(angle*2)*.10,math.sin(angle*2)*r*.55)) end
   local p=outlinePoint(i,g.sides,r,s.haloStyle=="Star",math.pi/2)
   return basis:PointToWorldSpace(Vector3.new(p.X,0,p.Y))
  end
  local previous=point(0)
  for i,p in g.edges do local nextPoint=point(i);segment(p,previous,nextPoint,.075);previous=nextPoint end
 end
 for _,b in self.beads do
  local style=s.haloStyle
  local ring=b.ring
  local t0=(b.index-1)/b.count*math.pi*2
  local spin=time*s.haloSpin*.012*(if ring==2 then -1 else 1)
  local a=t0+spin
  local r=hRadius*(if ring==1 then 1 elseif style=="Orbitals" then 1.18 else .72)
  local tilt=if style=="Orbitals" then (if ring==2 then .97 else -.19)
   elseif style=="Lunar" then -.44
   elseif style=="Solar" then .12
   elseif style=="Eclipse" then (if ring==2 then -.62 else .45)
   elseif style=="Prism" then (if ring==2 then .65 else -.35)
   else (if ring==2 then -.17 else .07)
  local rise=if style=="Spiral" then t0/math.pi*.23
   elseif style=="Comet" then math.sin(t0*2)*.15
   else 0
  local ringBasis=head.CFrame*CFrame.new(0,haloY,0)
   *CFrame.Angles(tilt+haloWalk*math.sin(self.phase)*.11,0,0)
   *CFrame.Angles(0,a,0)*CFrame.new(0,rise,r)
  local crown=is(style,"Crown","Thorns","Starfall") and b.index%4==0 and ring==1
  b.p.Size=Vector3.new(2*r*math.sin(math.pi/b.count)*1.025,if crown then .22 else .077,if ring==2 then .055 else .10)
  submit(b.p,ringBasis)
 end
 for _,o in self.ornaments do
  local style=s.haloStyle
  local n=o.index
  local a=(n-1)/o.count*math.pi*2+time*s.haloSpin*.011
  local radius=hRadius*(if style=="Starfall" or style=="Comet" then 1.23 else .97)
  local height=if style=="Crown" then .35
   elseif style=="Thorns" then .24
   elseif style=="Lotus" then .14
   elseif style=="Solar" then math.sin(n*1.57)*.15
   else .06
  local size
  if is(style,"Crown","Thorns","Solar") then
   size=Vector3.new(.12,if style=="Crown" then .43 else .30,.12)
  elseif is(style,"Lotus","Starfall","Comet") then
   size=Vector3.new(.17,.25,.1)
  else size=Vector3.new(.15,.16,.15) end
  o.p.Size=size
  local basis=head.CFrame*CFrame.new(0,haloY,0)*CFrame.Angles(.1,0,0)
   *CFrame.Angles(0,a,0)*CFrame.new(0,height,radius)
   *CFrame.Angles(if style=="Lotus" then .66 else 0,0,a)
  submit(o.p,basis)
 end
 if t-self.paintAt>=.09 or self.settings~=s then
  self.settings=s;self.paintAt=t
  local accent=U.hex(s.secondary)
  local wingColor=U.hex(s.wingColor)
  for _,f in self.feathers do
   local v=(f.index-1)/math.max(f.count-1,1)
   local color=if s.wingRainbow then Color3.fromHSV((time*.1+v*.25+f.layer*.1)%1,.56,1)
    else wingColor:Lerp(accent,math.clamp(v*.32+(.11*(f.layer-1)),0,.6))
   f.core.Color=color
   f.vein.Color=color:Lerp(Color3.new(1,1,1),.55)
   if f.tip then f.tip.Color=accent:Lerp(color,.4) end
  end
  for _,f in self.trims do f.p.Color=accent:Lerp(wingColor,f.index*.1) end
  local haloColor=U.hex(s.haloColor)
  for _,g in self.geoWings do
   for i,p in g.edges do p.Color=if s.wingRainbow then Color3.fromHSV((time*.09+i/#g.edges+g.tier*.13)%1,.55,1) else wingColor:Lerp(accent,(i/#g.edges)*.6) end
   g.gem.Color=accent
  end
  for _,g in self.geoHalos do
   for i,p in g.edges do p.Color=if s.haloRainbow then Color3.fromHSV((time*.10+i/#g.edges)%1,.55,1) else haloColor:Lerp(accent,i/#g.edges*.5) end
  end
  for _,b in self.beads do
   b.p.Color=if s.haloRainbow then Color3.fromHSV((time*.1+b.index/b.count+(.23*(b.ring-1)))%1,.58,1)
    else haloColor:Lerp(accent,if b.ring==2 then .46 else .12)
  end
  for _,o in self.ornaments do
   o.p.Color=if s.haloRainbow then Color3.fromHSV((time*.1+o.index/o.count)%1,.5,1)
    else accent:Lerp(haloColor,.53)
  end
  if self.highlight then
   local c=if s.neonRainbow then Color3.fromHSV(time*.12%1,.66,1) else U.hex(s.neonColor)
   self.highlight.OutlineColor=c;self.highlight.FillColor=c
   self.highlight.FillTransparency=1-s.neonFill/100;self.highlight.OutlineTransparency=.12
   if self.light then self.light.Color=c;self.light.Brightness=s.neonLight*.035 end
  end
  if self.emitter then
   self.emitter.Color=ColorSequence.new(U.hex(s.auraColor),accent)
   self.emitter.Rate=if s.reduce then 0 else s.auraRate
  end
  if self.trail then
   self.trail.Enabled=not s.reduce
   self.trail.Color=ColorSequence.new(U.hex(s.auraColor),accent)
   self.trail.Lifetime=s.trailLife/1000
  end
 end
end
function A.mannequin(world)
 local m=U.new("Model",{Name="PreviewRig"},world)
 for _,v in {{"UpperTorso",0,1.8,0,2,1.6,1},{"Head",0,3.15,0,1.2,1.2,1.2},
  {"LeftArm",-1.4,1.8,0,.65,1.9,.7},{"RightArm",1.4,1.8,0,.65,1.9,.7},
  {"LeftLeg",-.5,.1,0,.85,1.8,.8},{"RightLeg",.5,.1,0,.85,1.8,.8}} do
  local p=part(m,v[1],Vector3.new(v[5],v[6],v[7]),if v[1]=="Head" then Enum.PartType.Ball else Enum.PartType.Block,false)
  p.Color=Color3.fromRGB(89,80,119);p.Position=Vector3.new(v[2],v[3],v[4])
 end
 return m
end
return A

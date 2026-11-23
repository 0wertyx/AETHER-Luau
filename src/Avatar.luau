local U=require(script.Parent.Util)
local A={};A.__index=A
local function part(parent,name,size,shape)
 return U.new("Part",{Name=name,Size=size,Shape=shape or Enum.PartType.Block,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon},parent)
end
function A.new(parent,preview)
 return setmetatable({parent=parent,preview=preview,feathers={},beads={},parts={},frames={},key="",paintAt=-1},A)
end
function A:clear()
 if self.scope then self.scope:clear();self.scope=nil end;self.root=nil;self.highlight=nil;self.emitter=nil;self.trail=nil;self.light=nil;self.char=nil;self.body=nil;self.key="";table.clear(self.feathers);table.clear(self.beads);table.clear(self.parts);table.clear(self.frames)
end
function A:bind(char,body,head,s)
 local key=table.concat({tostring(s.wings),s.wingStyle,tostring(s.halo),s.haloStyle,tostring(s.neon),tostring(s.aura),tostring(s.trail)},"/")
 if not (body and head and char) or not(s.wings or s.halo or s.neon or s.aura or s.trail) then if self.root then self:clear() end;return end
 if self.key==key and self.char==char and self.body==body then return end;self:clear();self.key=key;self.char=char;self.body=body;self.scope=U.scope();self.root=self.scope:add(U.new("Folder",{Name="AetherAvatarFX"},self.parent));self.paintAt=-1
 if s.wings then for _,side in {-1,1} do for i=1,if s.wingStyle=="Sylph" then 6 else 9 do
  local p=part(self.root,"Wing",Vector3.one,if s.wingStyle=="Blade" then Enum.PartType.Block else Enum.PartType.Ball);table.insert(self.feathers,{p=p,side=side,i=i});table.insert(self.parts,p)
 end end end
 if s.halo then local count=if s.haloStyle=="Binary" then 36 else 24;for i=1,count do local p=part(self.root,"Halo",Vector3.one,if s.haloStyle=="Crown" and i%3==0 then Enum.PartType.Ball else Enum.PartType.Block);table.insert(self.beads,p);table.insert(self.parts,p) end end
 if s.neon then self.highlight=U.new("Highlight",{Name="Neon",Adornee=char,DepthMode=Enum.HighlightDepthMode.Occluded},self.root) end
 if not self.preview and (s.neon or s.aura or s.trail) then
  -- Attachments belong to this renderer. No changes to rig geometry, motors or character materials.
  local a=self.scope:add(U.new("Attachment",{Name="AetherEmitter",Position=Vector3.new(0,.5,.5)},body))
  if s.neon then self.light=U.new("PointLight",{Range=9,Shadows=false},a) end
  if s.aura then self.emitter=U.new("ParticleEmitter",{Name="Aura",Texture="rbxasset://textures/particles/sparkles_main.dds",Lifetime=NumberRange.new(.55,1.3),Speed=NumberRange.new(.8,2.5),SpreadAngle=Vector2.new(80,80),LightEmission=.9,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.18),NumberSequenceKeypoint.new(1,0)})},a) end
  if s.trail then local b=self.scope:add(U.new("Attachment",{Name="AetherTrailEnd",Position=Vector3.new(0,-.65,.5)},body));self.trail=U.new("Trail",{Name="AetherTrail",Attachment0=a,Attachment1=b,LightEmission=.85,MinLength=.08,FaceCamera=true,Transparency=NumberSequence.new(.15,1)},a) end
 end
end
function A:step(char,s,t)
 local body=char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"));local head=char and char:FindFirstChild("Head")
 self:bind(char,body,head,s);if not self.root then return end
 local time=if s.reduce then 0 else t;local scale=s.wingSpan/100*math.clamp(body.Size.X/2,.65,1.5);local flap=math.sin(time*s.wingBeat*.032)*.26;local idx=0
 for _,f in self.feathers do
  local i=f.i;local v=(i-1)/8;local side=f.side;local wing=s.wingStyle;local y=if wing=="Sylph" then math.sin(v*5)*.95 else .15+v*(if wing=="Blade" then .8 else .58)
  local len=(if wing=="Blade" then 1.8-v*.7 elseif wing=="Sylph" then 1.4-v*.45 else 1.8-v*.9)*scale
  local size=Vector3.new((if wing=="Sylph" then .48 else .25)*scale,len,.15*scale);if f.p.Size~=size then f.p.Size=size end
  idx+=1;self.frames[idx]=body.CFrame*CFrame.new(0,0,body.Size.Z*.54)*CFrame.Angles(0,side*(flap-math.rad(s.wingSweep)),0)*CFrame.new(side*(.65+2.5*v)*scale,y*scale,.25+v*.18)*CFrame.Angles(.15,0,-side*(.48+v*.7))
 end
 for i,p in self.beads do local ring=(s.haloStyle=="Binary" and i>24);local n=if ring then 12 else 24;local r=s.haloRadius/100*(if ring then .73 else 1);local a=(i-1)/n*math.pi*2+time*s.haloSpin*.013*(if ring then -1 else 1);local crown=s.haloStyle=="Crown" and i%3==0
  local size=Vector3.new(2*math.sin(math.pi/n)*r*1.04,if crown then .38 else .075,if crown then .13 else .09);if p.Size~=size then p.Size=size end;idx+=1;self.frames[idx]=head.CFrame*CFrame.new(0,s.haloHeight/100+(if ring then .2 else 0)+.05*math.sin(time*2),0)*CFrame.Angles(if ring then .27 else 0,a,0)*CFrame.new(0,if crown then .1 else 0,r)
 end
 if idx>0 then for i,p in self.parts do p.CFrame=self.frames[i] end end
 if t-self.paintAt>=.07 or self.settings~=s then
  self.settings=s;self.paintAt=t;local col=U.hex(s.secondary);for _,f in self.feathers do f.p.Color=if s.wingRainbow then Color3.fromHSV((time*.1+f.i*.052)%1,.55,1) else U.hex(s.wingColor):Lerp(col,(f.i-1)/14) end
  for i,p in self.beads do p.Color=if s.haloRainbow then Color3.fromHSV((time*.1+i/#self.beads)%1,.58,1) else U.hex(s.haloColor):Lerp(col,.25*(1+math.sin(i*.6))) end
  if self.highlight then local c=if s.neonRainbow then Color3.fromHSV(time*.12%1,.66,1) else U.hex(s.neonColor);self.highlight.OutlineColor=c;self.highlight.FillColor=c;self.highlight.FillTransparency=1-s.neonFill/100;self.highlight.OutlineTransparency=.12;if self.light then self.light.Color=c;self.light.Brightness=s.neonLight*.035 end end
  if self.emitter then self.emitter.Color=ColorSequence.new(U.hex(s.auraColor),col);self.emitter.Rate=if s.reduce then 0 else s.auraRate end
  if self.trail then self.trail.Enabled=not s.reduce;self.trail.Color=ColorSequence.new(U.hex(s.auraColor),col);self.trail.Lifetime=s.trailLife/1000 end
 end
end
function A.mannequin(world)
 local m=U.new("Model",{Name="PreviewRig"},world);for _,v in {{"UpperTorso",0,1.8,0,2,1.6,1},{"Head",0,3.15,0,1.2,1.2,1.2},{"LeftArm",-1.4,1.8,0,.65,1.9,.7},{"RightArm",1.4,1.8,0,.65,1.9,.7},{"LeftLeg",-.5,.1,0,.85,1.8,.8},{"RightLeg",.5,.1,0,.85,1.8,.8}} do local p=part(m,v[1],Vector3.new(v[5],v[6],v[7]),if v[1]=="Head" then Enum.PartType.Ball else Enum.PartType.Block);p.Color=Color3.fromRGB(89,80,119);p.Material=Enum.Material.SmoothPlastic;p.Position=Vector3.new(v[2],v[3],v[4]) end;return m
end
return A

-- Local cosmetic falling stars; pooled, anchored, non-colliding geometry.
local U=require(script.Parent.Util)
local Input=game:GetService("UserInputService")
local F={};F.__index=F
local RNG=Random.new()
local MAX_STARS=16
-- A softened five-point silhouette. Sample quadratic corner arcs once,
-- rather than merely placing round caps at the original sharp tips.
local raw={}
for i=0,9 do
 local angle=math.pi/2+i*math.pi/5
 local radius=if i%2==0 then 1 else .58
 raw[i+1]=Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,0)
end
local outline={}
local maxRadius=0
for i=1,10 do
 local p=raw[i]
 local a=p:Lerp(raw[(i-2)%10+1],.46)
 local b=p:Lerp(raw[i%10+1],.46)
 for _,t in {.18,.82} do
  local q=a*(1-t)^2+p*(2*t*(1-t))+b*t^2
  outline[#outline+1]=q
  maxRadius=math.max(maxRadius,q.Magnitude)
 end
end
for i,p in outline do outline[i]=p/maxRadius end
local VERTICES=#outline
local function part(parent,shape)
 return U.new("Part",{Name="StarRay",Shape=shape or Enum.PartType.Block,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(.1,.1,.1),Material=Enum.Material.Neon},parent)
end
local function segment(p,a,b,width)
 local d=b-a
 if d.Magnitude<.001 then p.Transparency=1;return false end
 local cf=CFrame.lookAt((a+b)*.5,b,if math.abs(d.Unit.Y)>.98 then Vector3.xAxis else Vector3.yAxis)
 if p.Shape==Enum.PartType.Cylinder then
  p.Size=Vector3.new(d.Magnitude,width,width)
  p.CFrame=cf*CFrame.Angles(0,math.pi/2,0)
 else
  p.Size=Vector3.new(width,width,d.Magnitude)
  p.CFrame=cf
 end
 return true
end
function F.new() return setmetatable({pool={}},F) end
function F:clear()
 if self.root then self.root:Destroy();self.root=nil end
 table.clear(self.pool);self.camera=nil;self.last=nil
end
function F:spawn(star,cam,initial)
 local origin=cam.CFrame.Position
 local forward=cam.CFrame.LookVector*Vector3.new(1,0,1)
 if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
 local right=Vector3.new(-forward.Z,0,forward.X)
 star.pos=origin+forward*RNG:NextNumber(15,85)+right*RNG:NextNumber(-65,65)+Vector3.new(0,if initial then RNG:NextNumber(-10,70) else RNG:NextNumber(45,80),0)
 star.age=0;star.scale=RNG:NextNumber(.65,1.3);star.speed=RNG:NextNumber(.7,1.35);star.phase=RNG:NextNumber(0,math.pi*2);star.tint=RNG:NextNumber();star.spinDirection=if RNG:NextNumber()<.5 then -1 else 1
end
function F:step(s,now)
 local cam=workspace.CurrentCamera
 if not s.starfall or s.reduce or not cam then if self.root then self:clear() end;return end
 if cam~=self.camera then self:clear();self.camera=cam end
 if not self.root then self.root=U.new("Folder",{Name="AetherStarfall"},cam) end
 local dt=math.clamp(now-(self.last or now),0,.1);self.last=now
 local count=math.clamp(math.floor(s.starfallCount),1,if Input.TouchEnabled and not Input.KeyboardEnabled then 8 else MAX_STARS)
 local colorA,colorB=U.hex(s.starfallA),U.hex(s.starfallB)
 local material=Enum.Material[s.starfallMaterial] or Enum.Material.Neon
 if material==Enum.Material.Neon and s.starfallGlow==0 then material=Enum.Material.SmoothPlastic end
 while #self.pool<count do
  local star={rays={}}
  for i=1,VERTICES do star.rays[i]=part(self.root,Enum.PartType.Cylinder) end
  for i=1,VERTICES do star.rays[VERTICES+i]=part(self.root,Enum.PartType.Ball) end
  star.rays[VERTICES*2+1]=part(self.root)
  self:spawn(star,cam,true);self.pool[#self.pool+1]=star
 end
 for i,star in self.pool do
  if i>count then for _,p in star.rays do p.Transparency=1 end;continue end
  star.age+=dt
  star.pos+=Vector3.new(2*dt,-s.starfallSpeed*star.speed*dt,0)
  if star.pos.Y<cam.CFrame.Position.Y-25 or (star.pos-cam.CFrame.Position).Magnitude>150 or star.age>12 then self:spawn(star,cam,false) end
  local r=s.starfallSize/10*star.scale
  local opacity=s.starfallOpacity/100
  local tint=if s.starfallRainbow then Color3.fromHSV((now*.12+star.tint)%1,.55,1) else colorA:Lerp(colorB,star.tint)
  local cf=CFrame.new(star.pos)*cam.CFrame.Rotation*CFrame.Angles(0,0,star.phase+star.age*math.rad(s.starfallRotation)*star.spinDirection)
  local width=math.max(.045,r*.29)
  for j=1,VERTICES do
   local a=cf:PointToWorldSpace(outline[j]*r)
   local b=cf:PointToWorldSpace(outline[j%VERTICES+1]*r)
   local p=star.rays[j]
   if segment(p,a,b,width) then p.Color=tint;p.Material=material;p.Transparency=1-opacity end
   local joint=star.rays[VERTICES+j]
   joint.Size=Vector3.one*width
   joint.Position=a;joint.Color=tint;joint.Material=material;joint.Transparency=1-opacity
  end
  local tail=star.rays[VERTICES*2+1]
  if s.starfallTail then
   local len=math.min(10,s.starfallSpeed*.12)
   if segment(tail,star.pos+Vector3.new(0,r*.5,0),star.pos+Vector3.new(0,r+len,0),math.max(.04,r*.08)) then tail.Material=material;tail.Color=tint;tail.Transparency=1-opacity*.35 end
  else tail.Transparency=1 end
 end
end
return F

-- Local cosmetic falling stars; pooled, anchored, non-colliding geometry.
local U=require(script.Parent.Util)
local Input=game:GetService("UserInputService")
local F={};F.__index=F
local RNG=Random.new()
local MAX_STARS=16
local function part(parent)
 return U.new("Part",{Name="StarRay",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(.1,.1,.1),Material=Enum.Material.Neon},parent)
end
local function segment(p,a,b,width)
 local d=b-a
 if d.Magnitude<.001 then p.Transparency=1;return false end
 p.Size=Vector3.new(width,width,d.Magnitude)
 p.CFrame=CFrame.lookAt((a+b)*.5,b,if math.abs(d.Unit.Y)>.98 then Vector3.xAxis else Vector3.yAxis)
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
 star.age=0;star.scale=RNG:NextNumber(.65,1.3);star.speed=RNG:NextNumber(.7,1.35);star.phase=RNG:NextNumber(0,math.pi*2);star.tint=RNG:NextNumber();star.spark=RNG:NextNumber()<.5
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
  for i=1,6 do star.rays[i]=part(self.root) end
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
  local cf=CFrame.new(star.pos)*cam.CFrame.Rotation*CFrame.Angles(0,0,star.phase+star.age*.6)
  local spark=s.starfallStyle=="Sparks" or (s.starfallStyle=="Mixed" and star.spark)
  local function vertex(j)
   local a=j*math.pi*2/5+math.pi/2
   return cf:PointToWorldSpace(Vector3.new(math.cos(a)*r,math.sin(a)*r,0))
  end
  for j=1,5 do
   local p=star.rays[j]
   local a,b
   if spark then
    if j>2 then p.Transparency=1;continue end
    local v=if j==1 then cf.UpVector*r else cf.RightVector*r
    a,b=star.pos-v,star.pos+v
   else a,b=vertex(j-1),vertex((j+1)%5) end
   if segment(p,a,b,math.max(.045,r*.13)) then p.Color=tint;p.Material=material;p.Transparency=1-opacity end
  end
  local tail=star.rays[6]
  if s.starfallTail then
   local len=math.min(10,s.starfallSpeed*.12)
   if segment(tail,star.pos+Vector3.new(0,r*.5,0),star.pos+Vector3.new(0,r+len,0),math.max(.04,r*.08)) then tail.Material=material;tail.Color=tint;tail.Transparency=1-opacity*.35 end
  else tail.Transparency=1 end
 end
end
return F

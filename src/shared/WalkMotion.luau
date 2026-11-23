-- Additive R6 / R15 walking, graceful glide, and ethereal hover.
-- Poses are visual-only; HumanoidRootPart physics and game controls are unchanged.
-- Evaluated at PreSimulation after Animator's own animation tracks.
local W={}
W.__index=W
local function motor(rig,...)
 for _,name in {...} do
  local m=rig:FindFirstChild(name,true)
  if m and m:IsA("Motor6D") then return m end
 end
 return nil
end
function W.new()
 return setmetatable({character=nil,motors={},phase=0,blend=0,hover=0},W)
end
function W:bind(character)
 if self.character==character then return end
 self.character=character;self.phase=0;self.blend=0;self.hover=0
 table.clear(self.motors)
 if not character then return end
 local j=self.motors
 j.RightHip=motor(character,"RightHip","Right Hip")
 j.LeftHip=motor(character,"LeftHip","Left Hip")
 j.RightShoulder=motor(character,"RightShoulder","Right Shoulder")
 j.LeftShoulder=motor(character,"LeftShoulder","Left Shoulder")
 j.RightElbow=motor(character,"RightElbow")
 j.LeftElbow=motor(character,"LeftElbow")
 j.RightKnee=motor(character,"RightKnee")
 j.LeftKnee=motor(character,"LeftKnee")
 j.RightAnkle=motor(character,"RightAnkle")
 j.LeftAnkle=motor(character,"LeftAnkle")
 j.Waist=motor(character,"Waist")
 j.Neck=motor(character,"Neck")
 j.Root=motor(character,"RootJoint","Root")
end
local function add(j,cf)
 if j and j.Parent then j.Transform=j.Transform*cf end
end
function W:step(character,s,dt)
 self:bind(character)
 if not character then return end
 local hum=character:FindFirstChildOfClass("Humanoid")
 if not hum or not hum:FindFirstChildOfClass("Animator") then return end
 dt=math.clamp(dt,0,.07)
 local style=s.walkStyle or "Natural"
 local pack=MotionPacks.get(style)
 local floating=style=="Floating" or style=="Glide" or style=="Ethereal"
 local enabled=s.walkAnimation and not s.reduce and hum.Health>0 and not hum.Sit
 local state=hum:GetState()
 local jumping=state==Enum.HumanoidStateType.Jumping
 local falling=state==Enum.HumanoidStateType.Freefall
 local climbing=state==Enum.HumanoidStateType.Climbing
 local swimming=state==Enum.HumanoidStateType.Swimming
 local airborne=jumping or falling
 local grounded=hum.FloorMaterial~=Enum.Material.Air
 local movement=hum.MoveDirection.Magnitude
 local intensity=math.clamp((s.walkIntensity or 65)/100,0,1)
 local target=if enabled then intensity*(if pack then
   (if movement>.08 or airborne or climbing or swimming then 1 else if pack.hover then .82 else .6)
   elseif floating then (if grounded then .62+.38*movement else 1)
   else (if grounded then movement else 0)) else 0
 self.blend+=(target-self.blend)*(1-math.exp(-dt*9))
 if self.blend<.002 then return end
 local speed=math.clamp(hum.WalkSpeed/16,.6,2.3)
 local moving=math.clamp(movement,0,1)
 local cadence=if pack then pack.cadence*(.62+.38*moving)*speed
  elseif floating then (2.3+2.8*moving)*speed else 7.8*speed
 self.phase+=dt*cadence
 local ph=self.phase;local wave=math.sin(ph);local cross=math.cos(ph)
 local weight=self.blend
 local j=self.motors
 if pack then
  -- Original procedural interpretation of an avatar pack (not purchased clips).
  -- Each state has its own posture, on both R6 and R15; optional joints on R15.
  local snap=pack.snap or 0
  local stepped=if wave>=0 then math.sqrt(wave) else -math.sqrt(-wave)
  local gait=wave*(1-snap)+stepped*snap
  local stride=if airborne then .08 elseif climbing then .25
   elseif swimming then .15 else pack.stride
  local walk=if airborne then .14 else if moving>.08 then moving else 0
  local run=if moving>.08 and hum.WalkSpeed>19 then 1 else 0
  local cycle=gait*walk
  local swing=stride*cycle*(1+run*.3)
  local pitch=pack.lean*(if moving>.08 or airborne then 1 else .32)
  local roll=(pack.roll or 0)*math.sin(ph*.5)*(.32+walk*.68)
  local twist=(pack.twist or 0)*cycle
  local hover=pack.hover or 0
  local floatY=hover*(.75+.25*math.sin(ph*.53))
  local bounce=(pack.bob or .03)*math.abs(cross)*walk
  local jumpAngle=if jumping then -.13 elseif falling then .12 else 0
  local rest=pack.rest or 0
  local spread=pack.spread or 0
  local arms=pack.arms or .2
  local armCycle=cycle*arms
  local idleWave=math.sin(ph*.65)*.045
  if swimming then
   pitch=-.22
   armCycle=math.cos(ph)*.18
   spread+=.30
  elseif climbing then
   pitch=.08
   armCycle=math.cos(ph)*.31
   swing=math.sin(ph)*.21
  elseif airborne then
   spread+=.11
   rest-=.12
  end
  if style=="Ninja" then
   -- Quiet forward lean and arms back, restrained footfall.
   rest-=.12*walk;pitch+=.085*walk;roll*=.5
  elseif style=="Bubbly" or style=="Cartoony" then
   bounce*=1.16
   spread+=math.abs(cross)*.09*walk
  elseif style=="Robot" or style=="Toy" then
   -- Sharper cadence with an intentionally stiff trunk.
   roll*=.35
   twist*=.35
  elseif style=="Stylish" then
   roll+=.045
   twist+=.02
  elseif style=="Zombie" then
   -- Uneven, slow shuffling gait.
   swing*=.72
   rest+=.08
   pitch+=.08
  elseif style=="Mage" or style=="Levitation" or style=="Astronaut" then
   -- Soft sustained buoyancy even at rest. No physical lift.
   swing*=.45
   rest-=.09
  end
  local r6=hum.RigType==Enum.HumanoidRigType.R6
  local scale=if r6 then .78 else 1
  local leftKnee=-(pack.knee or 0)*(.3+.7*math.max(0,-gait))*walk
  local rightKnee=-(pack.knee or 0)*(.3+.7*math.max(0,gait))*walk
  if airborne then rightKnee-=.13;leftKnee-=.13 end
  add(j.Root,CFrame.new(0,(floatY+bounce)*weight,0)
    *CFrame.Angles((pitch+jumpAngle)*weight,twist*.38*weight,roll*.5*weight))
  add(j.Waist,CFrame.Angles((-pitch*.34+idleWave*.3)*weight,twist*weight,roll*weight))
  add(j.Neck,CFrame.Angles((-pitch*.25+idleWave)*weight,-twist*.4*weight,-roll*.35*weight))
  add(j.RightHip,CFrame.Angles((swing+jumpAngle*.45)*weight*scale,0,(-spread*.14+roll*.25)*weight))
  add(j.LeftHip,CFrame.Angles((-swing+jumpAngle*.45)*weight*scale,0,(spread*.14+roll*.25)*weight))
  add(j.RightShoulder,CFrame.Angles((rest-armCycle+idleWave)*weight*scale,0,(-spread+roll*.14)*weight))
  add(j.LeftShoulder,CFrame.Angles((rest+armCycle-idleWave)*weight*scale,0,(spread+roll*.14)*weight))
  add(j.RightElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33)*weight,0,0))
  add(j.LeftElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33)*weight,0,0))
  add(j.RightKnee,CFrame.Angles(rightKnee*weight,0,0))
  add(j.LeftKnee,CFrame.Angles(leftKnee*weight,0,0))
  add(j.RightAnkle,CFrame.Angles(((pack.ankle or 0)*gait*walk)*weight,0,0))
  add(j.LeftAnkle,CFrame.Angles((-(pack.ankle or 0)*gait*walk)*weight,0,0))
 elseif floating then
  -- The floating pose is visible at rest and in air; no physical elevation.
  local spread=if style=="Ethereal" then .37 elseif style=="Glide" then .16 else .22
  local graceful=if style=="Ethereal" then 1.18 elseif style=="Glide" then .9 else .75
  local hover=math.sin(ph)*.065*graceful
  local lean=math.clamp(moving*(if style=="Glide" then .19 else .105),0,.22)
  local foot=if style=="Ethereal" then .26 else .15
  local back=if style=="Glide" then -.25 else .03
  add(j.Root,CFrame.new(0,(.13+hover)*weight,0)*CFrame.Angles(lean*weight,math.sin(ph*.5)*.045*weight,math.sin(ph*.65)*.045*weight))
  add(j.Waist,CFrame.Angles((-lean*.48+wave*.025)*weight,math.sin(ph*.55)*.045*weight,-wave*.06*weight))
  add(j.Neck,CFrame.Angles((-lean*.18+math.sin(ph+.5)*.03)*weight,0,math.sin(ph*.5)*.045*weight))
  -- Loose, buoyant shoulders: R6 and R15 both have shoulder motors.
  add(j.RightShoulder,CFrame.Angles((back+wave*.1)*weight,0,(-spread+cross*.10)*weight))
  add(j.LeftShoulder,CFrame.Angles((back-wave*.1)*weight,0,(spread-cross*.10)*weight))
  add(j.RightElbow,CFrame.Angles(-.21*weight,0,.09*weight))
  add(j.LeftElbow,CFrame.Angles(-.21*weight,0,-.09*weight))
  add(j.RightHip,CFrame.Angles((.12+wave*.13*graceful)*weight,0,.10*weight))
  add(j.LeftHip,CFrame.Angles((.12-wave*.13*graceful)*weight,0,-.10*weight))
  add(j.RightKnee,CFrame.Angles((-foot-wave*.07)*weight,0,0))
  add(j.LeftKnee,CFrame.Angles((-foot+wave*.07)*weight,0,0))
  add(j.RightAnkle,CFrame.Angles((foot*.53+wave*.035)*weight,0,0))
  add(j.LeftAnkle,CFrame.Angles((foot*.53-wave*.035)*weight,0,0))
 else
  -- Natural / Heroic / Bouncy: subtle animation layered over existing walk.
  local power=if style=="Heroic" then .22 elseif style=="Bouncy" then .21 else .15
  local leg=wave*power*weight
  local arm=-leg*.82
  local dip=(if style=="Bouncy" then .085 else .036)*math.abs(cross)*weight
  local twist=wave*(if style=="Heroic" then .09 else .043)*weight
  add(j.RightHip,CFrame.Angles(leg,0,0))
  add(j.LeftHip,CFrame.Angles(-leg,0,0))
  add(j.RightShoulder,CFrame.Angles(arm,0,twist*.32))
  add(j.LeftShoulder,CFrame.Angles(-arm,0,-twist*.32))
  add(j.RightKnee,CFrame.Angles(-math.max(0,-leg)*.2,0,0))
  add(j.LeftKnee,CFrame.Angles(-math.max(0,leg)*.2,0,0))
  add(j.Waist,CFrame.new(0,dip,0)*CFrame.Angles(dip*.18,twist,0))
  add(j.Neck,CFrame.Angles(0,-twist*.36,0))
  add(j.Root,CFrame.new(0,dip*.5,0)*CFrame.Angles(0,twist*.55,0))
 end
end
function W:destroy()
 self.character=nil
 table.clear(self.motors)
end
return W

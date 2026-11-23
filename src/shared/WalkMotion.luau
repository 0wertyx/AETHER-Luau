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
 local floating=style=="Floating" or style=="Glide" or style=="Ethereal"
 local enabled=s.walkAnimation and not s.reduce and hum.Health>0 and not hum.Sit
 local grounded=hum.FloorMaterial~=Enum.Material.Air
 local movement=hum.MoveDirection.Magnitude
 local intensity=math.clamp((s.walkIntensity or 65)/100,0,1)
 local target=if enabled then intensity*(if floating then (if grounded then .62+.38*movement else 1) else (if grounded then movement else 0)) else 0
 self.blend+=(target-self.blend)*(1-math.exp(-dt*9))
 if self.blend<.002 then return end
 local speed=math.clamp(hum.WalkSpeed/16,.6,2.3)
 local moving=math.clamp(movement,0,1)
 self.phase+=dt*(if floating then (2.3+2.8*moving)*speed else 7.8*speed)
 local ph=self.phase;local wave=math.sin(ph);local cross=math.cos(ph)
 local weight=self.blend
 local j=self.motors
 if floating then
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

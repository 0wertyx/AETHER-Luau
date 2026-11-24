-- Additive R6 / R15 walking, graceful glide, and ethereal hover.
-- Poses are visual-only; HumanoidRootPart physics and game controls are unchanged.
-- Evaluated at PreSimulation after Animator's own animation tracks.
local MotionPacks=require(script.Parent.MotionPacks)
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
 local target=0
 if enabled then
  if pack then
   target=intensity*(if movement>.08 or airborne or climbing or swimming then 1
    elseif pack.hover then .82 else .6)
  elseif floating then
   target=intensity*(if grounded then .62+.38*movement else 1)
  else
   target=intensity*(if grounded then movement else 0)
  end
 end
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
  local walk=if airborne then .14 elseif moving>.08 then moving else 0
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
  -- UGC-inspired choreography. These are ORIGINAL and purposely subtle
  -- additive poses; we do not download or replay creator animation clips.
  local mode=pack.mode
  local bodyShift=0
  local headPitch=0
  local headRoll=0
  local hipPair=0
  local hipSide=0
  local armYaw=0
  local elbowBend=0
  local kneeBend=0
  local rootRoll=0
  local shoulderAsym=0
  if mode=="angel" then
   -- Open shoulders with feather-light landing and a hovering silhouette.
   spread+=.13;rest-=.09;floatY+=math.sin(ph*.5)*.04
   armYaw=math.sin(ph*.42)*.08;hipPair=.13;headPitch=-.045
  elseif mode=="bat" then
   -- Sweeping wings, low forward soar, pitched fall recovery.
   spread+=math.sin(ph*1.1)*.16
   rest-=.13*walk;pitch+=.11*walk
   shoulderAsym=math.sin(ph*1.3)*.14
   rootRoll=math.sin(ph*.4)*.055
  elseif mode=="mermaid" then
   -- Paired legs form a tail-like wave, without changing the avatar's rig.
   swing*=.12;hipPair=.08+math.sin(ph*.76)*.21
   kneeBend=-.16-.12*math.sin(ph*.8)
   rootRoll=math.sin(ph*.5)*.12
   armYaw=math.sin(ph*.7)*.13
  elseif mode=="serpent" then
   -- Smooth S-curves along torso and alternating shoulder/hip yaw.
   swing*=.5;twist+=math.sin(ph*.5)*.17
   rootRoll=math.sin(ph*.5+.6)*.085
   bodyShift=math.sin(ph*.5)*.065
   armYaw=math.sin(ph*.5+.9)*.17
  elseif mode=="cartwheel" then
   -- Suggestive rolling acrobatic pose; no physical tumbling.
   rootRoll=math.sin(ph*.54)*.22*walk
   spread+=.22
   armYaw=math.sin(ph*.54)*.15
   hipSide=.13*math.cos(ph*.54)*walk
  elseif mode=="rubber" then
   -- Rubber-hose, overshooting arms and exaggerated stretch-squash.
   bounce*=1.4
   rootRoll=math.sin(ph*.77)*.09
   elbowBend=-.28+.16*math.sin(ph*1.4)
   hipPair=math.abs(math.sin(ph))*.08*walk
  elseif mode=="sleep" then
   -- Drifting doze with tucked arms and gently dangling feet.
   pitch-=.09;headPitch=.19;rest+=.18
   spread-=.09;hipPair=.12;kneeBend=-.25
   rootRoll=math.sin(ph*.3)*.09
  elseif mode=="plush" then
   -- Rounded plush-toy posture and tiny alternating feet.
   swing*=.48;rest+=.18
   elbowBend=-.35;hipPair=.09;headPitch=-.05
   bounce*=1.15
  elseif mode=="paws" then
   -- Cat-paw elbows and quick foot-taps.
   rest+=.14;elbowBend=-.42
   armYaw=.12;headRoll=math.sin(ph*.6)*.07
   swing*=.74;bounce*=1.09
  elseif mode=="shy" then
   -- Small crossed-in arms, inward-looking posture.
   rest+=.20;spread-=.07;elbowBend=-.28
   headPitch=.09;hipSide=-.09
   bodyShift=math.sin(ph*.65)*.032
  elseif mode=="gymnast" then
   -- Open arms and controlled lateral balance.
   spread+=.25;armYaw=.16*math.sin(ph*.8)
   rootRoll=math.sin(ph*.6)*.13
   hipSide=math.sin(ph*.6)*.13
   kneeBend=-math.abs(math.sin(ph*.5))*.12
  elseif mode=="skip" then
   -- Distinct skipping rhythm: hop on alternate steps.
   bounce+=math.max(0,math.sin(ph))*.095*walk
   hipPair=math.max(0,math.sin(ph))*.11*walk
   shoulderAsym=.13*math.sin(ph)
  elseif mode=="prance" then
   -- High light steps with upright neck and extra knee lift.
   swing*=1.15;bounce*=1.17
   kneeBend=-math.max(0,math.sin(ph))*.17*walk
   headPitch=-.075;spread+=.09
  elseif mode=="fighter" then
   -- A balanced athletic guard and precise quick steps.
   rest+=.13;elbowBend=-.42
   spread+=.07;pitch+=.08*walk
   kneeBend=-.08;rootRoll=math.sin(ph)*.045*walk
  elseif mode=="harpy" then
   -- Hovering upper arms resembling wings with descending swoop.
   spread+=.21;floatY+=.045*math.sin(ph*.6)
   rest-=.15;shoulderAsym=.13*math.sin(ph*1.1)
   hipPair=.15
  elseif mode=="aura" then
   -- Centered ceremonial float with circling arms.
   spread+=.21;armYaw=math.sin(ph*.4)*.22
   rootRoll=math.sin(ph*.4)*.035
   floatY+=.06*math.sin(ph*.45);headPitch=-.055
  elseif mode=="wavy" then
   -- Asymmetric hand and hip waves.
   armYaw=math.sin(ph*.6)*.19
   bodyShift=math.sin(ph*.7)*.055
   rootRoll=math.sin(ph*.8)*.12
   elbowBend=-.15+.08*math.sin(ph*.8)
  elseif mode=="shuffle" then
   -- Uneven shamble with heavy shoulder tilt.
   swing*=.6;rest+=.12
   headRoll=.08+math.sin(ph*.42)*.07
   rootRoll=math.sin(ph*.64)*.10
   hipSide=.06
  elseif mode=="bashful" then
   -- Expressive folded arms and shifting weight.
   rest+=.14;elbowBend=-.33
   armYaw=.09;headRoll=-.09+.06*math.sin(ph*.4)
   bodyShift=math.sin(ph*.6)*.045
  elseif mode=="doll" then
   -- Doll-like posture with semi-stiff wrists and pointed step.
   swing*=.67;rest+=.08
   headPitch=-.045;elbowBend=-.16
   hipSide=.055;rootRoll=math.sin(ph*.55)*.065
  elseif mode=="skate" then
   -- Push and glide alternating weight to the sides.
   swing*=.50;bodyShift=math.sin(ph*.74)*.11*walk
   rootRoll=-math.sin(ph*.74)*.07
   hipSide=math.sin(ph*.74)*.15
   spread+=.08;pitch+=.055*walk
  elseif mode=="waddle" then
   -- Side-by-side wobble with little flapping arms.
   swing*=.60;rootRoll=math.sin(ph)*.13
   spread+=.19;shoulderAsym=math.cos(ph)*.16
   bounce*=1.12;hipSide=.10
  elseif mode=="head" then
   -- Floating presentation focused on head and shoulder gestures.
   swing*=.18;hipPair=.16
   headRoll=math.sin(ph*.42)*.16
   headPitch=math.sin(ph*.56)*.06
   spread+=.12
  elseif mode=="dark" then
   -- Cloak-like drawn-back arms, angled float.
   rest-=.18;spread+=.13
   armYaw=-.09;headPitch=.07
   floatY+=math.sin(ph*.4)*.035
  elseif mode=="anime" then
   -- Forward heroic sprint, wind-swept arms and high steps.
   pitch+=.16*walk;rest-=.18*walk
   swing*=1.18;hipPair=.07
   elbowBend=-.15;rootRoll=.035*math.sin(ph)
  elseif mode=="ghost" then
   -- Dissolving-looking drift represented with shoulder and head sways.
   swing*=.10;hipPair=.12
   bodyShift=math.sin(ph*.42)*.085
   headRoll=math.sin(ph*.4+.7)*.13
   rootRoll=math.sin(ph*.5)*.08
  end
  local r6=hum.RigType==Enum.HumanoidRigType.R6
  local scale=if r6 then .78 else 1
  local leftKnee=-(pack.knee or 0)*(.3+.7*math.max(0,-gait))*walk+kneeBend
  local rightKnee=-(pack.knee or 0)*(.3+.7*math.max(0,gait))*walk+kneeBend
  if airborne then rightKnee-=.13;leftKnee-=.13 end
  add(j.Root,CFrame.new(bodyShift*weight,(floatY+bounce)*weight,0)
    *CFrame.Angles((pitch+jumpAngle)*weight,twist*.38*weight,(roll*.5+rootRoll)*weight))
  add(j.Waist,CFrame.Angles((-pitch*.34+idleWave*.3)*weight,twist*weight,(roll+rootRoll*.45)*weight))
  add(j.Neck,CFrame.Angles((-pitch*.25+idleWave+headPitch)*weight,-twist*.4*weight,(-roll*.35+headRoll)*weight))
  add(j.RightHip,CFrame.Angles((swing+jumpAngle*.45+hipPair)*weight*scale,0,(-spread*.14+roll*.25+hipSide)*weight))
  add(j.LeftHip,CFrame.Angles((-swing+jumpAngle*.45+hipPair)*weight*scale,0,(spread*.14+roll*.25-hipSide)*weight))
  add(j.RightShoulder,CFrame.Angles((rest-armCycle+idleWave+shoulderAsym)*weight*scale,armYaw*weight,(-spread+roll*.14)*weight))
  add(j.LeftShoulder,CFrame.Angles((rest+armCycle-idleWave-shoulderAsym)*weight*scale,-armYaw*weight,(spread+roll*.14)*weight))
  add(j.RightElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33+elbowBend)*weight,0,0))
  add(j.LeftElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33+elbowBend)*weight,0,0))
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

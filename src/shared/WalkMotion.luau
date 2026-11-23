-- Optional additive procedural walk cycle, local-only.
-- Runs AFTER Roblox Animator has written Motor6D.Transform (PreSimulation).
-- Disabled by default so it never takes over another game's native movement.
local W={};W.__index=W
local function joint(char,...)
 for _,name in {...} do
  local found=char:FindFirstChild(name,true)
  if found and found:IsA("Motor6D") then return found end
 end
 return nil
end
function W.new()
 return setmetatable({character=nil,joints={},blend=0,phase=0},W)
end
function W:bind(char)
 if char==self.character then return end
 self.character=char;self.blend=0;self.phase=0
 table.clear(self.joints)
 if not char then return end
 self.joints.RH=joint(char,"RightHip","Right Hip")
 self.joints.LH=joint(char,"LeftHip","Left Hip")
 self.joints.RS=joint(char,"RightShoulder","Right Shoulder")
 self.joints.LS=joint(char,"LeftShoulder","Left Shoulder")
 self.joints.Waist=joint(char,"Waist")
 self.joints.Root=joint(char,"RootJoint","Root")
end
function W:step(char,s,dt)
 self:bind(char)
 if not char then return end
 local hum=char:FindFirstChildOfClass("Humanoid")
 -- Transform is reset by Roblox Animator on PreAnimation. Do not modify motor
 -- poses on rigs with no Animator because transforms would accumulate forever.
 if not hum or not hum:FindFirstChildOfClass("Animator") then return end
 local grounded=hum.FloorMaterial~=Enum.Material.Air
 local moving=hum.MoveDirection.Magnitude>.1 and hum.Health>0 and not hum.Sit and grounded
 local enabled=s.walkAnimation and not s.reduce
 local amount=if enabled and moving then (s.walkIntensity or 65)/100 else 0
 dt=math.clamp(dt,0,.06)
 local smooth=1-math.exp(-dt*11)
 self.blend+=(amount-self.blend)*smooth
 if self.blend<.001 then return end
 local speed=math.clamp(hum.WalkSpeed/16,.55,2.25)
 self.phase+=dt*8.8*speed
 local wave=math.sin(self.phase)
 local alt=math.cos(self.phase)
 local style=s.walkStyle or "Natural"
 local power=if style=="Heroic" then .28 elseif style=="Floating" then .12 elseif style=="Bouncy" then .23 else .19
 local leg=wave*power*self.blend
 local arm=-leg*.77
 local bounce=if style=="Floating" then .02 elseif style=="Bouncy" then .075 else .03
 local dip=math.abs(alt)*bounce*self.blend
 local twist=if style=="Heroic" then wave*.075*self.blend else wave*.036*self.blend
 local function add(m,transform)
  if m and m.Parent then m.Transform=m.Transform*transform end
 end
 add(self.joints.RH,CFrame.Angles(leg,0,0))
 add(self.joints.LH,CFrame.Angles(-leg,0,0))
 add(self.joints.RS,CFrame.Angles(arm,0,twist*.22))
 add(self.joints.LS,CFrame.Angles(-arm,0,-twist*.22))
 add(self.joints.Waist,CFrame.new(0,dip,0)*CFrame.Angles(dip*.22,twist,0))
 add(self.joints.Root,CFrame.new(0,dip*.6,0)*CFrame.Angles(0,twist*.5,0))
end
function W:destroy()
 self.character=nil;table.clear(self.joints)
end
return W

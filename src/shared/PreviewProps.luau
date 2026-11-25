-- Decorative GUI-only props. No tools, hitboxes, game-world parts or physics.
local P={};P.__index=P
local function part(parent,name,size,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local violet=Color3.fromRGB(149,107,230)
local pale=Color3.fromRGB(218,191,255)
local dark=Color3.fromRGB(40,33,55)
function P.new(parent) return setmetatable({parent=parent},P) end
function P:clear() if self.root then self.root:Destroy() end;self.root=nil;self.kind=nil;self.parts=nil end
function P:build(kind)
 self:clear();self.kind=kind
 local root=Instance.new("Folder");root.Name="AetherPreviewProps";root.Parent=self.parent;self.root=root
 local items={};self.parts=items
 if kind=="Skater" then
  items.deck=part(root,"FantasyDeck",Vector3.new(1.45,.14,3.55),violet)
  items.grip=part(root,"DeckTop",Vector3.new(1.34,.025,3.42),dark)
  items.ends={}
  for i=1,2 do items.ends[i]=part(root,"RoundedDeckEnd",Vector3.new(.14,1.45,.48),violet,Enum.PartType.Cylinder) end
  items.wheels={}
  for i=1,4 do items.wheels[i]=part(root,"DecorativeWheel",Vector3.new(.27,.38,.38),pale,Enum.PartType.Cylinder) end
 elseif kind=="Doll Walk" then
  items.bar=part(root,"PuppetBar",Vector3.new(2.5,.10,.16),dark)
  items.cross=part(root,"PuppetCross",Vector3.new(.16,.10,1.6),dark)
  items.strings={}
  for i=1,5 do items.strings[i]=part(root,"PuppetThread",Vector3.new(.025,.025,1),pale) end
 elseif kind=="Fighter" then
  items.handle=part(root,"FantasyPropGrip",Vector3.new(.19,.57,.19),dark)
  items.guard=part(root,"FantasyPropOrnament",Vector3.new(.65,.12,.24),violet)
  items.blade=part(root,"FantasyLightBlade",Vector3.new(.24,2.05,.10),pale)
  items.blade.Material=Enum.Material.Neon
  items.tip=part(root,"FantasyLightTip",Vector3.new(.18,.18,.18),pale,Enum.PartType.Ball)
  items.tip.Material=Enum.Material.Neon
 end
end
local function line(p,a,b)
 local d=b-a;p.Size=Vector3.new(.025,.025,math.max(.025,d.Magnitude));p.CFrame=CFrame.lookAt((a+b)/2,b)
end
function P:update(rig,kind,phase,airProgress)
 local torso=rig and rig:FindFirstChild("Torso")
 local ra=rig and rig:FindFirstChild("Right Arm")
 local la=rig and rig:FindFirstChild("Left Arm")
 local rl=rig and rig:FindFirstChild("Right Leg")
 local ll=rig and rig:FindFirstChild("Left Leg")
 local head=rig and rig:FindFirstChild("Head")
 local root=rig and rig:FindFirstChild("HumanoidRootPart")
 if not torso or not ra or not la or not rl or not ll or not head or not root or (kind~="Skater" and kind~="Doll Walk" and kind~="Fighter") then self:clear();return end
 if self.kind~=kind then self:build(kind) end
 local q=self.parts
 if kind=="Fighter" then
  -- An oversized stylized light prop, permanently attached to the hand pose.
  local cf=ra.CFrame*CFrame.new(0,-ra.Size.Y/2+.10,0)*CFrame.Angles(math.rad(75),0,math.rad(8))
  q.handle.CFrame=cf;q.guard.CFrame=cf*CFrame.new(0,.34,0);q.blade.CFrame=cf*CFrame.new(0,1.38,0);q.tip.CFrame=cf*CFrame.new(0,2.40,0)
 elseif kind=="Doll Walk" then
  local bar=CFrame.new(head.Position+Vector3.new(.08*math.sin(phase),1.65,0))*root.CFrame.Rotation*CFrame.Angles(0,0,.12*math.sin(phase))
  q.bar.CFrame=bar;q.cross.CFrame=bar
  local targets={ra.CFrame:PointToWorldSpace(Vector3.new(0,-ra.Size.Y/2,0)),la.CFrame:PointToWorldSpace(Vector3.new(0,-la.Size.Y/2,0)),head.Position+Vector3.new(0,head.Size.Y/2,0),rl.Position,ll.Position}
  local anchors={Vector3.new(1.2,0,0),Vector3.new(-1.2,0,0),Vector3.new(0,0,0),Vector3.new(.45,0,.7),Vector3.new(-.45,0,-.7)}
  for i=1,5 do line(q.strings[i],bar:PointToWorldSpace(anchors[i]),targets[i]) end
 else
  local a=rl.CFrame:PointToWorldSpace(Vector3.new(0,-rl.Size.Y/2,0))
  local b=ll.CFrame:PointToWorldSpace(Vector3.new(0,-ll.Size.Y/2,0))
  local center=(a+b)/2
  local rotation=root.CFrame.Rotation*CFrame.Angles(0,math.rad(52)+(airProgress or 0)*math.pi*2,0)
  local cf=CFrame.new(center.X,math.min(a.Y,b.Y)-.10,center.Z)*rotation
  q.deck.CFrame=cf;q.grip.CFrame=cf*CFrame.new(0,.08,0)
  for i=1,2 do local side=if i==1 then -1 else 1;q.ends[i].CFrame=cf*CFrame.new(0,.01,side*1.65)*CFrame.Angles(0,0,math.pi/2) end
  for i=1,4 do local x=if i%2==0 then .65 else -.65;local z=if i<3 then 1.02 else -1.02;q.wheels[i].CFrame=cf*CFrame.new(x,-.20,z)*CFrame.Angles(phase*2,0,0) end
 end
end
return P

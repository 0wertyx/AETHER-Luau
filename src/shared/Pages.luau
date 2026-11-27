local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local MotionPacks=require(script.Parent.MotionPacks);local Symbol=require(script.Parent.Symbol);local Hud=require(script.Parent.Hud);local Avatar=require(script.Parent.Avatar);local Cues=require(script.Parent.Cues);local Http=game:GetService("HttpService")
local WalkMotion=require(script.Parent.WalkMotion)
local PreviewProps=require(script.Parent.PreviewProps)
local MotionStudio=require(script.Parent.MotionStudio)
local Input=game:GetService("UserInputService")
local E={}
local function names(t) local a=U.keys(t);return a end
local function preset(ui,a,group)
 local p=S.presets[group];if p then ui:title("PRESETS");ui:chips(names(p),function(n) a:patch(p[n]);a:log("Preset",n) end,3) end
end
local function preview(ui,a,showPanels)
 local f=ui:row(if showPanels then 210 else 149,"LivePreview");f.ClipsDescendants=true;f.BackgroundTransparency=0;U.gradient(f,Color3.fromRGB(105,87,145),Color3.fromRGB(49,46,94),36)
 local h=Hud.new(ui.page,f,true,function(tab) ui:open(tab) end,function(i,k,n,v,source) a:drag(i,k,n,v,source) end,nil,showPanels);a.preview={hud=h}
 if showPanels then
  h:layoutPreview(a.s)
  ui.page:on(f:GetPropertyChangedSignal("AbsoluteSize"),function() h:layoutPreview(a.s) end)
  ui:watch(function() h:layoutPreview(a.s) end)
 end
end
local function avatarPreview(ui,a,worldMode)
 local f=ui:row(if worldMode then 300 else 230,"RigPreview")
 local view=U.new("ViewportFrame",{Size=UDim2.fromScale(1,1),Active=true,BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(21,19,36),Ambient=Color3.fromRGB(155,145,175),LightColor=Color3.fromRGB(246,222,255),LightDirection=Vector3.new(-1,-1,-.6)},f)
 U.corner(view,10)
 local w=U.new("WorldModel",{},view)
 local cam=U.new("Camera",{FieldOfView=34},view);view.CurrentCamera=cam
 local player=game:GetService("Players").LocalPlayer
 local page=ui.page
 local avatar=Avatar.new(w,true)
 local previewState=if worldMode and a.preview then a.preview else {}
 previewState.avatar=avatar;previewState.rig=nil;a.preview=previewState
 local label=U.label(view,"Loading avatar...",12)
 label.TextXAlignment=Enum.TextXAlignment.Center
 local generation=0
 local characterScope=nil
 local motion=WalkMotion.new()
 local props=PreviewProps.new(w)
 local showProps=true
 local rootPart=nil
 local joints={}
 local motors={}
 local center=Vector3.zero
 local radius=1
 local yaw,pitch,zoom=.13,.08,1
 local targetYaw,targetPitch,targetZoom=yaw,pitch,zoom
 local dragging=false
 local hovered=false
 local lastMouse=nil
 local sc=ui.sc
 local middle=Enum.UserInputType.MouseButton3
 local full=false
 local paused=false
 local speed=1
 local demoState="Walk"
 local demoStrength=100
 local demoOrigin=100
 local previewStatus=nil
 local stage=nil
 local floorOffset=2
 local centerOffset=Vector3.zero
 local moving=false
 local velocity=Vector3.zero
 local verticalSpeed=0
 local grounded=true
 local jumpRequested=false
 local startPosition=Vector3.zero
 local orbitButton=nil
 local shiftLock=false
 local sceneParams=RaycastParams.new()
 sceneParams.FilterType=Enum.RaycastFilterType.Include
 local fullGui,fullHost,fullStatus,fullPause,fullSpeed=nil,nil,nil,nil,nil
 local actionName="AETHER_Preview_"..Http:GenerateGUID(false)
 local CAS=game:GetService("ContextActionService")
 local keys={}
 local function endOrbit()
  dragging=false;lastMouse=nil;orbitButton=nil
  if sc.Parent then sc.ScrollingEnabled=not hovered end
 end
 local function applyCamera()
  if page.dead then return end
  local aspect=math.max(.1,view.AbsoluteSize.X/math.max(1,view.AbsoluteSize.Y))
  local half=math.rad(cam.FieldOfView*.5)
  local angle=math.min(half,math.atan(math.tan(half)*aspect))
  local distance=if worldMode and full then 12*zoom else radius/math.sin(angle)*(if worldMode then 1.12 else 1.48)*zoom
  local offset=Vector3.new(math.sin(yaw)*math.cos(pitch),math.sin(pitch),-math.cos(yaw)*math.cos(pitch))
  local pos=center+offset*distance
  if worldMode and full and stage then
   sceneParams.FilterDescendantsInstances={stage}
   local hit=w:Raycast(center,pos-center,sceneParams)
   if hit then pos=center+offset*math.max(.6,hit.Distance-.4) end
  end
  cam.CFrame=CFrame.lookAt(pos,center)
 end
 local function fit()
  local rig=previewState.rig
  if page.dead or not rig or not rig.Parent then return end
  local cf,size=rig:GetBoundingBox()
  center=cf.Position;radius=math.max(.5,size.Magnitude*.5)
  if rootPart then
   centerOffset=center-rootPart.Position
   startPosition=rootPart.Position
   floorOffset=math.max(.5,rootPart.Position.Y-(cf.Position.Y-size.Y*.5))
  end
  applyCamera()
 end
 local function stageStatus(message)
  if fullStatus then fullStatus.Text=message end
  if not page.dead then ui:message(message) end
 end
 local function sceneClear()
  if stage then stage:Destroy();stage=nil end
 end
 local function sceneFloor()
  local ground=U.new("Part",{Name="PreviewFloor",Size=Vector3.new(110,.25,110),CFrame=CFrame.new(startPosition-Vector3.new(0,floorOffset+.125,0)),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,Color=Color3.fromRGB(52,44,74),Material=Enum.Material.SmoothPlastic},stage)
  return ground
 end
 local function resetScene()
  sceneClear()
  stage=U.new("Folder",{Name="PreviewEnvironment"},w)
  sceneFloor()
  stageStatus("Demo stage · capture visible scenery to preview your environment")
 end
 local function captureScene()
  if not worldMode or not rootPart or not rootPart.Parent then return end
  local character=player.Character
  local sourceRoot=character and character:FindFirstChild("HumanoidRootPart")
  local sourceCamera=workspace.CurrentCamera
  if not sourceRoot or not sourceCamera then stageStatus("Scene unavailable");return end
  sceneClear()
  stage=U.new("Folder",{Name="PreviewEnvironment"},w)
  local origin=sourceRoot.CFrame
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={character}
  local seen={}
  local count=0
  local size=sourceCamera.ViewportSize
  -- Sample only currently visible surfaces; never enumerate the whole map,
  -- copy other characters, scripts, remotes or hidden server objects.
  for y=0,13 do
   for x=0,21 do
    local ray=sourceCamera:ViewportPointToRay((x+.5)*size.X/22,(y+.5)*size.Y/14)
    local hit=workspace:Raycast(ray.Origin,ray.Direction*85,params)
    local source=hit and hit.Instance
    if source and source:IsA("BasePart") and not source:IsA("Terrain") and source.Anchored and source.Transparency<.98 and not seen[source] and count<180 then
     seen[source]=true
     local parent=source.Parent
     local characterPart=false
     while parent and parent~=workspace do
      if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then characterPart=true;break end
      parent=parent.Parent
     end
     if not characterPart then
      local ok,clone=pcall(function() return source:Clone() end)
      if ok and clone then
       for _,child in clone:GetDescendants() do
        if child.Parent and not (child:IsA("DataModelMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")) then child:Destroy() end
       end
       clone.Name="SceneSurface"
       clone.Anchored=true;clone.CanCollide=false;clone.CanTouch=false;clone.CanQuery=true
       clone.LocalTransparencyModifier=0
       clone.CFrame=CFrame.new(startPosition)*origin:ToObjectSpace(source.CFrame)
       clone.Parent=stage;count+=1
      end
     end
    end
   end
  end
  if count==0 then sceneFloor() end
  stageStatus(tostring(count).." visible surfaces · static local snapshot")
 end
 local function prepareRig(rig)
  motion:bind(nil);rootPart=rig:FindFirstChild("HumanoidRootPart")
  table.clear(joints);table.clear(motors)
  if not rootPart then return end
  -- Anchored viewport rigs need explicit forward kinematics. Cache joints
  -- once, including accessory welds, and keep the actual character untouched.
  local adjacency={}
  local function attach(part,edge)
   adjacency[part]=adjacency[part] or {}
   table.insert(adjacency[part],edge)
  end
  for _,joint in rig:GetDescendants() do
   if MotionStudio.isJoint(joint) or joint:IsA("Weld") or joint:IsA("ManualWeld") or joint:IsA("WeldConstraint") then
    local p0,p1,c0,c1=MotionStudio.jointFrames(joint)
    if p0 and p1 and p0:IsDescendantOf(rig) and p1:IsDescendantOf(rig) then
     local edge={joint=joint,p0=p0,p1=p1,c0=c0,c1=c1,motor=MotionStudio.isJoint(joint)}
     attach(p0,edge);attach(p1,edge)
     if edge.motor then table.insert(motors,joint) end
    end
   end
   if joint:IsA("Constraint") or joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then pcall(function() joint.Enabled=false end) end
  end
  local queue={rootPart};local seen={[rootPart]=true};local index=1
  while index<=#queue do
   local part=queue[index];index+=1
   for _,edge in adjacency[part] or {} do
    local forward=edge.p0==part
    local other=if forward then edge.p1 else edge.p0
    if not seen[other] then
     seen[other]=true;table.insert(queue,other)
     table.insert(joints,{edge=edge,forward=forward})
    end
   end
  end
 end
 previewState.pose=function(settings,dt)
  local rig=previewState.rig
  if page.dead or not ui.opened or not rootPart or not rootPart.Parent or not rig then return end
  if worldMode then
   if paused then return end
   dt=math.min(dt,.05)*speed
   previewState.effectTime=(previewState.effectTime or os.clock())+dt
   moving=false
   previewState.airTiltDirection=nil
   if full and ui.opened then
    local x=(if keys[Enum.KeyCode.D] or keys[Enum.KeyCode.Right] then 1 else 0)-(if keys[Enum.KeyCode.A] or keys[Enum.KeyCode.Left] then 1 else 0)
    local z=(if keys[Enum.KeyCode.W] or keys[Enum.KeyCode.Up] then 1 else 0)-(if keys[Enum.KeyCode.S] or keys[Enum.KeyCode.Down] then 1 else 0)
    local forward=Vector3.new(-math.sin(yaw),0,math.cos(yaw))
    local right=forward:Cross(Vector3.yAxis)
    local dir=forward*z+right*x
    if dir.Magnitude>1 then dir=dir.Unit end
    if grounded then
     velocity=velocity:Lerp(dir*16,1-math.exp(-dt*14))
    elseif settings.airControl then
     velocity=U.airRedirect(velocity,dir,16*settings.airControlSpeed/100,settings.airControlStrength,dt)
    end
    local pos=rootPart.Position
    local delta=velocity*dt
    sceneParams.FilterDescendantsInstances=if stage then {stage} else {}
    if delta.Magnitude>.001 then
     local wall=w:Raycast(pos,delta+delta.Unit*.65,sceneParams)
     if wall and math.abs(wall.Normal.Y)<.55 then
      delta-=wall.Normal*delta:Dot(wall.Normal)
      if delta.Magnitude>.001 and w:Raycast(pos,delta+delta.Unit*.4,sceneParams) then delta=Vector3.zero end
     end
    end
    if (jumpRequested or (settings.bunnyHop and keys[Enum.KeyCode.Space])) and grounded and not (a.mode=="Simulator" and a.sim.stateBusy and not a.sim.stateOverride) then verticalSpeed=36;grounded=false end
    jumpRequested=false
    verticalSpeed-=workspace.Gravity*dt
    local nextPos=pos+delta+Vector3.new(0,verticalSpeed*dt,0)
    local ground=w:Raycast(nextPos+Vector3.new(0,1.8,0),Vector3.new(0,-(floorOffset+4+math.abs(verticalSpeed*dt)),0),sceneParams)
    if verticalSpeed<=0 and ground and ground.Normal.Y>.5 and nextPos.Y<=ground.Position.Y+floorOffset then
     nextPos=Vector3.new(nextPos.X,ground.Position.Y+floorOffset,nextPos.Z);verticalSpeed=0;grounded=true
    else grounded=false end
    if nextPos.Y<startPosition.Y-40 or (nextPos-startPosition).Magnitude>80 then
     nextPos=startPosition;velocity=Vector3.zero;verticalSpeed=0;grounded=true
    end
    moving=velocity.Magnitude>.35
    local facing=if shiftLock then forward elseif dir.Magnitude>.1 then dir else rootPart.CFrame.LookVector
    rootPart.CFrame=rootPart.CFrame:Lerp(CFrame.lookAt(nextPos,nextPos+facing),1-math.exp(-dt*20))
    rootPart.CFrame=CFrame.new(nextPos)*rootPart.CFrame.Rotation
    if not grounded and settings.airControl and not settings.reduce then previewState.airTiltDirection=dir end
   end
   center=rootPart.Position+centerOffset;applyCamera()
  end
  if not worldMode and paused then return end
  for _,motor in motors do motor.Transform=CFrame.identity end
  if (ui.tab=="Character" or worldMode) and not settings.reduce then
   local demo=table.clone(settings);demo.walkAnimation=true
   local virtual
   if worldMode then
    virtual={movement=math.clamp(velocity.Magnitude/16,0,1),grounded=grounded,jumping=verticalSpeed>0,fullPose=true}
   else
    dt=math.min(dt,.05)*speed
    demo.walkIntensity=demoStrength
    local state=if demoState=="Jump" then Enum.HumanoidStateType.Jumping
     elseif demoState=="Fall" then Enum.HumanoidStateType.Freefall
     elseif demoState=="Swim" then Enum.HumanoidStateType.Swimming
     elseif demoState=="Climb" then Enum.HumanoidStateType.Climbing
     else Enum.HumanoidStateType.Running
    local airborne=demoState=="Jump" or demoState=="Fall"
    virtual={movement=if demoState=="Idle" then 0 elseif demoState=="Walk" then .78 else 1,grounded=not airborne,jumping=demoState=="Jump",state=state,speed=if demoState=="Run" then 24 else 16,fullPose=true,originStrength=demoOrigin,loopAir=true}
   end
   virtual.props=showProps
   motion:step(rig,demo,dt,virtual)
   if worldMode then motion:applyAirTilt(rig,previewState.airTiltDirection,dt,settings.airTiltAngle,true) end
  else
   motion:bind(nil)
  end
  for _,link in joints do
   local e=link.edge;local j=e.joint
   if j.Parent and e.p0.Parent and e.p1.Parent then
    local offset=e.c0*(if e.motor then j.Transform else CFrame.identity)*e.c1:Inverse()
    if link.forward then e.p1.CFrame=e.p0.CFrame*offset else e.p0.CFrame=e.p1.CFrame*offset:Inverse() end
   end
  end
  if showProps and not settings.reduce and motion.signatureActive then props:update(rig,settings.walkStyle,motion.phase,motion.previewState) else props:clear() end
 end
 local function refresh(char)
  generation+=1
  local current=generation
  task.delay(.18,function()
   if page.dead or current~=generation or not char or char~=player.Character then return end
   if not char:FindFirstChildOfClass("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then return end
   local previous=char.Archivable
   local ok,rig=pcall(function() char.Archivable=true;return char:Clone() end)
   char.Archivable=previous
   if not ok or not rig then
    label.Text="Avatar unavailable";label.Visible=not previewState.rig
    return
   end
   for _,obj in rig:GetDescendants() do
    if not obj.Parent then continue end
    if obj:IsA("LuaSourceContainer") or obj:IsA("Animator") or obj:IsA("AnimationController") or obj:IsA("Tool") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("Sound") then
     obj:Destroy()
    elseif obj:IsA("BasePart") then
     obj.Anchored=true;obj.CanCollide=false;obj.CanTouch=false;obj.CanQuery=false;obj.LocalTransparencyModifier=0
     if obj.Name=="HumanoidRootPart" then obj.Transparency=1 end
    end
   end
   local humanoid=rig:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
   local root=rig:FindFirstChild("HumanoidRootPart")
   if root then rig:PivotTo(root.CFrame:ToObjectSpace(rig:GetPivot())) end
   rig.Name="LocalAvatarPreview"
   avatar:clear()
   if previewState.rig then previewState.rig:Destroy() end
   rig.Parent=w;previewState.rig=rig;prepareRig(rig);fit();previewState.pose(a.s,0);label.Visible=false
   if worldMode then resetScene() end
  end)
 end
 local function bind(char)
  if characterScope then characterScope:clear() end
  characterScope=U.scope()
  generation+=1;avatar:clear();props:clear();motion:bind(nil);rootPart=nil;table.clear(joints);table.clear(motors)
  if previewState.rig then previewState.rig:Destroy();previewState.rig=nil end
  label.Text="Loading avatar...";label.Visible=true
  if not char then return end
  local function appearanceChanged(obj)
   if obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or obj:IsA("BasePart") or obj:IsA("Humanoid") or obj:IsA("Decal") or obj:IsA("CharacterMesh") or obj:IsA("SurfaceAppearance") or MotionStudio.isJoint(obj) then refresh(char) end
  end
  characterScope:on(char.DescendantAdded,appearanceChanged)
  characterScope:on(char.DescendantRemoving,appearanceChanged)
  refresh(char)
 end
 local function closeFull()
  if not full then return end
  full=false;velocity=Vector3.zero;shiftLock=false;jumpRequested=false
  CAS:UnbindAction(actionName);table.clear(keys)
  hovered=false;endOrbit()
  if not page.dead and f.Parent then view.Parent=f end
  if fullGui and fullGui.Parent then fullGui.Enabled=false end
  applyCamera()
 end
 local function togglePause()
  paused=not paused
  if fullPause then fullPause.Text=if paused then "Resume" else "Pause" end
  stageStatus(if paused then "Preview paused" else "Preview running")
 end
 local function cycleSpeed()
  speed=if speed==.5 then 1 elseif speed==1 then 2 else .5
  if fullSpeed then fullSpeed.Text=tostring(speed).."x" end
  stageStatus("Playback speed "..tostring(speed).."x")
 end
 local function openFull()
  if full or page.dead then return end
  if not fullGui then
   fullGui=page:add(U.new("ScreenGui",{Name="AETHER_WorldPreview",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483646,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=false},player:WaitForChild("PlayerGui")))
   local shell=U.frame(fullGui,"WorldPreview",nil,nil,Color3.fromRGB(17,14,28),0)
   shell.Active=true
   local bar=U.frame(shell,"Toolbar",UDim2.fromOffset(12,12),UDim2.new(1,-24,0,46),Color3.fromRGB(41,32,61),0);U.corner(bar,12)
   local title=U.label(bar,"AETHER / WORLD PREVIEW",16,UDim2.fromOffset(14,0),UDim2.new(1,-410,1,0))
   local function tool(text,offset,width,fn)
    local b=U.button(bar,text);b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-offset,.5,0);b.Size=UDim2.fromOffset(width,32)
    page:on(b.Activated,fn);return b
   end
   tool("Exit full screen",8,112,closeFull)
   fullSpeed=tool(tostring(speed).."x",128,54,cycleSpeed)
   fullPause=tool(if paused then "Resume" else "Pause",190,68,togglePause)
   tool("Capture",266,76,captureScene)
   fullHost=U.frame(shell,"Viewport",UDim2.fromOffset(12,68),UDim2.new(1,-24,1,-114),nil,1)
   fullStatus=U.label(shell,"WASD / arrows · Space jump · RMB camera · "..a.s.lockKey.." lock · scroll zoom",13,UDim2.new(0,16,1,-42),UDim2.new(1,-32,0,30))
  end
  full=true;fullGui.Enabled=true;view.Parent=fullHost
  if worldMode then
   local controls={Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Space}
   local lockCode=Enum.KeyCode[a.s.lockKey]
   if lockCode and not table.find(controls,lockCode) then table.insert(controls,lockCode) end
   CAS:BindActionAtPriority(actionName,function(_,state,input)
    if state==Enum.UserInputState.Begin then
     keys[input.KeyCode]=true
     if input.KeyCode==Enum.KeyCode.Space then jumpRequested=true end
     if input.KeyCode.Name==a.s.lockKey then shiftLock=not shiftLock end
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then keys[input.KeyCode]=nil end
    if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then return Enum.ContextActionResult.Pass end
    return Enum.ContextActionResult.Sink
   end,false,Enum.ContextActionPriority.High.Value+100,table.unpack(controls))
  end
  hovered=false;endOrbit();applyCamera()
 end
 page:on(view:GetPropertyChangedSignal("AbsoluteSize"),applyCamera)
 page:on(view.MouseEnter,function() if ui.opened then hovered=true;sc.ScrollingEnabled=false end end)
 page:on(view.MouseLeave,function() hovered=false;if not dragging then sc.ScrollingEnabled=true end end)
 -- Use global input rather than ViewportFrame.InputBegan, which can be
 -- swallowed by the surrounding ScrollingFrame or another GUI layer.
 page:on(Input.InputBegan,function(input)
  if (input.UserInputType==middle or (full and input.UserInputType==Enum.UserInputType.MouseButton2)) and hovered and ui.opened then
   dragging=true;orbitButton=input.UserInputType;lastMouse=Input:GetMouseLocation();sc.ScrollingEnabled=false
  end
 end)
 page:on(Input.InputChanged,function(input)
  if hovered and ui.opened and input.UserInputType==Enum.UserInputType.MouseWheel then
   targetZoom=math.clamp(targetZoom*math.exp(-input.Position.Z*.15),.35,2.6)
  end
 end)
 page:on(Input.InputEnded,function(input)
  if input.UserInputType==orbitButton then endOrbit() end
 end)
 page:on(Input.WindowFocusReleased,function() table.clear(keys);hovered=false;endOrbit() end)
 page:on(game:GetService("RunService").RenderStepped,function(dt)
  if not ui.opened then
   if full then closeFull() end
   if hovered or dragging then hovered=false;endOrbit() end
   return
  end
  if dragging then
   if not orbitButton or not Input:IsMouseButtonPressed(orbitButton) then
    endOrbit()
   else
    local mouse=Input:GetMouseLocation()
    local delta=mouse-(lastMouse or mouse)
    lastMouse=mouse
    targetYaw-=delta.X*.009
    targetPitch=math.clamp(targetPitch+delta.Y*.007,-1.15,1.15)
   end
  end
  local alpha=if a.s.reduce then 1 else 1-math.exp(-math.min(dt,.1)*18)
  if math.abs(targetYaw-yaw)+math.abs(targetPitch-pitch)+math.abs(targetZoom-zoom)>.0001 then
   yaw+=(targetYaw-yaw)*alpha
   pitch+=(targetPitch-pitch)*alpha
   zoom+=(targetZoom-zoom)*alpha
   applyCamera()
  end
 end)
 ui:note(if worldMode then "Capture visible scene · Full screen: WASD, Space, RMB camera, Shift lock" else "Hold middle mouse to orbit · Scroll to zoom · Full-body preview (independent of game animation)",42)
 if not worldMode and ui.tab=="Character" then
  ui:title("FULL-BODY ANIMATION PREVIEW")
  ui:note("Preview plays the selected style even when Custom walking animation is off. Only the local GUI rig is animated here.",44)
  ui:chips({"Idle","Walk","Run","Jump","Fall","Swim","Climb"},function(n)
   demoState=n;motion:bind(nil);ui:sync()
  end,4,function() return demoState end)
  ui:chips({"0.5x","1x","1.5x","2x"},function(n) speed=tonumber(n:sub(1,-2)) or 1;ui:sync() end,4,function() return tostring(speed).."x" end)
  ui:chips({"50%","75%","100%"},function(n) demoStrength=tonumber(n:sub(1,-2)) or 100;ui:sync() end,3,function() return tostring(demoStrength).."%" end)
  ui:chips({"Props on","Props off"},function(n) showProps=n=="Props on";if not showProps then props:clear() end;ui:sync() end,2,function() return if showProps then "Props on" else "Props off" end)
  ui:title("R6 · LIMB ORIGIN MOTION")
  ui:note("Animate shoulder and hip positions as well as rotation. Compare the original rotation-only preview with the stylized offsets.",42)
  ui:chips({"Origin off","Origin 50%","Origin 100%"},function(n)
   demoOrigin=if n=="Origin off" then 0 elseif n=="Origin 50%" then 50 else 100
   ui:sync()
  end,3,function() return if demoOrigin==0 then "Origin off" else "Origin "..tostring(demoOrigin).."%" end)
  ui:chips({"Pause","Play"},function(n) paused=n=="Pause";ui:sync() end,2,function() return if paused then "Pause" else "Play" end)
  previewStatus=ui:note("",28)
  ui:watch(function()
   previewStatus.Text=(a.s.walkStyle or "Natural").." / "..demoState.." · "..tostring(demoStrength).."% · Origin "..tostring(demoOrigin).."%"
  end)
 end
 if worldMode then
  ui:chips({"Capture visible scene","Full screen"},function(n) if n=="Full screen" then openFull() else captureScene() end end,2)
  ui:chips({"Demo stage","Pause / resume","Playback speed"},function(n) if n=="Demo stage" then resetScene() elseif n=="Pause / resume" then togglePause() else cycleSpeed() end end,3)
 end
 ui:chips({"Reset view"},function()
  targetYaw=yaw+((.13-yaw+math.pi)%(2*math.pi)-math.pi)
  targetPitch,targetZoom=.08,1
 end,1)
 page:on(player.CharacterAdded,bind)
 page:on(player.CharacterRemoving,function() bind(nil) end)
 page:on(player.CharacterAppearanceLoaded,function(char) if char==player.Character then refresh(char) end end)
 page:add(function()
  generation+=1
  closeFull()
  CAS:UnbindAction(actionName)
  hovered=false;endOrbit()
  if characterScope then characterScope:clear() end
  motion:destroy();props:clear();avatar:clear();sceneClear()
 end)
 bind(player.Character)
end
local function gallery(ui,a)
 ui:title("24 DIRECTION STYLES · HD");for i=1,#S.shapes,4 do local r=ui:row(72,"ShapeGallery");for j=0,3 do local n=S.shapes[i+j];local b=U.button(r,"");b.Name=n;b.Position=UDim2.fromScale(j/4,0);b.Size=UDim2.new(.25,-3,1,0);local g=Symbol.gallery(b,n,30);g.root.Position=UDim2.fromScale(.5,.37);g.root.Size=UDim2.fromOffset(47,47);local l=U.label(b,n,10,UDim2.fromScale(0,.65),UDim2.fromScale(1,.3));l.TextXAlignment=Enum.TextXAlignment.Center;ui.page:on(b.Activated,function() a:set("shape",n) end);ui:watch(function() b.BackgroundColor3=if a.s.shape==n then U.hex("624785") else U.hex("30273E");g:paint(U.hex(a.s.arrowA),U.hex(a.s.arrowB),a.s.ink,a.s.spread) end) end end
end
local function skyArt(host,row)
 local hi,mid,ground=U.hex(row[2]),U.hex(row[3]),U.hex(row[4])
 host.BackgroundColor3=Color3.new(1,1,1);host.BackgroundTransparency=0;host.ClipsDescendants=true
 U.new("UIGradient",{Rotation=90,Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,hi),ColorSequenceKeypoint.new(.60,mid),ColorSequenceKeypoint.new(1,ground)
 })},host)
 local night=(row[7] or 0)<65 or (row[7] or 0)>185
 if night then
  for i=1,9 do
   local dot=U.frame(host,"Star",UDim2.fromScale(.07+((i*.618)%1)*.86,.07+((i*.414)%1)*.43),UDim2.fromOffset(2,2),Color3.new(1,1,1),.24+(i%4)*.16)
   dot.Active=false;dot.Interactable=false;U.corner(dot,4)
  end
 end
 local orb=U.frame(host,"CelestialDisc",UDim2.fromScale(.70,.28),UDim2.fromScale(.18,.18),ground:Lerp(Color3.new(1,1,1),.45),.12)
 orb.AnchorPoint=Vector2.new(.5,.5);U.corner(orb,999);U.new("UIAspectRatioConstraint",{AspectRatio=1},orb)
 for i=1,4 do
  local mountain=U.frame(host,"HorizonSilhouette",UDim2.fromScale((i-.5)/4,.98),UDim2.fromScale(.42,.58),hi:Lerp(Color3.fromRGB(7,10,22),.45+i*.06),.04+i*.03)
  mountain.AnchorPoint=Vector2.new(.5,.5);mountain.Rotation=45;mountain.Active=false;mountain.Interactable=false;U.corner(mountain,5)
 end
 local floor=U.frame(host,"Horizon",UDim2.fromScale(0,.86),UDim2.fromScale(1,.14),hi:Lerp(Color3.fromRGB(7,10,22),.75),0);floor.Active=false;floor.Interactable=false
end
local function cosmeticSettings(source,item,kind)
 local s=S.copy(source)
 s.wings=false;s.halo=false;s.neon=false;s.aura=false;s.trail=false;s.redDiamond=false;s.blueDiamond=false;s.reduce=true;s.wingDetail="Balanced";s.haloDetail="Balanced"
 for i in S.haloV2Styles do s["haloV2"..i.."Enabled"]=false end
 if kind=="Halos" then
  if item.classic then s.halo=true;s.haloStyle=item.name
  else s[item.key.."Enabled"]=true;s[item.key.."Count"]=math.min(s[item.key.."Count"] or 5,12) end
 else s.wings=true;s.wingStyle=item.name end
 return s
end
-- Generate a static 2D thumbnail from the same cosmetic geometry as the avatar.
-- Only one temporary rig exists at a time; the cache stores plain numeric data.
local thumbnailCache={}
local function thumbnailGeometry(item,kind)
 local key=kind..":"..item.id
 if thumbnailCache[key] then return thumbnailCache[key] end
 local folder=Instance.new("Folder")
 local fx=Avatar.new(folder,true)
 local data={}
 local ok=pcall(function()
  local rig=Avatar.mannequin(folder)
  fx:step(rig,cosmeticSettings(S.defaults(),item,kind),0)
  local eye=if kind=="Halos" then CFrame.lookAt(Vector3.new(5,7,9),Vector3.new(0,4,0)) else CFrame.lookAt(Vector3.new(0,3,9),Vector3.new(0,2,0))
  local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
  for _,part in fx.parts do
   if not part.Parent or part.Transparency>=.96 then continue end
   local cf=part.CFrame;local size=part.Size
   local center=eye:PointToObjectSpace(cf.Position)
   local axes={eye:VectorToObjectSpace(cf.RightVector*size.X),eye:VectorToObjectSpace(cf.UpVector*size.Y),eye:VectorToObjectSpace(cf.LookVector*size.Z)}
   local along=Vector2.zero;local width=0
   for _,v in axes do
    local vv=Vector2.new(v.X,-v.Y)
    if vv.Magnitude>along.Magnitude then width=math.max(width,along.Magnitude);along=vv else width=math.max(width,vv.Magnitude) end
   end
   local x,y=center.X,-center.Y
   local radius=math.max(.025,along.Magnitude*.5+width*.25)
   minX=math.min(minX,x-radius);maxX=math.max(maxX,x+radius)
   minY=math.min(minY,y-radius);maxY=math.max(maxY,y+radius)
   data[#data+1]={x=x,y=y,depth=center.Z,length=along.Magnitude,width=width,angle=math.deg(math.atan2(along.Y,along.X)),color=part.Color,alpha=part.Transparency}
  end
  if #data>0 then
   local scale=84/math.max(.01,maxX-minX,maxY-minY)
   local cx,cy=(minX+maxX)*.5,(minY+maxY)*.5
   table.sort(data,function(a,b) return a.length>b.length end)
   while #data>96 do table.remove(data) end
   table.sort(data,function(a,b) return a.depth<b.depth end)
   for _,v in data do v.x=50+(v.x-cx)*scale;v.y=50+(v.y-cy)*scale;v.length=math.max(1,v.length*scale);v.width=math.clamp(v.width*scale,1,15) end
  end
 end)
 pcall(function() fx:clear() end);folder:Destroy()
 if not ok then table.clear(data) end
 thumbnailCache[key]=data
 return data
end
local function drawThumbnail(host,canvas,item,kind)
 for _,obj in canvas:GetChildren() do if not obj:IsA("UIScale") then obj:Destroy() end end
 host.BackgroundColor3=Color3.fromRGB(27,22,43);host.BackgroundTransparency=.33
 if kind=="Ambient" then
  canvas.Visible=false
  for _,obj in host:GetChildren() do if obj~=canvas and not obj:IsA("UICorner") then obj:Destroy() end end
  skyArt(host,item.sky)
  return
 end
 canvas.Visible=true
 local data=thumbnailGeometry(item,kind)
 for _,v in data do
  local edge=U.frame(canvas,"ProjectedPart",UDim2.fromOffset(v.x,v.y),UDim2.fromOffset(v.length,v.width),v.color,math.clamp(v.alpha,0,.8))
  edge.AnchorPoint=Vector2.new(.5,.5);edge.Rotation=v.angle;edge.Active=false;edge.Interactable=false;U.corner(edge,3)
 end
 if #data==0 then local msg=U.label(canvas,"Preview unavailable",10);msg.TextWrapped=true;msg.TextXAlignment=Enum.TextXAlignment.Center end
end
-- One static low-detail 3D preview, refreshed only when relevant settings change.
local function effectThumbnail(ui,card,a,item,kind)
 local host=U.frame(card,"EffectThumbnail",UDim2.fromOffset(4,4),UDim2.new(1,-8,0,66),Color3.fromRGB(27,22,43),0)
 host.ClipsDescendants=true;U.corner(host,7)
 if kind=="Ambient" then skyArt(host,item.sky);return end
 local vp=U.new("ViewportFrame",{Name="Effect3D",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(165,145,200),LightColor=Color3.fromRGB(245,230,255)},host)
 local wm=U.new("WorldModel",{},vp)
 local cam=U.new("Camera",{FieldOfView=40},vp);vp.CurrentCamera=cam
 local rig=Avatar.mannequin(wm)
 local fx=Avatar.new(wm,true)
 ui.page:add(function() fx:clear() end)
 local function previewSettings() return cosmeticSettings(a.s,item,kind) end
 local snapshot=a.s
 local ok,err=pcall(function() fx:step(rig,previewSettings(),0) end)
 if not ok then
  fx:clear();vp:Destroy()
  local fallback=U.label(host,"Preview unavailable",10);fallback.TextWrapped=true;fallback.TextXAlignment=Enum.TextXAlignment.Center
  return
 end
 local focus=if kind=="Halos" then Vector3.new(0,4.1,0) else Vector3.new(0,1.8,.5)
 local yaw=if kind=="Halos" then .42 else 0
 local pitch=if kind=="Halos" then .48 else .14
 local radius=if kind=="Halos" then 2.0 else 4.1
 local function fit()
  local size=vp.AbsoluteSize
  if size.X<2 or size.Y<2 then return end
  local halfV=math.rad(cam.FieldOfView*.5)
  local halfH=math.atan(math.tan(halfV)*size.X/size.Y)
  local distance=radius/math.sin(math.min(halfH,halfV))*1.02
  local direction=Vector3.new(math.sin(yaw)*math.cos(pitch),math.sin(pitch),math.cos(yaw)*math.cos(pitch))
  cam.CFrame=CFrame.lookAt(focus+direction*distance,focus)
 end
 fit();ui.page:on(vp:GetPropertyChangedSignal("AbsoluteSize"),fit)
 local hit=U.new("TextButton",{Name="OrbitInput",Text="",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,AutoButtonColor=false,ZIndex=5},host)
 local dragging,last
 ui.page:on(hit.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=input;last=Vector2.new(input.Position.X,input.Position.Y) end
 end)
 ui.page:on(Input.InputChanged,function(input)
  if not dragging or (input~=dragging and input.UserInputType~=Enum.UserInputType.MouseMovement) then return end
  local pos=Vector2.new(input.Position.X,input.Position.Y);local delta=pos-last;last=pos
  yaw-=delta.X*.012;pitch=math.clamp(pitch+delta.Y*.009,-.9,.9);fit()
 end)
 ui.page:on(Input.InputEnded,function(input) if dragging==input or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end end)
 local pending=false
 ui:watch(function()
  if snapshot==a.s or pending then return end
  pending=true
  task.delay(.12,function()
   pending=false
   if ui.page.dead or not vp.Parent then return end
   snapshot=a.s
   pcall(function() fx:step(rig,previewSettings(),0) end)
  end)
 end)
end
-- Reuse twelve 2D cards; only the selected effect has a persistent 3D viewport.
local function visualsHub(a,kind,ui)
 local items={}
 if kind=="Halos" then
  for i,style in S.haloV2Styles do items[#items+1]={id="layer:"..i,name=style,key="haloV2"..i} end
  for _,style in S.defs.haloStyle.min do items[#items+1]={id="classic:"..style,name=style,classic=true} end
 elseif kind=="Wings" then
  for _,style in S.defs.wingStyle.min do items[#items+1]={id=style,name=style} end
 else
  for _,row in S.skies do items[#items+1]={id=row[1],name=row[1],sky=row} end
 end
 if #items==0 then return end
 a.catalogPages=a.catalogPages or {};a.catalogSelection=a.catalogSelection or {};a.catalogEditors=a.catalogEditors or {}
 local maxPage=math.max(1,math.ceil(#items/12))
 local page=math.clamp(a.catalogPages[kind] or 1,1,maxPage)
 local selected=items[(page-1)*12+1]
 for _,item in items do if item.id==a.catalogSelection[kind] then selected=item;break end end
 local function active(item)
  local s=a.s
  if kind=="Halos" then return if item.classic then s.halo and s.haloStyle==item.name else s[item.key.."Enabled"] end
  if kind=="Wings" then return s.wings and s.wingStyle==item.name end
  return s.ambient and s.skyA==item.sky[2] and s.skyB==item.sky[3] and s.skyC==item.sky[4]
 end
 local function equip(item,on)
  if kind=="Halos" then
   if item.classic then if on then a:patch({halo=true,haloStyle=item.name}) elseif active(item) then a:set("halo",false) end
   else a:set(item.key.."Enabled",on) end
  elseif kind=="Wings" then
   if on then a:patch({wings=true,wingStyle=item.name}) elseif active(item) then a:set("wings",false) end
  else
   if on then a:patch(S.sky(item.sky)) elseif active(item) then a:set("ambient",false) end
  end
 end
 local host=ui.catalogHost
 local title=U.label(host,kind:upper().."  /  COLLECTION",14,UDim2.fromOffset(12,5),UDim2.new(1,-24,0,30));title.Font=Enum.Font.Code
 local grid=U.frame(host,"CardGrid",UDim2.fromOffset(9,40),UDim2.new(1,-18,1,-86),nil,1)
 U.new("UIGridLayout",{CellSize=UDim2.new(.25,-5,1/3,-5),CellPadding=UDim2.fromOffset(6,6),FillDirectionMaxCells=4,SortOrder=Enum.SortOrder.LayoutOrder},grid)
 local footer=U.frame(host,"CatalogPager",UDim2.new(0,9,1,-37),UDim2.new(1,-18,0,29),nil,1)
 local prev=U.button(footer,"<");prev.Size=UDim2.fromOffset(34,29)
 local nextButton=U.button(footer,">");nextButton.Position=UDim2.new(1,-34,0,0);nextButton.Size=UDim2.fromOffset(34,29)
 local info=U.label(footer,"",11,UDim2.fromOffset(38,0),UDim2.new(1,-76,1,0));info.TextXAlignment=Enum.TextXAlignment.Center;info.Font=Enum.Font.Code
 local cards={}
 local thumbGeneration=0
 local function queueThumbnails()
  thumbGeneration+=1;local generation=thumbGeneration
  task.spawn(function()
   for _,card in cards do
    if ui.page.dead or generation~=thumbGeneration then return end
    if card.item and card.renderId~=card.item.id then
     local item=card.item
     drawThumbnail(card.thumb,card.canvas,item,kind)
     card.renderId=item.id;card.thumb.Visible=true
     task.wait()
    end
   end
  end)
 end
 local function drawCards()
  info.Text=string.format("%d / %d   ·   %d",page,maxPage,#items)
  prev.BackgroundColor3=U.hex(a.s.uiButtonColor);nextButton.BackgroundColor3=U.hex(a.s.uiButtonColor)
  for i,card in cards do
   local item=items[(page-1)*12+i]
   if card.item~=item then card.thumb.Visible=false end
   card.item=item;card.button.Visible=item~=nil
   if not item then continue end
   if card.renderId==item.id then card.thumb.Visible=true end
   card.name.Text=item.name
   local on=active(item)
   card.badge.Text=if on then "EQUIPPED" else ""
   card.rim.Color=if selected==item or on then U.hex(a.s.accent) else U.hex(a.s.uiStrokeColor)
   card.rim.Transparency=if selected==item then .02 elseif on then .26 else .72
   card.button.BackgroundColor3=U.hex(if selected==item then a.s.uiHoverColor else a.s.uiButtonColor)
  end
 end
 local function buildEditor()
  local item=selected
  local ed=ui:makeCatalogEditor()
  ed:title(item.name:upper())
  local bar=ed:row(40,"EquipActions");bar.BackgroundTransparency=1
  local equipButton=U.button(bar,"EQUIP");equipButton.Size=UDim2.new(.62,-4,1,0)
  local cancel=U.button(bar,"CANCEL");cancel.Position=UDim2.new(.62,3,0,0);cancel.Size=UDim2.new(.38,-3,1,0)
  equipButton.Font=Enum.Font.Code;cancel.Font=Enum.Font.Code
  ed.page:on(equipButton.Activated,function() ui:action(function() equip(item,true);ui:sync() end) end)
  ed.page:on(cancel.Activated,function() ui:action(function() equip(item,false);ui:sync() end) end)
  ed:watch(function() equipButton.Text=if active(item) then "EQUIPPED" else "EQUIP";equipButton.BackgroundColor3=U.hex(if active(item) then a.s.uiHoverColor else a.s.uiButtonColor);cancel.BackgroundColor3=U.hex(a.s.uiButtonColor) end)
  local preview=ed:row(210,"SelectedPreview");preview.BackgroundTransparency=.3
  effectThumbnail(ed,preview,a,item,kind)
  local thumbnail=preview:FindFirstChild("EffectThumbnail")
  if thumbnail then thumbnail.Size=UDim2.new(1,-8,1,-8) end
  local editorButton=U.button(ed:row(36,"EditorPill"),if a.catalogEditors[kind] then "EDITOR   −" else "EDITOR   +")
  editorButton.Font=Enum.Font.Code;editorButton.Size=UDim2.fromScale(1,1);U.corner(editorButton,18);ed:watch(function() editorButton.BackgroundColor3=U.hex(a.s.uiButtonColor) end)
  ed.page:on(editorButton.Activated,function() a.catalogEditors[kind]=not a.catalogEditors[kind];buildEditor();ui:sync() end)
  if a.catalogEditors[kind] then
   if kind=="Halos" then
    if item.classic then
     ed:colorPicker("haloColor")
     for _,k in {"haloRadius","haloHeight","haloSpin","haloRainbow","haloDetail","haloWalk","haloGlow"} do ed:control(k) end
    else
     local k=item.key;ed:colorPicker(k.."Color");ed:colorPicker(k.."Secondary")
     for _,suffix in {"Radius","Height","Spin","Opacity","Glow","Thickness","Count","Tilt"} do ed:control(k..suffix) end
    end
    ed:chips({"Disable all halos"},function()
     local patch={halo=false};for i in S.haloV2Styles do patch["haloV2"..i.."Enabled"]=false end;a:patch(patch)
    end,1)
   elseif kind=="Wings" then ed:group("Wings",{wingStyle=true,wings=true})
   else
    ed:group("Ambient",{starfallA=true,starfallB=true,bloom=true,worldBloomSize=true,worldExposure=true})
    ed:colorPicker("starfallA");ed:colorPicker("starfallB")
   end
  end
  ui.sc.CanvasPosition=Vector2.zero
 end
 for i=1,12 do
  local b=U.button(grid,"");b.Name="VisualCard"..i;b.LayoutOrder=i;b.BackgroundTransparency=.40;U.corner(b,12)
  local rim=U.stroke(b,Color3.fromRGB(138,112,189),.72)
  local thumb=U.frame(b,"EffectThumbnail",UDim2.fromScale(.06,.06),UDim2.fromScale(.88,.60),Color3.fromRGB(27,22,43),.33);thumb.ClipsDescendants=true;thumb.Active=false;thumb.Interactable=false;U.corner(thumb,10)
  local canvas=U.frame(thumb,"Projection",UDim2.fromScale(.5,.5),UDim2.fromOffset(100,100),nil,1);canvas.AnchorPoint=Vector2.new(.5,.5);canvas.Active=false;canvas.Interactable=false
  local scale=U.new("UIScale",{Scale=.5},canvas)
  local function fitThumb() local size=thumb.AbsoluteSize;scale.Scale=math.max(.08,math.min(size.X,size.Y)/100) end
  fitThumb();ui.page:on(thumb:GetPropertyChangedSignal("AbsoluteSize"),fitThumb)
  local name=U.label(b,"",11,UDim2.fromScale(.04,.66),UDim2.fromScale(.92,.19));name.TextXAlignment=Enum.TextXAlignment.Center;name.TextScaled=true;name.Font=Enum.Font.Code;name.Active=false;name.Interactable=false
  U.new("UITextSizeConstraint",{MinTextSize=7,MaxTextSize=14},name)
  local badge=U.label(b,"",9,UDim2.fromScale(.04,.86),UDim2.fromScale(.92,.11));badge.TextScaled=true;badge.TextXAlignment=Enum.TextXAlignment.Center;badge.Active=false;badge.Interactable=false
  U.new("UITextSizeConstraint",{MinTextSize=6,MaxTextSize=10},badge)
  local card={button=b,rim=rim,thumb=thumb,canvas=canvas,name=name,badge=badge};cards[i]=card
  ui.page:on(b.MouseEnter,function() if card.item and selected~=card.item then b.BackgroundTransparency=.23;rim.Transparency=.30 end end)
  ui.page:on(b.MouseLeave,function() b.BackgroundTransparency=.40;drawCards() end)
  ui.page:on(b.Activated,function()
   if not card.item or selected==card.item then return end
   selected=card.item;a.catalogSelection[kind]=selected.id;buildEditor();ui:sync()
  end)
 end
 local function move(delta)
  local new=math.clamp(page+delta,1,maxPage)
  if new==page then return end
  page=new;a.catalogPages[kind]=page;drawCards();queueThumbnails()
 end
 ui.page:on(prev.Activated,function() move(-1) end);ui.page:on(nextButton.Activated,function() move(1) end)
 ui:watch(drawCards);buildEditor();queueThumbnails()
end
local function configs(ui,a)
 local selected=a.configSelection
 local current=a.bank.profiles
 local status=ui:note("",38)
 ui:watch(function() status.Text=a.store.status end)
 ui:title("CONFIG MANAGER")
 ui:note("Save HUD, cosmetics, and Volleyball module switches and modes together in each profile.",46)
 local list=names(current)
 if #list==0 then ui:note("No configurations yet. Enter a name and save.",28)
 else ui:chips(list,function(n) a.configSelection=n;a.configName=n;a.confirmDelete=nil;ui:open("Profiles") end,2,function() return selected or "" end) end
 local input=ui:box("Config name",a.configName or selected or "My setup",32)
 ui.page:on(input:GetPropertyChangedSignal("Text"),function() a.configName=input.Text end)
 local function validName()
  local n=input.Text:match("^%s*(.-)%s*$")
  assert(#n>0 and #n<=48 and not n:match("^@") and not n:find("%c"),"Enter a valid config name")
  return n
 end
 local function commit(bank,n,message)
  a:library(bank);a.configSelection=n;a.configName=n or ""
  a.store:save();ui:open("Profiles");ui:message(message.." · "..a.store.status)
 end
 ui:chips({"Save new","Load","Update selected"},function(op)
  local draft=S.copy(a.bank)
  if op=="Load" then
   assert(selected and current[selected],"Select a saved config")
   a:replace(S.copy(current[selected]));a.store:save();ui:message("Loaded "..selected)
  elseif op=="Update selected" then
   assert(selected and current[selected],"Select a saved config")
   draft.profiles[selected]=S.settings(a.s);commit(draft,selected,"Updated "..selected)
  else
   local n=validName();assert(not current[n],"Name exists; use Update selected")
   draft.profiles[n]=S.settings(a.s);commit(draft,n,"Saved "..n)
  end
 end,3)
 ui:chips({"Rename","Duplicate","Delete"},function(op)
  assert(selected and current[selected],"Select a saved config")
  local draft=S.copy(a.bank)
  if op=="Delete" then
   if a.confirmDelete~=selected then a.confirmDelete=selected;ui:message("Click Delete again to remove "..selected);return end
   a.confirmDelete=nil;draft.profiles[selected]=nil;commit(draft,nil,"Deleted "..selected)
  else
   local n=validName();assert(not current[n],"Name already exists")
   draft.profiles[n]=S.copy(current[selected]);if op=="Rename" then draft.profiles[selected]=nil end
   commit(draft,n,"Saved "..n)
  end
 end,3)
 ui:title("STORAGE")
 ui:note(if a.store.device then "Device storage: two alternating, validated JSON slots. Auto-save and restore on restart. Module preferences included." elseif a.store.remote then "Server storage available. Durable saving depends on the game's DataStore configuration." else "No device file API. Session only; use JSON backup to keep configs after exit.",62)
 ui:chips({"Save now","Reload bank"},function(op) if op=="Save now" then a.store:save() else a.store:read(true) end;ui:message(a.store.status);if not ui.page.dead then ui:sync() end end,2)
 ui:chips({if a.showConfigJSON then "Hide JSON tools" else "Advanced / JSON backup"},function() a.showConfigJSON=not a.showConfigJSON;ui:open("Profiles") end,1)
 if a.showConfigJSON then
  local transfer=ui:box("JSON backup",a.transfer or "",100)
  ui.page:on(transfer.FocusLost,function() a.transfer=transfer.Text end)
  ui:chips({"Export bank","Import bank"},function(op)
   if op=="Export bank" then
    a.transfer=Http:JSONEncode({format="aether.bank/1",data=a.bank});transfer.Text=a.transfer;transfer:CaptureFocus();transfer.CursorPosition=#transfer.Text+1;transfer.SelectionStart=1
   else
    assert(#transfer.Text<=110100,"Import too large")
    local v=Http:JSONDecode(transfer.Text);assert(v.format=="aether.bank/1","Invalid bank format")
    a:restore(S.bank(v.data));a:dirty();a.store:save();ui:message("Bank imported")
   end
  end,2)
 end
end
local function airControls(ui,a)
  ui:title("AIR REDIRECTION")
  ui:control("airControl");ui:control("airControlStrength");ui:control("airControlSpeed");ui:control("airTiltAngle");ui:control("bunnyHop")
  local hopStatus=ui:note("",40)
  ui:watch(function() hopStatus.Text=string.format("Bunny Hop: %s | requests: %d",if not a.s.bunnyHop then "Off" else (a.bunnyHopStatus or "Hold Space"),a.bunnyHopCount or 0) end)
  local airStatus=ui:note("",44)
  ui:watch(function() airStatus.Text=if a.mode=="Simulator" then "Simulator: steer with movement controls. Horizontal momentum is preserved." else "Live: steer in midair. Jump height is unchanged; game physics may override local steering." end)
  local airDebug=ui:note("",64)
  ui:watch(function() airDebug.Text="Last airborne sample: "..(a.airDiagnostic or "No airborne state recorded") end)
  local airLoop=ui:note("",52)
  ui:watch(function() airLoop.Text=string.format("Physics ticks: %d | velocity writes: %d | strength: %d%%",a.airTicks or 0,a.airWrites or 0,a.s.airControlStrength) end)
  local airInput=ui:note("",40)
  ui:watch(function() airInput.Text=string.format("Input: %s | air speed: %d%%",a.airInputSource or "Waiting",a.s.airControlSpeed) end)
  local airDetection=ui:note("",64)
  ui:watch(function() airDetection.Text=string.format("Air frames: %d | peak vertical speed: %.1f | UI guard: off",a.airObserved or 0,a.airPeakVertical or 0) end)
  local airObserved=ui:note("",64)
  ui:watch(function() airObserved.Text="Last detection: "..(a.airLastDetection or "No jump detected") end)
  local airReason=ui:note("",64)
  ui:watch(function() airReason.Text="Last active check: "..(a.airLastActive or "No physics callback recorded") end)
  local airTrack=ui:note("",60)
  ui:watch(function() airTrack.Text=a.airTracking or "Waiting for live character" end)
  local airPosition=ui:note("",64)
  ui:watch(function()
   local m=a.airMonitor
   airPosition.Text=if m then string.format("Jump requests: %d | height range: %.2f | position travel: %.2f | peak Y velocity: %.2f",a.airJumpRequests or 0,m.maxY-m.minY,m.travel,m.peakY) else "No live position sample"
  end)
end
-- Read-only game state monitor and isolated virtual-character controls.
local function statePanel(ui,a)
 ui:title("STATE MONITOR")
 local status=ui:note("",72)
 local cache=a.stateMonitorCache
 if not cache then
  cache={text="Waiting for game state",nextAt=0,pending=false}
  a.stateMonitorCache=cache
 end
 local function flag(value)
  if value==true then return "ON" elseif value==false then return "OFF" end
  return "N/A"
 end
 local function refresh()
  if a.mode=="Simulator" then
   local raw=a.sim.stateBusy==true
   local override=a.sim.stateOverride==true
   status.Text="SIMULATOR | Busy: "..flag(raw).." | Effective: "..flag(raw and not override).."\nOverride: "..flag(override).." | Virtual character only"
   return
  end
  status.Text="GAME | "..cache.text
  local now=os.clock()
  if cache.pending or now<cache.nextAt then return end
  cache.pending=true;cache.nextAt=now+.35
  task.spawn(function()
   local ok,result=pcall(function()
    local rf=game:GetService("ReplicatedFirst")
    local controllers=rf:FindFirstChild("Controllers")
    local g=controllers and controllers:FindFirstChild("GameController")
    local handlers=g and g:FindFirstChild("Handlers")
    if not handlers or not handlers:IsA("ModuleScript") then return "State module unavailable" end
    local states=require(handlers).States
    if not states then return "State table unavailable" end
    local function get(key)
     local success,value=pcall(function() return states[key]() end)
     return if success then flag(value) else "N/A"
    end
    return "Busy: "..get("IsBusy").." | Stunned: "..get("IsStunned").."\nJumping: "..get("IsJumping").." | Serving: "..get("IsServing")
   end)
   cache.text=if ok then result else "State read unavailable"
   cache.pending=false;cache.nextAt=os.clock()+.35
   if not ui.page.dead and ui.opened and a.mode=="Game" then status.Text="GAME | "..cache.text end
  end)
 end
 ui:watch(refresh)
 local elapsed=0
 ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
  elapsed+=dt
  if elapsed>=.35 then elapsed=0;if ui.opened then refresh() end end
 end)
end
function E.render(a,tab,ui)
 if tab=="Dashboard" then
  preview(ui,a);ui:title("AETHER / OVERVIEW")
  ui:note("Choose a branch on the left. Visual collections, interface settings and profiles are organized separately.",50)
  ui:chips({"Interface","Profiles","Halos","Wings"},function(n) ui:open(n) end,2)
 elseif tab=="Interface" then
  ui:title("INFINITE WORKSPACE")
  ui:note("Middle mouse: pan. Wheel on background or Ctrl + wheel: zoom. Drag node titles to move individual panels. Home resets camera; Shift + Home resets the current workspace. Double-click or double-tap the background to close.",80)
  ui:control("workspaceMode")
  ui:chips({"Reset camera","Reset current workspace"},function(n) ui:resetWorkspace(n=="Reset current workspace") end,2)
  ui:title("AFK SCREEN")
  ui:note("Type AFK in the workspace to open its full-screen view. Preview only changes appearance; it does not activate Anti-AFK.",48)
  ui:chips({"Preview AFK screen","Reset AFK appearance"},function(name)
   if name=="Preview AFK screen" then ui:setAFK(true,true)
   else
    local defaults=S.defaults();local patch={}
    for key,value in defaults do if key:sub(1,3)=="afk" then patch[key]=value end end
    a:patch(patch)
   end
  end,2)
  ui:control("afkBackground")
  ui:control("afkFadeMs")
  ui:control("afkGradientAngle")
  ui:control("afkPatternOpacity")
  ui:control("afkImageAsset")
  ui:control("afkImageOpacity")
  ui:note("Image mode uses a Roblox image asset ID. Only images accessible in the current experience can load.",36)
  for _,k in {"afkBgA","afkBgB","afkPatternColor","afkBrandColor","afkTitleColor","afkDetailColor","afkButtonColor","afkButtonText","afkButtonEdge","afkImageTint"} do ui:colorPicker(k) end
  ui:title("LAYOUT & WIDGETS")
  ui:chips({"Edit GUI size / position"},function() ui:editLayout(true) end,1)
  ui:chips({"Edit HUD size / position"},function() a:set("movePanels",true);a:editHUD(true) end,1)
  ui:chips({"Reset GUI layout","Save configuration"},function(n)
   if n=="Reset GUI layout" then a:patch({layoutCustom=false,navWidth=156,topScale=100,topCustom=false}) else a.store:save() end
  end,2)
  for _,k in {"layoutCustom","layoutX","layoutY","layoutW","layoutH","navWidth","topScale","clock","profile","keybindWidget"} do ui:control(k) end
  ui:title("LIQUID GLASS");preset(ui,a,"Theme")
  for _,k in {"uiGlassOpacity","uiReflection","rim","glass"} do ui:control(k) end
  for _,k in {"uiPanelColor","uiButtonColor","uiHoverColor","uiRowColor","uiStrokeColor","uiSpecularColor","accent","secondary","uiFontColor","uiMutedColor","glassColor","clockGlass","fpsGlass","clockText","fpsText"} do ui:colorPicker(k) end
  ui:title("SPACE BACKGROUND")
  for _,k in {"constellationBgA","constellationBgB","constellationLineA","constellationLineB","constellationNodeA","constellationNodeB"} do ui:colorPicker(k) end
  for _,k in {"menuGeometry","menuShape","menuDensity","menuMotion","menuOpacity","constellationLinks","constellationDistance","constellationThickness","constellationSize","constellationAngle","screenParticles","screenParticleOpacity"} do ui:control(k) end
  ui:title("MOTION");preset(ui,a,"Motion");ui:group("Motion")
 elseif tab=="HUD" then preview(ui,a,true);ui:chips({"Edit HUD on screen"},function() a:editHUD(true) end,1);preset(ui,a,"HUD");ui:control("layoutMode");ui:control("locked");ui:title("TOP PANEL");for _,v in {"movePanels","topScale"} do ui:control(v) end;ui:note("Enable moving panels to drag the AETHER capsule.",34);ui:chips({"Reset panel position"},function() a:patch({topCustom=false}) end,1);ui:title("HUD MOTION");for _,k in {"hudMotion","hudMotionStrength","hudSmoothness"} do ui:control(k) end;ui:note("Sketch places the HUD along screen edges. Select Custom to edit widget coordinates or drag in the unlocked preview.",29);local widgets={"clock","profile","top"};if not table.find(widgets,a.hudTab) then a.hudTab="clock" end;ui:chips(widgets,function(n) a.hudTab=n;ui:open("HUD") end,3,function() return a.hudTab end);local k=a.hudTab
  if k=="top" then for _,v in {k.."Custom",k.."X",k.."Y"} do ui:control(v) end
  else for _,suffix in {"","X","Y","Scale","Turn","Alpha"} do ui:control(k..suffix) end end
 elseif tab=="Character" then
  ui:title("AETHER MOTION STUDIO V12.14")
  MotionStudio.mount(ui,a)
 elseif tab=="Wings" or tab=="Halos" or tab=="Ambient" then
  if ui.catalogHost then visualsHub(a,tab,ui) end
 elseif tab=="Indicators" then preview(ui,a);gallery(ui,a);ui:group(tab,{shape=true});ui:title("PER-PLAYER OVERRIDE");local id=ui:box("UserId or simulator ID","1");local label=ui:box("Label override","");local color=ui:box("Override hex",a.s.arrowA);ui:chips({"Assign current shape","Remove override"},function(k) local p=S.copy(a.s.players);if k=="Assign current shape" then p[id.Text]={label=label.Text,color=color.Text,shape=a.s.shape} else p[id.Text]=nil end;a:set("players",p);ui:message("Overrides updated") end,2)
 elseif tab=="Cursor" then local f=ui:row(94,"CursorPreview");local host=U.frame(f,"OriginalCursorPreview",UDim2.fromScale(.5,.5),UDim2.fromOffset(60,60),nil,1);host.AnchorPoint=Vector2.new(.5,.5);a.preview={cursorHost=host};preset(ui,a,tab);ui:group(tab,{cursorTrailA=true,cursorTrailB=true});ui:title("TRAIL COLORS");ui:colorPicker("cursorTrailA");ui:colorPicker("cursorTrailB");ui:note("Cursor animation never moves its click hotspot. Enable Show hotspot marker to compare the real mouse position with the skin; use Pointer offset X/Y only for calibration. EditableImage renders desktop SVG; imports need an authorized asset ID.",57)
 elseif tab=="Interaction" then
  ui:title("AETHER PEER VISUALS")
  ui:note("Opt in to share avatar cosmetics in a supported place. ON requests connection; the status below confirms it. The place must have the AETHER server relay installed. Desktop relay is separate.",54)
  ui:control("peerVisuals");ui:control("peerQuality")
  local peerStatus=ui:note("",36)
  if a.peers then
   a.peers.statusLabel=peerStatus
   ui.page:add(function() if a.peers.statusLabel==peerStatus then a.peers.statusLabel=nil end end)
  end
  ui:watch(function() peerStatus.Text=if a.peers then a.peers.status else "Peer relay unavailable" end)
  airControls(ui,a)
  ui:title("CAMERA")
  preset(ui,a,"Camera");ui:group("Camera")
  ui:title("CUSTOM LOCK / KEYBIND")
  local keyButton=U.button(ui:row(38,"LockKeyCapture"),"")
  keyButton.Size=UDim2.new(1,-8,1,-8);keyButton.Position=UDim2.fromOffset(4,4)
  ui.page:on(keyButton.Activated,function() a.bindingLockKey=not a.bindingLockKey;ui:sync() end)
  ui:watch(function() keyButton.Text=if a.bindingLockKey then "PRESS ANY KEY · click to cancel" else "CHANGE KEY · "..a.s.lockKey end)
  ui:note("All keyboard codes can be selected. Block both Shift keys suppresses Shift actions such as sprint; AETHER can still observe its selected key. Click again to cancel.",50)
  ui.page:add(function() a.bindingLockKey=false end)
  local lockStatus=ui:note("",45)
  ui:watch(function()
   lockStatus.Text=if a.view:nativeLockAvailable() then "Native Shift Lock is controlled by the place. In Roblox Settings turn Shift Lock Switch off. Use Block both Shift keys to suppress their standard input actions."
    elseif not a.s.lock then "CUSTOM LOCK OFF · "..a.s.lockKey.." toggles; "..S.menuKey(a.s).." opens Studio."
    elseif a.s.cameraMode~="Follow" then "CUSTOM LOCK WAITING · Select Follow camera."
    else "CUSTOM LOCK READY · "..a.s.lockKey.." toggles AETHER only. Shift input blocking follows the Block both Shift keys setting."
  end)
  ui:title("SHIFT-LOCK / RETICLE")
  for _,k in {"cross","crossScale","crossAlpha"} do ui:control(k) end
  local inputKeys={gameInputPassthrough=true,peerVisuals=true,peerQuality=true,lockKey=true,inputOverlay=true,inputMouse=true,inputX=true,inputY=true,inputScale=true,inputOpacity=true,inputColor=true,wallhopHelper=true,wallhopX=true,wallhopY=true,wallhopScale=true,wallhopOpacity=true}
  ui:group(tab,inputKeys)
  ui:title("LIVE INPUT DISPLAY")
  local m2Status=ui:note("",76)
  ui:watch(function()
   m2Status.Text=string.format("%s | presses: %d\n%s | releases: %d",a.m2Last or "No M2 down",a.m2Presses or 0,a.m2LastRelease or "No M2 up",a.m2Releases or 0)
  end)
  ui:note("Shows your own WASD, Space, Shift and mouse presses. Read-only visualization: no synthetic inputs or game automation.",44)
  for _,k in {"inputOverlay","inputMouse","inputX","inputY","inputScale","inputOpacity","inputColor"} do ui:control(k) end
  ui:title("WALLHOP HELPER")
  ui:note("Practice display: tracks your jump and horizontal camera rotation. No automatic jumps or camera movement.",42)
  for _,k in {"wallhopHelper","wallhopX","wallhopY","wallhopScale","wallhopOpacity"} do ui:control(k) end
 elseif tab=="Volleyball" then
  if ui==a.ui then
   ui:title("WIDGET LAYOUT")
   ui:chips({"Edit widget positions"},function() a:editHUD(true,"Volleyball",false) end,1)
   ui:control("keybindWidget")
   ui:chips({"Reset widget positions"},function() a:patch({keybindCustom=false,quickCustom=false}) end,1)
  end
  if a.volleyball then
   local vb=a.volleyball
   local lp=game:GetService("Players").LocalPlayer
   statePanel(ui,a)
   ui:title("VOLLEYBALL MODIFIERS / BETA")
   local availability=ui:note("",64)
   ui:watch(function() availability.Text=vb:availabilityStatus() end)
   ui:note("Numeric preferences are included in configs. Local values depend on available game attributes; server acceptance is not guaranteed.",64)
   for _,name in S.vbMultiplierNames do
    local key="Multiplier_"..name
    local field=ui:box(name,tostring(lp:GetAttribute(key) or ""),32,function(value)
     vb:setMultiplier(name,assert(tonumber(value),"Enter a number"))
    end)
    local readback=ui:note("",40)
    local function refresh()
     if not field:IsFocused() then
      local requested=vb.multiplierRequests[name]
      local saved=a.s["vbMultiplier_"..name]
      local value=if type(saved)=="number" then saved elseif requested~=nil then requested else lp:GetAttribute(key)
      local shown=tostring(value or "")
      if field.Text~=shown then field.Text=shown end
     end
     readback.Text=vb:multiplierStatus(name)
    end
    ui:watch(refresh)
    local elapsed=0
    ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
     elapsed+=dt
     if elapsed>=.25 then elapsed=0;if ui.opened then refresh() end end
    end)
   end
   ui:chips({"Restore original values"},function() vb:reset();a:clearSavedMultipliers();ui:sync() end,1)
   ui:title("BALL HITBOX EXPANDER / BETA")
   ui:note("Purple box shows the actual oriented bounds of the queryable mesh; the faint sphere is an approximation. Mesh bounds do not guarantee hit acceptance.",72)
   local radiusField=ui:box("Ball size factor (>=1)",tostring(vb.ballRadius.factor),32,function(raw)
    vb:setBallRadiusFactor(assert(tonumber(raw),"Enter a number"))
   end)
   ui:chips({"Toggle Ball Expander"},function() vb:toggleBallRadius();ui:sync() end,1,function() return if vb.ballRadius.enabled then "Toggle Ball Expander" else "" end)
   ui:chips({"Show Hitbox"},function() vb:toggleBallRadiusGuide();ui:sync() end,1,function() return if vb.ballRadius.show then "Show Hitbox" else "" end)
   local radiusStatus=ui:note("",72)
   local function refreshRadius()
    if not radiusField:IsFocused() then radiusField.Text=tostring(vb.ballRadius.factor) end
    radiusStatus.Text=(if vb.ballRadius.enabled then "ON | " else "OFF | ")..vb.ballRadius.status.." | Guide: "..(if vb.ballRadius.show then "ON" else "OFF").." | Reconnects: "..tostring(vb.ballRadius.reconnects)
   end
   ui:watch(refreshRadius)
   local radiusElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    radiusElapsed+=dt
    if radiusElapsed>=.25 then radiusElapsed=0;if ui.opened then refreshRadius() end end
   end)
   ui:title("BALL TOUCH INFO")
   ui:chips({"Show last hitter"},function() vb:toggleBallTouchInfo();ui:sync() end,1,function() return if vb.ballTouchInfo.enabled then "Show last hitter" else "" end)
   ui:note("Shows the last hitter and received touch events for the active ball. Enable before a rally for a complete observed count.",64)
   local ballInfoStatus=ui:note("",56)
   local function refreshBallInfo()
    ballInfoStatus.Text=(if vb.ballTouchInfo.enabled then "ON | " else "OFF | ")..vb.ballTouchInfo.status
   end
   ui:watch(refreshBallInfo)
   local ballInfoElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    ballInfoElapsed+=dt
    if ballInfoElapsed>=.25 then ballInfoElapsed=0;if ui.opened then refreshBallInfo() end end
   end)
   ui:title("SHOT ARC / BETA")
   ui:chips({"Shot Arc"},function() vb:toggleShotArc();ui:sync() end,1,function() return if vb.shotArc.enabled then "Shot Arc" else "" end)
   ui:chips({"Auto","Spike","Set","Serve"},function(n) vb.shotArc.mode=n;ui:sync() end,2,function() return vb.shotArc.mode end)
   ui:note("Preview of a hypothetical next contact, not the incoming ball. Learns velocity from your observed hits; uses current power and tilt stats. No server hit formula is available.",76)
   local arcStatus=ui:note("",64)
   ui:watch(function() arcStatus.Text=vb.shotArc.status end)
   local arcRefresh=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    arcRefresh+=dt
    if arcRefresh>=.25 then arcRefresh=0;if ui.opened then arcStatus.Text=vb.shotArc.status end end
   end)
   ui:title("TRAJECTORY ESP / BETA")
   ui:note("Controller velocity when available; position sampling fallback. Green = IN, red = OUT, amber = obstacle or unknown court. Prediction stops at first contact; unreplicated curve effects remain estimates.",76)
   ui:chips({"Toggle Trajectory ESP"},function() vb:toggleTrajectory();ui:sync() end,1,function() return if vb.trajectory.enabled then "Toggle Trajectory ESP" else "" end)
   local trajectoryStatus=ui:note("",64)
   local function refreshTrajectory()
    trajectoryStatus.Text=(if vb.trajectory.enabled then "ON | " else "OFF | ")..vb.trajectory.status
   end
   ui:watch(refreshTrajectory)
   local trajectoryElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    trajectoryElapsed+=dt
    if trajectoryElapsed>=.25 then trajectoryElapsed=0;if ui.opened then refreshTrajectory() end end
   end)
   ui:title("DIRECTION ESP / BETA")
   ui:note("Jinko, Sanju, Kijo and Twins (TheTwins): purple arrow and 36-stud tilt guide. Flight prediction is unverified.",72)
   ui:chips({"Toggle Direction ESP"},function() vb:toggleJinkoDirection();ui:sync() end,1,function() return if vb.jinkoDirection.enabled then "Toggle Direction ESP" else "" end)
   local jinkoStatus=ui:note("",56)
   local function refreshJinko()
    jinkoStatus.Text=(if vb.jinkoDirection.enabled then "ON | " else "OFF | ")..vb.jinkoDirection.status
   end
   ui:watch(refreshJinko)
   local jinkoElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    jinkoElapsed+=dt
    if jinkoElapsed>=.25 then jinkoElapsed=0;if ui.opened then refreshJinko() end end
   end)
   ui:title("JINKO STYLE / LOCAL PREVIEW")
   ui:note("Uses the game's local style observer, including its animation and special refresh. No account slot or server multiplier is changed. Turn off to restore the original selection.",84)
   ui:chips({"Toggle Jinko preview"},function() vb:toggleStyle();ui:sync() end,1,function() return if vb.styleEnabled then "Toggle Jinko preview" else "" end)
   local styleStatus=ui:note("",72)
   local function refreshStyle()
    styleStatus.Text=(if vb.styleEnabled then "ON | " else "OFF | ")..vb.styleStatus
   end
   ui:watch(refreshStyle)
   local styleElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    styleElapsed+=dt
    if styleElapsed>=.25 then styleElapsed=0;if ui.opened then refreshStyle() end end
   end)
   ui:title("CURVE SPECIAL / EXPERIMENT")
   ui:note("Attempts a local Jinko special selection only. The server may ignore it. Stops on match exit or style change and restores the previous local special where unchanged.",84)
   ui:chips({"Toggle local Curve test"},function() vb:toggleCurve();ui:sync() end,1,function() return if vb.curveEnabled then "Toggle local Curve test" else "" end)
   local curveStatus=ui:note("",72)
   local function refreshCurve()
    curveStatus.Text=(if vb.curveEnabled then "ON | " else "OFF | ")..vb.curveStatus
   end
   ui:watch(refreshCurve)
   local curveElapsed=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    curveElapsed+=dt
    if curveElapsed>=.25 then curveElapsed=0;if ui.opened then refreshCurve() end end
   end)
   ui:title("AUTO PLAY / BETA")
   ui:note("Ground = Set; airborne = Spike; low distant ball = Dive. One attempt per ball approach; normal game rules remain active.",64)
   ui:chips({"Auto Set"},function() vb:togglePlay("Set");ui:sync() end,1,function() return if vb.play.set then "Auto Set" else "" end)
   ui:chips({"Auto Spike"},function() vb:togglePlay("Spike");ui:sync() end,1,function() return if vb.play.spike then "Auto Spike" else "" end)
   ui:chips({"Auto Dive"},function() vb:togglePlay("Dive");ui:sync() end,1,function() return if vb.play.dive then "Auto Dive" else "" end)
   ui:chips({"Auto Serve"},function() vb:togglePlay("Serve");ui:sync() end,1,function() return if vb.play.serve then "Auto Serve" else "" end)
   ui:title("CONSECUTIVE TOUCH / BETA")
   ui:chips({"Repeat touch test"},function() vb:toggleRepeatTouch();ui:sync() end,1,function() return if vb.repeatTouch.enabled then "Repeat touch test" else "" end)
   local touchStatus=ui:note("",70)
   local function refreshTouch()
    touchStatus.Text=vb.repeatTouch.status.."\nLocal checks allowed: "..tostring(vb.repeatTouch.checks).." | Server/team limit unchanged"
   end
   ui:watch(refreshTouch)
   local touchRefresh=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    touchRefresh+=dt
    if touchRefresh>=.25 then touchRefresh=0;if ui.opened then refreshTouch() end end
   end)
   ui:title("SPIKE CAMERA")
   ui:chips({"Free zone","Court center","Off"},function(n) vb.play.cameraAim=n;vb.play.cameraTargetAt=0;vb.play.cameraPoint=nil;ui:sync() end,3,function() return vb.play.cameraAim end)
   ui:chips({"Ground prediction"},function() vb.play.groundPredict=not vb.play.groundPredict;vb.play.cameraTargetAt=0;ui:sync() end,1,function() return if vb.play.groundPredict then "Ground prediction" else "" end)
   ui:chips({"Auto Jump"},function() vb.play.autoJump=not vb.play.autoJump;vb.play.jumpPendingUntil=0;ui:sync() end,1,function() return if vb.play.autoJump then "Auto Jump" else "" end)
   ui:note("Air: turn the character only; keep manual camera control. Ground: aim the camera at the predicted contact point. Paused in menus.",60)
   local playStatus=ui:note("",180)
   local function refreshPlay()
    playStatus.Text=string.format("SET %s | SPIKE %s | DIVE %s\n%s\nAttempts %d | confirmed touches %d\nCamera: %s\nJump: %s | %d\nServe: %s | %s",if vb.play.set then "ON" else "OFF",if vb.play.spike then "ON" else "OFF",if vb.play.dive then "ON" else "OFF",vb.play.status,vb.play.attempts,vb.play.hits,vb.play.cameraStatus,vb.play.jumpStatus,vb.play.jumpCount,if vb.play.serve then "ON" else "OFF",vb.play.serveStatus)
   end
   ui:watch(refreshPlay)
   local playRefresh=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    playRefresh+=dt
    if playRefresh>=.2 then playRefresh=0;if ui.opened then refreshPlay() end end
   end)
   ui:title("AUTO TILT / BETA")
   ui:chips({"Anti-out guard"},function() vb.edgeGuard=not vb.edgeGuard;ui:sync() end,1,function() return if vb.edgeGuard then "Anti-out guard" else "" end)
   ui:note("Proportional boundary correction while Auto Tilt is on. Local trajectory estimate; cannot guarantee an in-bounds server result.",64)
   ui:note("All-style beta: adjusts local jump tilt used by the hit handler. Correct edges preserves manual tilt when the straight heading is in bounds; Aim center estimates a lateral correction. Ball response depends on style and server logic.",96)
   ui:chips({"Auto detect court"},function() vb:detectCourt();ui:sync() end,1)
   ui:chips({"Corner A","Corner B","Corner C"},function(label)
    vb:capture(if label=="Corner A" then 1 elseif label=="Corner B" then 2 else 3);ui:sync()
   end,3)
   local cal=ui:note("",36)
   ui:watch(function() cal.Text=string.format("Calibration: A %s | B %s | C %s",if vb.corners[1] then "OK" else "-",if vb.corners[2] then "OK" else "-",if vb.corners[3] then "OK" else "-") end)
   local geometryStatus=ui:note("",56)
   ui:watch(function() geometryStatus.Text=vb:calibrationStatus() end)
   ui:chips({"Toggle Auto Tilt","Clear court"},function(label)
    if label=="Clear court" then vb:clearCourt() else vb:toggleAuto() end
    ui:sync()
   end,2,function() return if vb.auto then "Toggle Auto Tilt" else "" end)
   ui:chips({"Correct edges","Aim center","Aim left","Aim right","Free zone"},function(label)
    vb.tiltAim=label;vb.requestedTilt=nil;ui:sync()
   end,2,function() return vb.tiltAim end)
   local strength=ui:box("Curve input strength (0–1)",tostring(vb.tiltScale),32,function(raw)
    local n=assert(tonumber(raw),"Enter a number")
    assert(n==n and n>=0 and n<=1,"Enter 0 to 1")
    vb.tiltScale=n;vb.requestedTilt=nil
   end)
   ui:watch(function() if not strength:IsFocused() then strength.Text=tostring(vb.tiltScale) end end)
   local status=ui:note("",80)
   local diagnostic=ui:note("",96)
   local function refreshTilt()
    status.Text=(if vb.auto then "AUTO TILT ON | " else "AUTO TILT OFF | ")..vb.status
    diagnostic.Text=vb:tiltDebug().."\n"..vb.guardStatus
    geometryStatus.Text=vb:calibrationStatus()
    cal.Text=string.format("Calibration: A %s | B %s | C %s",if vb.corners[1] then "OK" else "-",if vb.corners[2] then "OK" else "-",if vb.corners[3] then "OK" else "-")
    availability.Text=vb:availabilityStatus()
   end
   ui:watch(refreshTilt)
   local tiltRefresh=0
   ui.page:on(game:GetService("RunService").Heartbeat,function(dt)
    tiltRefresh+=dt
    if tiltRefresh>=.25 then tiltRefresh=0;if ui.opened then refreshTilt() end end
   end)
  end
  airControls(ui,a)
 elseif tab=="Fonts" then local text=ui:note(a.s.sample,62);text:SetAttribute("AETHERKeepFontColor",true);text.TextXAlignment=Enum.TextXAlignment.Center;local gradient=U.gradient(text,Color3.new(),Color3.new(),10);local glow=U.stroke(text,U.hex(a.s.fontB),.8);glow.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;ui:watch(function() local s=a.s;text.Text=s.sample;text.FontFace=U.font(s);text.TextSize=s.fontSize*.23;text.TextColor3=if s.fontGradient then Color3.new(1,1,1) else U.hex(s.fontA);text.TextStrokeTransparency=1-s.fontOutline/100;gradient.Enabled=s.fontGradient;gradient.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB));glow.Color=U.hex(s.fontB);glow.Transparency=1-s.fontGlow*.008;glow.Thickness=1+s.fontGlow*.023 end);local query=ui:box("Search native typefaces",a.fontQuery or "",32,function(q) if q~=(a.fontQuery or "") then a.fontQuery=q;ui:open("Fonts") end end);local fonts={};for _,n in S.fonts do if n:lower():find((a.fontQuery or ""):lower(),1,true) then table.insert(fonts,n) end end;ui:chips(fonts,function(n) a:patch({font=n,fontAsset=""}) end,3,function() return a.s.font end);ui:group(tab,{font=true});preset(ui,a,tab)
 elseif tab=="Profiles" then configs(ui,a)
 elseif tab=="Diagnostics" then local info=ui:note("",54);local log=ui:box("Session events","",165);log.TextEditable=false;local function refresh() info.Text=string.format("%s  ·  HP %s / %s  ·  %d tracked\n%s",a.mode,tostring(a.frame.hp),tostring(a.frame.max),#a.frame.targets,a.store.status);log.Text=table.concat(a.logs,"\n") end;ui:chips({"Refresh","Clear log","Reset settings"},function(n) if n=="Clear log" then table.clear(a.logs) elseif n=="Reset settings" then a:replace(S.defaults()) end;refresh() end,3);refresh();ui:title("SESSION");ui:note("Unload stops AETHER, removes its HUD and effects, and releases its camera and mouse controls. Export a bank first to retain local-only settings.",52);-- Allocate one confirmation row, once per Diagnostics page. Never append rows from clicks.
  local page=ui.page
  local row=ui:row(40,"UnloadConfirmation")
  row.BackgroundTransparency=1
  local unload=U.button(row,"Unload AETHER")
  unload.Size=UDim2.fromScale(1,1)
  unload:SetAttribute("AETHERKeepFontColor",true)
  local cancel=U.button(row,"Cancel")
  cancel.Position=UDim2.fromScale(.72,0);cancel.Size=UDim2.new(.28,-2,1,0);cancel.Visible=false
  local state="idle"
  local token=0
  local red=Color3.fromRGB(135,35,53)
  local function draw()
   if page.dead or not row.Parent then return end
   unload.BackgroundColor3=if state=="waiting" then Color3.fromRGB(86,36,48) else red
   unload.TextColor3=Color3.fromRGB(255,222,226)
   unload.Size=if state=="idle" then UDim2.fromScale(1,1) else UDim2.new(.72,-4,1,0)
   unload.Active=state=="idle" or state=="ready"
   unload.Interactable=unload.Active
   unload.AutoButtonColor=unload.Active
   cancel.Visible=state=="waiting" or state=="ready"
   if state=="idle" then unload.Text="Unload AETHER"
   elseif state=="ready" then unload.Text="Confirm unload"
   elseif state=="done" then unload.Text="Unloading..." end
  end
  page:add(function() token+=1;state="closed" end)
  page:on(cancel.Activated,function()
   if state~="waiting" and state~="ready" then return end
   token+=1;state="idle";draw();ui:message("Unload cancelled.")
  end)
  page:on(unload.Activated,function()
   if page.dead or a.stopping then return end
   if state=="ready" then
    token+=1;state="done";draw();a:unload();return
   end
   if state~="idle" then return end
   token+=1
   local current=token
   state="waiting";draw();unload.Text="Confirm in 3 s"
   ui:message("Confirm after the countdown, or cancel.")
   task.spawn(function()
    local deadline=os.clock()+3
    while not page.dead and token==current and state=="waiting" do
     local remaining=deadline-os.clock()
     if remaining<=0 then break end
     unload.Text="Confirm in "..tostring(math.ceil(remaining)).." s"
     task.wait(math.min(.1,remaining))
    end
    if page.dead or token~=current or state~="waiting" or not row.Parent then return end
    state="ready";draw()
   end)
  end)
  draw()
 end
end
return E
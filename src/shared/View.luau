local Input=game:GetService("UserInputService");local Gui=game:GetService("GuiService");local U=require(script.Parent.Util);local VectorCursor=require(script.Parent.VectorCursor)
local V={};V.__index=V
function V.new(player,layer)
 local self=setmetatable({player=player,angle=0,clock=0},V);self.pointer=U.frame(layer,"Pointer",nil,UDim2.fromOffset(32,32),nil,1);self.pointer.Visible=false;self.pointer.Active=false;self.glyph=VectorCursor.new(self.pointer);self.image=U.new("ImageLabel",{Name="Asset",BackgroundTransparency=1,Active=false,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit,ZIndex=10},self.pointer);return self
end
function V:releaseLock()
 if self.mouse then Input.MouseBehavior=self.mouse;self.mouse=nil end;if self.lockHum then if self.lockHum.Parent then self.lockHum.AutoRotate=self.auto end;self.lockHum=nil end
end
function V:releaseCamera()
 self:releaseLock();if self.cam then local c=self.cam;local b=self.before;if c.Parent then c.FieldOfView=b.fov;c.CameraType=b.kind;if b.subject and b.subject.Parent then c.CameraSubject=b.subject end;if b.kind==Enum.CameraType.Scriptable then c.CFrame=b.cf;c.Focus=b.focus end end;self.player.CameraMode=b.mode;self.cam=nil end
 if self.hum then if self.hum.Parent then self.hum.CameraOffset=self.offset end;self.hum=nil end;self.orbitPos=nil
end
function V:preview(host,s)
 if self.previewHost~=host then
  self.glyph:preview(host)
  if self.previewImage then self.previewImage:Destroy();self.previewImage=nil end
  self.previewHost=host
  if host then
   self.previewImage=U.new("ImageLabel",{Name="ImportedCursorPreview",BackgroundTransparency=1,Active=false,Selectable=false,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit},host)
  end
 end
 if self.previewImage then
  local image=s.cursorShape=="Image" and s.image~=""
  self.previewImage.Visible=image
  if image then self.previewImage.Image="rbxassetid://"..s.image end
 end
end
function V:destroy()
 self:releaseCamera()
 if self.icon~=nil then Input.MouseIconEnabled=self.icon;self.icon=nil end
 if self.previewImage then self.previewImage:Destroy();self.previewImage=nil end
 self.glyph:destroy()
 self.pointer:Destroy()
end
-- Keep the real click hotspot and the visual pointer aligned.
-- This function runs in a separate, cheap render callback so complex SVG work
-- and HUD updates cannot defer the position assignment.
function V:cursorStep(s)
 local image=s.cursorShape=="Image"
 local show=s.cursor and Input.MouseEnabled and not Gui.MenuIsOpen
  and (not image or s.image~="") and Input:GetLastInputType()~=Enum.UserInputType.Touch
 if show then
  if self.icon==nil then self.icon=Input.MouseIconEnabled end
  Input.MouseIconEnabled=false
 elseif self.icon~=nil then
  Input.MouseIconEnabled=self.icon;self.icon=nil
 end
 self.pointer.Visible=show
 if not show then return end
 local hx,hy=s.hotX/100,s.hotY/100
 if s.hotX==19 and s.hotY==8 then
  local tip={["Rounded Triangle"]={.188,.094},["Soft Arrow"]={.188,.125},
   Diamond={.5,.0625},Orbit={.5,.0625},Spark={.5,.0625},Chevron={.125,.25}}
  local p=tip[s.cursorShape]
  if p then hx,hy=p[1],p[2] end
 end
 self.pointer.AnchorPoint=Vector2.new(hx,hy)
 self.pointer.Size=UDim2.fromOffset(s.cursorSize,s.cursorSize)
 self.image.Visible=image
 if image then self.image.Image="rbxassetid://"..s.image end
 local pos=Input:GetMouseLocation()
 -- ScreenGui uses IgnoreGuiInset=true / ScreenInsets.None.
 -- GetMouseLocation() is already in that full-screen coordinate system.
 local origin=self.pointer.Parent.AbsolutePosition
 self.pointer.Position=UDim2.fromOffset(pos.X-origin.X,pos.Y-origin.Y)
end
function V:step(s,hum,menu,dt,t)
 local camera=workspace.CurrentCamera;local hrp=hum and hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart");local enabled=s.camera and hrp and hum.Health>0 and camera
 if self.cam and (not enabled or self.cam~=camera or self.hum~=hum) then self:releaseCamera() end
 if enabled then
  if not self.cam then self.cam=camera;self.before={fov=camera.FieldOfView,mode=self.player.CameraMode,kind=camera.CameraType,subject=camera.CameraSubject,cf=camera.CFrame,focus=camera.Focus};self.hum=hum;self.offset=hum.CameraOffset end
  local lock=s.lock and s.cameraMode=="Follow" and not menu and not Gui.MenuIsOpen and Input:GetFocusedTextBox()==nil
  local first=s.cameraMode=="First Person" and not menu;local mode=if first then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic;if self.player.CameraMode~=mode then self.player.CameraMode=mode end
  local k=if s.reduce or s.follow==0 then 1 else 1-math.exp(-dt*1000/s.follow);camera.FieldOfView+=(s.fov-camera.FieldOfView)*k
  local dest=Vector3.new(if lock then s.shoulder/10 else 0,s.cameraHeight/10,0);hum.CameraOffset=hum.CameraOffset:Lerp(dest,k)
  if s.cameraMode=="Orbit" then
   self:releaseLock();camera.CameraType=Enum.CameraType.Scriptable;local center=hrp.Position+Vector3.new(0,1+s.cameraHeight/10,0);self.angle+=if s.reduce then 0 else math.rad(s.orbitSpeed)*dt
   local desired=Vector3.new(math.sin(self.angle)*s.radius,s.radius*.25,math.cos(self.angle)*s.radius);local params=self.ray or RaycastParams.new();self.ray=params;params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={hum.Parent}
   local hit=workspace:Raycast(center,desired,params);local pos=center+desired.Unit*(if hit then math.max(.4,hit.Distance-.28) else desired.Magnitude);self.orbitPos=if hit then pos else (self.orbitPos or pos):Lerp(pos,k);camera.CFrame=CFrame.lookAt(self.orbitPos,center);camera.Focus=CFrame.new(center)
  else
   if camera.CameraType~=Enum.CameraType.Custom then camera.CameraType=Enum.CameraType.Custom end;camera.CameraSubject=hum;self.orbitPos=nil
   if lock then if not self.mouse then self.mouse=Input.MouseBehavior;self.lockHum=hum;self.auto=hum.AutoRotate end;Input.MouseBehavior=Enum.MouseBehavior.LockCenter;hum.AutoRotate=false;local look=camera.CFrame.LookVector*Vector3.new(1,0,1);if look.Magnitude>.01 and not hum.Sit then hrp.CFrame=CFrame.lookAt(hrp.Position,hrp.Position+look) end else self:releaseLock() end
  end
 end
 -- Rasterization and gradient work is independent of pointer position.
 if self.pointer.Visible or self.previewHost then self.glyph:step(s,t) end
 self.settings=s
end
return V
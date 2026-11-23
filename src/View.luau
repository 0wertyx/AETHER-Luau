local Input=game:GetService("UserInputService");local Gui=game:GetService("GuiService");local U=require(script.Parent.Util);local Symbol=require(script.Parent.Symbol)
local V={};V.__index=V
function V.new(player,layer)
 local self=setmetatable({player=player,angle=0,clock=0},V);self.pointer=U.frame(layer,"Pointer",nil,UDim2.fromOffset(32,32),nil,1);self.pointer.Visible=false;self.glyph=Symbol.new(self.pointer,"Rounded Triangle",65);self.image=U.new("ImageLabel",{Name="Asset",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit},self.pointer);return self
end
function V:releaseLock()
 if self.mouse then Input.MouseBehavior=self.mouse;self.mouse=nil end;if self.lockHum then if self.lockHum.Parent then self.lockHum.AutoRotate=self.auto end;self.lockHum=nil end
end
function V:releaseCamera()
 self:releaseLock();if self.cam then local c=self.cam;local b=self.before;if c.Parent then c.FieldOfView=b.fov;c.CameraType=b.kind;if b.subject and b.subject.Parent then c.CameraSubject=b.subject end;if b.kind==Enum.CameraType.Scriptable then c.CFrame=b.cf;c.Focus=b.focus end end;self.player.CameraMode=b.mode;self.cam=nil end
 if self.hum then if self.hum.Parent then self.hum.CameraOffset=self.offset end;self.hum=nil end;self.orbitPos=nil
end
function V:destroy() self:releaseCamera();if self.icon~=nil then Input.MouseIconEnabled=self.icon;self.icon=nil end;self.pointer:Destroy() end
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
 local image=s.cursorShape=="Image";if image then self.image.Image=if s.image~="" then "rbxassetid://"..s.image else "" end
 local show=s.cursor and Input.MouseEnabled and not Gui.MenuIsOpen and (not image or s.image~="" and self.image.IsLoaded) and Input:GetLastInputType()~=Enum.UserInputType.Touch
 if show then if self.icon==nil then self.icon=Input.MouseIconEnabled end;Input.MouseIconEnabled=false elseif self.icon~=nil then Input.MouseIconEnabled=self.icon;self.icon=nil end
 self.pointer.Visible=show;if show then local pos=Input:GetMouseLocation();local layer=self.pointer.Parent;self.pointer.Position=UDim2.fromOffset(pos.X-layer.AbsolutePosition.X,pos.Y-layer.AbsolutePosition.Y);self.pointer.AnchorPoint=Vector2.new(s.hotX/100,s.hotY/100);self.pointer.Size=UDim2.fromOffset(s.cursorSize,s.cursorSize);self.glyph.root.Visible=not image;self.image.Visible=image
  if image then self.image.Image="rbxassetid://"..s.image else self.glyph:shape(s.cursorShape,60);if t>=self.clock or self.settings~=s then self.clock=t+.06;local h=if s.reduce then 0 else t*s.cursorSpeed*.001;self.glyph:paint(if s.cursorRainbow then Color3.fromHSV(h%1,.6,1) else U.hex(s.cursorA),if s.cursorRainbow then Color3.fromHSV((h+.25)%1,.58,1) else U.hex(s.cursorB),s.cursorGlow,8) end end
 end;self.settings=s
end
return V

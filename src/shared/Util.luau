local U={}
function U.new(class,props,parent)
 local obj=Instance.new(class);for k,v in props or {} do obj[k]=v end;obj.Parent=parent;return obj
end
function U.scope()
 local s={items={},dead=false}
 function s:add(v) assert(not self.dead,"Closed scope");table.insert(self.items,v);return v end
 function s:on(signal,fn) return self:add(signal:Connect(fn)) end
 function s:clear() if self.dead then return end;self.dead=true;for i=#self.items,1,-1 do local v=self.items[i];local ok,err=pcall(function() if typeof(v)=="RBXScriptConnection" then v:Disconnect() elseif typeof(v)=="Instance" then v:Destroy() else v() end end);if not ok then warn("AETHER cleanup:",err) end end;table.clear(self.items) end
 return s
end
function U.corner(p,r) return U.new("UICorner",{CornerRadius=UDim.new(0,r or 10)},p) end
function U.stroke(p,c,alpha,width) return U.new("UIStroke",{Color=c,Transparency=alpha or .5,Thickness=width or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
function U.gradient(p,a,b,rot) return U.new("UIGradient",{Color=ColorSequence.new(a,b),Rotation=rot or 25},p) end
function U.frame(p,name,pos,size,color,alpha) return U.new("Frame",{Name=name,Position=pos or UDim2.new(),Size=size or UDim2.fromScale(1,1),BackgroundColor3=color or Color3.fromRGB(22,18,37),BackgroundTransparency=alpha or 0,BorderSizePixel=0},p) end
function U.label(p,text,sz,pos,size) return U.new("TextLabel",{BackgroundTransparency=1,Text=text,Font=Enum.Font.GothamMedium,TextSize=sz,TextColor3=Color3.fromRGB(242,237,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Position=pos or UDim2.new(),Size=size or UDim2.fromScale(1,1)},p) end
function U.button(p,text) local b=U.new("TextButton",{Text=text,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(241,234,255),BackgroundColor3=Color3.fromRGB(52,40,77),BorderSizePixel=0,AutoButtonColor=true},p);U.corner(b,8);return b end
-- Shared original panel components. Runtime attaches actions; HUD preview attaches
-- movement handles to the same components without executing game actions.
function U.topPanel(parent)
 local panel=U.frame(parent,"TopCapsule",nil,UDim2.fromOffset(136,38),Color3.fromRGB(19,16,32),.12)
 panel.AnchorPoint=Vector2.new(.5,0);U.corner(panel,18)
 local rim=U.stroke(panel,Color3.fromRGB(166,138,255),.42)
 panel.BackgroundTransparency=1;rim.Enabled=false
 local label=U.label(panel,"A E T H E R",14,UDim2.fromOffset(4,4),UDim2.new(1,-8,1,-8))
 label.Name="AetherTitle";label.TextXAlignment=Enum.TextXAlignment.Center
 label.Active=false;label.Interactable=false
 return panel,rim,{label}
end
function U.hex(s) return Color3.fromHex(s) end
function U.font(s) local w=Enum.FontWeight[s.weight];if s.fontAsset~="" then return Font.new("rbxassetid://"..s.fontAsset,w) end;local base=Font.fromEnum(Enum.Font[s.font]);return Font.new(base.Family,w,base.Style) end
function U.ease(t,name)
 t=math.clamp(t,0,1)
 if name=="Linear" then return t elseif name=="Sine" then return .5-.5*math.cos(math.pi*t) end
 -- Quintic smootherstep: continuous velocity and acceleration at both endpoints.
 return t*t*t*(t*(t*6-15)+10)
end
function U.approach(current,target,dt,seconds)
 if math.abs(current-target)<.0001 then return target end
 return target+(current-target)*math.exp(-dt/math.max(.001,seconds))
end
-- Horizontal air steering: rotate momentum instead of lerping opposing vectors.
-- No movement input or zero strength leaves the original velocity untouched.
function U.airRedirect(horizontal,input,cap,strength,dt)
 local magnitude=input.Magnitude
 local speed=horizontal.Magnitude
 local response=math.clamp(strength,0,100)/100
 dt=math.clamp(dt,0,.05)
 if magnitude<.01 or cap<=0 or response<=0 or dt<=0 then return horizontal end
 local target=math.atan2(input.Z,input.X)
 local angle=target
 if speed>.05 then
  local current=math.atan2(horizontal.Z,horizontal.X)
  local delta=math.atan2(math.sin(target-current),math.cos(target-current))
  local maxTurn=math.rad(900)*response*dt
  angle=current+math.clamp(delta,-maxTurn,maxTurn)
 end
 -- Keep existing momentum, including speeds above the nominal WalkSpeed.
 -- Steering cannot accelerate past the greater of current speed and WalkSpeed.
 local targetSpeed=math.max(speed,cap*math.min(magnitude,1))
 local nextSpeed=speed+(targetSpeed-speed)*(1-math.exp(-24*response*dt))
 return Vector3.new(math.cos(angle)*nextSpeed,0,math.sin(angle)*nextSpeed)
end
function U.keys(t) local a={};for k in t do table.insert(a,k) end;table.sort(a);return a end
function U.count(t) local n=0;for _ in t do n+=1 end;return n end
return U
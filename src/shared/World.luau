local L=game:GetService("Lighting");local T=game:GetService("TweenService");local U=require(script.Parent.Util)
local W={};W.__index=W
function W.new() return setmetatable({saved={},owned={},tweens={}},W) end
function W:stop()
 for _,tw in self.tweens do tw:Cancel();tw:Destroy() end;table.clear(self.tweens)
end
function W:clear()
 self:stop();for obj,props in self.saved do if obj==L or obj.Parent then for k,v in props do obj[k]=v end end end;table.clear(self.saved)
 for _,obj in self.owned do obj:Destroy() end;table.clear(self.owned);self.atmo=nil;self.key=nil
end
function W:apply(s)
 if not s.ambient then if self.atmo then self:clear() end;return end
 local key=table.concat({s.skyA,s.skyB,s.skyC,s.fog,s.bloom,s.time,s.light,s.saturation,s.blur,s.fade,s.worldContrast,s.worldExposure,s.worldGlare,s.worldRays,s.worldFocus,s.worldFocusDistance,s.worldBloomSize,tostring(s.reduce)},":");if self.key==key then return end;self.key=key;self:stop()
 local function own(class) local o=U.new(class,{Name="Aether"..class},L);table.insert(self.owned,o);return o end
 if not self.atmo then self.atmo=L:FindFirstChildOfClass("Atmosphere") or own("Atmosphere");self.bloom=own("BloomEffect");self.grade=own("ColorCorrectionEffect");self.blur=own("BlurEffect");self.rays=own("SunRaysEffect");self.focus=own("DepthOfFieldEffect") end
 local function set(o,p)
  if not self.saved[o] then self.saved[o]={} end;for k in p do if self.saved[o][k]==nil then self.saved[o][k]=o[k] end end
  if s.reduce or s.fade==0 then for k,v in p do o[k]=v end else local tw=T:Create(o,TweenInfo.new(s.fade/1000,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),p);table.insert(self.tweens,tw);tw:Play() end
 end
 set(L,{Ambient=U.hex(s.skyA),OutdoorAmbient=U.hex(s.skyB),Brightness=s.light/40,ClockTime=s.time/10,ExposureCompensation=s.worldExposure/50});set(self.atmo,{Color=U.hex(s.skyC),Decay=U.hex(s.skyB),Density=s.fog/150,Haze=s.fog/30,Glare=s.worldGlare*.03});set(self.bloom,{Intensity=s.bloom/50,Size=s.worldBloomSize,Threshold=1.2});set(self.grade,{Saturation=s.saturation/100,Contrast=s.worldContrast/100,TintColor=Color3.new(1,1,1):Lerp(U.hex(s.skyC),.13)});set(self.blur,{Size=s.blur});set(self.rays,{Intensity=s.worldRays/100,Spread=.8});set(self.focus,{FarIntensity=s.worldFocus/100,NearIntensity=s.worldFocus*.003,FocusDistance=s.worldFocusDistance,InFocusRadius=25})
end
return W
local U=require(script.Parent.Util);local Symbol=require(script.Parent.Symbol);local Icons=require(script.Parent.Icons)
local H={};H.__index=H
local sizes={hp=Vector2.new(264,94),clock=Vector2.new(116,58),profile=Vector2.new(172,58),dock=Vector2.new(221,49),cross=Vector2.new(18,18)}
local function center(p,t,size) local n=U.label(p,t,size);n.TextXAlignment=Enum.TextXAlignment.Center;return n end
function H.new(scope,parent,preview,go,drag)
 local self=setmetatable({view=parent,preview=preview,widgets={},markers={},extras={},spark={},time=0,phase=0,paintAt=0,last=-1,dockIcons={}},H)
 self.layer=U.frame(parent,"Directions",nil,nil,nil,1);self.layer.ClipsDescendants=true
 for i=1,9 do
  local n=U.frame(parent,"Dust",UDim2.fromScale((i*.617)%1,(i*.349)%1),UDim2.fromOffset(2+i%2,2+i%2),nil,.54)
  U.corner(n,8);self.spark[i]=n
 end
 for _,k in {"hp","clock","profile","dock","cross"} do
  local d=sizes[k]
  local p=U.new("CanvasGroup",{Name=k,BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(d.X,d.Y),BorderSizePixel=0,ZIndex=3},parent)
  local g=U.gradient(p,Color3.fromRGB(53,40,75),Color3.fromRGB(22,21,36))
  U.corner(p,if k=="cross" then 0 else 15)
  local rim=U.stroke(p,Color3.fromRGB(189,156,255),.4,1.15)
  local scale=U.new("UIScale",{},p)
  self.widgets[k]={p=p,g=g,rim=rim,scale=scale}
  if drag then
   p.Active=true
   scope:on(p.InputBegan,function(i) drag(i,k,p,parent) end)
  end
 end
 local hp=self.widgets.hp.p
 self.hpAccent=U.frame(hp,"AccentLine",UDim2.fromOffset(0,0),UDim2.new(1,0,0,3),Color3.fromRGB(188,150,255))
 U.gradient(self.hpAccent,Color3.fromRGB(190,144,255),Color3.fromRGB(111,220,249),0)
 self.heart=Symbol.new(hp,"Heart",50)
 self.heart.root.AnchorPoint=Vector2.new(.5,.5)
 self.heart.root.Position=UDim2.fromOffset(40,44)
 self.heart.root.Size=UDim2.fromOffset(35,35)
 self.hpTitle=U.label(hp,"VITALS  /  HEALTH",10,UDim2.fromOffset(77,14),UDim2.fromOffset(127,17))
 self.hpTitle.TextColor3=Color3.fromRGB(194,177,229)
 self.value=U.label(hp,"— / — HP",20,UDim2.fromOffset(76,35),UDim2.fromOffset(165,27))
 self.stateText=U.label(hp,"READY",10,UDim2.fromOffset(192,14),UDim2.fromOffset(53,17))
 self.stateText.TextXAlignment=Enum.TextXAlignment.Right
 self.track=U.frame(hp,"HealthMeter",UDim2.fromOffset(16,77),UDim2.new(1,-32,0,7),Color3.fromRGB(62,52,86),.06)
 U.corner(self.track,6)
 self.trail=U.frame(self.track,"DamageTrail",nil,UDim2.fromScale(1,1),Color3.fromRGB(245,208,255))
 U.corner(self.trail,6)
 self.fill=U.frame(self.track,"Fill",nil,UDim2.fromScale(1,1),Color3.new(1,1,1))
 U.corner(self.fill,6)
 self.fillG=U.gradient(self.fill,Color3.fromRGB(167,130,249),Color3.fromRGB(241,147,213),0)
 local clock=self.widgets.clock.p
 self.clock=U.label(clock,"--:--",21,UDim2.fromOffset(13,6),UDim2.new(1,-24,0,29))
 self.clockSub=U.label(clock,"AETHER · TIME",9,UDim2.fromOffset(13,34),UDim2.new(1,-23,0,15))
 local profile=self.widgets.profile.p
 self.profileDot=U.frame(profile,"Online",UDim2.fromOffset(13,18),UDim2.fromOffset(7,7),Color3.fromRGB(152,240,210))
 U.corner(self.profileDot,9)
 self.profileTitle=U.label(profile,"PLAYER  /  ONLINE",9,UDim2.fromOffset(28,9),UDim2.new(1,-35,0,18))
 self.name=U.label(profile,"",15,UDim2.fromOffset(14,28),UDim2.new(1,-27,0,22))
 local dock=self.widgets.dock.p
 for i,item in {{"HUD","HUD"},{"FX","Character"},{"ASSETS","Workshop"}} do
  local b=U.button(dock,item[1])
  b.Name="Dock_"..item[2]
  b:SetAttribute("AETHERIconOnly",true)
  b:SetAttribute("AETHERText",item[1])
  b.Size=UDim2.fromOffset(64,35)
  b.Position=UDim2.fromOffset(8+(i-1)*71,7)
  b.TextSize=11
  table.insert(self.dockIcons,Icons.new(b,item[2]))
  scope:on(b.Activated,function() go(item[2]) end)
 end
 local cr=self.widgets.cross.p
 cr.BackgroundTransparency=1
 self.widgets.cross.rim.Enabled=false
 self.reticleRoot=U.frame(cr,"ShiftReticle",UDim2.fromScale(.5,.5),UDim2.fromScale(1,1),nil,1)
 self.reticleRoot.AnchorPoint=Vector2.new(.5,.5);self.reticleRoot.Active=false
 self.reticleEdges={}
 for i=1,48 do
  local edge=U.frame(self.reticleRoot,"Line"..i,nil,UDim2.fromOffset(1,1),Color3.new(1,1,1),0)
  edge.AnchorPoint=Vector2.new(.5,.5);edge.Active=false;edge.Visible=false;U.corner(edge,3);self.reticleEdges[i]=edge
 end
 return self
end
function H:clearMarkers() for _,m in self.markers do m.root:Destroy() end;table.clear(self.markers) end
function H:setStyle(s)
 local factor=if self.preview then math.clamp(self.view.AbsoluteSize.X/850,.43,.74) else math.clamp(self.view.AbsoluteSize.X/770,.66,1)
 self.factor=factor
 local accent=U.hex(s.accent)
 local a,b=U.hex(s.glassColor),Color3.fromRGB(17,16,30)
 local face=U.font(s)
 for k,w in self.widgets do
  local x,y=s[k.."X"]/100,s[k.."Y"]/100
  w.p.AnchorPoint=Vector2.new(x,y)
  w.p.Position=UDim2.fromScale(x,y)
  w.p.Rotation=s[k.."Turn"]
  w.scale.Scale=factor*s[k.."Scale"]/100
  w.p.GroupTransparency=1-s[k.."Alpha"]/100
  w.p.Visible=s[k]
  w.rim.Color=accent
  w.rim.Transparency=1-s.rim/100
  w.g.Color=ColorSequence.new(a,b)
  w.p.BackgroundTransparency=if k=="cross" then 1 else 1-s.glass/100
 end
 self.widgets.hp.p.Size=UDim2.fromOffset(264,if s.compact then 72 else 94)
 self.track.Visible=true
 self.track.Position=UDim2.fromOffset(16,if s.compact then 60 else 77)
 self.reticleKey=nil
 self.hpAccent.BackgroundColor3=accent
 self.profileDot.BackgroundColor3=U.hex(s.secondary)
 for _,icon in self.dockIcons do icon:sync(s.iconAtlas) end
 for _,item in {{self.clock,21},{self.clockSub,9},{self.hpTitle,10},{self.value,19},{self.stateText,10},{self.name,15},{self.profileTitle,9}} do
  local n=item[1]
  n.FontFace=face
  n.TextSize=item[2]*s.fontSize/100
  n.TextColor3=if s.fontGradient then Color3.new(1,1,1) else U.hex(s.fontA)
  n.TextStrokeColor3=U.hex(s.fontB)
  n.TextStrokeTransparency=1-s.fontOutline/100
  local grad=n:FindFirstChildOfClass("UIGradient") or U.gradient(n,accent,b,0)
  grad.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB))
  grad.Enabled=s.fontGradient
 end
 self.settings=s
 self.width=self.view.AbsoluteSize.X
end
function H:reticle(s,f,t)
 local widget=self.widgets.cross
 widget.p.Visible=s.cross and s.lockReticle~="None" and (self.preview or f.shiftLock==true)
 if not widget.p.Visible then return end
 if not self.preview then widget.p.AnchorPoint=Vector2.new(.5,.5);widget.p.Position=UDim2.fromScale(.5,.5);widget.p.Rotation=0 end
 widget.p.Size=UDim2.fromOffset(s.reticleSize,s.reticleSize)
 local style=s.lockReticle
 local key=style..":"..s.reticleSize..":"..s.reticleStroke
 if self.reticleKey~=key then
  self.reticleKey=key
  local used=0
  local function line(x1,y1,x2,y2)
   used+=1
   local edge=self.reticleEdges[used];if not edge then return end
   local dx,dy=x2-x1,y2-y1
   edge.Position=UDim2.fromScale((x1+x2)*.5,(y1+y2)*.5)
   edge.Size=UDim2.new(math.sqrt(dx*dx+dy*dy),0,0,s.reticleStroke)
   edge.Rotation=math.deg(math.atan2(dy,dx));edge.Visible=true
  end
  local function poly(count,r,phase,star)
   for i=0,count-1 do
    local a=phase+i/count*math.pi*2;local b=phase+(i+1)/count*math.pi*2
    local r1=r*(if star and i%2==1 then .44 else 1)
    local r2=r*(if star and (i+1)%2==1 then .44 else 1)
    line(.5+math.cos(a)*r1,.5+math.sin(a)*r1,.5+math.cos(b)*r2,.5+math.sin(b)*r2)
   end
  end
  if style=="Dot" then
   used=1;local d=self.reticleEdges[1];d.Position=UDim2.fromScale(.5,.5);d.Size=UDim2.fromOffset(s.reticleStroke*2,s.reticleStroke*2);d.Rotation=0;d.Visible=true
  elseif style=="Cross" then line(.08,.5,.92,.5);line(.5,.08,.5,.92)
  elseif style=="Split Cross" then for i=0,3 do local a=i*math.pi/2;line(.5+.18*math.cos(a),.5+.18*math.sin(a),.5+.44*math.cos(a),.5+.44*math.sin(a)) end
  elseif style=="Corners" then for _,x in {-1,1} do for _,y in {-1,1} do line(.5+x*.43,.5+y*.43,.5+x*.23,.5+y*.43);line(.5+x*.43,.5+y*.43,.5+x*.43,.5+y*.23) end end
  elseif style=="Diamond" then poly(4,.42,-math.pi/2,false)
  elseif style=="Triangle" then poly(3,.45,-math.pi/2,false)
  elseif style=="Hexagon" then poly(6,.42,0,false)
  elseif style=="Star" then poly(10,.45,-math.pi/2,true)
  elseif style=="Petal" then poly(8,.43,-math.pi/2,true)
  elseif style=="Compass" then poly(4,.43,0,false);poly(4,.22,0,false)
  elseif style=="Double Ring" then poly(24,.44,0,false);poly(20,.25,0,false)
  elseif style=="Orbit" then for i=0,21 do local a=i/24*math.pi*2;local b=(i+1)/24*math.pi*2;line(.5+.40*math.cos(a),.5+.40*math.sin(a),.5+.40*math.cos(b),.5+.40*math.sin(b)) end
  else poly(28,.42,0,false) end
  for i=used+1,#self.reticleEdges do self.reticleEdges[i].Visible=false end
  self.reticleUsed=math.min(used,#self.reticleEdges)
  self.reticlePaint=nil
 end
 local tm=if s.reduce or not s.reticleMotion then 0 else t*s.reticleSpeed/100
 self.reticleRoot.Rotation=if style=="Orbit" or style=="Star" or style=="Petal" or style=="Compass" or style=="Double Ring" then tm*22 else 0
 local col=if s.reticleRainbow then Color3.fromHSV((tm*.12)%1,.55,1) else U.hex(s.reticleColor)
 if self.reticlePaint~=col then
  self.reticlePaint=col
  for i=1,self.reticleUsed do self.reticleEdges[i].BackgroundColor3=col end
 end
end
function H:vitals(s,f,dt)
 local hp,max=f.hp,f.max;local w=self.widgets.hp;w.p.Visible=s.hp and hp~=nil;if hp==nil then self.last=-1;self.phase=0;return end
 local ratio=math.clamp(hp/math.max(.001,max),0,1);local dead=hp<=0;local band=if dead then "DEAD" elseif ratio<=.30 then "CRITICAL" elseif ratio<=.65 then "ALERT" else "CALM"
 if self.last~=hp or self.gen~=f.gen or self.maximum~=max then
  self.effect=if self.gen~=nil and (f.gen~=self.gen or self.last==0 and hp>0) then "Revive" elseif self.last>=0 and hp<self.last then "Damage" elseif self.last>=0 and hp>self.last then "Heal" else "None";self.age=0;self.from=self.shown or hp;self.fromRatio=self.bar or ratio;self.fromTrail=math.max(self.trailRatio or ratio,self.bar or ratio);self.last=hp;self.gen=f.gen;self.maximum=max;w.p:SetAttribute("Effect",self.effect);w.p:SetAttribute("Health",hp);w.p:SetAttribute("MaxHealth",max);w.p:SetAttribute("Life",band)
 end
 self.age+=dt;local dur=s.duration/1000*100/s.speed;local q=if dead or s.reduce then 1 else U.ease(self.age/dur,s.ease);self.shown=self.from+(hp-self.from)*q;self.bar=self.fromRatio+(ratio-self.fromRatio)*q
 self.trailRatio=if self.effect=="Damage" and not s.reduce and not dead then self.fromTrail+(ratio-self.fromTrail)*U.ease((self.age-.20)/dur,s.ease) else self.bar
 self.fill.Size=UDim2.fromScale(self.bar,1);self.trail.Size=UDim2.fromScale(self.trailRatio,1);self.value.Text=string.format("%d / %d HP",math.ceil(self.shown-.00001),math.ceil(max));self.stateText.Text=band
 local a,b;if dead then a,b=Color3.fromRGB(91,85,102),Color3.fromRGB(104,98,115) elseif ratio<=.3 then a,b=Color3.fromRGB(245,46,78),Color3.fromRGB(255,109,169) elseif ratio<=.65 then a,b=Color3.fromRGB(255,225,99),Color3.fromRGB(255,144,60) else a,b=U.hex(s.accent),U.hex(s.secondary) end
 local mix=if s.reduce or dead then 1 else 1-math.exp(-dt*12);self.tint=(self.tint or a):Lerp(a,mix);self.tint2=(self.tint2 or b):Lerp(b,mix);self.fillG.Color=ColorSequence.new(self.tint,self.tint2)
 local beat=0;if not dead and not s.reduce then local period=if ratio<=.3 then .33+.5*ratio elseif ratio<=.65 then .62+.45*ratio else .91+.62*ratio;self.phase=(self.phase+dt*s.speed/100/period)%1;beat=math.max(0,1-math.abs(self.phase-.12)*9)+.6*math.max(0,1-math.abs(self.phase-.31)*13) else self.phase=0 end
 local bump=if not s.reduce and not dead and (self.effect=="Heal" or self.effect=="Revive") then math.sin(math.pi*q)*(if self.effect=="Revive" then .22 else .09) else 0
 local side=30*(1+beat*(.12+.15*(1-ratio))+bump);self.heart.root.Size=UDim2.fromOffset(side,side);self.heart:paint(self.tint,self.tint2,if dead then 0 else math.clamp(s.rim+beat*25,0,100),8);self.heart.root.GroupTransparency=if dead then .55 else 0
 local shake=if not s.reduce and not dead and self.effect=="Damage" and self.age<.28 then math.sin(self.age*100)*3*(1-self.age/.28) else 0;w.p.Position=UDim2.new(s.hpX/100,shake,s.hpY/100,0);w.rim.Color=self.tint;w.rim.Transparency=if dead then .9 else 1-math.min(1,(s.rim+beat*15)/100)
end
function H:marker(id)
 local root=U.frame(self.layer,"Marker_"..id,nil,UDim2.fromOffset(40,40),nil,1);root.AnchorPoint=Vector2.new(.5,.5);local glyph=Symbol.new(root,"Soft Triangle",30)
 local label=U.label(root,"",11,UDim2.new(.5,-65,1,-4),UDim2.fromOffset(130,15));label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeTransparency=.3
 local m={root=root,glyph=glyph,label=label,fade=0};self.markers[id]=m;return m
end
function H:directions(s,f,dt,t,paint)
 self.serial=(self.serial or 0)+1;local view=self.view.AbsoluteSize;local w,h=view.X,view.Y
 if s.indicators and w>0 and h>0 then for _,p in f.targets do if p.visible or p.distance>s.reach then continue end;local id=p.id;local m=self.markers[id] or self:marker(id);m.serial=self.serial;local custom=s.players[id];m.glyph:shape(if custom then custom.shape else s.shape,s.corners)
  local dir=Vector2.new(p.x*w,p.y*h);if dir.Magnitude<.001 then dir=Vector2.yAxis end;dir=dir.Unit;local sz=s.size*self.factor*math.clamp(1.35/(1+p.distance*.002),.65,1.35);local px=math.max(sz*.7,w*s.edge/100);local py=math.max(sz*.7+(if s.labels=="Off" then 0 else 12),h*s.edge/100);local d=math.max(0,math.min((w/2-px)/math.max(.0001,math.abs(dir.X)),(h/2-py)/math.max(.0001,math.abs(dir.Y))));local dest=view*.5+dir*d
  local k=if s.reduce or s.turn==0 then 1 else 1-math.exp(-dt*4500/s.turn);local angle=math.deg(math.atan2(dir.X,-dir.Y));m.pos=(m.pos or dest):Lerp(dest,k);m.angle=m.angle or angle;m.angle+=((angle-m.angle+180)%360-180)*k;m.root.Position=UDim2.fromOffset(m.pos.X,m.pos.Y);m.glyph.root.Rotation=m.angle
  local pulse=if s.pulse and not s.reduce then 1+.075*math.sin(t*4*s.arrowSpeed/100) else 1;m.root.Size=UDim2.fromOffset(sz*pulse,sz*pulse);m.fade=if s.reduce then 1 else math.min(1,m.fade+dt*6)
  if paint or m.style~=s then local time=if s.reduce then 0 else t;local c=if custom then U.hex(custom.color) elseif s.arrowRainbow then Color3.fromHSV((time*.14*s.arrowSpeed/100)%1,.68,1) else U.hex(s.arrowA);local b=if s.arrowRainbow then Color3.fromHSV((time*.14*s.arrowSpeed/100+.29)%1,.62,1) else U.hex(s.arrowB);m.glyph:paint(c,b,s.ink,s.spread);m.label.FontFace=U.font(s);m.style=s end
  local title=if custom and custom.label~="" then custom.label else p.label;local dist=math.round(p.distance).."m";m.label.Visible=s.labels~="Off";m.label.Text=if s.labels=="Both" then title.." · "..math.round(p.distance).." st" elseif s.labels=="Distance" then math.round(p.distance).." st" else title
 end end
 for id,m in self.markers do if m.serial~=self.serial then m.fade=if s.reduce then 0 else math.max(0,m.fade-dt*7) end;if m.fade<=0 then m.root:Destroy();self.markers[id]=nil else local alpha=1-m.fade*s.arrowAlpha/100;m.glyph.root.GroupTransparency=alpha;m.label.TextTransparency=alpha end end
end
function H:step(s,f,dt)
 if self.settings~=s or self.width~=self.view.AbsoluteSize.X then self:setStyle(s) end;self.time+=dt;local t=self.time;local paint=t>=self.paintAt;if paint then self.paintAt=t+.075 end
 self:reticle(s,f,t);self:vitals(s,f,dt);self:directions(s,f,dt,t,paint);self.name.Text=f.name;self.clock.Text=os.date("%H:%M");self.clockSub.Text=f.mode
 if paint then for i,n in self.spark do n.Visible=s.sparkles;if s.sparkles then n.BackgroundColor3=U.hex(s.secondary);n.Position=UDim2.fromScale((i*.617)%1,(i*.349-(if s.reduce then 0 else t*.014))%1) end end end
 for id,n in self.extras do if not f.widgets[id] then n:Destroy();self.extras[id]=nil end end
 for id,w in f.widgets do local n=self.extras[id];if not n then n=U.label(self.view,"",14,nil,UDim2.fromOffset(150,25));n.Name="Cue_"..id;n.ZIndex=4;self.extras[id]=n end;n.Text=w.text;n.FontFace=U.font(s);n.TextColor3=U.hex(s.fontA);n.TextStrokeTransparency=.4;local wave=if s.reduce then 0 else math.sin(t*3);n.Position=UDim2.new(w.x/100,0,w.y/100,if w.animation=="float" then wave*5 else 0);n.TextTransparency=if w.animation=="pulse" then .17+wave*.16 else 0 end
end
return H
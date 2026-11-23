local Input=game:GetService("UserInputService");local Tween=game:GetService("TweenService");local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Icons=require(script.Parent.Icons)
local UI={};UI.__index=UI
local bg=Color3.fromRGB(19,16,32);local dim=Color3.fromRGB(173,163,197);local soft=Color3.fromRGB(43,35,60)
function UI.new(app,gui,scope)
 local self=setmetatable({app=app,gui=gui,scope=scope,syncs={},icons={},tab="Dashboard",opened=true,seq=0},UI)
 self.stage=U.frame(gui,"StudioArea",nil,nil,nil,1);self.panel=U.frame(self.stage,"Studio",nil,nil,bg,.035);self.panel.Active=true;U.corner(self.panel,17);self.outline=U.stroke(self.panel,Color3.fromRGB(159,127,230),.3);U.gradient(self.panel,Color3.new(1,1,1),Color3.fromRGB(192,180,215),82)
 self.header=U.frame(self.panel,"Titlebar",nil,UDim2.new(1,0,0,46),nil,1);self.header.Active=true;self.brand=U.label(self.header,"A E T H E R",18,UDim2.fromOffset(16,2),UDim2.fromOffset(135,40));self.tag=U.label(self.header,"",11,UDim2.fromOffset(147,3),UDim2.new(1,-211,0,40));self.tag.TextColor3=dim
 self.close=U.button(self.header,"×");self.close.Modal=true;self.close.Size=UDim2.fromOffset(33,29);self.close.Position=UDim2.new(1,-43,0,8);scope:on(self.close.Activated,function() self:show(false) end)
 self.reopen=U.button(self.stage,"A  /  STUDIO");self.reopen.Size=UDim2.fromOffset(99,31);self.reopen.Position=UDim2.fromOffset(12,10);self.reopen.Visible=false;scope:on(self.reopen.Activated,function() self:show(true) end)
 self.nav=U.new("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3},self.panel);self.navList=U.new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},self.nav)
 self.pageBox=U.frame(self.panel,"PageArea",nil,nil,nil,1);self.status=U.label(self.panel,"",11,UDim2.new(0,16,1,-28),UDim2.new(1,-32,0,22));self.status.TextColor3=dim
 self.buttons={};for i,name in {"Dashboard","HUD","Character","Wings","Halos","Neon","Ambient","Indicators","Cursor","Camera","Fonts","Simulator","Scripts","Workshop","Profiles","Diagnostics"} do local b=U.button(self.nav,name);b.Name=name;b.LayoutOrder=i;self.buttons[name]=b;self.icons[name]=Icons.new(b,name);scope:on(b.Activated,function() self:open(name) end) end
 function self:layout()
  local sz=self.stage.AbsoluteSize;if sz.X<2 or sz.Y<2 then return end;local w,h=math.min(776,sz.X-16),math.min(526,sz.Y-24);local narrow=w<560;local p=self.panel;p.Size=UDim2.fromOffset(w,h);local xy=self.xy or Vector2.new((sz.X-w)*.5,(sz.Y-h)*.47);self.xy=Vector2.new(math.clamp(xy.X,0,sz.X-w),math.clamp(xy.Y,0,sz.Y-h));p.Position=UDim2.fromOffset(self.xy.X,self.xy.Y)
  self.nav.Position=UDim2.fromOffset(10,49);self.nav.Size=if narrow then UDim2.new(1,-20,0,35) else UDim2.new(0,122,1,-85);self.navList.FillDirection=if narrow then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical;self.nav.AutomaticCanvasSize=if narrow then Enum.AutomaticSize.X else Enum.AutomaticSize.Y;self.nav.ScrollingDirection=if narrow then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y
  for _,b in self.buttons do b.Size=if narrow then UDim2.fromOffset(91,30) else UDim2.new(1,-5,0,32) end;self.pageBox.Position=UDim2.fromOffset(if narrow then 12 else 145,if narrow then 90 else 50);self.pageBox.Size=if narrow then UDim2.new(1,-24,1,-126) else UDim2.new(1,-158,1,-88)
 end
 scope:on(self.stage:GetPropertyChangedSignal("AbsoluteSize"),function() self:layout() end);self:layout()
 scope:on(self.header.InputBegan,function(i) self:begin(i,function(point,start,origin) self.xy=origin+point-start;self:layout() end,self.xy) end)
 scope:on(Input.InputChanged,function(i) local d=self.drag;if d and (i==d.i or d.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement) then d.fn(Vector2.new(i.Position.X,i.Position.Y),d.start,d.origin) end end)
 scope:on(Input.InputEnded,function(i) if self.drag and (self.drag.i==i or self.drag.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseButton1) then self.drag=nil end end)
 scope:on(Input.WindowFocusReleased,function() self.drag=nil end);scope:add(function() if self.page then self.page:clear() end end);return self
end
function UI:begin(i,fn,origin) if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end;local v=Vector2.new(i.Position.X,i.Position.Y);self.drag={i=i,start=v,fn=fn,origin=origin};fn(v,v,origin) end
function UI:show(on) self.opened=on;self.panel.Visible=on;self.reopen.Visible=not on;self.drag=nil;if self.app.onMenu then self.app:onMenu(on) end end
function UI:message(s) self.status.Text=s end
function UI:open(tab)
 if not self.buttons[tab] then return end;self:show(true);self.drag=nil;if self.page then self.page:clear() end;self.app.preview=nil;self.page=U.scope();self.syncs={};self.seq=0;self.tab=tab
 for k,b in self.buttons do b.BackgroundColor3=if k==tab then Color3.fromRGB(93,67,138) else soft end
 local sc=self.page:add(U.new("ScrollingFrame",{Name="Page_"..tab,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=dim,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},self.pageBox));U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sc);self.sc=sc
 self:title(tab:upper().."   /   AETHER STUDIO");self.app:page(tab,self);self:sync()
 if not self.app.s.reduce then local fade=Tween:Create(self.titleLabel,TweenInfo.new(.18),{TextTransparency=0});self.titleLabel.TextTransparency=.6;self.page:add(fade);fade:Play() end
end
function UI:row(h,name) self.seq+=1;local f=U.frame(self.sc,name or "Row",nil,UDim2.new(1,-8,0,h),soft,.47);f.LayoutOrder=self.seq;U.corner(f,8);return f end
function UI:title(str) local f=self:row(26,"Heading");f.BackgroundTransparency=1;local n=U.label(f,str,13);n.TextColor3=U.hex(self.app.s.accent);self.titleLabel=n;return n end
function UI:note(str,h) local f=self:row(h or 36,"Note");f.BackgroundTransparency=1;local l=U.label(f,str,12);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextColor3=dim;l:SetAttribute("AETHERMuted",true);return l end
function UI:watch(fn) table.insert(self.syncs,fn);fn() end
function UI:sync()
 if not self.panel.Parent then return end
 local st=self.app.s
 local primary=U.hex(st.uiFontColor or "F1E6FF")
 local muted=U.hex(st.uiMutedColor or "ADA3C5")
 self.brand.TextColor3=U.hex(st.accent)
 self.outline.Color=self.brand.TextColor3
 self.tag.Text=self.app.mode.."   /   "..self.tab
 self.tag.TextColor3=muted
 self.status.TextColor3=muted
 for _,asset in self.icons do asset:sync(st.iconAtlas) end
 for _,f in self.syncs do f() end
 -- Only recolor editor controls, not HUD/3D previews or their own palette.
 for _,obj in self.panel:GetDescendants() do
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
   if obj==self.brand or obj==self.tag or obj==self.status then continue end
   if obj:GetAttribute("AETHERKeepFontColor") then continue end
   local holder=obj.Parent
   local skip=false
   while holder and holder~=self.panel do
    if holder.Name=="LivePreview" or holder.Name=="RigPreview"
      or holder.Name=="CursorPreview" or holder.Name=="ShapeGallery" then
     skip=true;break
    end
    if S.defs[holder.Name] and S.defs[holder.Name].kind=="color" and obj:IsA("TextLabel") then
     skip=true;break
    end
    holder=holder.Parent
   end
   if skip then continue end
   if obj:IsA("TextLabel") and obj.Parent and obj.Parent.Name=="Heading" then
    obj.TextColor3=U.hex(st.accent)
   elseif obj:GetAttribute("AETHERMuted") then
    obj.TextColor3=muted
   else
    obj.TextColor3=primary
   end
  end
 end
end
function UI:action(fn) local ok,err=pcall(fn);if not ok then self.app:log("Error",tostring(err));self:message(tostring(err):sub(-150)) end end
function UI:chips(items,fn,cols,selected)
 cols=cols or 3;for start=1,#items,cols do local row=self:row(33,"Actions");row.BackgroundTransparency=1;for j=0,math.min(cols-1,#items-start) do local item=items[start+j];local b=U.button(row,item);b.Name=item;b.Size=UDim2.new(1/cols,-4,1,0);b.Position=UDim2.fromScale(j/cols,0);self.page:on(b.Activated,function() self:action(function() fn(item) end) end);if selected then self:watch(function() b.BackgroundColor3=if selected()==item then Color3.fromRGB(98,68,150) else soft end) end end end
end
function UI:box(label,initial,h,commit)
 self:title(label);local r=self:row(h or 34,"Field");local t=U.new("TextBox",{Name=label,Size=UDim2.new(1,-12,1,-4),Position=UDim2.fromOffset(6,2),ClearTextOnFocus=false,MultiLine=(h or 0)>45,TextWrapped=(h or 0)>45,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=if (h or 0)>45 then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,BackgroundTransparency=1,Text=initial or "",PlaceholderText=label,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(232,222,255)},r);if commit then self.page:on(t.FocusLost,function() self:action(function() commit(t.Text) end) end) end;return t
end
function UI:control(k)
 local d=S.defs[k];local app=self.app;local a=d.kind;if a=="players" then return end
 if a=="text" or a=="asset" then local box=self:box(d.label,tostring(app.s[k]),32,function(v) app:set(k,v) end);self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end end);return end
 local row=self:row(if a=="number" then 48 else 34,k);local label=U.label(row,d.label,12,UDim2.fromOffset(9,0),UDim2.new(.57,0,0,30));label.TextColor3=Color3.fromRGB(219,210,234)
 if a=="bool" or a=="choice" then local b=U.button(row,"");b.Name="Value";b.Position=UDim2.new(.58,0,0,3);b.Size=UDim2.new(.42,-6,1,-6);self.page:on(b.Activated,function() if a=="bool" then app:set(k,not app.s[k]) else app:set(k,d.min[(table.find(d.min,app.s[k]) or 0)%#d.min+1]) end end);self:watch(function() b.Text=if a=="bool" then (if app.s[k] then "ON" else "OFF") else tostring(app.s[k]).."  ›";b.BackgroundColor3=if a=="bool" and not app.s[k] then Color3.fromRGB(48,45,59) else Color3.fromRGB(84,61,118) end);return end
 local box=U.new("TextBox",{Name="Value",Position=UDim2.new(.6,0,0,3),Size=UDim2.new(.4,-7,0,23),BackgroundColor3=bg,ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=12,Text="",BorderSizePixel=0},row);U.corner(box,6)
 self.page:on(box.FocusLost,function() self:action(function() app:set(k,if a=="number" then math.clamp(math.round(assert(tonumber(box.Text),"Enter a number")),d.min,d.max) else (box.Text:gsub("^#",""))) end);self:sync() end)
 if a=="color" then self:watch(function() if not box:IsFocused() then box.Text="#"..app.s[k] end;label.TextColor3=U.hex(app.s[k]) end);return end
 local hit=U.new("TextButton",{Name="Slider",Position=UDim2.fromOffset(10,26),Size=UDim2.new(1,-20,0,21),BackgroundTransparency=1,Text="",AutoButtonColor=false},row);local track=U.frame(hit,"Track",UDim2.fromScale(0,.37),UDim2.new(1,0,0,5),bg);U.corner(track,4);local fill=U.frame(track,"Fill",nil,nil,U.hex(app.s.accent));U.corner(fill,4);local dot=U.frame(fill,"Thumb",UDim2.fromScale(1,.5),UDim2.fromOffset(11,11),Color3.fromRGB(237,225,255));dot.AnchorPoint=Vector2.new(.5,.5);U.corner(dot,9)
 self.page:on(hit.InputBegan,function(i) self:begin(i,function(pos) local t=math.clamp((pos.X-hit.AbsolutePosition.X)/math.max(1,hit.AbsoluteSize.X),0,1);app:set(k,math.round(d.min+t*(d.max-d.min))) end) end)
 self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end;fill.Size=UDim2.fromScale((app.s[k]-d.min)/(d.max-d.min),1);fill.BackgroundColor3=U.hex(app.s.accent) end)
end
function UI:group(g,skip) for _,k in S.order do if S.defs[k].group==g and not(skip and skip[k]) then self:control(k) end end end
return UI
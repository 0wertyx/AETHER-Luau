-- Native vector masks. Scan-convert once per silhouette/softness, merge identical runs vertically.
-- No image uploads, EditableImage permissions, or external texture dependencies for built-ins.
local AssetService=game:GetService("AssetService")
local U=require(script.Parent.Util)
local M={};local masks={};local N=64
local paths={
 ["Soft Triangle"]="16,1 30,29 16,22 2,29",Chevron="4,8 6,7 16,15 26,7 28,8 28,14 16,26 4,14",Diamond="16,2 18,4 30,16 18,29 16,30 14,29 2,16",
 ["Neon Pointer"]="16,1 27,30 16,21 5,30|16,8 19,19 13,19",["Double Chevron"]="3,16 16,3 29,16 25,20 16,11 7,20|3,26 16,13 29,26 25,30 16,21 7,30",
 ["Angel Wings"]="1,4 12,10 16,21 20,10 31,4 28,16 23,18 25,20 19,25 16,31 13,25 7,20 9,18 4,16",
 Arrowhead="16,2 30,29 16,22 2,29",["Split Arrow"]="16,2 30,27 18,20 16,30 14,20 2,27",Needle="16,1 22,30 16,23 10,30",["Broad Chevron"]="2,24 16,7 30,24 25,29 16,18 7,29",
 ["Hollow Diamond"]="16,1 31,16 16,31 1,16|16,8 8,16 16,24 24,16",Crystal="16,1 29,14 22,30 10,30 3,14",Spear="16,1 28,29 16,21 4,29|16,8 17,19 15,19",
 ["Twin Wings"]="1,8 13,14 16,28 19,14 31,8 24,26 16,31 8,26",Shield="16,2 29,8 26,23 16,31 6,23 3,8",Beacon="16,1 26,10 26,25 16,31 6,25 6,10",
 ["Star Pointer"]="16,1 21,12 31,16 21,20 16,31 11,20 1,16 11,12",Compass="16,1 20,12 31,16 20,20 16,31 12,20 1,16 12,12|16,12 20,16 16,20 12,16",
 ["Double Spike"]="16,1 28,18 16,14 4,18|16,19 25,31 16,27 7,31",["Arc Pointer"]="2,21 5,15 10,9 16,6 22,9 27,15 30,21 24,26 20,19 16,15 12,19 8,26",Kite="16,1 29,14 16,31 3,14",Crosshair="14,1 18,1 18,12 21,15 31,15 31,18 20,18 18,22 18,31 14,31 14,22 12,18 1,18 1,15 12,15 14,12",
 ["Rounded Triangle"]="8,3 6,5 6,29 8,30 15,22 24,22 26,20",["Soft Arrow"]="6,4 8,4 27,17 28,19 26,21 18,22 13,30 11,28",Spark="16,2 19,12 29,16 29,18 19,21 16,30 13,21 3,18 3,16 13,12",
 Heart="16,29 4,18 1,12 2,7 5,4 10,3 14,5 16,8 19,4 23,3 28,5 31,9 30,15 26,21",
 Studio="16,1 20,12 31,16 20,20 16,31 12,20 1,16 12,12",
}
local function smooth(poly,r)
 if r==0 then return poly end;local out={};for i,p in poly do local a=poly[(i-2)%#poly+1]-p;local b=poly[i%#poly+1]-p
  local s=p+a.Unit*math.min(r,a.Magnitude*.43);local e=p+b.Unit*math.min(r,b.Magnitude*.43)
  for j=0,3 do local t=j/3;table.insert(out,s*(1-t)^2+p*2*t*(1-t)+e*t^2) end
 end;return out
end
local function build(name,round)
 local polys={};for sub in string.gmatch(paths[name] or paths.Diamond,"[^|]+") do local a={};for x,y in sub:gmatch("(%d+),(%d+)") do table.insert(a,Vector2.new(tonumber(x),tonumber(y))) end;table.insert(polys,smooth(a,round*.055)) end
 local rows={};local last={}
 for y=0,N-1 do local yy=(y+.5)*32/N;local inter={};for _,p in polys do for i,a in p do local b=p[i%#p+1];if (a.Y>yy)~=(b.Y>yy) then table.insert(inter,a.X+(yy-a.Y)*(b.X-a.X)/(b.Y-a.Y)) end end end;table.sort(inter)
  local function pixel(x) local xx=(x+.5)*32/N
   if name=="Location Pin" then return ((xx-16)^2+(yy-20)^2<112 or (yy>=2 and yy<21 and math.abs(xx-16)<(yy-1)*.56)) and (xx-16)^2+(yy-20)^2>15 end
   if name=="Orbit Arc" or name=="Orbit" then local d=(xx-16)^2+(yy-17)^2;return (d<186 and d>93 and (yy>=13 or xx<13)) or (yy<13 and math.abs(xx-18)<yy*.55) end
   for i=1,#inter-1,2 do if xx>=inter[i] and xx<inter[i+1] then return true end end;return false end
  local x=0;local nextRow={};while x<N do if not pixel(x) then x+=1;continue end;local l=x;repeat x+=1 until x==N or not pixel(x);local id=l*64+x;local b=last[id];if b then b.h+=1 else b={x=l,y=y,w=x-l,h=1};table.insert(rows,b) end;nextRow[id]=b end;last=nextRow
 end;return rows
end
-- Smooth heart silhouette, with a real 128x128 alpha texture rather than GUI scanline rectangles.
local function heartImage(parent)
 local edit
 local ok,label,gradient=pcall(function()
  local n=128
  edit=AssetService:CreateEditableImage({Size=Vector2.new(n,n)})
  assert(edit,"EditableImage unavailable")
  local data=buffer.create(n*n*4)
  -- Four-by-four coverage sampling of a smooth algebraic heart.
  for y=0,n-1 do
   for x=0,n-1 do
    local hits=0
    for sy=0,3 do
     local py=1.45-(y+(sy+.5)/4)*2.65/n
     for sx=0,3 do
      local px=-1.35+(x+(sx+.5)/4)*2.70/n
      local q=px*px+py*py-1
      if q*q*q-px*px*py*py*py<=0 then hits+=1 end
     end
    end
    if hits>0 then
     local offset=(y*n+x)*4
     buffer.writeu32(data,offset,0x00FFFFFF)
     buffer.writeu8(data,offset+3,math.round(hits*255/16))
    end
   end
  end
  edit:WritePixelsBuffer(Vector2.zero,Vector2.new(n,n),data)
  local image=U.new("ImageLabel",{Name="HeartHD128",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
   Active=false,Selectable=false,Interactable=false,ScaleType=Enum.ScaleType.Fit,
   ImageContent=Content.fromObject(edit),ResampleMode=Enum.ResamplerMode.Default,ZIndex=parent.ZIndex+1},parent)
  local grad=U.new("UIGradient",{Rotation=90},image)
  return image,grad
 end)
 if not ok then if edit then edit:Destroy() end;return nil,nil end
 label.Destroying:Once(function() edit:Destroy() end)
 return label,gradient
end
function M.new(parent,name,round)
 local root=U.new("CanvasGroup",{Name="Glyph",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1)},parent)
 local outer=U.frame(root,"OuterGlow",nil,nil,nil,.89);U.corner(outer,999);local inner=U.frame(root,"InnerGlow",nil,nil,nil,.80);U.corner(inner,999)
 local ink=U.frame(root,"Ink",nil,nil,nil,1);for _,f in {outer,inner,ink} do f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5) end
 local self={root=root,ink=ink,parts={},key=""}
 if name=="Heart" then self.hd,self.hdGradient=heartImage(ink) end
 function self:shape(n,r)
  r=math.round(r/10)*10;local key=n..r;if self.key==key then return end;self.key=key
  if self.hd then
   self.hd.Visible=n=="Heart"
   if n=="Heart" then for _,part in self.parts do part.Visible=false end;self.mask={};self.a=nil;return end
  end
  local mask=masks[key];if not mask then mask=build(n,r);masks[key]=mask end
  for i,rect in mask do local part=self.parts[i] or U.frame(ink,"Run",nil,nil,Color3.new(1,1,1));self.parts[i]=part;part.Position=UDim2.fromScale(rect.x/N,rect.y/N);part.Size=UDim2.fromScale(rect.w/N,rect.h/N);part.Visible=true end
  for i=#mask+1,#self.parts do self.parts[i].Visible=false end;self.mask=mask;self.a=nil
 end
 function self:paint(a,b,glow,spread,middle,angle)
  angle=angle or 90
  if self.a~=a or self.b~=b or self.mid~=middle or self.angle~=angle then
   if self.hdGradient and self.hd.Visible then
    self.hdGradient.Color=if middle then ColorSequence.new({ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(.5,middle),ColorSequenceKeypoint.new(1,b)}) else ColorSequence.new(a,b)
    self.hdGradient.Rotation=angle
   end
   local rad=math.rad(angle);local dx,dy=math.cos(rad),math.sin(rad)
   local span=math.abs(dx)+math.abs(dy)
   for i,rect in self.mask do
    local x=(rect.x+rect.w*.5)/N-.5;local y=(rect.y+rect.h*.5)/N-.5
    local q=math.clamp(.5+(x*dx+y*dy)/math.max(.001,span),0,1)
    self.parts[i].BackgroundColor3=if middle then (if q<.5 then a:Lerp(middle,q*2) else middle:Lerp(b,q*2-1)) else a:Lerp(b,q)
   end
   outer.BackgroundColor3=b;inner.BackgroundColor3=a;self.a=a;self.b=b;self.mid=middle;self.angle=angle
  end
  if self.glow~=glow or self.spread~=spread then outer.BackgroundTransparency=1-glow*.0016;inner.BackgroundTransparency=1-glow*.0024;outer.Visible=glow>0;inner.Visible=glow>0;local k=.69+spread*.016;outer.Size=UDim2.fromScale(k,k);inner.Size=UDim2.fromScale(k*.77,k*.77);ink.Size=if self.hd and self.hd.Visible then UDim2.fromScale(.94,.94) else UDim2.fromScale(.73,.73);self.glow=glow;self.spread=spread end
 end
 self:shape(name,round or 30);self:paint(Color3.fromRGB(185,150,255),Color3.fromRGB(255,165,220),50,8);return self
end
return M
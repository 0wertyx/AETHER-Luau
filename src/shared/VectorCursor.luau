-- AETHER desktop cursor SVG paths, rasterized with antialiasing into EditableImage.
-- Built-in shapes are copied verbatim from Web/dist/cursors.js in AETHER_Build.
-- EditableImage requires Roblox Mesh / Image APIs; Symbol is the safe fallback.
local AssetService=game:GetService("AssetService")
local U=require(script.Parent.Util)
local Symbol=require(script.Parent.Symbol)
local M={}
local RES=128
local paths={
 ["Rounded Triangle"]="M 8 3 Q 6 2 6 6 L 6 29 Q 6 32 9 29 L 15 22 L 24 22 Q 28 22 25 19 Z",
 ["Soft Arrow"]="M 6 4 Q 5 2 9 4 L 27 17 Q 30 19 26 21 L 18 22 L 14 29 Q 12 32 10 28 Z",
 Diamond="M 16 2 Q 17 2 18 4 L 30 16 L 18 29 Q 16 31 14 29 L 2 16 Z",
 Orbit="M 16 2 C 24 2 30 9 30 16 C 30 24 23 30 16 30 C 8 30 2 24 2 16 C 2 9 9 2 16 2 Z M 16 9 L 21 21 L 16 18 L 11 21 Z",
 Spark="M 16 2 Q 18 2 19 12 L 29 16 Q 31 17 29 18 L 19 21 L 16 30 L 13 21 L 3 18 Q 1 17 3 16 L 13 12 Z",
 Chevron="M 4 8 Q 4 5 7 7 L 16 15 L 25 7 Q 28 5 28 8 L 28 14 L 16 26 L 4 14 Z",
}
local palettes={
 Aurora={"B78AFF","FC82D6","7DE3FF"},
 Sunset={"FFBD7D","FF6AAF","C487FF"},
 Ocean={"57E9D6","6CA5FF","B48BFF"},
 Rainbow={"FF6F91","FFD66F","7DF5BC","74AAFF","D68DFF"},
 Mono={"E9DCFF","B18DFF","E9DCFF"},
}
local masks={}
local apiAvailable
local function point(x,y) return Vector2.new(x,y) end
local function cubic(a,b,c,d,t)
 local v=1-t
 return a*(v*v*v)+b*(3*v*v*t)+c*(3*v*t*t)+d*(t*t*t)
end
local function quadratic(a,b,c,t)
 local v=1-t
 return a*(v*v)+b*(2*v*t)+c*(t*t)
end
local function contours(path)
 local tokens={}
 for item in path:gsub("([A-Za-z])"," %1 "):gmatch("%S+") do table.insert(tokens,item) end
 local output,vertices={},{}
 local index=1;local here=point(0,0)
 local function number() local n=tonumber(tokens[index]);assert(n,"Bad SVG cursor path");index+=1;return n end
 local function xy() return point(number(),number()) end
 local function finish()
  if #vertices>=3 then table.insert(output,vertices) end
  vertices={}
 end
 while index<=#tokens do
  local command=tokens[index];index+=1
  if command=="M" then
   finish();here=xy();table.insert(vertices,here)
  elseif command=="L" then
   here=xy();table.insert(vertices,here)
  elseif command=="Q" then
   local control=xy();local ending=xy()
   for i=1,14 do table.insert(vertices,quadratic(here,control,ending,i/14)) end
   here=ending
  elseif command=="C" then
   local first=xy();local second=xy();local ending=xy()
   for i=1,20 do table.insert(vertices,cubic(here,first,second,ending,i/20)) end
   here=ending
  elseif command=="Z" then
   finish()
  else error("Unsupported SVG cursor command: "..command) end
 end
 finish()
 return output
end
local function prepare(name)
 local mask=masks[name];if mask then return mask end
 local curves=contours(paths[name])
 local edges={}
 for _,poly in curves do
  for i,a in poly do
   local b=poly[i%#poly+1]
   if math.abs(a.Y-b.Y)>1e-6 then
    table.insert(edges,{x=a.X,y=a.Y,dx=(b.X-a.X)/(b.Y-a.Y),lo=math.min(a.Y,b.Y),hi=math.max(a.Y,b.Y)})
   end
  end
 end
 local coverage=table.create(RES*RES,0)
 -- Two-by-two subpixel sampling. All subpaths participate in one even-odd fill.
 for subY=0,RES*2-1 do
  local yy=(subY+.5)*16/RES
  local intersections={}
  for _,e in edges do
   if yy>=e.lo and yy<e.hi then table.insert(intersections,e.x+(yy-e.y)*e.dx) end
  end
  table.sort(intersections)
  for j=1,#intersections-1,2 do
   local x0=intersections[j];local x1=intersections[j+1]
   for subX=math.max(0,math.floor(x0*RES/16)),math.min(RES*2-1,math.ceil(x1*RES/16)) do
    local xx=(subX+.5)*16/RES
    if xx>=x0 and xx<x1 then
     local ix=math.floor(subX/2);local iy=math.floor(subY/2)
     local offset=iy*RES+ix+1
     coverage[offset]+=0.25
    end
   end
  end
 end
 -- Separable blur for a subtle premultiplied glow outside the vector edge.
 local horizontal=table.create(RES*RES,0)
 local bloom=table.create(RES*RES,0)
 for y=0,RES-1 do
  for x=0,RES-1 do
   local i=y*RES+x+1
   horizontal[i]=(coverage[y*RES+math.max(0,x-2)+1]+4*coverage[y*RES+math.max(0,x-1)+1]+6*coverage[i]+4*coverage[y*RES+math.min(RES-1,x+1)+1]+coverage[y*RES+math.min(RES-1,x+2)+1])/16
  end
 end
 for y=0,RES-1 do
  for x=0,RES-1 do
   local i=y*RES+x+1
   bloom[i]=(horizontal[math.max(0,y-2)*RES+x+1]+4*horizontal[math.max(0,y-1)*RES+x+1]+6*horizontal[i]+4*horizontal[math.min(RES-1,y+1)*RES+x+1]+horizontal[math.min(RES-1,y+2)*RES+x+1])/16
  end
 end
 mask={coverage=coverage,bloom=bloom};masks[name]=mask;return mask
end
local function colors(s)
 local list=palettes[s.cursorPalette] or {s.cursorA or "B78AFF",s.cursorB or "FC82D6"}
 local rgb={}
 for _,hex in list do
  local c=U.hex(hex)
  table.insert(rgb,{c.R,c.G,c.B})
 end
 return rgb
end
local function render(img,mask,settings,t)
 local data=buffer.create(RES*RES*4)
 local grad=colors(settings)
 local phase=if settings.reduce then 0 else t*math.pi*2/math.max(1,15-(settings.cursorSpeed or 65)*.07)
 local ux=math.cos(phase+math.pi/4);local uy=math.sin(phase+math.pi/4)
 local glow=math.clamp((settings.cursorGlow or 0)/100,0,1)
 for y=0,RES-1 do
  local dy=(y+.5)/RES-.5
  for x=0,RES-1 do
   local i=y*RES+x+1
   local fill=mask.coverage[i];local haze=mask.bloom[i]
   local a=math.clamp(fill+(1-fill)*haze*glow*.5,0,1)
   local p=i*4-4
   if a==0 then
    buffer.writeu32(data,p,0)
   else
    local dx=(x+.5)/RES-.5
    local u=math.clamp(.5+(dx*ux+dy*uy)*.71,0,1)*(#grad-1)
    local left=math.min(#grad-1,math.floor(u)+1)
    local mix=math.clamp(u-(left-1),0,1)
    local c0=grad[left];local c1=grad[left+1]
    for k=0,2 do
     buffer.writeu8(data,p+k,math.clamp(math.round((c0[k+1]*(1-mix)+c1[k+1]*mix)*255),0,255))
    end
    buffer.writeu8(data,p+3,math.round(a*255))
   end
  end
 end
 img:WritePixelsBuffer(Vector2.zero,Vector2.new(RES,RES),data)
end
local function nativeImage(parent,source)
 return U.new("ImageLabel",{
  Name="OriginalSVGCursor",BackgroundTransparency=1,BorderSizePixel=0,
  Active=false,Selectable=false,Size=UDim2.fromScale(1,1),
  ScaleType=Enum.ScaleType.Fit,ImageContent=Content.fromObject(source)
 },parent)
end
function M.new(parent)
 local self={parent=parent,editable=nil,display=nil,oldFallback=nil,previewParent=nil,previewObject=nil,previewFallback=nil,lastKey="",lastTime=-1,mode="fallback"}
 if apiAvailable~=false then
  local ok,img=pcall(function()
   local edit=AssetService:CreateEditableImage({Size=Vector2.new(RES,RES)})
   assert(edit,"EditableImage allocation failed")
   return edit
  end)
  if ok and img then
   local fine,display=pcall(nativeImage,parent,img)
   if fine then self.editable=img;self.display=display;self.mode="vector";apiAvailable=true
   else img:Destroy();apiAvailable=false end
  else apiAvailable=false end
 end
 self.oldFallback=Symbol.new(parent,"Rounded Triangle",60)
 self.oldFallback.root.Size=UDim2.fromScale(1,1)
 self.oldFallback.root.Visible=not self.display
 function self:preview(host)
  if self.previewParent==host and (not host or (self.previewObject and self.previewObject.Parent==host) or (self.previewFallback and self.previewFallback.root.Parent==host)) then return end
  if self.previewObject then self.previewObject:Destroy();self.previewObject=nil end
  if self.previewFallback then self.previewFallback.root:Destroy();self.previewFallback=nil end
  self.previewParent=host
  if not host then return end
  if self.editable then
   local ok,image=pcall(nativeImage,host,self.editable)
   if ok then self.previewObject=image else warn("AETHER preview EditableImage:",image) end
  end
  self.previewFallback=Symbol.new(host,"Rounded Triangle",60)
  self.previewFallback.root.Size=UDim2.fromScale(1,1)
  self.previewFallback.root.Visible=not self.previewObject
 end
 function self:step(s,t)
  if s.cursorShape=="Image" then
   if self.display then self.display.Visible=false end
   if self.oldFallback then self.oldFallback.root.Visible=false end
   if self.previewObject then self.previewObject.Visible=false end
   if self.previewFallback then self.previewFallback.root.Visible=false end
   return
  end
  local original=paths[s.cursorShape]~=nil
  if self.display then self.display.Visible=original end
  if self.oldFallback then self.oldFallback.root.Visible=not (self.display and original) end
  if self.previewObject then self.previewObject.Visible=original end
  if self.previewFallback then self.previewFallback.root.Visible=not (self.previewObject and original) end
  local shape=s.cursorShape
  local key=table.concat({shape,s.cursorPalette or "",s.cursorA or "",s.cursorB or "",s.cursorGlow or 0,s.reduce and 1 or 0},":")
  if self.editable and original then
   if key~=self.lastKey or (not s.reduce and t-self.lastTime>=.12) then
    self.lastKey=key;self.lastTime=t
    local mask=prepare(shape)
    local ok,err=pcall(render,self.editable,mask,s,t)
    if not ok then
     warn("AETHER SVG rasterizer:",err)
     if self.display then self.display:Destroy();self.display=nil end
     if self.previewObject then self.previewObject:Destroy();self.previewObject=nil end
     if self.editable then self.editable:Destroy();self.editable=nil end
     self.mode="fallback"
     self.oldFallback.root.Visible=true
     if self.previewFallback then self.previewFallback.root.Visible=true end
    end
   end
  end
  if not original or not self.editable then
   local p=palettes[s.cursorPalette] or {s.cursorA or "B78AFF",s.cursorB or "FC82D6"}
   local a=U.hex(p[1]);local b=U.hex(p[2])
   self.oldFallback:shape(shape,60)
   self.oldFallback:paint(a,b,s.cursorGlow,6)
   if self.previewFallback then
    self.previewFallback:shape(shape,60)
    self.previewFallback:paint(a,b,s.cursorGlow,6)
   end
  end
 end
 function self:destroy()
  self:preview(nil)
  if self.display then self.display:Destroy() end
  if self.oldFallback then self.oldFallback.root:Destroy() end
  if self.editable then self.editable:Destroy() end
 end
 return self
end
return M

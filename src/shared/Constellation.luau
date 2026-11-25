-- Decorative menu-only background. No external assets or services.
local U=require(script.Parent.Util)
local Input=game:GetService("UserInputService")
local Shapes=require(script.Parent.FxShapes)
local FX={};FX.__index=FX
local MAX_LINKS=100
local MAX_NODES=24
local RNG=Random.new()
local kinds=Shapes.names
local aliases={Squares="Rounded Square",Crystals="Diamond",Triangles="Rounded Triangle",Hexagons="Rounded Hexagon",Stars="Rounded Star",Dots="Circle"}

local function frame(parent,name)
 local f=U.frame(parent,name,nil,UDim2.fromOffset(1,1),Color3.new(1,1,1),1)
 f.AnchorPoint=Vector2.new(.5,.5);f.Active=false;f.Interactable=false;f.Visible=false
 return f
end
local function segment(f,a,b,width)
 local d=b-a
 f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
 f.Size=UDim2.fromOffset(d.Magnitude,width)
 f.Rotation=math.deg(math.atan2(d.Y,d.X))
end
function FX.new(parent)
 parent.Interactable=false
 local links=U.frame(parent,"Connections",nil,nil,nil,1)
 links.Active=false;links.Interactable=false
 local nodes=U.frame(parent,"Figures",nil,nil,nil,1)
 nodes.Active=false;nodes.Interactable=false
 return setmetatable({parent=parent,linkLayer=links,nodeLayer=nodes,nodes={},links={},w=0,h=0},FX)
end
function FX:addNode(w,h)
 local root=frame(self.nodeLayer,"Figure")
 root.BackgroundTransparency=1
 local a=RNG:NextNumber(0,math.pi*2)
 local speed=RNG:NextNumber(10,27)
 local n={root=root,x=RNG:NextNumber(0,w),y=RNG:NextNumber(0,h),vx=math.cos(a)*speed,vy=math.sin(a)*speed,t=RNG:NextNumber(),scale=RNG:NextNumber(.7,1.25),kind=kinds[RNG:NextInteger(1,#kinds)],edges={},key=nil}
 self.nodes[#self.nodes+1]=n
 return n
end
function FX:addLink()
 local f=frame(self.linkLayer,"Connection")
 local g=U.gradient(f,Color3.new(1,1,1),Color3.new(1,1,1),0)
 local l={frame=f,gradient=g}
 self.links[#self.links+1]=l
 return l
end
local function drawNode(n,kind,r,color,opacity)
 local root=n.root
 local key=kind..":"..tostring(r)..":"..color:ToHex()..":"..tostring(opacity)
 if n.key==key then return end
 n.key=key
 root.Size=UDim2.fromOffset(r*2,r*2)
 root.Rotation=0
 root.BackgroundTransparency=1
 local rim=root:FindFirstChildOfClass("UIStroke")
 if not rim then rim=Instance.new("UIStroke");rim.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;rim.Parent=root end
 local ring=kind=="Rings"
 rim.Enabled=ring;rim.Color=color;rim.Transparency=1-opacity;rim.Thickness=1
 local corner=root:FindFirstChildOfClass("UICorner")
 if not corner then corner=U.corner(root,0) end
 corner.CornerRadius=if ring then UDim.new(.5,0) else UDim.new(0,0)
 local spans=if ring then {} else Shapes.spans(aliases[kind] or kind)
 for j,p in spans do
  local e=n.edges[j]
  if not e then e=frame(root,"Fill");e.AnchorPoint=Vector2.zero;n.edges[j]=e end
  e.Position=UDim2.fromScale(p.x,p.y)
  e.Size=UDim2.fromScale(p.w,p.h)
  e.BackgroundColor3=color;e.BackgroundTransparency=1-opacity;e.Visible=true
 end
 for j=#spans+1,#n.edges do n.edges[j].Visible=false end
end
function FX:step(dt,s)
 -- Called once per Roblox RenderStepped via Controls:animateBackground.
 -- Integrate movement using frame delta; do not impose an independent FPS cap.
 local step=math.clamp(dt,0,.1)
 local size=self.parent.AbsoluteSize
 local w,h=size.X,size.Y
 if w<2 or h<2 then return end
 if self.w>0 and self.h>0 and (w~=self.w or h~=self.h) then
  for _,n in self.nodes do n.x=n.x*w/self.w;n.y=n.y*h/self.h end
 end
 self.w=w;self.h=h
 local mobile=Input.TouchEnabled and not Input.KeyboardEnabled
 local count=math.clamp(math.floor(s.menuDensity),0,if mobile then 16 else MAX_NODES)
 local cap=math.clamp(math.floor(s.constellationLinks),0,MAX_LINKS)
 local radius=s.constellationDistance
 local opacity=s.menuOpacity/100
 local speed=if s.reduce then 0 else s.menuMotion/100
 local na,nb=U.hex(s.constellationNodeA),U.hex(s.constellationNodeB)
 local la,lb=U.hex(s.constellationLineA),U.hex(s.constellationLineB)
 while #self.nodes<count do self:addNode(w,h) end
 for i,n in self.nodes do
  n.root.Visible=i<=count
  if i>count then continue end
  n.x+=n.vx*step*speed;n.y+=n.vy*step*speed
  if n.x<0 or n.x>w then n.x=math.clamp(n.x,0,w);n.vx=-n.vx end
  if n.y<0 or n.y>h then n.y=math.clamp(n.y,0,h);n.vy=-n.vy end
  n.root.Position=UDim2.fromOffset(n.x,n.y)
  drawNode(n,if s.menuShape=="Mixed" then n.kind else s.menuShape,s.constellationSize*n.scale,na:Lerp(nb,n.t),opacity)
 end
 local pairs={}
 if cap>0 and opacity>0 then
  for i=1,count-1 do
   local a=self.nodes[i]
   for j=i+1,count do
    local b=self.nodes[j];local x,y=b.x-a.x,b.y-a.y;local d=x*x+y*y
    if d<radius*radius and d>.01 then pairs[#pairs+1]={i=i,j=j,d=d} end
   end
  end
 end
 table.sort(pairs,function(a,b) if a.d==b.d then if a.i==b.i then return a.j<b.j end;return a.i<b.i end;return a.d<b.d end)
 local used=math.min(#pairs,cap)
 for k=1,used do
  local pair=pairs[k];local a,b=self.nodes[pair.i],self.nodes[pair.j]
  local line=self.links[k] or self:addLink()
  local f=line.frame
  segment(f,Vector2.new(a.x,a.y),Vector2.new(b.x,b.y),s.constellationThickness/10)
  f.BackgroundTransparency=1-opacity*(1-math.sqrt(pair.d)/radius)
  line.gradient.Color=ColorSequence.new(la:Lerp(lb,a.t),la:Lerp(lb,b.t))
  f.Visible=true
 end
 for k=used+1,#self.links do self.links[k].frame.Visible=false end
end
return FX

-- Included only in the example place. Its beacons/players are explicitly opted in by the experience.
local Players=game:GetService("Players");local Tags=game:GetService("CollectionService")
local folder=Instance.new("Folder");folder.Name="AetherAtrium";folder.Parent=workspace
local function part(name,size,pos,color,material,solid)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos;p.Color=Color3.fromHex(color);p.Material=material;p.CanCollide=solid==true;p.CanTouch=false;p.CastShadow=solid==true;p.Parent=folder;return p
end
local ground=part("Studio floor",Vector3.new(176,1,176),Vector3.new(0,-.55,0),"232033",Enum.Material.Slate,true)
for i=-4,4 do part("Inlay",Vector3.new(.07,.03,174),Vector3.new(i*18,-.026,0),"61597E",Enum.Material.Neon);part("Inlay",Vector3.new(174,.03,.07),Vector3.new(0,-.026,i*18),"504C70",Enum.Material.Neon) end
for _,v in {{"Aurora",60,18,"73CFE9"},{"Nebula",-58,-28,"BE91FF"},{"Solstice",-14,64,"FFACCA"}} do
 part("Plinth",Vector3.new(6,2,6),Vector3.new(v[2],1,v[3]),"383044",Enum.Material.SmoothPlastic,true)
 local gem=part(v[1],Vector3.new(2.8,2.8,2.8),Vector3.new(v[2],5,v[3]),v[4],Enum.Material.Neon);gem.Orientation=Vector3.new(45,25,45);Tags:AddTag(gem,"AetherBeacon");local l=Instance.new("PointLight");l.Brightness=1;l.Range=16;l.Color=gem.Color;l.Parent=gem
end
local function join(p) p:SetAttribute("AetherShareBearing",true) end
Players.PlayerAdded:Connect(join);for _,p in Players:GetPlayers() do join(p) end

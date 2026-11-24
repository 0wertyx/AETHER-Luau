-- Shared, data-only contract. All settings/banks contain JSON primitives, not Instances.
local S = {version = 1, defs = {}, order = {}, kinds = {"Theme","HUD","Motion","Character","Wings","Halos","Neon","Ambient","Indicators","Cursor","Camera","Fonts","Scripts"}}
S.shapes = {"Soft Triangle","Chevron","Diamond","Neon Pointer","Double Chevron","Angel Wings","Orbit Arc","Location Pin","Arrowhead","Split Arrow","Needle","Broad Chevron","Hollow Diamond","Crystal","Spear","Twin Wings","Shield","Beacon","Star Pointer","Compass","Double Spike","Arc Pointer","Kite","Crosshair"}
S.fonts = {"Gotham","Code","RobotoMono","Ubuntu","Nunito","GothamMedium","SciFi","Arcade","FredokaOne","Oswald","TitilliumWeb","SourceSans","Highway","Fantasy","Garamond","Bodoni","Bangers","Cartoon","Kalam","Roboto","Sarpanch"}
-- name, high sky, horizon, low light, fog %, bloom %, clock (tenths of an hour), brightness %, saturation.
S.skies = {
 {"Dreamcore","282057","8C70C2","EAB6CD",35,40,166,105,9},{"Cyberpunk","090B2A","741CA4","F032A9",26,80,210,92,42},
 {"Anime","70AFE5","C8A4E8","FFE0AD",16,34,141,118,18},{"Midnight","060A1D","1A2455","403D75",20,18,8,65,-22},
 {"Aurora","091E33","2B6B86","A56ACC",24,48,30,91,25},{"Sunset","563857","DC7165","FFC888",42,60,178,108,23},
 {"Nebula","151137","6143A0","C882CB",56,65,225,87,34},{"Moonlight","080F35","526493","D1DEED",34,52,24,79,-24},
 {"Anime Sunset","5269B9","EAA6AE","FFE1A1",25,43,174,106,12},{"Vaporwave","281858","D258B0","F2A8C6",37,57,189,95,32},
 {"Golden Hour","2E254D","D8798A","FFCE7E",38,52,171,107,8},{"Ocean Night","061A30","124969","52B4BC",28,30,34,73,-4},
 {"Sakura","5B3B83","C18EC4","FFCEE4",32,48,145,108,5},{"Eclipse","090914","393251","B187A5",23,61,120,64,-24},
 {"Neon Rain","070F25","2646A5","BC4CF3",57,70,201,82,28},{"Twilight","151A49","74539C","E1A6BD",34,35,185,88,-10},
}
local function def(g,k,title,kind,value,lo,hi)
 S.defs[k]={group=g,label=title,kind=kind,default=value,min=lo,max=hi}; table.insert(S.order,k)
end
local function toggle(g,k,t,v) def(g,k,t,"bool",v) end
local function range(g,k,t,v,a,b) def(g,k,t,"number",v,a,b) end
local function choice(g,k,t,v,opts) def(g,k,t,"choice",v,opts) end
local function color(g,k,t,v) def(g,k,t,"color",v) end
local function text(g,k,t,v,n) def(g,k,t,"text",v,0,n) end
color("Theme","accent","Accent","A68AFF");color("Theme","secondary","Second neon","FF89C7");color("Theme","glassColor","Glass tint","211C35");color("Theme","uiFontColor","Studio text color","F1E6FF");color("Theme","uiMutedColor","Studio secondary text","ADA3C5");def("Theme","iconAtlas","AETHER icon atlas Roblox asset ID","asset","")
range("Theme","glass","Glass opacity %",81,10,100);range("Theme","rim","Neon rim %",55,0,100);toggle("Theme","sparkles","Floating sparkles",true)
toggle("Motion","reduce","Reduce motion",false);range("Motion","speed","Animation speed %",100,40,200);range("Motion","duration","Transition (ms)",300,80,1400);choice("Motion","ease","Interpolation","Smooth",{"Smooth","Linear","Sine"})
toggle("HUD","locked","Lock widget positions",true);toggle("HUD","compact","Compact health panel",false)
for _,row in {{"hp","Health",82,13},{"clock","Clock",3,93},{"profile","Player card",96,94},{"dock","Studio dock",48,95},{"cross","Reticle",50,50}} do
 local k,t=row[1],row[2];toggle("HUD",k,t,true); range("HUD",k.."X",t.." · horizontal %",row[3],0,100);range("HUD",k.."Y",t.." · vertical %",row[4],0,100)
 range("HUD",k.."Scale",t.." · scale %",100,50,160);range("HUD",k.."Turn",t.." · rotation",0,-180,180);range("HUD",k.."Alpha",t.." · opacity %",100,10,100)
end
toggle("Character","walkAnimation","Custom walking animation",false);choice("Character","walkStyle","Walking style","Natural",{"Natural","Heroic","Floating","Bouncy","Glide","Ethereal","Toy","Robot","Ninja","Bubbly","Stylish","Mage","Levitation","Oldschool","Vampire","Astronaut","Zombie","Cartoony",
 "Angel Glide","Bat Swoop","Mermaid Drift","Serpent Slither","Cartwheel Flow","Rubberhose","Dream Sleep","Plushie","Cat Paws","Shy Kawaii","Gymnast","Skip Hop","Reindeer Prance","Fighter","Harpy Glide","Godly Aura","Wavy Expressive","Retro Zombie","Tsundere","Doll Walk","Skater","Little Duck","Floating Head","Dark Aura","Anime Hero","Headless Float"});range("Character","walkIntensity","Walking intensity %",65,0,100);toggle("Character","aura","Aura particles",false);toggle("Character","trail","Motion trail",false);range("Character","auraRate","Emission / second",12,1,45);range("Character","trailLife","Trail lifetime (ms)",400,80,1300);color("Character","auraColor","Aura color","C4A3FF")
toggle("Wings","wings","Show wings",false);choice("Wings","wingStyle","Silhouette","Seraph",{"Seraph","Blade","Sylph","Phoenix","Frost","Butterfly","Raven","Celestial","Crystal","Dusk","Petal","Storm","Royal","Eclipse"});range("Wings","wingSpan","Span %",100,50,175);range("Wings","wingSweep","Sweep (degrees)",24,-25,65);range("Wings","wingBeat","Flap speed %",90,0,200);color("Wings","wingColor","Feather color","B49BFF");toggle("Wings","wingRainbow","Prismatic feathers",false);choice("Wings","wingDetail","Feather detail","High",{"Balanced","High","Ultra"});toggle("Wings","wingWalk","Walking wing reaction",true)
toggle("Halos","halo","Show halo",false);choice("Halos","haloStyle","Orbit form","Ring",{"Ring","Binary","Crown","Double Ring","Spiral","Starfall","Solar","Lunar","Orbitals","Thorns","Prism","Eclipse","Comet","Lotus"});range("Halos","haloRadius","Radius %",88,45,175);range("Halos","haloHeight","Height above head %",105,55,220);range("Halos","haloSpin","Orbit speed %",75,0,200);color("Halos","haloColor","Halo color","FFB4D6");toggle("Halos","haloRainbow","Prismatic halo",false);choice("Halos","haloDetail","Halo geometry detail","High",{"Balanced","High","Ultra"});toggle("Halos","haloWalk","Walking halo reaction",true)
toggle("Neon","neon","Character outline",true);range("Neon","neonFill","Body tint %",10,0,65);range("Neon","neonLight","Light intensity %",40,0,100);color("Neon","neonColor","Neon color","AB87FF");toggle("Neon","neonRainbow","Rainbow neon",false)
toggle("Ambient","ambient","Apply local atmosphere",false);color("Ambient","skyA","High sky","282057");color("Ambient","skyB","Horizon","8C70C2");color("Ambient","skyC","Ground light","EAB6CD");range("Ambient","fog","Fog density %",35,0,90);range("Ambient","bloom","Bloom %",40,0,100);range("Ambient","time","Time (tenths of an hour)",166,0,239);range("Ambient","light","Brightness %",105,25,180);range("Ambient","saturation","Saturation %",9,-85,85);range("Ambient","blur","Depth blur",0,0,16);range("Ambient","fade","Atmosphere fade (ms)",700,0,3500)
toggle("Indicators","indicators","Directional indicators",true);choice("Indicators","shape","Indicator shape","Soft Triangle",S.shapes);range("Indicators","size","Size (px)",31,14,72);range("Indicators","corners","Corner softness %",30,0,100);range("Indicators","edge","Distance from edges %",11,4,30);range("Indicators","turn","Rotation smoothing (ms)",180,0,800);range("Indicators","ink","Neon intensity %",60,0,100);range("Indicators","spread","Neon spread (px)",6,0,18);range("Indicators","arrowAlpha","Opacity %",95,10,100);range("Indicators","arrowSpeed","Animation speed %",100,40,220);color("Indicators","arrowA","Gradient start","BFA2FF");color("Indicators","arrowB","Gradient end","FF9ECE");toggle("Indicators","arrowRainbow","Rainbow gradient",false);toggle("Indicators","pulse","Pulsation",true);choice("Indicators","labels","Arrow labels","Both",{"Off","Name","Distance","Both"});toggle("Indicators","nearby","Nearby nameplates",false);range("Indicators","reach","Tracking range (studs)",800,50,2500)
toggle("Cursor","cursor","Custom game pointer",false);choice("Cursor","cursorShape","Pointer shape","Rounded Triangle",{"Rounded Triangle","Soft Arrow","Diamond","Orbit","Spark","Chevron","Neon Pointer","Arrowhead","Split Arrow","Needle","Crystal","Spear","Star Pointer","Compass","Crosshair","Heart","Image"});range("Cursor","cursorSize","Pointer size",30,12,72);range("Cursor","cursorGlow","Pointer glow %",55,0,100);choice("Cursor","cursorPalette","Desktop AETHER palette","Aurora",{"Aurora","Sunset","Ocean","Rainbow","Mono","Custom"});range("Cursor","hotX","Hotspot X %",19,0,100);range("Cursor","hotY","Hotspot Y %",8,0,100);color("Cursor","cursorA","Gradient start","BA99FF");color("Cursor","cursorB","Gradient end","69D9FA");toggle("Cursor","cursorRainbow","Rainbow pointer",true);range("Cursor","cursorSpeed","Gradient speed %",65,10,200);choice("Cursor","cursorAnimation","Cursor animation","Sway",{"Off","Breathe","Sway","Spin","Pulse"});range("Cursor","cursorMotionSpeed","Animation speed %",100,20,200);toggle("Cursor","cursorTrail","Soft cursor trail",false);range("Cursor","cursorOffsetX","Pointer offset X (px)",0,-120,120);range("Cursor","cursorOffsetY","Pointer offset Y (px)",0,-120,120);toggle("Cursor","cursorDebug","Show hotspot marker",false);def("Cursor","image","Roblox image asset ID","asset","")
toggle("Camera","camera","Enable camera settings",false);choice("Camera","cameraMode","Camera mode","Follow",{"Follow","First Person","Orbit"});range("Camera","fov","Field of view",70,40,105);range("Camera","shoulder","Shoulder offset (tenths)",16,-35,35);range("Camera","cameraHeight","Height offset (tenths)",2,-10,35);range("Camera","radius","Orbit radius (studs)",9,4,24);range("Camera","orbitSpeed","Orbit rate (degrees/s)",18,-65,65);range("Camera","follow","Follow smoothing (ms)",140,0,750);toggle("Camera","lock","Shift-lock · LeftAlt",false)
choice("Fonts","font","Typeface","Gotham",S.fonts);choice("Fonts","weight","Weight","Bold",{"Regular","Medium","Bold","Heavy"});def("Fonts","fontAsset","Optional Roblox font family ID","asset","");text("Fonts","sample","Preview text","AETHER · Your interface",96);range("Fonts","fontSize","HUD type scale %",100,70,145);toggle("Fonts","fontGradient","Gradient lettering",true);range("Fonts","fontOutline","Text outline %",24,0,100);range("Fonts","fontGlow","Letter glow %",35,0,100);color("Fonts","fontA","Letter color","F1E6FF");color("Fonts","fontB","Letter gradient","CCA4FF")
S.example='hud.widget("status", "Ready", 8, 38)\nfunction onHealthChanged(hp, maxHP)\n  hud.widget("status", hud.join("HP: ", hp), 8, 38)\n  if hp > 0 and hp <= maxHP * 0.3 then\n    hud.animate("status", "pulse")\n  else\n    hud.animate("status", "none")\n  end\nend'
text("Scripts","cue","HUD script",S.example,8192);text("Scripts","luau","Luau draft",'-- ModuleScript for your own place\nreturn function(humanoid: Humanoid)\n  return humanoid.HealthChanged:Connect(function(hp)\n    print(hp, humanoid.MaxHealth)\n  end)\nend',8192)
S.defs.players={group="Indicators",kind="players",default={}};table.insert(S.order,"players")
function S.copy(v) if type(v)~="table" then return v end;local r={};for k,x in v do r[k]=S.copy(x) end;return r end
local function str(s,n) return type(s)=="string" and #s<=n and utf8.len(s)~=nil end
local function name(s) return str(s,48) and s:match("%S") and not s:find("%c") end
local function hex(s) return type(s)=="string" and #s==6 and s:match("^%x+$")~=nil end
function S.value(k,v)
 local d=S.defs[k];if not d then error("Unknown setting: "..tostring(k),0) end
 local a=d.kind
 if a=="bool" and type(v)=="boolean" then return v end
 if a=="number" and type(v)=="number" and v==math.floor(v) and v>=d.min and v<=d.max then return v end
 if a=="choice" and table.find(d.min,v) then return v end
 if a=="color" and hex(v) then return string.upper(v) end
 if a=="text" and str(v,d.max) then return v end
 if a=="asset" and str(v,16) and (v=="" or v:match("^[1-9]%d*$")) then return v end
 if a=="players" and type(v)=="table" then local r,n={},0;for id,o in v do
   n+=1;assert(n<=16 and str(id,18) and id:match("^%-?%d+$") and type(o)=="table" and str(o.label,32) and hex(o.color) and table.find(S.shapes,o.shape),"Invalid player override");r[id]={label=o.label,color=o.color,shape=o.shape}
  end;return r end
 error("Invalid value: "..k,0)
end
function S.defaults() local r={};for k,d in S.defs do r[k]=S.copy(d.default) end;return r end
function S.settings(v,group)
 assert(type(v)=="table","Expected settings");local r=if group then {} else S.defaults();local count=0
 for k,x in v do local d=S.defs[k];assert(d and (not group or d.group==group),"Unexpected setting");r[k]=S.value(k,x);count+=1 end
 if group then assert(count>0,"Empty asset") end;return r
end
function S.capture(settings,group) local r={};for k,d in S.defs do if d.group==group then r[k]=S.copy(settings[k]) end end;return r end
function S.asset(v) assert(type(v)=="table" and v.version==1 and name(v.name) and table.find(S.kinds,v.kind),"Invalid AETHER asset");return {version=1,name=v.name,kind=v.kind,data=S.settings(v.data,v.kind)} end
function S.blank() return {version=1,settings=S.defaults(),profiles={},assets={}} end
function S.bank(v)
 assert(type(v)=="table" and v.version==1,"Unsupported bank version");local r=S.blank();r.settings=S.settings(v.settings)
 local n=0;assert(type(v.profiles)=="table" and type(v.assets)=="table","Invalid library");for k,x in v.profiles do n+=1;assert(n<=10 and name(k),"Invalid profile name/count");r.profiles[k]=S.settings(x) end
 n=0;for k,x in v.assets do n+=1;assert(n<=40 and name(k),"Invalid asset name/count");r.assets[k]=S.asset(x);assert(k==r.assets[k].name,"Asset name mismatch") end;return r
end
function S.sky(row) return {ambient=true,skyA=row[2],skyB=row[3],skyC=row[4],fog=row[5],bloom=row[6],time=row[7],light=row[8],saturation=row[9]} end
S.presets={Theme={Violet={accent="A68AFF",secondary="FF89C7",glassColor="211C35"},Ocean={accent="68CEF4",secondary="9B91FF",glassColor="112636"},Rose={accent="F699C6",secondary="D8A5FF",glassColor="301B31"}},HUD={Classic={hpX=82,hpY=13,clockX=3,clockY=93,compact=false},Broadcast={hpX=3,hpY=78,clockX=95,clockY=5,hpScale=115},Compact={compact=true,hpX=96,hpY=16,hpScale=80}},Motion={Calm={speed=70,duration=520},Swift={speed=155,duration=150},Still={reduce=true}},Wings={Seraph={wings=true,wingStyle="Seraph",wingSpan=115},Blade={wings=true,wingStyle="Blade",wingColor="76E3FF"},Sylph={wings=true,wingStyle="Sylph",wingRainbow=true}},Halos={Crown={halo=true,haloStyle="Crown"},Binary={halo=true,haloStyle="Binary",haloColor="82D9FF"}},Character={Comet={aura=true,trail=true,auraColor="AA89FE"}},Neon={Pulse={neon=true,neonRainbow=true,neonLight=65}},Cursor={Aurora={cursor=true,cursorShape="Rounded Triangle",cursorRainbow=true},Diamond={cursor=true,cursorShape="Diamond",hotX=50,hotY=50}},Camera={Portrait={camera=true,cameraMode="Orbit",fov=55,radius=8,lock=false},Shoulder={camera=true,cameraMode="Follow",lock=true}},Fonts={Terminal={font="Code",weight="Bold",fontAsset="",fontGradient=false},Soft={font="FredokaOne",weight="Regular",fontAsset=""}},Indicators={},Ambient={},Scripts={Vitals={cue=S.example}}}
for _,v in S.shapes do S.presets.Indicators[v]={shape=v,indicators=true} end
S.presets.Character.NaturalWalk={walkAnimation=true,walkStyle="Natural",walkIntensity=65}
S.presets.Character.HeroicWalk={walkAnimation=true,walkStyle="Heroic",walkIntensity=80}
S.presets.Character.FloatWalk={walkAnimation=true,walkStyle="Floating",walkIntensity=60}
S.presets.Character.GracefulGlide={walkAnimation=true,walkStyle="Glide",walkIntensity=68}
S.presets.Character.EtherealHover={walkAnimation=true,walkStyle="Ethereal",walkIntensity=78}
-- Twelve new original locomotion interpretations inspired by Roblox avatar packs.
for _,name in {"Toy","Robot","Ninja","Bubbly","Stylish","Mage","Levitation",
 "Oldschool","Vampire","Astronaut","Zombie","Cartoony"} do
 S.presets.Character[name.." Inspired"]={walkAnimation=true,walkStyle=name,walkIntensity=80}
end
-- UGC-inspired styles: original procedural interpretation, no paid clips copied.
for _,name in {"Angel Glide","Bat Swoop","Mermaid Drift","Serpent Slither","Cartwheel Flow","Rubberhose","Dream Sleep","Plushie","Cat Paws","Shy Kawaii","Gymnast","Skip Hop","Reindeer Prance","Fighter","Harpy Glide","Godly Aura","Wavy Expressive","Retro Zombie","Tsundere","Doll Walk","Skater","Little Duck","Floating Head","Dark Aura","Anime Hero","Headless Float"} do
 S.presets.Character[name]={walkAnimation=true,walkStyle=name,walkIntensity=75}
end
for _,v in S.defs.wingStyle.min do S.presets.Wings[v]={wings=true,wingStyle=v} end
for _,v in S.defs.haloStyle.min do S.presets.Halos[v]={halo=true,haloStyle=v} end
for _,v in S.skies do S.presets.Ambient[v[1]]=S.sky(v) end
return S
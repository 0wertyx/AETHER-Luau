local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Symbol=require(script.Parent.Symbol);local Hud=require(script.Parent.Hud);local Avatar=require(script.Parent.Avatar);local Cues=require(script.Parent.Cues);local Http=game:GetService("HttpService")
local E={}
local function names(t) local a=U.keys(t);return a end
local function preset(ui,a,group)
 local p=S.presets[group];if p then ui:title("PRESETS");ui:chips(names(p),function(n) a:patch(p[n]);a:log("Preset",n) end,3) end
end
local function preview(ui,a)
 local f=ui:row(149,"LivePreview");f.ClipsDescendants=true;f.BackgroundTransparency=0;U.gradient(f,Color3.fromRGB(105,87,145),Color3.fromRGB(49,46,94),36)
 local h=Hud.new(ui.page,f,true,function(tab) ui:open(tab) end,function(i,k,n,v) a:drag(i,k,n,v) end);a.preview={hud=h}
end
local function avatarPreview(ui,a)
 local f=ui:row(165,"RigPreview");local view=U.new("ViewportFrame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(21,19,36),Ambient=Color3.fromRGB(155,145,175),LightColor=Color3.fromRGB(246,222,255),LightDirection=Vector3.new(-1,-1,-.6)},f);U.corner(view,10);local w=U.new("WorldModel",{},view);local rig=Avatar.mannequin(w);local cam=U.new("Camera",{FieldOfView=34,CFrame=CFrame.lookAt(Vector3.new(2.3,3.6,9.3),Vector3.new(0,2.1,0))},view);view.CurrentCamera=cam;local avatar=Avatar.new(w,true);a.preview={avatar=avatar,rig=rig};ui.page:add(function() avatar:clear() end)
end
local function gallery(ui,a)
 ui:title("24 DIRECTION STYLES");for i=1,#S.shapes,4 do local r=ui:row(56,"ShapeGallery");for j=0,3 do local n=S.shapes[i+j];local b=U.button(r,"");b.Name=n;b.Position=UDim2.fromScale(j/4,0);b.Size=UDim2.new(.25,-3,1,0);local g=Symbol.new(b,n,30);g.root.Position=UDim2.fromScale(.5,.34);g.root.Size=UDim2.fromOffset(33,33);local l=U.label(b,n,10,UDim2.fromScale(0,.65),UDim2.fromScale(1,.3));l.TextXAlignment=Enum.TextXAlignment.Center;ui.page:on(b.Activated,function() a:set("shape",n) end);ui:watch(function() b.BackgroundColor3=if a.s.shape==n then U.hex("624785") else U.hex("30273E");g:paint(U.hex(a.s.arrowA),U.hex(a.s.arrowB),a.s.ink,a.s.spread) end) end end
end
local function simMap(ui,a)
 local map=ui:row(132,"VirtualMap");map.ClipsDescendants=true;map.BackgroundColor3=U.hex("211E36");local center=U.label(map,"CAMERA ↑",11,UDim2.new(.5,-32,.5,-8),UDim2.fromOffset(70,18));center.TextColor3=U.hex(a.s.accent)
 for _,p in a.sim.players do local b=U.button(map,tostring(p.id));b.AnchorPoint=Vector2.new(.5,.5);b.Size=UDim2.fromOffset(27,25);b.Position=UDim2.fromScale(.5+p.x*.45,.5+p.y*.45);ui.page:on(b.InputBegan,function(i) ui:begin(i,function(pos) local rel=pos-map.AbsolutePosition;p.x=math.clamp((rel.X/map.AbsoluteSize.X-.5)/.45,-1,1);p.y=math.clamp((rel.Y/map.AbsoluteSize.Y-.5)/.45,-1,1);b.Position=UDim2.fromScale(.5+p.x*.45,.5+p.y*.45) end) end) end
end
local function library(ui,a,profiles)
 local list=if profiles then a.bank.profiles else a.bank.assets;local group=a.libraryKind or "Theme";local selected=a.selection or "";local built=not profiles and S.presets[group] or {}
 if not profiles then ui:chips(S.kinds,function(k) a.libraryKind=k;a.selection=nil;ui:open("Workshop") end,4,function() return group end) end
 local function selectItem(n) a.selection=n;ui:open(ui.tab) end
 if not profiles then ui:title("BUNDLED · DUPLICATE TO EDIT");ui:chips(names(built),function(n) selectItem("@"..n) end,3,function() return selected:sub(1,1)=="@" and selected:sub(2) or "" end) end
 local user={};for k,v in list do if profiles or v.kind==group then table.insert(user,k) end end;table.sort(user);ui:title(if profiles then "NAMED HUD / FX PROFILES" else "YOUR ASSETS");if #user>0 then ui:chips(user,selectItem,3,function() return selected end) else ui:note("No saved entries in this collection yet.",23) end
 local box=ui:box("Name",a.libraryName or "",32);ui.page:on(box:GetPropertyChangedSignal("Text"),function() a.libraryName=box.Text end)
 local function name() local n=box.Text:match("^%s*(.-)%s*$");assert(#n>0 and #n<=48 and not n:match("^@") and not n:find("%c"),"Enter a name (1–48 bytes; no @ prefix)");return n end
 local function item() if not profiles and selected:sub(1,1)=="@" then local k=selected:sub(2);assert(built[k],"Select an asset");return {version=1,kind=group,name=k,data=S.copy(built[k])} end;assert(list[selected],"Select an entry first");return S.copy(list[selected]) end
 local function put(n,v,remove,replace) assert(replace or not list[n],"Name already exists");local draft=S.copy(a.bank);local dest=if profiles then draft.profiles else draft.assets;if remove then dest[remove]=nil end;if not profiles then v.name=n end;dest[n]=v;a:library(draft);a.selection=n;ui:open(ui.tab);ui:message("Saved: "..n) end
 ui:chips({"Save current","Apply","Duplicate","Rename","Delete"},function(action)
  if action=="Save current" then local n=name();put(n,if profiles then S.copy(a.s) else {version=1,kind=group,name=n,data=S.capture(a.s,group)},nil,true)
  elseif action=="Apply" then local v=item();if profiles then a:replace(v) else a:patch(v.data) end;ui:message("Applied: "..selected)
  elseif action=="Duplicate" then put(name(),item()) elseif action=="Rename" then assert(list[selected],"Bundled entry is read-only");put(name(),item(),selected)
  else assert(list[selected],"Choose a user entry");local draft=S.copy(a.bank);(if profiles then draft.profiles else draft.assets)[selected]=nil;a:library(draft);a.selection=nil;ui:open(ui.tab) end
 end,3)
 ui:note("JSON transfer: select and copy the text, or paste JSON and import. Nothing is executed on import.",36)
 local transfer=ui:box("Transfer JSON",a.transfer or "",80);ui.page:on(transfer.FocusLost,function() a.transfer=transfer.Text end)
 ui:chips({"Export JSON","Import JSON"},function(action)
  if action=="Export JSON" then a.transfer=Http:JSONEncode(if profiles then {format="aether.bank/1",data=a.bank} else {format="aether.asset/1",data=item()});transfer.Text=a.transfer;transfer:CaptureFocus();transfer.CursorPosition=#transfer.Text+1;transfer.SelectionStart=1
  else assert(#transfer.Text<=110100,"Import too large");local v=Http:JSONDecode(transfer.Text);if profiles then assert(v.format=="aether.bank/1","Expected full bank JSON");a:restore(S.bank(v.data));a:dirty();ui:open("Profiles");ui:message("Bank imported") else assert(v.format=="aether.asset/1","Expected asset JSON");local it=S.asset(v.data);assert(it.kind==group,"Select collection: "..it.kind);put(if box.Text~="" then name() else it.name,it) end end
 end,2)
 if profiles then ui:note("Save now waits for the server acknowledgement. Reload replaces the current bank. Studio defaults to session storage.",40);ui:chips({"Save now","Reload saved"},function(k) if k=="Save now" then a.store:save() else a.store:read(true) end;ui:message(a.store.status) end,2) end
end
local function scripts(ui,a)
 local draft=a.scriptTab=="Luau draft";ui:chips({"AETHER Lua","Luau draft"},function(n) a:stopCue();a.scriptTab=n;ui:open("Scripts") end,2,function() return a.scriptTab or "AETHER Lua" end)
 ui:note(if draft then "Author Studio source here. Copy it to a ModuleScript in Studio for compilation. In-game checks are lexical only." else "Bounded HUD language: local values, arithmetic, if/elseif/else, hud calls, onHealthChanged(hp,maxHP) and onEvent(name,hp).",42)
 local k=if draft then "luau" else "cue";local box=ui:box("Source",a.s[k],125,function(v) if a.s[k]~=v then a:stopCue();a:set(k,v) end end);box.TextTruncate=Enum.TextTruncate.None
 local function esc(v) return (v:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
 local syntax=ui:note("",45);syntax.RichText=true;local function highlight() local code=esc(box.Text:sub(1,280));syntax.Text=code:gsub("[%a_][%w_]*",function(w) return if table.find({"local","function","if","then","else","end","return","and","or","nil","true","false"},w) then '<font color="#CF9BFF">'..w..'</font>' else w end) end;ui.page:on(box:GetPropertyChangedSignal("Text"),highlight);highlight()
 ui:chips({"Template","Complete symbol","Select source","Check"},function(op)
  if op=="Template" then a:set(k,S.defs[k].default);box.Text=a.s[k]
  elseif op=="Select source" then box:CaptureFocus();box.CursorPosition=#box.Text+1;box.SelectionStart=1
  elseif op=="Complete symbol" then local i=if box.CursorPosition>0 then box.CursorPosition else #box.Text+1;local left=box.Text:sub(1,i-1);local pre=left:match("([%w%.:_]+)$") or "";local opts=if draft then {"game:GetService","Players","Humanoid","HealthChanged","MaxHealth","CharacterAdded","workspace.CurrentCamera","Vector3.new","function","return"} else {"hud.widget","hud.animate","hud.setGlow","hud.indicator","hud.theme","hud.join","onHealthChanged","onEvent"};for _,w in opts do if w:lower():sub(1,#pre)==pre:lower() then box.Text=left:sub(1,#left-#pre)..w..box.Text:sub(i);a:set(k,box.Text);return end end;ui:message("No matching symbol")
  else if draft then local depth={};local close={[")"]="(",["]"]="[",["}"]="{"};local clean=box.Text:gsub('"[^"\n]*"',''):gsub("'[^'\n]*'",''):gsub("%-%-[^\n]*",'');for ch in clean:gmatch("[%(%)%[%]{}]") do if close[ch] then assert(table.remove(depth)==close[ch],"Unbalanced delimiter") else table.insert(depth,ch) end end;assert(#depth==0,"Open delimiter");ui:message("Delimiters balanced · compile in Studio") else Cues.compile(box.Text);ui:message("HUD syntax OK") end end
 end,2)
 if not draft then ui:title("RUN PERMISSIONS · SESSION ONLY");ui:chips({"widgets","appearance","events"},function(p) a:stopCue();a.grants[p]=not a.grants[p];ui:sync() end,3);local report=ui:note("",26);ui:watch(function() local v={};for _,p in {"widgets","appearance","events"} do if a.grants[p] then table.insert(v,p) end end;report.Text="Granted: "..table.concat(v,", ").."   /   "..(if a.cue then "Running" else "Stopped") end)
  ui:chips({"Run HUD script","Stop"},function(op) if op=="Stop" then a:stopCue();ui:message("Stopped") else a:set(k,box.Text);a:runCue() end;ui:sync() end,2)
 end
 ui:chips({"Save / browse script assets"},function() a.libraryKind="Scripts";a.selection=nil;ui:open("Workshop") end,1)
end
function E.render(a,tab,ui)
 if tab=="Dashboard" then preview(ui,a);ui:note("Game reads the local Humanoid and authorized targets. Simulator edits only a separate virtual scene. RightShift opens Studio; LeftAlt toggles shoulder lock.",43);ui:chips({"Game","Simulator"},function(n) a:modeSet(n) end,2,function() return a.mode end);ui:title("THEMES");preset(ui,a,"Theme");ui:group("Theme");ui:note("For 32 ORIGINAL desktop icons, upload AETHER_original_icons_atlas.png as a Roblox image and enter its asset ID above. The atlas includes all 32 icons at 224px per tile.",53);ui:title("MOTION");ui:group("Motion")
 elseif tab=="HUD" then preview(ui,a);preset(ui,a,"HUD");ui:control("locked");ui:control("compact");ui:note("Unlock layout and drag a widget in the preview, or edit its coordinates below.",29);ui:chips({"hp","clock","profile","dock","cross"},function(n) a.hudTab=n;ui:open("HUD") end,3,function() return a.hudTab end);local k=a.hudTab;for _,suffix in {"","X","Y","Scale","Turn","Alpha"} do ui:control(k..suffix) end
 elseif tab=="Character" or tab=="Wings" or tab=="Halos" or tab=="Neon" then
  avatarPreview(ui,a)
  if tab=="Character" then
   ui:title("ANIMATION PACK-INSPIRED MOTION")
   ui:note("Original AETHER styles based on the feel of Roblox avatar packs, not copied animation assets. Procedural R6/R15 poses for idle, walk, run, jump/fall, swim and climb. Visual-only motion.",55)
   ui:chips({"Toy","Robot","Ninja","Bubbly","Stylish","Mage","Levitation","Oldschool","Vampire","Astronaut","Zombie","Cartoony"},
    function(style) a:patch({walkAnimation=true,walkStyle=style}) end,4,
    function() return a.s.walkStyle end)
  end
  preset(ui,a,tab);ui:group(tab)
 elseif tab=="Ambient" then local sky=ui:row(106,"SkyPreview");local grad=U.gradient(sky,Color3.new(),Color3.new(),90);local sun=U.frame(sky,"Sun",nil,UDim2.fromOffset(30,30));U.corner(sun,30);ui:watch(function() local s=a.s;sky.BackgroundColor3=Color3.new(1,1,1);grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,U.hex(s.skyA)),ColorSequenceKeypoint.new(.64,U.hex(s.skyB)),ColorSequenceKeypoint.new(1,U.hex(s.skyC))});sun.BackgroundColor3=U.hex(s.skyC);sun.Position=UDim2.fromScale(.7,.66-.45*math.sin(s.time/240*math.pi));sun.BackgroundTransparency=.04+s.fog*.004 end);preset(ui,a,tab);ui:group(tab)
 elseif tab=="Indicators" then preview(ui,a);gallery(ui,a);ui:group(tab,{shape=true});ui:title("PER-PLAYER OVERRIDE");local id=ui:box("UserId or simulator ID","1");local label=ui:box("Label override","");local color=ui:box("Override hex",a.s.arrowA);ui:chips({"Assign current shape","Remove override"},function(k) local p=S.copy(a.s.players);if k=="Assign current shape" then p[id.Text]={label=label.Text,color=color.Text,shape=a.s.shape} else p[id.Text]=nil end;a:set("players",p);ui:message("Overrides updated") end,2)
 elseif tab=="Cursor" then local f=ui:row(94,"CursorPreview");local host=U.frame(f,"OriginalCursorPreview",UDim2.fromScale(.5,.5),UDim2.fromOffset(60,60),nil,1);host.AnchorPoint=Vector2.new(.5,.5);a.preview={cursorHost=host};preset(ui,a,tab);ui:group(tab);ui:note("Cursor animation never moves its click hotspot. Enable Show hotspot marker to compare the real mouse position with the skin; use Pointer offset X/Y only for calibration. EditableImage renders desktop SVG; imports need an authorized asset ID.",57)
 elseif tab=="Camera" then ui:note("Follow and Orbit use the current character. LeftAlt toggles shift-lock. Close Studio to capture the mouse; opening it releases the lock.",40);preset(ui,a,tab);ui:group(tab)
 elseif tab=="Fonts" then local text=ui:note(a.s.sample,62);text:SetAttribute("AETHERKeepFontColor",true);text.TextXAlignment=Enum.TextXAlignment.Center;local gradient=U.gradient(text,Color3.new(),Color3.new(),10);local glow=U.stroke(text,U.hex(a.s.fontB),.8);glow.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;ui:watch(function() local s=a.s;text.Text=s.sample;text.FontFace=U.font(s);text.TextSize=s.fontSize*.23;text.TextColor3=if s.fontGradient then Color3.new(1,1,1) else U.hex(s.fontA);text.TextStrokeTransparency=1-s.fontOutline/100;gradient.Enabled=s.fontGradient;gradient.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB));glow.Color=U.hex(s.fontB);glow.Transparency=1-s.fontGlow*.008;glow.Thickness=1+s.fontGlow*.023 end);local query=ui:box("Search native typefaces",a.fontQuery or "",32,function(q) if q~=(a.fontQuery or "") then a.fontQuery=q;ui:open("Fonts") end end);local fonts={};for _,n in S.fonts do if n:lower():find((a.fontQuery or ""):lower(),1,true) then table.insert(fonts,n) end end;ui:chips(fonts,function(n) a:patch({font=n,fontAsset=""}) end,3,function() return a.s.font end);ui:group(tab,{font=true});preset(ui,a,tab)
 elseif tab=="Simulator" then preview(ui,a);ui:chips({"Use simulator","Use game"},function(n) a:modeSet(if n=="Use game" then "Game" else "Simulator") end,2);simMap(ui,a);ui:chips({"Damage −25","Heal +25","Respawn","Add player","Move players","Clear players"},function(k) a:simulate(k);ui:open("Simulator") end,3);local hp=ui:box("Set virtual HP",tostring(a.sim.hp));local mx=ui:box("Virtual max HP",tostring(a.sim.max));ui:chips({"Apply virtual vitals"},function() local h,m=tonumber(hp.Text),tonumber(mx.Text);assert(m and h and m>=1 and m<=100000 and h>=0 and h<=m,"Invalid HP / maximum");a:modeSet("Simulator");a:simVitals(h,m,"set") end,1)
 elseif tab=="Scripts" then scripts(ui,a)
 elseif tab=="Workshop" or tab=="Profiles" then library(ui,a,tab=="Profiles")
 elseif tab=="Diagnostics" then local info=ui:note("",54);local log=ui:box("Session events","",165);log.TextEditable=false;local function refresh() info.Text=string.format("%s  ·  HP %s / %s  ·  %d tracked\n%s",a.mode,tostring(a.frame.hp),tostring(a.frame.max),#a.frame.targets,a.store.status);log.Text=table.concat(a.logs,"\n") end;ui:chips({"Refresh","Clear log","Reset settings"},function(n) if n=="Clear log" then table.clear(a.logs) elseif n=="Reset settings" then a:replace(S.defaults()) end;refresh() end,3);refresh() end
end
return E
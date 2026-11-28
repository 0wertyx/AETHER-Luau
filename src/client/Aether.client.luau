--!strict
-- AETHER client entry: regular Roblox LocalScript, no external loader.
-- Modules are synchronized by Rojo into ReplicatedStorage.Aether.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("Aether", 30)
assert(modules, "AETHER: ReplicatedStorage.Aether is missing; sync the Rojo project")
local function module(name)
    return require(modules:WaitForChild(name, 15))
end

local U = module("Util")
local S = module("Schema")
local Hud = module("Hud")
local Avatar = module("Avatar")
local WalkMotion = module("WalkMotion")
local PeerVisuals = module("PeerVisuals")
local PreviewProps = module("PreviewProps")
local World = module("World")
local View = module("View")
local Controls = module("Controls")
local Pages = module("Pages")
local Storage = module("Storage")
local Cues = module("Cues")

-- Prevent multiple copies if the script is restarted in Studio.
local pg = player:WaitForChild("PlayerGui")
local prior = pg:FindFirstChild("AETHER_Studio")
if prior then prior:Destroy() end
-- Reloads must not leave a previous high-order pointer behind.
local priorPointer = pg:FindFirstChild("AETHER_Pointer")
if priorPointer then priorPointer:Destroy() end
local scope = U.scope()
local gui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Studio", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 2147483644,
}, pg))
local overlay = U.frame(gui, "HUDLayer", nil, nil, nil, 1)
local pointerGui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Pointer", ResetOnSpawn = false,
    IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None,
    ClipToDeviceSafeArea = false, DisplayOrder = 2147483647,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, pg))
local pointer = U.frame(pointerGui, "PointerLayer", nil, nil, nil, 1)
pointer.Active=false;pointer.Interactable=false
local studioLayer = U.frame(gui, "StudioLayer", nil, nil, nil, 1)
studioLayer.ZIndex=2

local app = {
    bank = S.blank(), mode = "Game", logs = {}, preview = nil,
    hudTab = "clock", scriptTab = "AETHER Lua",
    grants = {widgets = false, appearance = false, events = false},
    sim = {hp = 100, max = 100, gen = 0, players = {}},
    frame = {hp = nil, max = nil, gen = 0, name = player.DisplayName, mode = "GAME", targets = {}, widgets = {}},
    cues = nil, lastVitals = nil, altLock = false,
}
app.s = app.bank.settings
-- Use an ordinary input action, scoped to this AETHER instance.
local shiftBlockAction = "AETHER_BlockShift_"..game:GetService("HttpService"):GenerateGUID(false)
local function blockShift(_, _, input)
    if app.stopping or not gui.Parent or not app.s.blockShift or UserInputService:GetFocusedTextBox() or game:GetService("GuiService").MenuIsOpen then
        return Enum.ContextActionResult.Pass
    end
    return Enum.ContextActionResult.Sink
end
ContextActionService:BindActionAtPriority(shiftBlockAction, blockShift, false, Enum.ContextActionPriority.High.Value+200, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
scope:add(function() ContextActionService:UnbindAction(shiftBlockAction) end)

function app:log(topic, message)
    local stamp = os.date("%H:%M:%S")
    table.insert(self.logs, string.format("%s [%s] %s", stamp, tostring(topic), tostring(message)))
    while #self.logs > 35 do table.remove(self.logs, 1) end
end
function app:dirty()
    if not self.store then self.pendingStoreEdit=true;return end
    self.store:edit()
end
function app:set(key, value)
    local normalized = S.value(key, value)
    self.s = table.clone(self.s)
    self.s[key] = normalized
    self.bank.settings = self.s
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:patch(patch)
    local next = table.clone(self.s)
    for k, v in patch do next[k] = S.value(k, v) end
    self.s = next
    self.bank.settings = next
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:replace(settings)
    self.s = S.settings(settings)
    self.bank.settings = self.s
    self.moduleGeneration=(self.moduleGeneration or 0)+1;self.moduleRestoreRequested=true
    self:stopCue()
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:restore(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self.moduleGeneration=(self.moduleGeneration or 0)+1;self.moduleRestoreRequested=true
    self:stopCue()
    if self.ui and self.ui.tab then
        if self.ui.opened then self.ui:open(self.ui.tab) else self.ui:sync() end
    end
end
function app:library(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self:dirty()
end
-- Runtime Volleyball objects are session-local; private module preferences are saved separately.
do
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local vb={originals={},multiplierRequests={},corners={},auto=false,status="Waiting for compatible game",target=nil,tiltAim="Correct edges",tiltScale=1,tiltWrites=0,tiltOverrides=0}
    app.volleyball=vb
    local pingSmooth,pingAt=0,-100
    local pingJitter,pingTry,lastPing=0,-100,nil
    local adaptiveOffset,adaptiveAt,previousMode=0,os.clock(),nil
    function vb:visualDelay()
        local now=os.clock()
        if now-pingTry>=.25 then
            pingTry=now
            local ok,value=pcall(function() return player:GetNetworkPing() end)
            if ok and type(value)=="number" and value==value and value>=0 and value<=5 then
                pingSmooth=if lastPing==nil then value else pingSmooth*.75+value*.25
                if lastPing~=nil then pingJitter=pingJitter*.8+math.abs(value-lastPing)*.2 end
                lastPing=value
                pingAt=now
            end
        end
        local mode=app.s.vbPingMode
        local fresh=now-pingAt<2
        local dt=math.clamp(now-adaptiveAt,0,.5)
        adaptiveAt=now
        local target=if fresh then math.clamp(pingSmooth*.5+math.min(pingJitter*.25,.025),0,.125) else 0
        if previousMode~=mode then adaptiveOffset=if mode=="Adaptive" then target else 0 end
        previousMode=mode
        adaptiveOffset+=(target-adaptiveOffset)*(1-math.exp(-dt*5))
        local delay=if mode=="Manual" then math.clamp(app.s.vbPingMs/1000,0,.5)
            elseif mode=="Adaptive" then adaptiveOffset
            elseif mode=="Auto" and fresh then math.clamp(pingSmooth*.5,0,.125) else 0
        return delay,if fresh then pingSmooth*2000 else -1,pingJitter*2000
    end
    vb.edgeGuard=true;vb.guardStatus="Anti-out | waiting"
    local attrs={
        BlockPower=true,BumpPower=true,DashPower=true,DiveSpeed=true,
        DrawPower=true,JumpPower=true,ServePower=true,SetPower=true,Speed=true
    }
    local tiltKey="Gameplay_TiltDirection"
    local rf=game:GetService("ReplicatedFirst")
    local function gameModules()
        local controllers=rf:FindFirstChild("Controllers")
        local g=controllers and controllers:FindFirstChild("GameController")
        local actions=g and g:FindFirstChild("Actions")
        local move=actions and actions:FindFirstChild("Move")
        local jump=move and move:FindFirstChild("Jump")
        local physics=jump and jump:FindFirstChild("Physics")
        local handlers=g and g:FindFirstChild("Handlers")
        if handlers and handlers:IsA("ModuleScript") and physics and physics:IsA("ModuleScript") then return handlers,physics end
        return nil,nil
    end
    local function available()
        local handlers,physics=gameModules()
        return app.mode=="Game" and handlers~=nil and physics~=nil
    end
    local handlers,physics,originalTilt,wrappedTilt,lastManual,lastApplied
    local function releaseLocalTilt()
        if handlers and handlers.Values and lastApplied~=nil and handlers.Values.TiltDirection==lastApplied then
            handlers.Values.TiltDirection=lastManual or Vector3.zero
        end
        lastManual=nil;lastApplied=nil
    end
    local function detachTilt()
        releaseLocalTilt()
        if physics and wrappedTilt and physics._handleTilt==wrappedTilt then physics._handleTilt=originalTilt end
        handlers=nil;physics=nil;originalTilt=nil;wrappedTilt=nil
        vb.requestedTilt=nil
    end
    local function attachTilt()
        local h,p=gameModules()
        assert(h and p,"Tilt modules unavailable")
        local ht,pt=require(h),require(p)
        assert(type(ht)=="table" and type(ht.Values)=="table" and typeof(ht.Values.TiltDirection)=="Vector3","Unexpected Handlers shape")
        assert(type(pt)=="table" and type(pt._handleTilt)=="function","Unexpected Jump.Physics shape")
        assert(not table.isfrozen(pt) and not table.isfrozen(ht.Values),"Tilt modules are read-only")
        handlers,physics=ht,pt
        originalTilt=pt._handleTilt
        local original=originalTilt
        wrappedTilt=function(...)
            local result=table.pack(original(...))
            local manual=ht.Values.TiltDirection
            local desired=vb.requestedTilt
            if vb.auto and app.mode=="Game" and not app.stopping and gui.Parent and player:GetAttribute("Gameplay_InGame")==true then
                if not vb.tiltFresh or os.clock()-vb.tiltFresh>=.25 then desired=nil end
                desired=vb:guardTilt(manual,desired)
            else desired=nil end
            if typeof(desired)=="Vector3" then
                if lastApplied==nil or manual~=lastApplied then lastManual=manual end
                if manual~=desired then
                    ht.Values.TiltDirection=desired
                    vb.tiltWrites+=1
                end
                lastApplied=desired
                vb.tiltHooks=(vb.tiltHooks or 0)+1
            else
                releaseLocalTilt()
            end
            return table.unpack(result,1,result.n)
        end
        pt._handleTilt=wrappedTilt
    end
    function vb:available() return available() end
    function vb:availabilityStatus()
        if app.mode~="Game" then return "Waiting: switch to Game mode" end
        if not available() then return "Waiting for GameController tilt modules" end
        return if wrappedTilt and physics and physics._handleTilt==wrappedTilt then "Jump tilt hook connected" else "GameController modules detected"
    end
    function vb:tiltDebug()
        local current=handlers and handlers.Values and handlers.Values.TiltDirection or player:GetAttribute(tiltKey)
        local function fmt(v)
            if typeof(v)~="Vector3" then return "-" end
            return string.format("%.3f, %.3f, %.3f",v.X,v.Y,v.Z)
        end
        return string.format("Local tilt: %s\nRequested: %s\nWrites: %d | jump ticks: %d",fmt(current),fmt(self.requestedTilt),self.tiltWrites,self.tiltHooks or 0)
    end
    local function write(key,value)
        local current=player:GetAttribute(key)
        local entry=vb.originals[key]
        if not entry or current~=entry.applied then
            entry={base=current,applied=current}
            vb.originals[key]=entry
        end
        if current~=value then player:SetAttribute(key,value) end
        entry.applied=value
    end
    local function restore(key)
        local entry=vb.originals[key]
        if not entry then return end
        if player:GetAttribute(key)==entry.applied then player:SetAttribute(key,entry.base) end
        vb.originals[key]=nil
    end
    function vb:setMultiplier(name,value)
        assert(app.mode=="Game","Switch to Game mode")
        assert(attrs[name],"Unknown multiplier")
        assert(type(value)=="number" and value==value and value>=0 and value<math.huge,"Enter a finite nonnegative number")
        local key="Multiplier_"..name
        assert(type(player:GetAttribute(key))=="number","Multiplier unavailable")
        write(key,value)
        self.multiplierRequests[name]=value
        self.status=name.." set locally"
    end
    function vb:clearMultiplier(name)
        assert(attrs[name],"Unknown multiplier")
        restore("Multiplier_"..name)
        self.multiplierRequests[name]=nil
    end
    function vb:multiplierStatus(name)
        local actual=player:GetAttribute("Multiplier_"..name)
        local requested=self.multiplierRequests[name]
        if type(actual)~="number" then return "Attribute unavailable" end
        if requested==nil then return string.format("Actual: %.5g | Not edited",actual) end
        local same=math.abs(actual-requested)<=math.max(1e-6,math.abs(requested)*1e-6)
        return string.format("Requested: %.5g | Actual: %.5g | %s",requested,actual,if same then "Local match" else "Changed by game")
    end
    function vb:reset()
        self.auto=false;detachTilt()
        if self.repeatTouch and self.repeatTouch.enabled then self:toggleRepeatTouch() end
        if self.play then self.play.set=false;self.play.spike=false;self.play.dive=false;self.play.serve=false;self.play.serveActive=false;self.play.ownsTilt=false;self.play.generation+=1;table.clear(self.play.locks);table.clear(self.play.receiverTouches);self.play.receiverActive=nil;table.clear(self.play.jumpLocks);self.play.jumpPendingUntil=0;self.play.status="Off | reset" end
        table.clear(self.multiplierRequests)
        for key in table.clone(self.originals) do restore(key) end
        self.target=nil
        self.status="Original values restored where unchanged"
    end
    -- Consecutive-touch client experiment.
    -- Keep serve checks and ordinary hit cooldowns unchanged.
    vb.repeatTouch={enabled=false,status="Off | beta",checks=0}
    local repeatRules,repeatOriginal,repeatWrapped
    local function stopRepeatTouch(reason)
        if repeatRules and repeatRules.isHitboxSkipped==repeatWrapped then
            repeatRules.isHitboxSkipped=repeatOriginal
        end
        repeatRules=nil;repeatOriginal=nil;repeatWrapped=nil
        vb.repeatTouch.enabled=false
        vb.repeatTouch.status=reason or "Off"
    end
        function vb:toggleRepeatTouch()
        if self.repeatTouch.enabled then stopRepeatTouch();return end
        if app.mode~="Game" then
            self.repeatTouch.status="Switch to Game mode"
            return
        end
        local ok,err=pcall(function()
            local controllers=rf:FindFirstChild("Controllers")
            local g=controllers and controllers:FindFirstChild("GameController")
            local actions=g and g:FindFirstChild("Actions")
            local move=actions and actions:FindFirstChild("Move")
            local dm=move and move:FindFirstChild("DoMove")
            local module=dm and dm:FindFirstChild("Game")
            assert(module and module:IsA("ModuleScript"),"DoMove.Game unavailable")
            local rules=require(module)
            assert(type(rules.isHitboxSkipped)=="function" and not table.isfrozen(rules),"Rule module unavailable or read-only")
            local original=rules.isHitboxSkipped
            local wrapped=function(action,...)
                local skipped=original(action,...)
                if skipped and vb.repeatTouch.enabled and app.mode=="Game" and not app.stopping and gui.Parent and ReplicatedStorage:GetAttribute("LastHitter")==player.Name
                    and (action=="Set" or action=="Spike" or action=="Bump" or action=="JumpSet" or action=="Dive") then
                    vb.repeatTouch.checks+=1
                    vb.repeatTouch.status="Beta | consecutive check allowed"
                    return false
                end
                return skipped
            end
            rules.isHitboxSkipped=wrapped
            repeatRules=rules;repeatOriginal=original;repeatWrapped=wrapped
            self.repeatTouch.checks=0;self.repeatTouch.enabled=true
            self.repeatTouch.status="Beta | waiting for consecutive touch"
        end)
        if not ok then stopRepeatTouch("Error: "..tostring(err)) end
    end
    local repeatElapsed=0
    scope:on(RunService.Heartbeat,function(dt)
        if not vb.repeatTouch.enabled then return end
        repeatElapsed+=dt
        if repeatElapsed<.2 then return end
        repeatElapsed=0
        if app.stopping or not gui.Parent or app.mode~="Game" then
            stopRepeatTouch("Off | left Game mode")
        elseif not repeatRules or repeatRules.isHitboxSkipped~=repeatWrapped then
            stopRepeatTouch("Off | rule module changed")
        end
    end)
    scope:add(function() stopRepeatTouch("Off | unload") end)
    local function flatten(p) return Vector3.new(p.X,0,p.Z) end
    function vb:clearCourt()
        self.auto=false;detachTilt();restore(tiltKey)
        table.clear(self.corners);self.target=nil;self.side=nil;self.map=nil;self.courtSource=nil;self.courtPart=nil;self.courtZones=nil;self.status="Calibration cleared"
    end
    function vb:capture(index)
        if app.mode~="Game" then self.status="Calibration needs Game mode";return end
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then self.status="Calibration: character root unavailable";return end
        local map=ReplicatedStorage:GetAttribute("Map")
        if map~=nil and self.map~=nil and self.map~=map then self:clearCourt() end
        if map~=nil then self.map=map end
        self.auto=false;detachTilt();restore(tiltKey);self.target=nil
        self.courtSource="Manual";self.courtPart=nil;self.courtZones=nil
        self.corners[index]=flatten(root.Position)
        self.status=string.format("Corner %s saved: X %.2f Z %.2f",({"A","B","C"})[index],root.Position.X,root.Position.Z)
    end
    local function geometry()
        local a,b,c=vb.corners[1],vb.corners[2],vb.corners[3]
        if not a or not b or not c then return nil end
        local ab=b-a
        local width=ab.Magnitude
        if width<4 then return nil end
        local u=ab.Unit
        local ac=c-a
        local along=ac:Dot(u)
        local cross=ac-u*along
        local length=cross.Magnitude
        if length<8 or math.abs(along)>width*.2 then return nil end
        return a,u,cross.Unit,width,length
    end
    -- Estimate coverage from positions and recent movement, not just distance.
    local opponentMotion={}
    local function freeZone(a,u,v,width,length,side,root,cameraAim)
        local half=length*.5
        local rel=flatten(root.Position)-a
        local px,pz=rel:Dot(u),rel:Dot(v)
        local look=flatten(root.CFrame.LookVector)
        local dv=look:Dot(v)
        if not cameraAim and math.abs(dv)<.15 then return nil end
        local opponents,seen={},{}
        local now=os.clock()
        for _,other in Players:GetPlayers() do
            if other==player or (player.Team and other.Team==player.Team) then continue end
            local c=other.Character
            local r=c and c:FindFirstChild("HumanoidRootPart")
            local h=c and c:FindFirstChildOfClass("Humanoid")
            if not r or not h or h.Health<=0 then continue end
            local pos=flatten(r.Position)
            local d=pos-a
            local x,z=d:Dot(u),d:Dot(v)
            if x< -3 or x>width+3 or not ((side==-1 and z>=half and z<=length+3) or (side==1 and z<=half and z>=-3)) then continue end
            seen[other]=true
            local m=opponentMotion[other]
            local vel=flatten(r.AssemblyLinearVelocity)
            if vel.Magnitude>45 then vel=vel.Unit*45 end
            if not m or m.root~=r then
                m={root=r,p=pos,t=now,velocity=vel,activity=vel.Magnitude};opponentMotion[other]=m
            elseif now-m.t>=.09 then
                local dt=now-m.t
                local sample=(pos-m.p)/dt
                if sample.Magnitude>45 then sample=vel end
                local k=1-math.exp(-dt*3)
                m.velocity=m.velocity:Lerp(sample,k)
                m.activity=m.activity+(math.max(sample.Magnitude,vel.Magnitude)-m.activity)*k
                m.p=pos;m.t=now
            end
            local predicted=pos+m.velocity*.40-a
            table.insert(opponents,{p=Vector2.new(x,z),next=Vector2.new(predicted:Dot(u),predicted:Dot(v)),activity=math.clamp(m.activity/16,0,2)})
        end
        for other in pairs(opponentMotion) do if not seen[other] then opponentMotion[other]=nil end end
        local best,score=nil,-math.huge
        for ix=1,9 do for iz=1,7 do
            local x=width*(.14+.72*(ix-1)/8)
            local f=.16+.68*(iz-1)/6
            local z=if side==-1 then half+half*f else half-half*f
            if not cameraAim and (z-pz)*dv<=0 then continue end
            local point=Vector2.new(x,z)
            local nearest=math.min(width,half)
            local pressure=0
            local radius=math.max(4,width*.21)
            for _,o in opponents do
                local d=math.min((point-o.p).Magnitude,(point-o.next).Magnitude)
                nearest=math.min(nearest,d)
                pressure+=math.exp(-.5*(d/radius)^2)*(1+o.activity*1.4)
            end
            local correction=if cameraAim then .035*math.abs(x-px) else .35*math.abs(x-(px+look:Dot(u)*(z-pz)/dv))
            local edge=math.min(x,width-x,math.abs(z-half),if side==-1 then length-z else z)
            local q=nearest+.28*edge-pressure*radius*1.1-correction
            if q>score then best,score=point,q end
        end end
        return best
    end
    -- Proportional anti-out clamp using the same court projection as Auto Tilt.
    -- This is a bounded local estimate; styles and server physics can differ.
    function vb:guardTilt(manual,desired)
        if not self.edgeGuard then return desired end
        local a,u,v,width,length=geometry()
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not a or not root then return desired end
        local rel=flatten(root.Position)-a
        local x,z=rel:Dot(u),rel:Dot(v)
        local half=length*.5
        local side=if z<half then -1 else 1
        local forward=flatten(root.CFrame.LookVector)
        local right=flatten(root.CFrame.RightVector)
        if forward.Magnitude<.01 or right.Magnitude<.01 then return desired end
        forward=forward.Unit;right=right.Unit
        local depth=if side==-1 then length*.75 else length*.25
        local margin=math.min(math.max(2,width*.10),width*.30)
        local dv=forward:Dot(v)
        if math.abs(dv)<.12 or (depth-z)*dv<=0 then
            local target=a+u*(width*.5)+v*depth
            local inward=target-flatten(root.Position)
            self.guardStatus="Heading outside | maximum inward correction"
            return if inward.Magnitude>.1 then inward.Unit+Vector3.yAxis else Vector3.yAxis
        end
        local straight=x+forward:Dot(u)*(depth-z)/dv
        local reach=math.max(4,width*.15)
        local base=if typeof(desired)=="Vector3" then desired elseif typeof(manual)=="Vector3" then manual else Vector3.yAxis
        local lateral=math.clamp(flatten(base):Dot(right),-1,1)
        local axis=right:Dot(u)
        if math.abs(axis)<.12 then return desired end
        local projected=straight+lateral*reach*axis
        local safe=math.clamp(projected,margin,width-margin)
        if math.abs(projected-safe)>.01 or straight<margin or straight>width-margin then
            -- Recompute inward correction from the uncurved heading; outward manual input cannot replace it.
            local value=math.clamp((safe-straight)/(reach*axis),-1,1)
            if straight<margin then value=math.clamp((margin-straight)/(reach*axis),-1,1)
            elseif straight>width-margin then value=math.clamp((width-margin-straight)/(reach*axis),-1,1) end
            self.guardStatus=string.format("Anti-out | %.0f%% inward",math.abs(value)*100)
            return right*value+Vector3.yAxis
        end
        self.guardStatus="Anti-out | within estimated corridor"
        return desired
    end
    -- Identify a full, horizontal rectangular court from explicitly named
    -- map geometry. Do not guess from an arbitrary baseplate or half-court.
    function vb:detectCourt()
        if app.mode~="Game" then self.status="Detection needs Game mode";return false end
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then self.status="Detection: character root unavailable";return false end
        -- Map.Zones distinguishes playing halves from service and total volumes.
        local mapModel=workspace:FindFirstChild("Map")
        local zones=mapModel and mapModel:FindFirstChild("Zones")
        if zones then
            local halves={}
            local duplicates=false
            for _,part in zones:GetChildren() do
                if part:IsA("BasePart") and part:GetAttribute("Type")=="Court" then
                    local team=tonumber(part:GetAttribute("Team"))
                    if team==1 or team==2 then
                        if halves[team] then duplicates=true end
                        halves[team]=part
                    end
                end
            end
            local first,second=halves[1],halves[2]
            if first and second and not duplicates then
                local delta=flatten(second.Position-first.Position)
                if delta.Magnitude>8 then
                    local v=delta.Unit
                    local u=Vector3.new(v.Z,0,-v.X)
                    local function bounds(part)
                        local loU,hiU,loV,hiV=math.huge,-math.huge,math.huge,-math.huge
                        for _,x in {-1,1} do for _,z in {-1,1} do
                            local p=flatten(part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X*.5,0,z*part.Size.Z*.5)))
                            local pu,pv=p:Dot(u),p:Dot(v)
                            loU=math.min(loU,pu);hiU=math.max(hiU,pu)
                            loV=math.min(loV,pv);hiV=math.max(hiV,pv)
                        end end
                        return loU,hiU,loV,hiV
                    end
                    local a,b,c,d=bounds(first)
                    local e,f,g,h=bounds(second)
                    local lo,hi=math.max(a,e),math.min(b,f)
                    if hi-lo>4 and h-c>8 then
                        self:clearCourt()
                        self.map=ReplicatedStorage:GetAttribute("Map")
                        self.corners[1]=u*lo+v*c
                        self.corners[2]=u*hi+v*c
                        self.corners[3]=u*lo+v*h
                        self.courtZones={first,second}
                        self.courtSource="Zones: "..first.Name.." / "..second.Name
                        self.status="Detected both Type= Court zones"
                        return true
                    end
                end
            end
            self.status="Zones found, but two distinct Court teams could not be validated. Use manual calibration."
            return false
        end
        local best,bestScore,bestWidth,bestLength,bestU,bestV=nil,-math.huge,nil,nil,nil,nil
        local count=0
        local function cleanName(name) return string.lower(name):gsub("[^%w]","") end
        for _,part in workspace:GetDescendants() do
            if not part:IsA("BasePart") or not part.Anchored then continue end
            if math.abs(part.CFrame.UpVector:Dot(Vector3.yAxis))<.98 then continue end
            local n=cleanName(part.Name)
            local parentName=part.Parent and cleanName(part.Parent.Name) or ""
            local named=n:find("court",1,true) or n:find("playarea",1,true) or n:find("playingfield",1,true)
            local floorName=n=="floor" or n=="ground" or n=="surface" or n=="base" or n=="sand"
            local inCourt=parentName:find("court",1,true) or parentName:find("playarea",1,true)
            if not named and not (floorName and inCourt) then continue end
            if n:find("half",1,true) or n:find("line",1,true) or n:find("net",1,true) or n:find("wall",1,true) or n:find("decor",1,true) or n:find("outof",1,true) then continue end
            local width=math.min(part.Size.X,part.Size.Z)
            local length=math.max(part.Size.X,part.Size.Z)
            if width<12 or length<24 or length/width<1.4 or length/width>2.7 or part.Size.Y>width*.35 then continue end
            local p=part.CFrame:PointToObjectSpace(root.Position)
            if math.abs(p.X)>part.Size.X*.5+5 or math.abs(p.Z)>part.Size.Z*.5+5 then continue end
            if p.Y < -part.Size.Y*.5-4 or p.Y>part.Size.Y*.5+24 then continue end
            local x=flatten(part.CFrame.RightVector).Unit
            local z=flatten(part.CFrame.ZVector).Unit
            local u,v=if part.Size.X<=part.Size.Z then x else z,if part.Size.X<=part.Size.Z then z else x
            count+=1
            local score=(if named then 4 else 2)-math.abs(length/width-2)*3-math.abs(p.Y-part.Size.Y*.5)*.025
            if score>bestScore then best,bestScore,bestWidth,bestLength,bestU,bestV=part,score,width,length,u,v end
        end
        if not best then
            self.status="No named full court near character. Use manual A/B/C."
            return false
        end
        local center=flatten(best.Position)
        self:clearCourt()
        self.map=ReplicatedStorage:GetAttribute("Map")
        self.corners[1]=center-bestU*(bestWidth*.5)-bestV*(bestLength*.5)
        self.corners[2]=self.corners[1]+bestU*bestWidth
        self.corners[3]=self.corners[1]+bestV*bestLength
        self.courtPart=best
        self.courtSource="Auto: "..best.Name
        self.status=string.format("Detected %s (%.1f x %.1f); candidates: %d",best.Name,bestWidth,bestLength,count)
        return true
    end
    function vb:calibrationStatus()
        local a,b,c=self.corners[1],self.corners[2],self.corners[3]
        if not (a and b and c) then return "Capture missing corners A / B / C" end
        local width=(b-a).Magnitude
        if width<4 then return "A and B are too close (minimum 4 studs)" end
        local u=(b-a).Unit
        local ac=c-a
        local along=ac:Dot(u)
        local length=(ac-u*along).Magnitude
        if length<8 then return "C is too close to the A-B edge (minimum 8 studs)" end
        if math.abs(along)>width*.2 then return "C must be across the net on A's sideline, not B's" end
        return string.format("%s | %.1f x %.1f studs",self.courtSource or "Court ready",width,length)
    end
    function vb:toggleAuto()
        if self.auto then self.auto=false;detachTilt();restore(tiltKey);self.target=nil;self.status="Auto Tilt off";return end
        if not available() then self.status=self:availabilityStatus();return end
        if not geometry() then
            if not self:detectCourt() then return end
            if not geometry() then self.status=self:calibrationStatus();return end
        end
        local ok,err=pcall(attachTilt)
        if not ok then detachTilt();self.status="Tilt module unavailable: "..tostring(err);return end
        self.tiltWrites=0;self.tiltHooks=0;self.requestedTilt=nil
        self.auto=true;self.status="Local tilt correction enabled; ball response depends on style"
    end
    -- Auto Play dispatches normal game inputs; it does not bypass move validation.
    local play={set=false,spike=false,dive=false,busy=false,ownsTilt=false,status="Off",locks={},receiverTouches={},receiverActive=nil,nextLockCheck=0,lastAt=0,generation=0,attempts=0,hits=0,cameraAim="Off",groundPredict=false,cameraStatus="Off",cameraTargetAt=0,autoJump=true,jumpStatus="Off",jumpCount=0,jumpLocks={},jumpCheckAt=0,nextJumpAt=0,jumpPendingUntil=0,serve=false,serveActive=false,serveShotAttempted=false,serveStatus="Off",serveUntil=0,serveNextAt=0,serveDetectAt=0}
    vb.play=play
    local api,retryAt=nil,0
    local tags=game:GetService("CollectionService")
    local overlap=OverlapParams.new()
    overlap.FilterType=Enum.RaycastFilterType.Include
    overlap.MaxParts=1
    local function resolvePlay()
        local controllers=rf:FindFirstChild("Controllers")
        local g=controllers and controllers:FindFirstChild("GameController")
        local actions=g and g:FindFirstChild("Actions")
        local binding=actions and actions:FindFirstChild("Binding")
        local registry=binding and binding:FindFirstChild("Registry")
        local move=actions and actions:FindFirstChild("Move")
        local dm=move and move:FindFirstChild("DoMove")
        assert(g and registry and dm,"Game action modules unavailable")
        local knit=require(ReplicatedStorage.Packages.Knit)
        local c=knit.GetController("GameController")
        assert(c and c.Loaded,"GameController is loading")
        local h=require(g.Handlers)
        local bind=require(registry.DoMove)
        local tossBinding=require(registry.Toss)
        assert(type(tossBinding.onTossRequest)=="function" and type(tossBinding.canToss)=="function","Toss binding unavailable")
        local jumpBinding=require(registry.Jump)
        local jumpPhysics=require(move.Jump.Physics)
        assert(type(jumpBinding.onJumpRequest)=="function" and type(jumpPhysics.LaunchSpeed)=="number","Jump binding unavailable")
        assert(type(bind.onMoveRequest)=="function" and type(bind.canDoMove)=="function","Action binding unavailable")
        return {controller=c,tossBinding=tossBinding,jumpBinding=jumpBinding,jumpPhysics=jumpPhysics,service=knit.GetService("BallService"),config=require(ReplicatedStorage.Configuration.Game),states=h.States,values=h.Values,input=knit.GetController("InputController"),
            balls=knit.GetController("BallController"),binding=bind,orch=require(dm.Orchestrator),
            rules=require(dm.Game),special=require(dm.StyleSpecial),hitbox=require(ReplicatedStorage.Tools.Hitbox),
            joint=require(ReplicatedStorage.Tools.TiltJoint),physics=require(ReplicatedStorage.Common.Physics),
            actions=require(ReplicatedStorage.Configuration.Actions)}
    end
    local function waiting(reason)
        play.status=reason
        return nil
    end
    local function allowed(m)
        local s=m.states
        if not s.IsPlaying() then return false,"Waiting for match" end
        if s.IsStunned() then return false,"Stunned" end
        if s.IsServing() then return false,"Serving" end
        if s.IsBusy() then return false,"Move already active" end
        if m.orch.isOnCooldown() then return false,"Game cooldown" end
        if m.input.GameplaySuppressed() or game:GetService("UserInputService"):GetFocusedTextBox() then return false,"Gameplay input suppressed" end
        return true
    end
    local function candidates(m)
        local out,seen={},{}
        local function add(b)
            if typeof(b)=="Instance" and b:IsA("Model") and b.PrimaryPart and b:IsDescendantOf(workspace) and not seen[b] then
                seen[b]=true;table.insert(out,b)
            end
        end
        for _,state in pairs(m.balls.ActiveBalls) do if type(state)=="table" then add(state.Ball) end end
        for _,b in tags:GetTagged("Ball") do add(b) end
        local active=ReplicatedStorage:GetAttribute("ActiveBall")
        if active~=nil then
            for _,b in out do
                if tostring(b:GetAttribute("ServerId"))==tostring(active) or b.Name=="CLIENT_BALL_"..tostring(active) then return {b} end
            end
            return {} -- Do not receive a different ball during a round transition.
        end
        return if #out==1 then out else {}
    end
    local function ballMotion(m,b)
        local id=b:GetAttribute("ServerId")
        local state=id~=nil and m.balls.ActiveBalls[id] or nil
        if not state and id~=nil then state=m.balls.ActiveBalls[tonumber(id) or tostring(id)] end
        if not state then
            for _,s in pairs(m.balls.ActiveBalls) do if type(s)=="table" and s.Ball==b then state=s;break end end
        end
        local vel=state and state.Velocity
        if typeof(vel)~="Vector3" or vel~=vel or vel.Magnitude>500 then return nil end
        local g=ReplicatedStorage:GetAttribute("Modifier_BallGravity")
        if type(g)~="number" or g~=g then g=m.config.Physics.Gravity end
        local gm=state.GravityMultiplier
        if type(gm)~="number" or gm~=gm then gm=1 end
        local acc=Vector3.new(0,-g*gm,0)
        if typeof(state.Acceleration)=="Vector3" and state.Acceleration==state.Acceleration and state.Acceleration.Magnitude<1000 then acc+=state.Acceleration end
        local jerk=state.Jerk
        if typeof(jerk)~="Vector3" or jerk~=jerk or jerk.Magnitude>600 then jerk=Vector3.zero end
        return vel,acc,jerk
    end
    local function netTop()
        local map=workspace:FindFirstChild("Map")
        local colliders=map and map:FindFirstChild("BallCollideOnly")
        local net=colliders and colliders:FindFirstChild("Net")
        if not net or not net:IsA("BasePart") then net=tags:GetTagged("Net")[1] end
        if net and net:IsA("BasePart") then return net.Position.Y+net.Size.Y*.5 end
        return nil
    end
    local function servingShot()
        return play.serveActive or ReplicatedStorage:GetAttribute("ServedByPlayer")==player.Name
    end
    local function wantsSpike()
        return play.spike or (play.serve and play.serveActive)
    end
    local function contactAllowed(m,ball)
        if not ball or not ball.PrimaryPart or not ball:IsDescendantOf(workspace) then return false,"Ball unavailable" end
        local vel=ballMotion(m,ball)
        if not vel then return false,"Waiting for measured ball velocity" end
        if vel.Y>=-.2 then return false,"Waiting for descending ball" end
        if servingShot() then
            local top=netTop()
            if not top then return false,"Serve | net height unavailable" end
            local radius=m.config.Physics.Radius*(ReplicatedStorage:GetAttribute("Modifier_BallSizeMultiplier") or 1)
            if ball:GetPivot().Position.Y<top+radius+.25 then return false,"Serve | below net clearance" end
        end
        return true
    end
    local function ballKey(ball)
        local id=ball:GetAttribute("ServerId") or ball.Name:match("^CLIENT_BALL_(.+)$")
        return if id~=nil then "ball:"..tostring(id) else ball
    end
    local function touchKey(id)
        if id==nil then id=ReplicatedStorage:GetAttribute("ActiveBall") end
        if id==nil then return nil end
        return "ball:"..tostring(id)
    end
    local touchConnection
    local function listenTouches(m)
        if touchConnection then return end
        touchConnection=m.service.BallTouched:Connect(function(who,id)
            local key=touchKey(id)
            if not key then return end
            local lock=play.locks[key]
            if app.mode=="Game" and player:GetAttribute("Gameplay_InGame")==true and typeof(who)=="Instance" and who:IsA("Player") then
                play.receiverTouches[key]={who=who,at=os.clock()}
            end
            if who==player then
                if lock and lock.pending then play.hits+=1 end
                if play.serveActive and play.serveShotAttempted then play.serveActive=false;play.serveStatus="Serve touch confirmed" end
                if lock then
                    lock.pending=false;lock.outSince=nil;lock.at=os.clock()
                elseif play.set or play.spike or play.dive or play.serve then
                    for _,ball in candidates(m) do
                        if ballKey(ball)==key then
                            play.locks[key]={ball=ball,at=os.clock(),move="Manual",pending=false}
                            break
                        end
                    end
                end
            elseif typeof(who)=="Instance" and who:IsA("Player") then
                play.locks[key]=nil;play.jumpLocks[key]=nil
            end
        end)
    end
    local function receiveTeam(ball)
        local touch=play.receiverTouches[ballKey(ball)]
        if not touch or not touch.who or not touch.who.Parent then return false,"Waiting for confirmed opponent touch" end
        if touch.who==player then return false,"Last touch was yours" end
        if not player.Team or not touch.who.Team or player.Neutral or touch.who.Neutral then
            return false,"Waiting for confirmed teams"
        end
        if player.Team==touch.who.Team then return false,"Last touch was teammate" end
        return true
    end
    local function onOwnHalf(char,p,margin)
        local root=char.PrimaryPart
        local a,u,v,width,length=geometry()
        if a and vb.map==ReplicatedStorage:GetAttribute("Map") then
            local own=(flatten(root.Position)-a):Dot(v)
            local d=flatten(p)-a
            local x,z=d:Dot(u),d:Dot(v)
            if x< -margin or x>width+margin then return false end
            return if own<length*.5 then z>=-margin and z<=length*.5 else z>=length*.5 and z<=length+margin
        end
        -- Court zones are already used by AETHER's explicit map calibration.
        -- Read the two distinct halves directly without changing tilt settings.
        local map=workspace:FindFirstChild("Map")
        local zones=map and map:FindFirstChild("Zones")
        if not zones then return false end
        local halves={}
        for _,zone in zones:GetChildren() do
            if zone:IsA("BasePart") and zone:GetAttribute("Type")=="Court" then
                local team=tonumber(zone:GetAttribute("Team"))
                if team==1 or team==2 then
                    if halves[team] then return false end
                    halves[team]=zone
                end
            end
        end
        local first,second=halves[1],halves[2]
        if not first or not second then return false end
        local d1=flatten(root.Position-first.Position).Magnitude
        local d2=flatten(root.Position-second.Position).Magnitude
        local own,other=if d1<=d2 then first else second,if d1<=d2 then second else first
        local across=flatten(other.Position-own.Position)
        if across.Magnitude<.1 then return false end
        local midpoint=flatten((own.Position+other.Position)*.5)
        if (flatten(p)-midpoint):Dot(across.Unit)>0 then return false end
        local localPoint=own.CFrame:PointToObjectSpace(p)
        return math.abs(localPoint.X)<=own.Size.X*.5+margin and math.abs(localPoint.Z)<=own.Size.Z*.5+margin
    end
    local function receiveAllowed(m,char,ball,point,margin)
        local ok,reason=receiveTeam(ball)
        if not ok then return false,reason end
        if m.states.IsServing() or play.serveActive then return false,"Serve in progress" end
        if not onOwnHalf(char,point,margin or 0) then return false,"Waiting for ball on own court" end
        return true
    end
    local function bounds(m,char,action,pad)
        local h=m.hitbox.get({Special=m.special.getSpecial(),MoveId=action})
        if not h then return nil end
        local offset,size=h.Offset,h.Size
        if h.Custom and h.Custom.AdjustBoundsLocal then
            local a,b=h.Custom.AdjustBoundsLocal(offset,size)
            if typeof(a)=="CFrame" then offset=a end
            if typeof(b)=="Vector3" then size=b end
        end
        local c0=m.joint.get(char):GetC0()
        return char.PrimaryPart.CFrame*(c0-c0.Position)*offset,size+Vector3.one*(pad or 0)
    end
    local function overlaps(ball,transform,size)
        if not transform then return false end
        overlap.FilterDescendantsInstances={ball}
        return #workspace:GetPartBoundsInBox(transform,size,overlap)>0
    end
    local function diveRange(m)
        local mult=player:GetAttribute("Multiplier_DiveSpeed")
        if type(mult)~="number" or mult~=mult or mult<=0 then mult=1 end
        local duration=m.config.Ball.Dive.Duration*.9
        -- Default move's velocity falls approximately linearly over its duration.
        return math.clamp(36*mult*duration*.45,7,24)
    end
    local function refreshLocks(m,char,now)
        if now<play.nextLockCheck then return end
        play.nextLockCheck=now+.08
        if not next(play.locks) then return end
        local sf,ss=bounds(m,char,"Set",6)
        local pf,ps=bounds(m,char,"Spike",6)
        for key,lock in pairs(play.locks) do
            local ball=lock.ball
            if not ball or not ball.Parent or not ball:IsDescendantOf(workspace) or ballKey(ball)~=key then
                play.locks[key]=nil
            else
                local d=ball:GetPivot().Position-char.PrimaryPart.Position
                local horizontal=Vector3.new(d.X,0,d.Z).Magnitude
                local close=overlaps(ball,sf,ss) or overlaps(ball,pf,ps)
                if not sf and not pf then close=d.Magnitude<10 end
                if lock.move=="Dive" or play.dive then
                    close=close or (horizontal<diveRange(m)+4 and math.abs(d.Y)<9)
                end
                -- Never rearm from cooldown, own timestamp or transient collision changes.
                if close or now-lock.at<.35 then
                    lock.outSince=nil
                elseif not lock.outSince then
                    lock.outSince=now
                elseif now-lock.outSince>=.5 then
                    play.locks[key]=nil
                end
            end
        end
    end
    local function findReachable(m,char,action)
        local transform,size=bounds(m,char,action,0)
        if not transform then return nil,"No hitbox for "..action end
        local list=candidates(m)
        if #list==0 then return nil,"No streamed ball" end
        local chosen,best,locked=nil,math.huge,false
        local rejected
        for _,b in list do
            if overlaps(b,transform,size) then
                if play.locks[ballKey(b)] then locked=true;continue end
                if action=="Set" then
                    local valid,why=receiveAllowed(m,char,b,b:GetPivot().Position,0)
                    if not valid then rejected=why;continue end
                elseif action=="Spike" then
                    local valid,why=contactAllowed(m,b)
                    if not valid then rejected=why;continue end
                end
                local p=b:GetPivot().Position
                local distance=(p-char.PrimaryPart.Position).Magnitude
                if distance<best and m.physics.canInteract(player,action,p) and m.rules.isBallInNetBoundary(b) then
                    chosen,best=b,distance
                end
            end
        end
        if not chosen then return nil,if locked then "Touch locked | wait for next approach" else (rejected or "Ball outside "..action.." reach or game validation") end
        return chosen
    end
    local function findDive(m,char)
        local root=char.PrimaryPart
        local setTransform,setSize=bounds(m,char,"Set",0)
        local range=diveRange(m)
        local chosen,dir,best=nil,nil,math.huge
        local scale=ReplicatedStorage:GetAttribute("GlobalTimeScale")
        if type(scale)~="number" or scale~=scale then scale=1 end
        if scale<=0 then return nil,"Ball simulation paused" end
        scale=math.clamp(scale,.01,3)
        local mult=player:GetAttribute("Multiplier_DiveSpeed")
        if type(mult)~="number" or mult~=mult or mult<=0 then mult=1 end
        local hum=char:FindFirstChildOfClass("Humanoid")
        local floorY=root.Position.Y-root.Size.Y*.5-(hum and hum.HipHeight or 2)
        if hum and hum.RigType==Enum.HumanoidRigType.R6 then
            local leg=char:FindFirstChild("Left Leg")
            if leg and leg:IsA("BasePart") then floorY-=leg.Size.Y end
        end
        if vb.courtPart and vb.courtPart:IsDescendantOf(workspace) then floorY=vb.courtPart.Position.Y+vb.courtPart.Size.Y*.5 end
        for _,ball in candidates(m) do
            if play.locks[ballKey(ball)] or overlaps(ball,setTransform,setSize) or not receiveTeam(ball) then continue end
            local p=ball:GetPivot().Position
            if not m.physics.canInteract(player,"Dive",p) or not m.rules.isBallInNetBoundary(ball) then continue end
            local vel,acc,jerk=ballMotion(m,ball)
            if not vel then continue end
            local radius=tonumber(m.config.Physics.Radius) or 1.2835
            local sizeMult=ReplicatedStorage:GetAttribute("Modifier_BallSizeMultiplier")
            if type(sizeMult)~="number" or sizeMult~=sizeMult or sizeMult<=0 then sizeMult=1 end
            radius=math.clamp(radius*sizeMult,.1,10)
            local function at(t)
                local st=t*scale
                return p+vel*st+acc*(.5*st*st)+jerk*(st*st*st/6)
            end
            -- The landing must be inside our half or overlap its outside line.
            -- Use the standard dive reach; no player speed or physics writes.
            local landing,landingTime
            local previous=at(0)
            for t=.025,2,.025 do
                local point=at(t)
                if point.Y<=floorY+radius and point.Y<=previous.Y then
                    landing,landingTime=point,t;break
                end
                previous=point
            end
            if not landing or not onOwnHalf(char,landing,radius) then continue end
            local duration=math.min(.55,m.config.Ball.Dive.Duration*.9,landingTime)
            for t=.025,duration,.025 do
                local target=at(t)
                local offset=target-root.Position
                local horizontal=flatten(offset)
                local reachable=math.min(range,36*mult*t)
                if horizontal.Magnitude>=2 and horizontal.Magnitude<=reachable and offset.Y<=4 and target.Y>=floorY+radius-.1 and onOwnHalf(char,target,radius) then
                    local score=landingTime+t*.35
                    if score<best then chosen,dir,best=ball,horizontal.Unit*(7*mult),score end
                    break
                end
            end
        end
        if not chosen then return nil,"Waiting for reachable in-bounds opponent ball" end
        return chosen,dir
    end
    -- Camera assistance is independent of the hit lock and uses the local camera only.
    local cameraRay=RaycastParams.new()
    cameraRay.FilterType=Enum.RaycastFilterType.Exclude
    cameraRay.RespectCanCollide=true
    local function courtAim(root)
        local a,u,v,width,length=geometry()
        if not a then return nil end
        local rel=flatten(root.Position)-a
        local x,z=rel:Dot(u),rel:Dot(v)
        local pad=if play.serve and (play.serveActive or (api and api.states.IsServing())) then 45 else 12
        if x< -5 or x>width+5 or z< -pad or z>length+pad then return nil end
        local side=if math.abs(z-length*.5)<1 then (vb.side or (if z<length*.5 then -1 else 1)) else (if z<length*.5 then -1 else 1)
        local p=if play.cameraAim=="Free zone" or (play.serve and (play.serveActive or (api and api.states.IsServing()))) then freeZone(a,u,v,width,length,side,root,true) else nil
        local flat=a+u*(if p then p.X else width*.5)+v*(if p then p.Y else (if side==-1 then length*.75 else length*.25))
        local y=play.groundY or (root.Position.Y-4)
        if vb.courtPart and vb.courtPart.Parent then y=vb.courtPart.Position.Y+vb.courtPart.Size.Y*.5 end
        return Vector3.new(flat.X,y+1,flat.Z)
    end
    local function incomingAim(m,root)
        local a,u,v,width,length=geometry()
        if not a then return nil end
        local rel=flatten(root.Position)-a
        local ownZ=rel:Dot(v)
        local ownSide=if ownZ<length*.5 then -1 else 1
        local gravity=ReplicatedStorage:GetAttribute("Modifier_BallGravity")
        if type(gravity)~="number" or gravity~=gravity then gravity=17 end
        local scale=ReplicatedStorage:GetAttribute("GlobalTimeScale")
        if type(scale)~="number" or scale~=scale then scale=1 end
        if scale<=.01 then return nil end
        local best,distance=nil,math.huge
        for _,b in candidates(m) do
            if play.locks[ballKey(b)] then continue end
            local p=b:GetPivot().Position
            local id=b:GetAttribute("ServerId")
            local state=id~=nil and m.balls.ActiveBalls[id] or nil
            local vel=state and state.Velocity
            if typeof(vel)~="Vector3" or vel~=vel or vel.Magnitude>500 then
                vel=b.PrimaryPart.AssemblyLinearVelocity
            end
            local gm=state and state.GravityMultiplier
            if type(gm)~="number" or gm~=gm then gm=1 end
            local acc=Vector3.new(0,-gravity*gm,0)
            if state and typeof(state.Acceleration)=="Vector3" and state.Acceleration==state.Acceleration and state.Acceleration.Magnitude<1000 then acc+=state.Acceleration end
            -- Solve the descending crossing of a standing player's contact height.
            local h=p.Y-(root.Position.Y+2)
            local t=nil
            if math.abs(acc.Y)>.01 then
                local disc=vel.Y*vel.Y-2*acc.Y*h
                if disc>=0 then
                    local q=(-vel.Y-math.sqrt(disc))/acc.Y
                    if q>=0 then t=q end
                end
            elseif vel.Y< -.01 then t=-h/vel.Y end
            if not t or t<0 or t/scale>1.7 then continue end
            local target=p+vel*t+acc*(.5*t*t)
            local d=flatten(target)-a
            local x,z=d:Dot(u),d:Dot(v)
            if x< -2 or x>width+2 or (ownSide==-1 and (z< -2 or z>length*.5+2)) or (ownSide==1 and (z<length*.5-2 or z>length+2)) then continue end
            local range=flatten(target-root.Position).Magnitude
            if range>math.min(32,math.max(12,width)) or range>=distance then continue end
            if range<3 then target=p end
            best,distance=target,range
        end
        return best
    end
    function vb:stepSpikeCamera(blocked,lockActive)
        local function idle(reason)
            play.cameraPhase=nil;play.cameraPoint=nil;play.cameraTargetAt=0;play.cameraStatus=reason
        end
        if (not play.spike and not play.serve) or app.stopping or not gui.Parent or app.mode~="Game" then idle("Off");return end
        if blocked or UserInputService:GetFocusedTextBox() or game:GetService("GuiService").MenuIsOpen or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then idle("Paused | manual camera/menu");return end
        local m=api
        if not m or not m.states.IsPlaying() or m.states.IsStunned() then idle("Waiting for rally");return end
        if play.cameraAim=="Off" then idle("Manual camera");play.cameraAppliedAt=nil;return end
        local serveAim=play.serve and (m.states.IsServing() or play.serveActive)
        if not serveAim and (not play.spike or m.states.IsServing()) then idle("Off");return end
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local cam=workspace.CurrentCamera
        if not root or not hum or hum.Health<=0 or not cam or cam.CameraType~=Enum.CameraType.Custom or cam.CameraSubject~=hum then idle("Waiting for player camera");return end
        local air=m.states.IsJumping()==true
        if not air then
            play.groundY=root.Position.Y-(hum.HipHeight+root.Size.Y*.5)
            if hum.RigType==Enum.HumanoidRigType.R6 then
                local leg=char:FindFirstChild("Left Leg")
                if leg and leg:IsA("BasePart") then play.groundY-=leg.Size.Y end
            end
        end
        if not serveAim and not air and not play.groundPredict then idle("Manual ground camera");return end
        local phase=if serveAim then "Serve" elseif air then "Air" else "Ground"
        local now=os.clock()
        if phase~=play.cameraPhase or now>=play.cameraTargetAt then
            play.cameraPhase=phase;play.cameraTargetAt=now+.12
            play.cameraPoint=if air or serveAim then courtAim(root) else incomingAim(m,root)
        end
        local target=play.cameraPoint
        if not target then play.cameraStatus=if air or serveAim then "Waiting for court" else "Waiting for incoming prediction";return end
        -- Airborne aim supplies only a body heading to View. Never rotate the camera here.
        if air then
            local heading=flatten(target-root.Position)
            if heading.Magnitude<.15 then return end
            play.cameraStatus=(if serveAim then "Serve | body aim" else "Air | body aim")..(if lockActive then " | AETHER Lock" else "")
            play.cameraAppliedAt=os.clock()
            return heading.Unit
        end
        local focus=cam.Focus.Position
        local direction=target-focus
        if direction.Magnitude<.1 or flatten(direction).Magnitude<.15 then return end
        -- Rotate around the existing camera focus, keeping zoom and shoulder offset.
        local relative=cam.CFrame:PointToObjectSpace(focus)
        local orientation=CFrame.lookAt(Vector3.zero,direction)
        local offset=-orientation:VectorToWorldSpace(relative)
        local pos=focus+offset
        if offset.Magnitude>.2 then
            cameraRay.FilterDescendantsInstances={char,cam}
            local hit=workspace:Raycast(focus,offset,cameraRay)
            if hit then pos=focus+offset.Unit*math.max(.15,hit.Distance-.25) end
        end
        if (target-pos).Magnitude<.1 then return end
        cam.CFrame=CFrame.lookAt(pos,target)
        play.cameraStatus=(if serveAim then "Serve | low-activity zone" elseif air then "Air | "..play.cameraAim else "Ground | predicted contact")..(if lockActive then " | AETHER Lock" else "")
        play.cameraAppliedAt=os.clock()
    end
    local function refreshJumpLocks(m,char,now)
        if now<play.jumpCheckAt then return end
        play.jumpCheckAt=now+.12
        for key,lock in pairs(play.jumpLocks) do
            local b=lock.ball
            if not b or not b:IsDescendantOf(workspace) or ballKey(b)~=key then
                play.jumpLocks[key]=nil
            else
                local d=b:GetPivot().Position-char.PrimaryPart.Position
                local distant=flatten(d).Magnitude>22 or d.Y< -7
                if distant then
                    lock.outSince=lock.outSince or now
                    if now-lock.outSince>.6 then play.jumpLocks[key]=nil end
                else lock.outSince=nil end
            end
        end
    end
    local function jumpPrediction(m,char,hum)
        local root=char.PrimaryPart
        if not root or root.Anchored or hum.Health<=0 or hum.Sit then return nil end
        if char:GetAttribute("EmoteFrozen") or char:GetAttribute("IsWatchingCharacter") then return nil end
        if hum.FloorMaterial==Enum.Material.Air then return nil end
        local context=m.jumpBinding.buildContext(Enum.UserInputState.Begin)
        if m.jumpBinding.canDoKazanaChargeJump(context) then
            play.jumpStatus="Charge jump style | manual jump";return nil
        end
        if not m.jumpBinding.canJump(context) then return nil end
        local a,u,v,width,length=geometry()
        if not a then return nil end
        local ownZ=(flatten(root.Position)-a):Dot(v)
        local side=if ownZ<length*.5 then -1 else 1
        local aim=if play.cameraAim~="Off" then courtAim(root) else nil
        local heading=if aim then flatten(aim-root.Position) else flatten(root.CFrame.LookVector)
        if heading.Magnitude<.01 then return nil end
        heading=heading.Unit
        local h=m.hitbox.get({Special=m.special.getSpecial(),MoveId="Spike"})
        if not h or typeof(h.Offset)~="CFrame" or typeof(h.Size)~="Vector3" then return nil end
        local off,size=h.Offset,h.Size
        if h.Custom and h.Custom.AdjustBoundsLocal then
            local o,n=h.Custom.AdjustBoundsLocal(off,size)
            if typeof(o)=="CFrame" then off=o end
            if typeof(n)=="Vector3" then size=n end
        end
        local joint=m.joint.get(char):GetC0()
        local pose=CFrame.lookAt(Vector3.zero,heading)*(joint-joint.Position)*off
        local setCF,setSize=bounds(m,char,"Set",0)
        local mult=player:GetAttribute("Multiplier_JumpPower")
        if type(mult)~="number" or mult~=mult or mult<=0 then mult=1 end
        local launch=m.jumpPhysics.LaunchSpeed*mult
        local g=workspace.Gravity
        if launch<=0 or g<=0 then return nil end
        local flight=math.min(1.35,2*launch/g)
        if flight<.08 then return nil end
        local apex=launch/g
        local peak=launch*apex-.5*g*apex*apex
        local isServe=servingShot()
        local top=if isServe then netTop() else nil
        if isServe and not top then play.jumpStatus="Serve | net height unavailable";return nil end
        local scale=ReplicatedStorage:GetAttribute("GlobalTimeScale")
        if type(scale)~="number" or scale~=scale then scale=1 end
        if scale<=.01 then return nil end
        local ballG=ReplicatedStorage:GetAttribute("Modifier_BallGravity")
        if type(ballG)~="number" or ballG~=ballG then ballG=17 end
        local move=flatten(hum.MoveDirection)*math.max(0,hum.WalkSpeed)
        local best,bestPoint,bestT,bestScore=nil,nil,nil,math.huge
        for _,ball in candidates(m) do
            local key=ballKey(ball)
            if play.locks[key] or play.jumpLocks[key] then continue end
            local p=ball:GetPivot().Position
            local vel,acc,jerk=ballMotion(m,ball)
            if not vel or vel.Magnitude<.5 then continue end
            local radius=math.clamp(math.min(ball.PrimaryPart.Size.X,ball.PrimaryPart.Size.Y,ball.PrimaryPart.Size.Z)*.5,.1,3)
            for t=.06,flight,.035 do
                local bt=(t+.025)*scale
                local fallVelocity=vel.Y+acc.Y*bt+.5*jerk.Y*bt*bt
                if fallVelocity>=-.2 then continue end
                local bp=p+vel*bt+acc*(.5*bt*bt)+jerk*(bt*bt*bt/6)
                local rise=launch*t-.5*g*t*t
                if isServe and (rise<peak*.75 or bp.Y<top+radius+.25) then continue end
                if rise<.35 or bp.Y<root.Position.Y+1 then continue end
                local d=flatten(bp)-a
                local x,z=d:Dot(u),d:Dot(v)
                if x< -2 or x>width+2 or (side==-1 and (z< -2 or z>length*.5+2)) or (side==1 and (z<length*.5-2 or z>length+2)) then continue end
                local future=root.Position+move*math.max(0,t-.035)+Vector3.yAxis*rise
                local center=CFrame.new(future)*pose
                local q=center:PointToObjectSpace(bp)
                local half=size*.5
                local delta=Vector3.new(math.max(0,math.abs(q.X)-half.X),math.max(0,math.abs(q.Y)-half.Y),math.max(0,math.abs(q.Z)-half.Z))
                if delta.Magnitude>radius then continue end
                -- Do not replace an immediately reachable low Set with a marginal jump.
                if setCF and overlaps(ball,setCF,setSize) and bp.Y<root.Position.Y+2.5 then continue end
                local score=math.abs(t-apex)*.8+.025*q.Magnitude+(if isServe then -math.min(bp.Y-top,8)*.035 else t*.08)
                if score<bestScore then best,bestPoint,bestT,bestScore=ball,bp,t,score end
            end
        end
        return best,bestPoint,bestT
    end
    local function tryAutoJump(m,char,now)
        if not wantsSpike() or (not play.autoJump and not play.serveActive) then play.jumpStatus="Off";return false end
        if now<play.jumpPendingUntil then return true end
        if now<play.nextJumpAt then return false end
        play.nextJumpAt=now+.055
        if (app.ui and app.ui.opened) or app.editingHUD or game:GetService("GuiService").MenuIsOpen then
            play.jumpStatus="Paused | menu";return false
        end
        if m.states.Charge()~=nil then return false end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local valid=m.rules.isMoveInvalidOnServe("Spike")
        if not valid or m.rules.isHitboxSkipped("Spike") then play.jumpStatus="Waiting for legal Spike";return false end
        play.jumpStatus="Waiting for descending reachable prediction"
        local ball,point,t=jumpPrediction(m,char,hum)
        if not ball then return false end
        local key=ballKey(ball)
        play.jumpLocks[key]={ball=ball}
        play.jumpPendingUntil=now+.24
        play.jumpCount+=1
        play.jumpStatus=string.format("Jump | predicted contact %.2fs",t)
        play.jumpPoint=point
        play.busy=true
        local gen=play.generation
        task.spawn(function()
            local ok,err=pcall(function()
                if gen~=play.generation or not wantsSpike() or (not play.autoJump and not play.serveActive) or player.Character~=char or m.states.IsJumping() or not allowed(m) then return end
                m.jumpBinding.onJumpRequest(Enum.UserInputState.Begin)
            end)
            play.busy=false
            if not ok then play.jumpStatus="Jump error: "..tostring(err) end
        end)
        return true
    end
    -- The saved place has a two-step Toss binding. Use it, then the ordinary jump/Spike.
    local function tryAutoServe(m,char,now)
        if not play.serve then return false end
        if not m.states.IsServing() then return false end
        if play.serveActive and now<play.serveUntil then play.serveStatus="Waiting for toss transition";return true end
        play.serveActive=false
        if (app.ui and app.ui.opened) or app.editingHUD or game:GetService("GuiService").MenuIsOpen or m.input.GameplaySuppressed() then
            play.serveStatus="Paused | menu";return true
        end
        if m.states.IsStunned() or m.states.IsBusy() or m.states.IsJumping() then play.serveStatus="Waiting for ready state";return true end
        if play.cameraAim~="Off" then
            if not geometry() then
                if now>=play.serveDetectAt then
                    play.serveDetectAt=now+1
                    pcall(function() vb:detectCourt() end)
                end
                play.serveStatus="Waiting for court calibration";return true
            end
            local target=play.cameraPoint
            if play.cameraPhase~="Serve" or not target or not play.cameraAppliedAt or now-play.cameraAppliedAt>.3 then
                play.serveStatus="Waiting for serve aim";return true
            end
            local root=char.PrimaryPart
            local d=flatten(target-root.Position)
            local look=flatten(root.CFrame.LookVector)
            if d.Magnitude<.1 or look.Magnitude<.1 or d.Unit:Dot(look.Unit)<.93 then
                play.serveStatus="Waiting for alignment | AETHER Shift Lock";return true
            end
        end
        if now<play.serveNextAt then return true end
        if not m.tossBinding.canToss(Enum.UserInputState.Begin) then play.serveStatus="Toss unavailable";return true end
        local visible=m.states.IsPowerBallVisible()==true
        if not visible and m.states.Charge()~=nil then play.serveStatus="Manual charge in progress";return true end
        play.serveNextAt=now+.58
        play.busy=true
        play.serveStatus=if visible then "Tossing for jump serve" else "Preparing serve"
        local gen=play.generation
        task.spawn(function()
            local ok,err=pcall(function()
                if gen~=play.generation or not play.serve or not m.states.IsServing() or not m.tossBinding.canToss(Enum.UserInputState.Begin) then return end
                if visible then
                    -- Keep the toss vertical; the normal camera/character aim selects the shot direction.
                    m.states.TossDirection:set(Vector3.zero)
                    play.serveActive=true;play.serveShotAttempted=false;play.serveUntil=os.clock()+8
                end
                m.tossBinding.onTossRequest(Enum.UserInputState.Begin)
                -- Wait for the serving state to replicate before clearing serveActive.
            end)
            play.busy=false
            if not ok then play.serveActive=false;play.serveStatus="Toss error: "..tostring(err)
            elseif visible and play.serveActive then play.serveStatus="Waiting for high descending contact" end
        end)
        return true
    end
    local function stopPlay(reason)
        play.set=false;play.spike=false;play.dive=false;play.serve=false;play.serveActive=false;play.serveStatus="Off";play.generation+=1;table.clear(play.locks);table.clear(play.receiverTouches);play.receiverActive=nil;table.clear(play.jumpLocks);play.jumpPendingUntil=0;play.jumpStatus="Off"
        if play.ownsTilt and vb.auto then vb:toggleAuto() end
        play.ownsTilt=false;play.status=reason
    end
    function vb:togglePlay(which)
        local key=if which=="Set" then "set" elseif which=="Spike" then "spike" elseif which=="Serve" then "serve" else "dive"
        play[key]=not play[key];play.generation+=1
        if play[key] then
            retryAt=0;play.status="Waiting for game controller"
            if key=="serve" then play.serveNextAt=0;play.serveStatus="Waiting for serve turn" end
            if (key=="spike" or key=="serve") and not self.auto then
                local ok=pcall(function() self:toggleAuto() end)
                play.ownsTilt=ok and self.auto
            end
        else
            if (key=="spike" or key=="serve") and not play.spike and not play.serve and play.ownsTilt and self.auto then self:toggleAuto();play.ownsTilt=false end
            if key=="spike" and not play.serveActive then table.clear(play.jumpLocks);play.jumpPendingUntil=0;play.jumpStatus="Off" end
            if key=="serve" then play.serveActive=false;play.serveStatus="Off" end
            play.status="Auto "..which.." off"
        end
    end
    local function playTick()
        if not (play.set or play.spike or play.dive or play.serve) then return end
        if app.stopping or not gui.Parent or app.mode~="Game" then stopPlay("Off | left Game mode");return end
        if play.busy then return end
        local now=os.clock()
        if not api then
            if now<retryAt then return end
            retryAt=now+1
            local ok,m=pcall(resolvePlay)
            if not ok then return waiting("Init: "..tostring(m)) end
            listenTouches(m);api=m
        end
        local m=api
        if not m.states.IsPlaying() then table.clear(play.locks);table.clear(play.receiverTouches);play.receiverActive=nil;table.clear(play.jumpLocks);play.jumpPendingUntil=0;play.serveActive=false;return waiting("Waiting for match") end
        local activeKey=touchKey(ReplicatedStorage:GetAttribute("ActiveBall"))
        if activeKey~=play.receiverActive then
            local recent=activeKey and play.receiverTouches[activeKey]
            table.clear(play.receiverTouches)
            if recent and now-recent.at<1 then play.receiverTouches[activeKey]=recent end
            play.receiverActive=activeKey
        end
        local char=m.states.Character
        if not char or char~=player.Character or not char.PrimaryPart then return waiting("Waiting for character") end
        if m.states.IsServing() then
            table.clear(play.receiverTouches)
            if tryAutoServe(m,char,now) then return waiting(play.serveStatus) end
            return waiting("Serving manually")
        end
        if play.serveActive and (now>play.serveUntil or (ReplicatedStorage:GetAttribute("ServedByPlayer")~=nil and ReplicatedStorage:GetAttribute("ServedByPlayer")~=player.Name)) then
            play.serveActive=false;play.serveStatus="Waiting for next turn"
        end
        refreshLocks(m,char,now);refreshJumpLocks(m,char,now)
        local ready,reason=allowed(m)
        if not ready then return waiting(reason) end
        local jumping=m.states.IsJumping()==true
        if jumping then play.jumpPendingUntil=0 end
        if m.states.Charge()~=nil then return waiting("Manual charge in progress") end
        local action=if jumping then "Spike" else "Set"
        local ball,ballWhy,dir
        local function legal(move)
            if m.rules.isHitboxSkipped(move) then return false,"Game skipped consecutive hit" end
            local valid,why=m.rules.isMoveInvalidOnServe(move)
            return valid,if valid then nil else "Serve rule: "..tostring(why or move)
        end
        if jumping then
            if not wantsSpike() then return waiting("Waiting for landing") end
            local valid,why=legal("Spike")
            if not valid then return waiting(why) end
            ball,ballWhy=findReachable(m,char,"Spike")
        else
            -- A reachable receive wins over jump prediction. Dive is the fallback
            -- when Set cannot reach a descending in-bounds opponent ball.
            if play.set and not play.serveActive then
                local valid,why=legal("Set")
                if valid then ball,ballWhy=findReachable(m,char,"Set") else ballWhy=why end
            end
            if not ball and play.dive and not play.serveActive then
                local valid,why=legal("Dive")
                if valid then
                    local b,d=findDive(m,char)
                    if b then ball,dir,action=b,d,"Dive" else ballWhy=ballWhy or d end
                else ballWhy=ballWhy or why end
            end
            if not ball and tryAutoJump(m,char,now) then return waiting(play.jumpStatus) end
        end
        if not ball then return waiting(ballWhy or "Waiting for ball") end
        local key=ballKey(ball)
        if play.locks[key] or now-play.lastAt<.35 then return waiting("Touch locked | wait for next approach") end
        local request
        if action~="Dive" then
            local cfg=m.actions[action]
            if not cfg or cfg.IsAerial~=jumping then return waiting("Action configuration mismatch") end
            request={ActionName=action,IsAerial=cfg.IsAerial,InputState=Enum.UserInputState.Begin,Metadata={}}
            if not m.binding.canDoMove(request) then return waiting("Game input rejected") end
        end
        play.locks[key]={ball=ball,at=now,move=action,pending=true}
        play.lastAt=now
        play.busy=true;play.attempts+=1;play.status="Executing "..action
        local gen=play.generation
        task.spawn(function()
            local ownedCharge=false
            local dispatched=false
            local lock=play.locks[key]
            local ok,err=pcall(function()
                if gen~=play.generation or player.Character~=char or not ball.PrimaryPart or not ball:IsDescendantOf(workspace) or not allowed(m) then return end
                if action=="Set" or action=="Dive" then
                    if not receiveTeam(ball) or play.serveActive then play.locks[key]=nil;return end
                    if action=="Set" and not onOwnHalf(char,ball:GetPivot().Position,0) then play.locks[key]=nil;return end
                end
                if action=="Dive" then
                    m.controller:Dive({Target=dir})
                    dispatched=true
                    return
                end
                if action=="Spike" then
                    if not contactAllowed(m,ball) or not m.states.IsJumping() then return end
                    local a,u,v,width,length=geometry()
                    if not a or not char.PrimaryPart or vb.map~=ReplicatedStorage:GetAttribute("Map") then return end
                    local root=char.PrimaryPart
                    local z=(flatten(root.Position)-a):Dot(v)
                    local dz=flatten(root.CFrame.LookVector):Dot(v)
                    if math.abs(z-length*.5)<1 or (z<length*.5 and dz<=.15) or (z>length*.5 and dz>=-.15) then return end
                    if vb.auto and (not vb.target or not vb.tiltFresh or os.clock()-vb.tiltFresh>=.25) then return end
                end
                if jumping and vb.auto then
                    local desired=if vb.tiltFresh and os.clock()-vb.tiltFresh<.25 then (vb.requestedTilt or Vector3.yAxis) else nil
                    desired=vb:guardTilt(m.values.TiltDirection,desired)
                    if typeof(desired)=="Vector3" then lastManual=m.values.TiltDirection;lastApplied=desired;m.values.TiltDirection=desired end
                end
                if action=="Spike" and play.serveActive then play.serveShotAttempted=true;play.serveStatus="Serve Spike dispatched" end
                m.binding.onMoveRequest(request)
                dispatched=true
                ownedCharge=m.binding.AdvancedChargeAction==action and m.states.Charge()~=nil
                if ownedCharge then
                    task.wait(.06)
                    request.InputState=Enum.UserInputState.End
                    if gen==play.generation and player.Character==char and m.binding.canDoMove(request) then
                        m.binding.onMoveRequest(request)
                    end
                end
            end)
            if ownedCharge and m.binding.AdvancedChargeAction==action then pcall(m.binding.releaseHeldInput) end
            if not dispatched and lock and lock.pending and play.locks[key]==lock then play.locks[key]=nil end
            play.busy=false
            if gen==play.generation then play.status=if not ok then action.." error: "..tostring(err) elseif not dispatched then action.." cancelled | state changed" else action.." returned | attempts "..play.attempts.." | observed hits "..play.hits end
        end)
    end
    local playElapsed=0
    scope:on(RunService.Heartbeat,function(dt)
        playElapsed+=dt
        if playElapsed<.016 then return end
        playElapsed=0
        local ok,err=pcall(playTick)
        if not ok then
            api=nil;retryAt=os.clock()+1;play.status="Auto Play error: "..tostring(err)
        end
    end)
    scope:add(function()
        stopPlay("Off | unload")
        if touchConnection then touchConnection:Disconnect();touchConnection=nil end
    end)
    local elapsed=0
    scope:on(RunService.Heartbeat,function(dt)
        elapsed+=dt
        if elapsed<.1 then return end
        elapsed=0
        if app.stopping or not gui.Parent then return end
        if app.mode~="Game" then
            if next(vb.originals) or vb.auto then vb:reset() end
            return
        end
        if not vb.auto then return end
        if not available() or not physics or physics._handleTilt~=wrappedTilt then
            vb.auto=false;detachTilt();vb.status="Tilt module changed; re-enable";return
        end
        vb.requestedTilt=nil
        local ok,err=pcall(function()
            local map=ReplicatedStorage:GetAttribute("Map")
            if map~=nil and vb.map~=nil and map~=vb.map then vb:clearCourt();vb.status="Map changed; recalibrate";return end
            if map~=nil then vb.map=map end
            if vb.courtPart and not vb.courtPart:IsDescendantOf(workspace) then vb:clearCourt();vb.status="Court removed; toggle to detect again";return end
            if vb.courtZones and (not vb.courtZones[1]:IsDescendantOf(workspace) or not vb.courtZones[2]:IsDescendantOf(workspace)) then
                vb:clearCourt();vb.status="Court zones removed; toggle to detect again";return
            end
            if player:GetAttribute("Gameplay_InGame")~=true then restore(tiltKey);vb.target=nil;vb.status="Waiting for match";return end
            local a,u,v,width,length=geometry()
            if not a then vb:clearCourt();return end
            local char=player.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then restore(tiltKey);return end
            local relative=flatten(root.Position)-a
            local px,pz=relative:Dot(u),relative:Dot(v)
            local padding=if vb.courtZones then 45 else 5
            if px<-5 or px>width+5 or pz<-padding or pz>length+padding then
                restore(tiltKey);vb.target=nil;vb.status="Outside calibrated court";return
            end
            local half=length*.5
            -- Near the net, keep the last observed side instead of oscillating.
            if math.abs(pz-half)>1 then vb.side=if pz<half then -1 else 1 end
            local side=vb.side or (if pz<half then -1 else 1)
            local depth=if side==-1 then length*.75 else length*.25
            local aimPoint=if vb.play and (vb.play.spike or vb.play.serveActive) and (vb.play.cameraPhase=="Air" or vb.play.cameraPhase=="Serve") then vb.play.cameraPoint else nil
            local open=if aimPoint then Vector2.new((flatten(aimPoint)-a):Dot(u),(flatten(aimPoint)-a):Dot(v)) elseif vb.tiltAim=="Free zone" or (vb.play and vb.play.spike) then freeZone(a,u,v,width,length,side,root) else nil
            if open then depth=open.Y end
            local look=flatten(root.CFrame.LookVector)
            local dv=look:Dot(v)
            if math.abs(dv)<.15 or (depth-pz)*dv<=0 then
                releaseLocalTilt();vb.target=nil;vb.status="Face the opposite court";return
            end
            local straightLateral=px+look:Dot(u)*(depth-pz)/dv
            local margin=math.min(2,width*.2)
            local lateral=if open then open.X elseif vb.tiltAim=="Aim center" then width*.5
                elseif vb.tiltAim=="Aim left" then width*.2
                elseif vb.tiltAim=="Aim right" then width*.8
                else math.clamp(straightLateral,margin,width-margin)
            -- Court left/right are relative to the player's attacking half.
            if not open and (vb.tiltAim=="Aim left" or vb.tiltAim=="Aim right") and u:Dot(flatten(root.CFrame.RightVector))<0 then
                lateral=width-lateral
            end
            local target=a+u*lateral+v*depth
            if vb.courtZones then
                -- Clamp the target within the actual opposite zone's local rectangle.
                local opposite=vb.courtZones[if side==-1 then 2 else 1]
                local localPoint=opposite.CFrame:PointToObjectSpace(target)
                local mx=math.min(2,opposite.Size.X*.2)
                local mz=math.min(2,opposite.Size.Z*.2)
                target=flatten(opposite.CFrame:PointToWorldSpace(Vector3.new(
                    math.clamp(localPoint.X,-opposite.Size.X*.5+mx,opposite.Size.X*.5-mx),
                    0,
                    math.clamp(localPoint.Z,-opposite.Size.Z*.5+mz,opposite.Size.Z*.5-mz))))
            end
            -- Estimate lateral correction relative to the uncurved heading.
            -- This is an aiming heuristic, not a server-side impact guarantee.
            local right=flatten(root.CFrame.RightVector)
            if right.Magnitude<.01 then return end
            right=right.Unit
            local straight=a+u*straightLateral+v*depth
            local lateralError=(target-straight):Dot(right)
            local curve=math.clamp(lateralError/math.max(4,width*.15)*vb.tiltScale,-1,1)
            if math.abs(curve)<.04 then
                releaseLocalTilt();vb.target=target;vb.tiltFresh=os.clock();vb.status="Straight heading inside target; manual tilt retained";return
            end
            vb.requestedTilt=right*curve+Vector3.yAxis
            vb.tiltFresh=os.clock()
            vb.target=target
            vb.status=string.format("Tilt correction %.2f | target X %.1f Z %.1f",curve,target.X,target.Z)
        end)
        if not ok then
            vb.auto=false
            pcall(detachTilt);pcall(restore,tiltKey)
            vb.status="Auto Tilt error: "..tostring(err)
        end
    end)
    scope:add(function() vb:reset() end)
end


-- Local ball mesh radius experiment. Visual copy and guide never participate in queries.
do
    local vb=app.volleyball
    local rs=game:GetService("ReplicatedStorage")
    local tags=game:GetService("CollectionService")
    local exp={factor=2,enabled=false,show=true,status="Off",reconnects=0}
    vb.ballRadius=exp
    local entry,folder
    local searchAt=0
    local controller,controllerRetry=nil,0
    local lastActive=nil
    local lastFailure,lastFailureAt=nil,0
    local phase="idle"
    local function reportFailure(stage,err)
        local message=stage..": "..tostring(err)
        local now=os.clock()
        if message~=lastFailure or now-lastFailureAt>=5 then
            lastFailure=message;lastFailureAt=now
            app:log("Ball bounds",message)
            warn("[AETHER Ball bounds] "..message)
        end
        return message
    end
    local function clear()
        local e=entry;entry=nil
        if e and e.part.Parent then
            pcall(function()
                if e.part.Size==e.applied then e.part.Size=e.base end
                if e.part.LocalTransparencyModifier==1 then e.part.LocalTransparencyModifier=e.ltm end
            end)
        end
        if folder then folder:Destroy();folder=nil end
    end
    local function reset(reason)
        clear();searchAt=0;lastActive=nil;exp.enabled=false;exp.status=reason or "Off";lastFailure=nil
    end
    local function resolvePart(model)
        if not model or not model:IsA("Model") or not model.Name:match("^CLIENT_BALL_") or not model:IsDescendantOf(workspace) then return nil end
        local p=model.PrimaryPart
        if p and p:IsA("MeshPart") and p.CanQuery then return p end
        local found
        for _,child in model:GetChildren() do
            if child:IsA("MeshPart") and child.CanQuery then
                if found then return nil end
                found=child
            end
        end
        return found
    end
    local function resolveController()
        if controller and type(controller.ActiveBalls)=="table" then return controller end
        local now=os.clock()
        if now<controllerRetry then return nil end
        controllerRetry=now+2
        local ok,c=pcall(function() return require(rs.Packages.Knit).GetController("BallController") end)
        if ok and type(c)=="table" and type(c.ActiveBalls)=="table" then controller=c;return c end
        return nil
    end
    local function findPart()
        local seen,models={},{}
        local function add(obj)
            if typeof(obj)~="Instance" then return end
            if obj:IsA("BasePart") then obj=obj:FindFirstAncestorWhichIsA("Model") end
            if obj and not seen[obj] then
                seen[obj]=true
                if resolvePart(obj) then table.insert(models,obj) end
            end
        end
        local c=resolveController()
        if c then
            for _,state in pairs(c.ActiveBalls) do if type(state)=="table" then add(state.Ball) end end
        end
        for _,obj in tags:GetTagged("Ball") do add(obj) end
        local active=rs:GetAttribute("ActiveBall")
        local function matches(model)
            return active~=nil and (model.Name=="CLIENT_BALL_"..tostring(active) or tostring(model:GetAttribute("ServerId"))==tostring(active))
        end
        for _,model in models do if matches(model) then return resolvePart(model) end end
        if #models==0 or active~=nil then
            for _,obj in workspace:GetDescendants() do
                if obj.Name:match("^CLIENT_BALL_") then add(obj) end
            end
        end
        if active~=nil then
            for _,model in models do if matches(model) then return resolvePart(model) end end
            -- Do not bind a stale ball while the next round is loading.
            return nil
        end
        if #models==1 then return resolvePart(models[1]) end
        if entry then
            for _,model in models do if resolvePart(model)==entry.part then return entry.part end end
        end
        return nil
    end
    local function nonInteractive(p)
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        for _,tag in tags:GetTags(p) do tags:RemoveTag(p,tag) end
    end
    local function attach(p)
        clear()
        local base=p.Size
        local oldArchivable=p.Archivable
        p.Archivable=true
        local ok,copy=pcall(function() return p:Clone() end)
        p.Archivable=oldArchivable
        if not ok or not copy then error("Ball visual copy unavailable") end
        for _,child in copy:GetChildren() do
            if not (child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
        end
        for _,obj in copy:GetDescendants() do
            for _,tag in tags:GetTags(obj) do tags:RemoveTag(obj,tag) end
        end
        nonInteractive(copy);copy.Name="NormalBallVisual";copy.Size=base;copy.LocalTransparencyModifier=0
        copy.CFrame=p.CFrame
        folder=Instance.new("Folder");folder.Name="AETHER_BallHitboxPreview";folder.Parent=workspace
        copy.Parent=folder
        -- Adorn the queried part itself, not a separately sized physics part.
        -- The box is its actual oriented bounding box, not the mesh collision hull.
        local outline=Instance.new("SelectionBox")
        outline.Name="ActualBallBounds";outline.Adornee=p
        outline.Color3=Color3.fromRGB(185,125,255);outline.LineThickness=.025
        outline.SurfaceTransparency=1;outline.Transparency=.05;outline.Parent=folder
        local guide=Instance.new("SphereHandleAdornment")
        guide.Name="ApproximateBallRadius";guide.Adornee=p
        guide.Color3=outline.Color3;guide.Transparency=.94
        guide.AlwaysOnTop=false;guide.Radius=base.X*.5;guide.Parent=folder
        entry={part=p,base=base,applied=base,ltm=p.LocalTransparencyModifier,copy=copy,guide=guide,outline=outline}
        exp.reconnects+=1
    end
    function vb:setBallRadiusFactor(value)
        assert(type(value)=="number" and value==value and value>=1 and value<math.huge,"Enter a finite number >= 1")
        exp.factor=value
    end
    function vb:toggleBallRadiusGuide() exp.show=not exp.show end
    function vb:toggleBallRadius()
        if exp.enabled then reset();return end
        if app.mode~="Game" then exp.status="Switch to Game mode";return end
        exp.enabled=true;exp.status="Waiting for match ball";searchAt=0
    end
    local oldReset=vb.reset
    function vb:reset()
        reset()
        oldReset(self)
    end
    local function tick()
        if not exp.enabled then return end
        if app.stopping or not gui.Parent or app.mode~="Game" then reset("Off | left Game mode");return end
        if player:GetAttribute("Gameplay_InGame")~=true then
            if entry or folder then clear() end
            searchAt=0;lastActive=nil;exp.status="Waiting for match | auto reconnect"
            return
        end
        local active=rs:GetAttribute("ActiveBall")
        if active~=lastActive then clear();lastActive=active;searchAt=0 end
        if entry and (not entry.part:IsDescendantOf(workspace) or not entry.part.CanQuery or not folder or not folder.Parent or entry.copy.Parent~=folder or entry.guide.Parent~=folder or entry.outline.Parent~=folder) then
            clear();searchAt=0
        end
        if os.clock()>=searchAt then
            searchAt=os.clock()+(if entry then .5 else .25)
            phase="Find active ball"
            local p=findPart()
            if entry and p~=entry.part then clear() end
            phase="Create ball preview"
            if p and not entry then attach(p) end
        end
        if not entry then exp.status="Waiting for active ball | auto reconnect";return end
        local e=entry
        local p=e.part
        -- A game-side change to just one axis must not rebase the other,
        -- already-expanded axes. Compare against the actual engine readback.
        local observed=p.Size
        if observed~=e.applied then
            e.base=Vector3.new(
                if math.abs(observed.X-e.applied.X)>.0001 then observed.X else e.base.X,
                if math.abs(observed.Y-e.applied.Y)>.0001 then observed.Y else e.base.Y,
                if math.abs(observed.Z-e.applied.Z)>.0001 then observed.Z else e.base.Z)
        end
        if p.LocalTransparencyModifier~=1 then e.ltm=p.LocalTransparencyModifier end
        phase="Compute requested dimensions"
        local target=e.base*exp.factor
        if target.X>=math.huge or target.Y>=math.huge or target.Z>=math.huge then error("Size exceeds numeric range") end
        -- Remember the engine readback so clamped dimensions never compound.
        phase="Apply requested dimensions"
        if e.requested~=target or p.Size~=e.applied then p.Size=target;e.requested=target end
        e.applied=p.Size
        phase="Update visual copy"
        p.LocalTransparencyModifier=1
        e.copy.Size=e.base;e.copy.CFrame=p.CFrame
        e.copy.Transparency=p.Transparency;e.copy.Color=p.Color;e.copy.Material=p.Material
        local size=e.applied
        local round=math.abs(size.X-size.Y)<.01 and math.abs(size.X-size.Z)<.01
        phase="Update guide"
        local ok,err=pcall(function()
            e.guide.Radius=math.min(size.X,size.Y,size.Z)*.5
            e.guide.Visible=exp.show and round
            e.outline.Visible=exp.show
        end)
        local detail=""
        if not ok then
            detail=" | Guide unavailable: "..reportFailure(phase,err)
            pcall(function() e.guide.Visible=false;e.outline.Visible=false end)
        end
        local mismatch=(size-target).Magnitude>math.max(.01,target.Magnitude*1e-5)
        if mismatch then detail=detail.." | Size limited by engine" end
        exp.status=string.format("Requested %.5gx | actual XYZ %.4g / %.4g / %.4gx | bounds %.3f x %.3f x %.3f studs",exp.factor,size.X/e.base.X,size.Y/e.base.Y,size.Z/e.base.Z,size.X,size.Y,size.Z)..detail
    end
    scope:on(RunService.RenderStepped,function()
        local ok,err=pcall(tick)
        if not ok then
            clear();searchAt=os.clock()+.5
            exp.status="Retrying | "..reportFailure(phase,err)
        end
    end)
    scope:add(function() reset() end)
end

-- Read-only last-touch overlay. Counts received BallTouched events, never sends hits.
do
    local vb=app.volleyball
    local rs=game:GetService("ReplicatedStorage")
    local info={enabled=false,status="Off"}
    vb.ballTouchInfo=info
    local connection,controller,billboard,nameLabel,countLabel,trackedKey
    local records={}
    local nextAt=0
    local function key(id) return if id~=nil then tostring(id) else nil end
    local function hide()
        if billboard then billboard:Destroy();billboard=nil;nameLabel=nil;countLabel=nil end
    end
    local function reset()
        hide();table.clear(records);trackedKey=nil;controller=nil;nextAt=0
        if connection then connection:Disconnect();connection=nil end
        info.enabled=false;info.status="Off"
    end
    local function getRecord(id)
        local k=key(id)
        if not k then return nil end
        local r=records[k]
        if not r then r={count=0,last=nil,at=os.clock()};records[k]=r end
        r.at=os.clock()
        return r
    end
    local function subscribe()
        if connection and controller then return true end
        local packages=rs:FindFirstChild("Packages")
        local module=packages and packages:FindFirstChild("Knit")
        if not module then return false end
        local knit=require(module)
        controller=knit.GetController("BallController")
        if not controller or type(controller.ActiveBalls)~="table" then return false end
        local service=knit.GetService("BallService")
        if not service or not service.BallTouched then return false end
        if connection then connection:Disconnect() end
        connection=service.BallTouched:Connect(function(who,id)
            if not info.enabled or app.mode~="Game" or player:GetAttribute("Gameplay_InGame")~=true then return end
            if typeof(who)~="Instance" or not who:IsA("Player") then return end
            local r=getRecord(id or rs:GetAttribute("ActiveBall"))
            if r then r.count+=1;r.last=who.Name end
        end)
        return true
    end
    local function activeBall()
        local active=key(rs:GetAttribute("ActiveBall"))
        local onlyPart,onlyKey,count=nil,nil,0
        for id,state in pairs(controller.ActiveBalls) do
            local b=type(state)=="table" and state.Ball or nil
            if typeof(b)=="Instance" and b:IsA("Model") and b:IsDescendantOf(workspace) and b.PrimaryPart then
                local k=key(b:GetAttribute("ServerId") or id)
                if active and k==active then return b.PrimaryPart,k end
                onlyPart=b.PrimaryPart;onlyKey=k;count+=1
            end
        end
        if not active and count==1 then return onlyPart,onlyKey end
        return nil,nil
    end
    local function ensure(part)
        if not billboard or not billboard.Parent then
            hide()
            billboard=Instance.new("BillboardGui")
            billboard.Name="AETHER_BallTouchInfo"
            billboard.Size=UDim2.fromOffset(176,52)
            billboard.StudsOffsetWorldSpace=Vector3.new(0,3.1,0)
            billboard.AlwaysOnTop=false;billboard.MaxDistance=160
            billboard.LightInfluence=0;billboard.Parent=gui
            local panel=Instance.new("Frame")
            panel.BackgroundColor3=Color3.fromRGB(26,20,40);panel.BackgroundTransparency=.22
            panel.BorderSizePixel=0;panel.Size=UDim2.fromScale(1,1);panel.Parent=billboard
            local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,10);round.Parent=panel
            local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(179,131,250);stroke.Transparency=.35;stroke.Thickness=1;stroke.Parent=panel
            nameLabel=Instance.new("TextLabel")
            nameLabel.Position=UDim2.fromOffset(7,3);nameLabel.Size=UDim2.new(1,-14,0,24)
            nameLabel.BackgroundTransparency=1;nameLabel.TextColor3=Color3.fromRGB(244,237,255)
            nameLabel.Font=Enum.Font.GothamBold;nameLabel.TextSize=14;nameLabel.TextTruncate=Enum.TextTruncate.AtEnd;nameLabel.Parent=panel
            countLabel=Instance.new("TextLabel")
            countLabel.Position=UDim2.fromOffset(7,27);countLabel.Size=UDim2.new(1,-14,0,18)
            countLabel.BackgroundTransparency=1;countLabel.TextColor3=Color3.fromRGB(205,173,255)
            countLabel.Font=Enum.Font.GothamMedium;countLabel.TextSize=12;countLabel.Parent=panel
        end
        billboard.Adornee=part
        billboard.Enabled=true
    end
    function vb:toggleBallTouchInfo()
        if info.enabled then reset();return end
        info.enabled=true;info.status="Waiting for ball";nextAt=0
    end
    local oldReset=vb.reset
    function vb:reset()
        reset();oldReset(self)
    end
    local function tick()
        if not info.enabled then return end
        if app.stopping or not gui.Parent or app.mode~="Game" then reset();return end
        if not subscribe() then info.status="Waiting for BallService";return end
        if player:GetAttribute("Gameplay_InGame")~=true then
            hide();table.clear(records);trackedKey=nil;info.status="Waiting for match";return
        end
        local part,k=activeBall()
        if not part or not k then
            hide()
            if rs:GetAttribute("ActiveBall")==nil and trackedKey then records[trackedKey]=nil;trackedKey=nil end
            info.status="Waiting for active ball";return
        end
        if trackedKey and trackedKey~=k then records[trackedKey]=nil end
        trackedKey=k
        local r=getRecord(k)
        local now=os.clock()
        for other,v in pairs(records) do if other~=k and now-v.at>10 then records[other]=nil end end
        local last=r.last
        if not last and key(rs:GetAttribute("ActiveBall"))==k then
            local raw=rs:GetAttribute("LastHitter")
            if type(raw)=="string" and raw~="" and Players:FindFirstChild(raw) then last=raw end
        end
        ensure(part)
        nameLabel.Text=if last then "@"..last else "No confirmed hitter"
        countLabel.Text="Hits seen: "..tostring(r.count)
        info.status=nameLabel.Text.." | "..countLabel.Text
    end
    scope:on(RunService.Heartbeat,function()
        if not info.enabled then return end
        local now=os.clock();if now<nextAt then return end;nextAt=now+.12
        local ok,err=pcall(tick)
        if not ok then hide();nextAt=now+1;info.status="Retrying | "..tostring(err) end
    end)
    scope:add(reset)
end

-- Multi-style beta: visualize the replicated horizontal tilt vector only.
-- This does not expose input, predict a hit, or modify the game state.
do
    local vb=app.volleyball
    local esp={enabled=false,status="Off"}
    vb.jinkoDirection=esp
    local entries={}
    local folder=nil
    local elapsed=0
    local tint=Color3.fromRGB(190,150,255)
    local projectionLength=36 -- Direction guide in studs, not a ball flight model.
    -- Public names and internal aliases, including observed TheTwins special ID.
    local supported={Jester=true,Jinko=true,Rintaro=true,Sanju=true,Sanu=true,Kijo=true,Okuro=true,Twin1=true,Twin2=true,TheTwins=true}
    local function clear()
        if folder then folder:Destroy();folder=nil end
        table.clear(entries)
    end
    local function part(parent)
        local p=Instance.new("Part")
        p.Name="TiltArrow";p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.CastShadow=false;p.Material=Enum.Material.Neon;p.Color=tint;p.Parent=parent
        return p
    end
    local function make()
        if not folder then
            folder=Instance.new("Folder");folder.Name="AETHER_JinkoTiltBeta";folder.Parent=workspace
        end
        local model=Instance.new("Folder");model.Parent=folder
        local guide=part(model);guide.Name="TiltProjection";guide.Transparency=.3
        return {model=model,shaft=part(model),left=part(model),right=part(model),guide=guide}
    end
    local function segment(p,a,b,width)
        local delta=b-a
        local w=width or .12
        p.Size=Vector3.new(w,w,delta.Magnitude)
        p.CFrame=CFrame.lookAt((a+b)*.5,b)
    end
    function vb:toggleJinkoDirection()
        esp.enabled=not esp.enabled
        clear()
        esp.status=if esp.enabled then "Waiting for supported style tilt" else "Off"
    end
    local function tick(dt)
        elapsed+=dt
        if elapsed<.05 then return end
        elapsed=0
        if not esp.enabled or app.stopping or not gui.Parent or app.mode~="Game" then
            if folder then clear() end
            return
        end
        if folder and not folder.Parent then clear() end
        local camera=workspace.CurrentCamera
        local seen={}
        local count=0
        for _,other in Players:GetPlayers() do
            if other==player or other:GetAttribute("Gameplay_InGame")~=true then continue end
            local style=other:GetAttribute("Gameplay_Style")
            local special=other:GetAttribute("Gameplay_Special")
            if not supported[style] and not supported[special] then continue end
            local v=other:GetAttribute("Gameplay_TiltDirection")
            if typeof(v)~="Vector3" then continue end
            local planar=Vector3.new(v.X,0,v.Z)
            local mag=planar.Magnitude
            if mag~=mag or mag<.05 or mag>10 then continue end
            local char=other.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if not root or not root:IsA("BasePart") or not hum or hum.Health<=0 or not camera then continue end
            if (root.Position-camera.CFrame.Position).Magnitude>150 then continue end
            local dir=planar.Unit
            local right=Vector3.new(-dir.Z,0,dir.X)
            local start=root.Position+Vector3.new(0,2.6,0)
            local tip=start+dir*6
            local back=tip-dir*1.35
            local entry=entries[other]
            if not entry then entry=make();entries[other]=entry end
            segment(entry.guide,start,start+dir*projectionLength,.2)
            segment(entry.shaft,start,tip)
            segment(entry.left,tip,back+right*.75)
            segment(entry.right,tip,back-right*.75)
            seen[other]=true;count+=1
            if count>=16 then break end
        end
        for other,entry in entries do
            if not seen[other] then entry.model:Destroy();entries[other]=nil end
        end
        esp.status=if count>0 then string.format("%d active | 36-stud tilt guide | flight unverified",count) else "Waiting for supported style tilt"
    end
    scope:on(RunService.Heartbeat,tick)
    scope:add(clear)
end

-- Read-only trajectory preview. Prefer existing controller velocity and retain
-- position sampling as fallback. No network events or ball state are modified.
do
    local rs=game:GetService("ReplicatedStorage")
    local tags=game:GetService("CollectionService")
    local vb=app.volleyball
    local esp={enabled=false,status="Off",ball=nil,samples={},segments={},clock=0,searchAt=0,drawAt=0,map=nil}
    vb.trajectory=esp
    local folder,marker,billboard,caption
    local controller=nil
    local controllerAt=0
    local physicsRadius=nil
    local physicsGravity=nil
    local function resolveController()
        local packages=rs:FindFirstChild("Packages")
        local knit=packages and packages:FindFirstChild("Knit")
        if not knit then return nil end
        local ok,c=pcall(function() return require(knit).GetController("BallController") end)
        if ok and type(c)=="table" and type(c.ActiveBalls)=="table" then return c end
        return nil
    end
    local function liveState(obj)
        if not controller or not obj then return nil end
        local id=obj:GetAttribute("ServerId")
        if id==nil then return nil end
        local state=controller.ActiveBalls[id] or controller.ActiveBalls[tostring(id)] or controller.ActiveBalls[tonumber(id) or id]
        if type(state)=="table" and state.Ball==obj then return state end
        for _,candidate in pairs(controller.ActiveBalls) do if type(candidate)=="table" and candidate.Ball==obj then return candidate end end
        return nil
    end
    local function hide()
        if folder then folder:Destroy();folder=nil end
        table.clear(esp.segments);marker=nil;billboard=nil;caption=nil
    end
    local function clearSamples()
        table.clear(esp.samples);esp.ball=nil;esp.searchAt=0
    end
    local function part(name)
        local p=Instance.new("Part")
        p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.CastShadow=false;p.Material=Enum.Material.Neon;p.Transparency=.2
        p.Parent=folder
        return p
    end
    local function ensureVisual()
        if folder and folder.Parent then return end
        folder=Instance.new("Folder");folder.Name="AETHER_TrajectoryPreview";folder.Parent=workspace
        table.clear(esp.segments)
        for i=1,72 do
            local p=part("Segment");p.Transparency=1;esp.segments[i]=p
        end
        marker=part("Landing");marker.Shape=Enum.PartType.Ball;marker.Size=Vector3.new(1.4,1.4,1.4)
        billboard=Instance.new("BillboardGui");billboard.Size=UDim2.fromOffset(132,32)
        billboard.StudsOffsetWorldSpace=Vector3.new(0,2,0);billboard.AlwaysOnTop=true;billboard.Parent=marker
        caption=Instance.new("TextLabel");caption.Size=UDim2.fromScale(1,1);caption.BackgroundTransparency=1
        caption.Font=Enum.Font.GothamBold;caption.TextSize=15;caption.TextStrokeTransparency=.2;caption.Parent=billboard
    end
    local function finite(v) return v==v and v.Magnitude<1e6 end
    local function ballPosition(obj)
        if not obj or not obj:IsDescendantOf(workspace) then return nil end
        if obj:IsA("Model") then return if obj.PrimaryPart then obj.PrimaryPart.Position else obj:GetPivot().Position end
        if obj:IsA("BasePart") then return obj.Position end
    end
    local function findBall()
        local candidates,seen={},{}
        local function add(obj)
            if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name:match("^CLIENT_BALL_") then obj=obj.Parent end
            if not seen[obj] and ballPosition(obj) then seen[obj]=true;table.insert(candidates,obj) end
        end
        if controller then for _,state in pairs(controller.ActiveBalls) do if type(state)=="table" and typeof(state.Ball)=="Instance" then add(state.Ball) end end end
        for _,obj in tags:GetTagged("Ball") do add(obj) end
        for _,obj in workspace:GetDescendants() do
            if obj.Name:match("^CLIENT_BALL_") then add(obj) end
        end
        local active=rs:GetAttribute("ActiveBall")
        if active~=nil then
            for _,obj in candidates do
                local serverId=obj:GetAttribute("ServerId")
                if obj.Name=="CLIENT_BALL_"..tostring(active) or (serverId~=nil and tostring(serverId)==tostring(active)) then return obj end
            end
            return nil -- Never substitute a stale ball for an explicit active ID.
        end
        local client={}
        for _,obj in candidates do if obj.Name:match("^CLIENT_BALL_") then table.insert(client,obj) end end
        if #client==1 then return client[1] end
        if #candidates==1 then return candidates[1] end
        -- Do not silently predict a different ball in a multi-ball training session.
        return nil
    end
    local function courtColor(p,radius)
        local found=false
        for _,line in tags:GetTagged("Courtlines") do
            if line:IsA("BasePart") and line:IsDescendantOf(workspace) then
                local d=line.CFrame:PointToObjectSpace(p)
                if math.abs(d.Y)<=10+line.Size.Y*.5 then
                    found=true
                    local dx=math.max(0,math.abs(d.X)-line.Size.X*.5)
                    local dz=math.max(0,math.abs(d.Z)-line.Size.Z*.5)
                    if dx*dx+dz*dz<=radius*radius then return Color3.fromRGB(75,255,145),"IN" end
                end
            end
        end
        if found then return Color3.fromRGB(255,80,100),"OUT" end
        return Color3.fromRGB(255,205,100),"UNKNOWN COURT"
    end
    local function radiusOf(obj)
        if obj.Name:match("^CLIENT_BALL_") or liveState(obj) then
            local m=rs:GetAttribute("Modifier_BallSizeMultiplier")
            if type(m)~="number" or m~=m or m<=0 then m=1 end
            return math.clamp((physicsRadius or 1.2835)*m,.05,50)
        end
        local p=if obj:IsA("Model") then obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true) else obj
        if p and p:IsA("BasePart") then return math.clamp(math.min(p.Size.X,p.Size.Y,p.Size.Z)*.5,.25,12) end
        return 1
    end
    local function estimate(samples)
        -- Least squares quadratic fit, centered on the latest sample.
        -- Scaling time avoids tiny determinants at high frame rates.
        local last=samples[#samples];local span=last.t-samples[1].t
        if #samples<5 or span<.12 then return nil end
        local s1,s2,s3,s4=0,0,0,0
        local y0,y1,y2=Vector3.zero,Vector3.zero,Vector3.zero
        for _,s in samples do
            local x=(s.t-last.t)/span;local x2=x*x
            local y=s.p-last.p
            s1+=x;s2+=x2;s3+=x2*x;s4+=x2*x2
            y0+=y;y1+=y*x;y2+=y*x2
        end
        local n=#samples
        local a=s2-s1*s1/n;local b=s3-s1*s2/n;local c=s4-s2*s2/n
        local d=y1-y0*(s1/n);local e=y2-y0*(s2/n)
        local det=a*c-b*b
        if det<1e-8 then return nil end
        local velocity=(d*c-e*b)/det/span
        local acceleration=(e*a-d*b)/det*(2/(span*span))
        if not finite(velocity) or not finite(acceleration) or velocity.Magnitude>1800 or acceleration.Magnitude>2500 then return nil end
        return velocity,acceleration
    end
    local function velocityAcceleration(samples,timeScale)
        local n=0;local st,stt=0,0;local sv,stv=Vector3.zero,Vector3.zero
        local last=samples[#samples]
        local firstTime=nil
        for _,s in samples do
            if not s.v then continue end
            firstTime=firstTime or s.t
            local t=(s.t-last.t)*timeScale
            n+=1;st+=t;stt+=t*t;sv+=s.v;stv+=s.v*t
        end
        local det=n*stt-st*st
        if n<4 or not firstTime or (last.t-firstTime)<.10 or det<1e-7 then return nil end
        local a=(stv*n-sv*st)/det
        if finite(a) and a.Magnitude<600 then return a end
        return nil
    end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    local filterAt=0
    local function refreshMap(map)
        local valid={}
        for _,p in map:GetDescendants() do
            if not p:IsA("BasePart") or not p.CanQuery then continue end
            local skip=false;local cur=p
            while cur and cur~=map do
                if cur:HasTag("BallNoCollide") then skip=true;break end
                cur=cur.Parent
            end
            if not skip then table.insert(valid,p) end
        end
        params.FilterDescendantsInstances=valid
        filterAt=esp.clock+.75
    end
    local function draw(pos,vel,acc,ball,map,timeScale,source,jerk)
        if esp.clock>=filterAt then refreshMap(map) end
        local radius=radiusOf(ball)
        local points={pos};local hit,hitTime
        for i=1,72 do
            local t=i*.05
            local nextPos,result,contactTime=U.ballSweep(pos,vel,acc,jerk,t-.05,t,radius,params)
            table.insert(points,nextPos)
            if result then hit=result;hitTime=contactTime;break end
        end
        if #points<2 then hide();esp.status="Waiting for movement";return end
        local color,label=Color3.fromRGB(175,155,255),"NO CONTACT"
        if hit then
            if hit.Normal.Y>.5 and not hit.Instance:GetAttribute("IsNet") then
                color,label=courtColor(hit.Position,radius)
            else
                color,label=Color3.fromRGB(255,205,100),"OBSTACLE"
            end
        end
        ensureVisual()
        for i,p in esp.segments do
            local a,b=points[i],points[i+1]
            if a and b and (b-a).Magnitude>.001 then
                p.Size=Vector3.new(.14,.14,(b-a).Magnitude);p.CFrame=CFrame.lookAt((a+b)*.5,b)
                p.Color=color;p.Transparency=.2
            else p.Transparency=1 end
        end
        marker.Transparency=if hit then .12 else 1
        billboard.Enabled=hit~=nil
        if hit then marker.Position=hit.Position+hit.Normal*.25;marker.Color=color;caption.Text=string.format("%s ~%.2fs",label,math.max(0,hitTime/timeScale-vb:visualDelay()));caption.TextColor3=color end
        esp.status=string.format("%s | %s | %.1f studs/s | %s",ball.Name,label,vel.Magnitude,source)
    end
    function vb:toggleTrajectory()
        esp.enabled=not esp.enabled;clearSamples();hide()
        controller=nil;controllerAt=0;esp.lastActive=nil
        esp.status=if esp.enabled then "Waiting for moving ball" else "Off"
    end
    local function tick(dt)
        esp.clock+=dt
        if not esp.enabled or app.stopping or not gui.Parent or app.mode~="Game" then
            if folder then hide() end
            if esp.ball then clearSamples() end
            if esp.enabled then esp.status="Waiting for Game mode" end
            return
        end
        local map=workspace:FindFirstChild("Map")
        if map~=esp.map then esp.map=map;clearSamples();hide();filterAt=0 end
        if not map then esp.status="Waiting for map";return end
        local active=rs:GetAttribute("ActiveBall")
        if esp.lastActive~=active then esp.lastActive=active;clearSamples();hide() end
        if not controller and esp.clock>=controllerAt then
            controllerAt=esp.clock+2;controller=resolveController()
            local ok,cfg=pcall(function() return require(rs.Configuration.Game).Physics end)
            if ok and type(cfg)=="table" then
                if type(cfg.Radius)=="number" and cfg.Radius>0 and cfg.Radius<50 then physicsRadius=cfg.Radius end
                if type(cfg.Gravity)=="number" and cfg.Gravity>0 and cfg.Gravity<1000 then physicsGravity=cfg.Gravity end
            end
        end
        if not ballPosition(esp.ball) and esp.clock>=esp.searchAt then
            clearSamples();esp.ball=findBall();esp.searchAt=esp.clock+.6
        end
        local pos=ballPosition(esp.ball)
        if not pos then hide();esp.status="Waiting for one identifiable client ball";return end
        local scale=rs:GetAttribute("GlobalTimeScale")
        if type(scale)~="number" or scale~=scale then scale=1 end
        if scale<=.01 then hide();table.clear(esp.samples);esp.status="Simulation paused";return end
        scale=math.clamp(scale,.01,20)
        if esp.lastScale~=scale then table.clear(esp.samples);esp.lastScale=scale end
        local state=liveState(esp.ball)
        local direct=state and state.Velocity
        if typeof(direct)~="Vector3" or not finite(direct) or direct.Magnitude>1800 then direct=nil end
        local samples=esp.samples;local last=samples[#samples]
        if last and (esp.clock-last.t>.25 or (pos-last.p).Magnitude>80 or (direct and last.v and (direct-last.v).Magnitude>85)) then table.clear(samples);last=nil end
        if not last or esp.clock-last.t>=.025 then
            table.insert(samples,{t=esp.clock,p=pos,v=direct})
            while #samples>1 and esp.clock-samples[1].t>.24 do table.remove(samples,1) end
        end
        if esp.clock<esp.drawAt then return end
        esp.drawAt=esp.clock+.05
        local vel,acc,jerk,source
        jerk=Vector3.zero
        if direct then
            vel=direct
            local g=rs:GetAttribute("Modifier_BallGravity")
            if type(g)~="number" or g~=g or math.abs(g)>1000 then g=physicsGravity or 17 end
            local gm=state.GravityMultiplier
            if type(gm)~="number" or gm~=gm or math.abs(gm)>100 then gm=1 end
            local gravity=Vector3.new(0,-g*gm,0)
            if typeof(state.Acceleration)=="Vector3" and finite(state.Acceleration) then
                acc=gravity+state.Acceleration
                source="Controller physics"
                if typeof(state.Jerk)=="Vector3" and finite(state.Jerk) and state.Jerk.Magnitude<600 then jerk=state.Jerk end
            else
                acc=velocityAcceleration(samples,scale) or gravity
                source="Controller velocity"
            end
        else
            vel,acc=estimate(samples)
            if vel then vel=vel/scale;acc=acc/(scale*scale) end
            source="Position fallback"
        end
        if not vel or not acc or not finite(vel) or not finite(acc) or vel.Magnitude<3 then hide();esp.status="Sampling moving ball";return end
        draw(pos,vel,acc,esp.ball,map,scale,source,jerk)
    end
    scope:on(RunService.Heartbeat,function(dt)
        local ok,err=pcall(tick,dt)
        if not ok then esp.enabled=false;hide();clearSamples();esp.status="Trajectory error: "..tostring(err) end
    end)
    scope:add(function() esp.enabled=false;hide();clearSamples() end)
end

-- Read-only next-shot estimate. Learn observed launch velocities rather than
-- inventing an authoritative server spike/serve formula.
do
    local rs=game:GetService("ReplicatedStorage")
    local vb=app.volleyball
    local arc={enabled=false,mode="Auto",status="Off"}
    vb.shotArc=arc
    local controller,handlers,config,connection,styleController,specialController
    local learned,pending={},nil
    local folder,marker,caption
    local segments={}
    local nextAt,retryAt,filterAt,errorUntil=0,0,0,0
    local lastDraw,visibleCount=nil,0
    local SEGMENTS,STEP,INTERVAL=64,.0625,1/30
    local map
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    local function flat(v) return Vector3.new(v.X,0,v.Z) end
    local function stat(name)
        local v=player:GetAttribute("Multiplier_"..name)
        return if type(v)=="number" and v==v and v>0 and v<100 then v else 1
    end
    local function rootPart()
        local char=player.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    local function kind()
        if handlers.States.IsServing() or (vb.play and vb.play.serveActive) then return "Serve" end
        return if handlers.States.IsJumping() then "Spike" else "Set"
    end
    local function power(k) return stat(if k=="Spike" then "SpikePower" elseif k=="Serve" then "ServePower" else "SetPower") end
    local function facing(root)
        local f=flat(root.CFrame.LookVector)
        return if f.Magnitude>.01 then f.Unit else Vector3.zAxis
    end
    local function tilt(root)
        local t=handlers.Values.TiltDirection
        if typeof(t)~="Vector3" then t=player:GetAttribute("Gameplay_TiltDirection") end
        if typeof(t)~="Vector3" or t~=t or t.Magnitude>100 then return 0,0 end
        local f=facing(root);local right=Vector3.new(-f.Z,0,f.X)
        -- Roblox right vector: use the character basis to avoid inverted tilt.
        local r=flat(root.CFrame.RightVector)
        if r.Magnitude>.01 then right=r.Unit end
        return math.clamp(flat(t):Dot(right),-1,1),math.clamp(flat(t):Dot(f),-1,1)
    end
    local aliases={Jester="Jinko",Jinko="Jinko",Sanu="Sanju",Sanju="Sanju",Kijo="Kijo",Twin1="Twins",Twin2="Twins",TheTwins="Twins",Twins="Twins"}
    local function identifier(value)
        if type(value)=="string" and #value>0 then return value end
        if type(value)=="table" then
            local id=value.Id or value.Name
            if type(id)=="string" and #id>0 then return id end
        end
        return nil
    end
    local function styleIdentity()
        local id=identifier(player:GetAttribute("Gameplay_Style"))
        local sp=identifier(player:GetAttribute("Gameplay_Special"))
        if styleController then
            local ok,value=pcall(function() return styleController.Style() end)
            if ok then id=identifier(value) or id end
        end
        if specialController then
            local ok,value=pcall(function() return specialController.Special() end)
            if ok then sp=identifier(value) or sp end
        end
        id=id or sp or "Unknown"
        sp=sp or "-"
        -- Keep internal variants separate even when their public display names match.
        return id.."|"..sp,aliases[id] or aliases[sp] or id
    end
    local function bin(x)
        if x<-.08 then return -1 elseif x>.08 then return 1 else return 0 end
    end
    local function keyFor(style,k,t,back)
        return style.."|"..k.."|"..bin(t).."|"..bin(back)
    end
    local function validVec(v,limit)
        return typeof(v)=="Vector3" and v==v and v.Magnitude<limit
    end
    local function localVec(v,f,r)
        return Vector3.new(v:Dot(r),v.Y,v:Dot(f))
    end
    local function worldVec(v,f,r)
        return r*v.X+Vector3.yAxis*v.Y+f*v.Z
    end
    local function gravity()
        local g=rs:GetAttribute("Modifier_BallGravity")
        if type(g)~="number" or g~=g or g<=0 or g>1000 then g=config.Physics.Gravity end
        return if type(g)=="number" and g==g and g>0 and g<1000 then g else 17
    end
    local function stateFor(id)
        if not controller then return nil end
        local active=id or rs:GetAttribute("ActiveBall")
        local one,count=nil,0
        for index,state in pairs(controller.ActiveBalls) do
            local b=type(state)=="table" and state.Ball
            if typeof(b)=="Instance" and b:IsA("Model") and b.PrimaryPart and b:IsDescendantOf(workspace) then
                if active~=nil and tostring(b:GetAttribute("ServerId") or index)==tostring(active) then return state end
                one=state;count+=1
            end
        end
        return if active==nil and count==1 then one else nil
    end
    local function hide()
        if folder then folder:Destroy();folder=nil end
        table.clear(segments);marker=nil;caption=nil;lastDraw=nil;visibleCount=0
    end
    local function stop()
        hide();pending=nil
        if connection then connection:Disconnect();connection=nil end
        controller=nil;handlers=nil;config=nil;styleController=nil;specialController=nil;arc.enabled=false;arc.status="Off"
    end
    local function connect()
        if connection and controller and handlers and config then return true end
        if os.clock()<retryAt then return false end
        retryAt=os.clock()+2
        local knit=require(rs.Packages.Knit)
        controller=knit.GetController("BallController")
        local gc=game:GetService("ReplicatedFirst"):FindFirstChild("Controllers")
        gc=gc and gc:FindFirstChild("GameController")
        if not gc or not controller or type(controller.ActiveBalls)~="table" then return false end
        handlers=require(gc.Handlers)
        config=require(rs.Configuration.Game)
        local ok,c=pcall(function() return knit.GetController("StyleController") end)
        styleController=if ok then c else nil
        local ok2,c2=pcall(function() return knit.GetController("SpecialController") end)
        specialController=if ok2 then c2 else nil
        local svc=knit.GetService("BallService")
        connection=svc.BallTouched:Connect(function(who,id)
            if who~=player or not arc.enabled then return end
            local root=rootPart()
            if not root then return end
            local st=stateFor(id)
            if not st then return end
            local k=kind()
            local style=styleIdentity()
            local side,back=tilt(root)
            local right=flat(root.CFrame.RightVector)
            if right.Magnitude<.01 then return end
            pending={id=id,k=k,at=os.clock(),before=st.Velocity,forward=facing(root),right=right.Unit,power=power(k),tilt=side,back=back,tiltPower=stat("TiltPower"),key=keyFor(style,k,side,back)}
        end)
        return true
    end
    local function sample(now)
        if not pending then return end
        local p=pending
        local st=stateFor(p.id)
        local elapsed=now-p.at
        if elapsed>.4 or not st then pending=nil;return end
        local v=st.Velocity
        if elapsed<.035 or not validVec(v,1800) or v.Magnitude<2 then return end
        if validVec(p.before,1800) and (v-p.before).Magnitude<2 then return end
        local scale=rs:GetAttribute("GlobalTimeScale")
        if type(scale)~="number" or scale~=scale or scale<=0 or scale>20 then scale=1 end
        local gm=st.GravityMultiplier
        if type(gm)~="number" or gm~=gm or math.abs(gm)>100 then gm=1 end
        local g=gravity()
        local extra=if validVec(st.Acceleration,1000) then st.Acceleration else nil
        local jerk=if validVec(st.Jerk,600) then st.Jerk else Vector3.zero
        if not p.firstV then
            p.firstV=v;p.firstAt=now
        end
        -- Allow time for the post-action curve physics to appear.
        if elapsed<.11 then return end
        local dt=(now-p.firstAt)*scale
        local measured=dt>=.035 and (v-p.firstV)/dt or nil
        if not extra then
            extra=if validVec(measured,1000) then measured+Vector3.yAxis*(g*gm) else Vector3.zero
        end
        -- Rewind only the interval between observed velocity samples.
        -- Event receipt time is not the authoritative contact timestamp.
        local simTime=math.max(0,(now-p.firstAt)*scale)
        local acceleration=extra-Vector3.yAxis*(g*gm)
        local launch=v-acceleration*simTime+jerk*(.5*simTime*simTime)
        if not validVec(launch,1800) or flat(launch):Dot(p.forward)<1 then pending=nil;return end
        local record={velocity=localVec(launch,p.forward,p.right),power=p.power,
            acceleration=localVec(extra,p.forward,p.right),jerk=localVec(jerk,p.forward,p.right),
            gm=gm,tilt=p.tilt*p.tiltPower,back=p.back*p.tiltPower}
        local history=learned[p.key]
        if not history then history={};learned[p.key]=history end
        table.insert(history,record)
        if #history>12 then table.remove(history,1) end
        pending=nil;lastDraw=nil
    end
    -- Retain recent observations rather than replacing a calibration with the
    -- last hit. Prefer nearby tilt values within the same style/action bin.
    local function calibration(key,t,back,strength)
        local history=learned[key]
        if not history or #history==0 then return nil end
        local weightSum=0
        local m={velocity=Vector3.zero,acceleration=Vector3.zero,jerk=Vector3.zero,gm=0,tilt=0,back=0,count=#history}
        local candidates={}
        for _,r in history do
            local powerDistance=math.abs(math.log(math.max(.001,r.power)/math.max(.001,strength)))
            local distance=(r.tilt-t)^2+(r.back-back)^2+4*powerDistance^2
            table.insert(candidates,{r=r,w=1/(.035+distance),powerDistance=powerDistance})
        end
        table.sort(candidates,function(a,b) return a.w>b.w end)
        local anchor=candidates[1].r.velocity
        local nearest=candidates[1].powerDistance
        if nearest>.18 then return nil end
        local used=0
        for _,item in candidates do
            if item.powerDistance>math.min(.18,nearest+.07) then continue end
            local r=item.r
            local residual=(r.velocity-anchor).Magnitude/math.max(10,anchor.Magnitude)
            local w=item.w/(1+4*residual*residual)
            weightSum+=w;used+=1
            m.velocity+=r.velocity*w;m.acceleration+=r.acceleration*w;m.jerk+=r.jerk*w
            m.gm+=r.gm*w;m.tilt+=r.tilt*w;m.back+=r.back*w
        end
        if weightSum<=0 then return nil end
        m.count=used
        m.velocity/=weightSum;m.acceleration/=weightSum;m.jerk/=weightSum
        m.gm/=weightSum;m.tilt/=weightSum;m.back/=weightSum
        return m
    end
    local function makePart(name)
        local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(197,143,255);p.Transparency=1;p.Parent=folder
        return p
    end
    local function visual()
        if folder and folder.Parent then return end
        hide();folder=Instance.new("Folder");folder.Name="AETHER_ShotArc";folder.Parent=workspace
        for i=1,SEGMENTS do segments[i]=makePart("Arc") end
        marker=makePart("Landing");marker.Shape=Enum.PartType.Ball;marker.Size=Vector3.new(.9,.9,.9)
        local bb=Instance.new("BillboardGui");bb.Size=UDim2.fromOffset(126,28);bb.StudsOffsetWorldSpace=Vector3.new(0,1.2,0);bb.AlwaysOnTop=false;bb.Parent=marker
        caption=Instance.new("TextLabel");caption.BackgroundTransparency=1;caption.Size=UDim2.fromScale(1,1);caption.TextSize=13;caption.Font=Enum.Font.GothamBold;caption.TextColor3=marker.Color;caption.TextStrokeTransparency=.25;caption.Parent=bb
    end
    local function invisible()
        if not folder then return end
        for i=1,visibleCount do segments[i].Transparency=1 end
        visibleCount=0;lastDraw=nil
        marker.Transparency=1;caption.Text=""
    end
    function vb:toggleShotArc()
        if arc.enabled then stop();return end
        arc.enabled=true;arc.status="Waiting for your first hit";retryAt=0;nextAt=0;errorUntil=0
    end
    local function tick()
        if not arc.enabled then return end
        local now=os.clock()
        if app.stopping or not gui.Parent or app.mode~="Game" then stop();return end
        if now<errorUntil then return end
        if not connect() then arc.status="Waiting for game data";return end
        sample(now)
        if now<nextAt then return end;nextAt=now+INTERVAL
        if player:GetAttribute("Gameplay_InGame")~=true then invisible();pending=nil;arc.status="Waiting for match";return end
        local root=rootPart()
        local st=stateFor(nil)
        if not root or not st or not st.Ball.PrimaryPart then invisible();arc.status="Waiting for active ball";return end
        local k=if arc.mode=="Auto" then kind() else arc.mode
        local origin=st.Ball.PrimaryPart.Position
        if (origin-root.Position).Magnitude>18 then invisible();arc.status="Waiting for nearby ball";return end
        local style,styleName=styleIdentity()
        local f=facing(root);local rv=flat(root.CFrame.RightVector)
        if rv.Magnitude<.01 then invisible();return end
        local right=rv.Unit
        local t,back=tilt(root)
        local tp=stat("TiltPower")
        local strength=power(k)
        local m=calibration(keyFor(style,k,t,back),t*tp,back*tp,strength)
        local v,source
        local extra,jerk,gm=Vector3.zero,Vector3.zero,1
        if m then
            local factor=1
            if math.abs(m.tilt)>.08 and math.abs(t*tp)>.08 then factor=math.clamp((t*tp)/m.tilt,.25,2.5)
            elseif math.abs(m.back)>.08 and math.abs(back*tp)>.08 then factor=math.clamp((back*tp)/m.back,.25,2.5) end
            local vv=m.velocity
            v=worldVec(Vector3.new(vv.X*factor,vv.Y,vv.Z),f,right)
            local av=m.acceleration;local jv=m.jerk
            extra=worldVec(Vector3.new(av.X*factor,av.Y,av.Z),f,right)
            jerk=worldVec(Vector3.new(jv.X*factor,jv.Y,jv.Z),f,right)
            gm=m.gm
            source="Learned "..tostring(m.count).." hits | power "..string.format("%.2f",strength)
        elseif k=="Set" and bin(t)==0 and bin(back)==0 then
            local c=config.Ball.Set
            local range=c.VerticalVelocity
            local move=player.Character:FindFirstChildOfClass("Humanoid")
            v=(f*c.LookVectorHorizontalVelocity+(move and flat(move.MoveDirection) or Vector3.zero)*c.MoveHorizontalVelocity+Vector3.yAxis*((range.Min+range.Max)*.5))*strength
            source="Config estimate"
        else
            invisible();arc.status=styleName.." | Make a "..k.." hit with this tilt and power to calibrate";return
        end
        if not validVec(v,1800) then invisible();arc.status="Invalid launch sample";return end
        local currentMap=workspace:FindFirstChild("Map")
        if not currentMap then invisible();arc.status="Waiting for map";return end
        if currentMap~=map or now>=filterAt then
            map=currentMap;filterAt=now+4;lastDraw=nil
            local parts={}
            for _,p in map:GetDescendants() do
                if p:IsA("BasePart") and p.CanQuery then
                    local skip=false;local node=p
                    while node and node~=map do if node:HasTag("BallNoCollide") then skip=true;break end;node=node.Parent end
                    if not skip then table.insert(parts,p) end
                end
            end
            params.FilterDescendantsInstances=parts
        end
        local g=gravity()
        local acceleration=extra-Vector3.yAxis*(g*gm)
        local radius=config.Physics.Radius
        if type(radius)~="number" or radius~=radius or radius<=0 then radius=1.2835 end
        local multiplier=tonumber(rs:GetAttribute("Modifier_BallSizeMultiplier")) or 1
        if multiplier~=multiplier or multiplier<=0 then multiplier=1 end
        radius=math.clamp(radius*multiplier,.05,50)
        local delay=vb:visualDelay()
        if delay>0 and validVec(st.Velocity,1800) then
            local scale=rs:GetAttribute("GlobalTimeScale")
            if type(scale)~="number" or scale~=scale or scale<=0 or scale>20 then scale=1 end
            local incomingG=st.GravityMultiplier
            if type(incomingG)~="number" or incomingG~=incomingG or math.abs(incomingG)>100 then incomingG=1 end
            local incomingA=(if validVec(st.Acceleration,1000) then st.Acceleration else Vector3.zero)-Vector3.yAxis*(g*incomingG)
            local incomingJ=if validVec(st.Jerk,600) then st.Jerk else Vector3.zero
            local predicted,obstacle=U.ballSweep(origin,st.Velocity,incomingA,incomingJ,0,delay*scale,radius,params)
            if not obstacle and (predicted-origin).Magnitude<=18 then origin=predicted end
        end
        visual()
        local ld=lastDraw
        if ld and now-ld.at<.15 and (ld.origin-origin).Magnitude<.025 and (ld.v-v).Magnitude<.06 and (ld.a-acceleration).Magnitude<.1 and (ld.j-jerk).Magnitude<.1 and ld.radius==radius then return end
        lastDraw={at=now,origin=origin,v=v,a=acceleration,j=jerk,radius=radius}
        local prev=origin;local hit
        local count=0
        for i=1,SEGMENTS do
            local time=i*STEP
            local target,result=U.ballSweep(origin,v,acceleration,jerk,time-STEP,time,radius,params)
            hit=result
            if (target-prev).Magnitude>.001 then
                local part=segments[i]
                part.Size=Vector3.new(.15,.15,(target-prev).Magnitude);part.CFrame=CFrame.lookAt((prev+target)*.5,target)
                if i>visibleCount then part.Transparency=.15 end
                count=i
            end
            prev=target
            if hit then break end
        end
        for i=count+1,visibleCount do segments[i].Transparency=1 end
        visibleCount=count
        marker.Transparency=if hit then .15 else 1
        if hit then marker.Position=hit.Position+hit.Normal*.15 end
        caption.Text=if hit then (if hit.Normal.Y>.5 then "EST. LANDING" else "EST. CONTACT") else ""
        arc.status=styleName.." | "..k.." | "..source.." | Tilt "..string.format("%.2f / %.2f",t,back).." | 30 Hz target"
    end
    scope:on(RunService.Heartbeat,function()
        if not arc.enabled then return end
        local ok,err=pcall(tick)
        if not ok then hide();arc.status="Retrying | "..tostring(err);errorUntil=os.clock()+1;nextAt=errorUntil end
    end)
    scope:add(stop)
end

-- Save only deliberate UI changes, not transient runtime cleanup or match resets.
local moduleSwitches={
    {"vbBallRadius",function(v) return v.ballRadius.enabled end,function(v) v:toggleBallRadius() end},
    {"vbBallTouchInfo",function(v) return v.ballTouchInfo.enabled end,function(v) v:toggleBallTouchInfo() end},
    {"vbShotArc",function(v) return v.shotArc.enabled end,function(v) v:toggleShotArc() end},
    {"vbTrajectory",function(v) return v.trajectory.enabled end,function(v) v:toggleTrajectory() end},
    {"vbDirection",function(v) return v.jinkoDirection.enabled end,function(v) v:toggleJinkoDirection() end},
    {"vbRepeatTouch",function(v) return v.repeatTouch.enabled end,function(v) v:toggleRepeatTouch() end},
    {"vbAutoSet",function(v) return v.play.set end,function(v) v:togglePlay("Set") end},
    {"vbAutoSpike",function(v) return v.play.spike end,function(v) v:togglePlay("Spike") end},
    {"vbAutoDive",function(v) return v.play.dive end,function(v) v:togglePlay("Dive") end},
    {"vbAutoServe",function(v) return v.play.serve end,function(v) v:togglePlay("Serve") end},
    {"vbAutoTilt",function(v) return v.auto end,function(v) v:toggleAuto() end},
}
local moduleOptions={
    {"vbBallFactor",function(v) return v.ballRadius.factor end,function(v,x) v:setBallRadiusFactor(x) end},
    {"vbTiltScale",function(v) return v.tiltScale end,function(v,x) v.tiltScale=x;v.requestedTilt=nil end},
    {"vbBallGuide",function(v) return v.ballRadius.show end,function(v,x) v.ballRadius.show=x end},
    {"vbGroundPredict",function(v) return v.play.groundPredict end,function(v,x) v.play.groundPredict=x;v.play.cameraTargetAt=0 end},
    {"vbAutoJump",function(v) return v.play.autoJump end,function(v,x) v.play.autoJump=x;v.play.jumpPendingUntil=0 end},
    {"vbEdgeGuard",function(v) return v.edgeGuard end,function(v,x) v.edgeGuard=x end},
    {"vbShotMode",function(v) return v.shotArc.mode end,function(v,x) v.shotArc.mode=x end},
    {"vbCameraAim",function(v) return v.play.cameraAim end,function(v,x) v.play.cameraAim=x;v.play.cameraTargetAt=0;v.play.cameraPoint=nil end},
    {"vbTiltAim",function(v) return v.tiltAim end,function(v,x) v.tiltAim=x;v.requestedTilt=nil end},
}
function app:moduleSnapshot()
    local result={};local vb=self.volleyball
    if not vb then return result end
    for _,spec in moduleSwitches do result[spec[1]]=spec[2](vb)==true end
    for _,spec in moduleOptions do result[spec[1]]=spec[2](vb) end
    for _,name in S.vbMultiplierNames do
        result["vbMultiplier_"..name]=vb.multiplierRequests[name] or false
    end
    return result
end
function app:recordModuleChanges(before,generation)
    if not self.store or self.moduleApplying or generation~=self.moduleGeneration then return end
    local after=self:moduleSnapshot()
    local changed=false;local settings=table.clone(self.s)
    for key,value in after do
        if before[key]~=value and before[key]~=nil then
            settings[key]=S.value(key,value)
            if self.modulePending then self.modulePending[key]=nil end
            changed=true
        end
    end
    if changed then self.s=settings;self.bank.settings=settings;self:dirty() end
end
function app:clearSavedMultipliers()
    local settings=table.clone(self.s)
    for _,name in S.vbMultiplierNames do
        local key="vbMultiplier_"..name
        settings[key]=false
        if self.modulePending then self.modulePending[key]=nil end
    end
    self.s=settings;self.bank.settings=settings;self:dirty()
end
local function syncModuleUI()
    if not app.ui then return end
    if app.ui.quickAdapter then app.ui.quickAdapter:sync() else app.ui:sync() end
end
local function restoreModuleTick()
    if app.stopping or not gui.Parent or app.moduleApplying then return end
    local vb=app.volleyball
    if app.moduleRestoreRequested then
        app.moduleRestoreRequested=false
        app.modulePending={}
        for _,spec in moduleSwitches do app.modulePending[spec[1]]={attempts=0} end
        for _,name in S.vbMultiplierNames do app.modulePending["vbMultiplier_"..name]={attempts=0} end
        for _,spec in moduleOptions do spec[3](vb,app.s[spec[1]]) end
        syncModuleUI()
    end
    local pending=app.modulePending
    if not pending or not next(pending) or app.mode~="Game" then return end
    local generation=app.moduleGeneration
    app.moduleApplying=true
    local changed=false
    local ok,err=pcall(function()
        -- Restore explicit numeric preferences once, not on every replication update.
        for _,name in S.vbMultiplierNames do
            local key="vbMultiplier_"..name
            local item=pending[key]
            if not item then continue end
            local want=app.s[key]
            local current=vb.multiplierRequests[name]
            if want==false then
                if current~=nil then vb:clearMultiplier(name);changed=true end
                pending[key]=nil
            elseif current==want then
                pending[key]=nil
            elseif vb:available() and player:GetAttribute("Gameplay_InGame")==true and type(player:GetAttribute("Multiplier_"..name))=="number" then
                item.attempts+=1
                local good,why=pcall(vb.setMultiplier,vb,name,want)
                if app.moduleGeneration~=generation then return end
                if good then pending[key]=nil;changed=true
                elseif item.attempts>=8 then pending[key]=nil;app:log("Config",key.." could not be restored: "..tostring(why)) end
            end
        end
        -- Turn saved-OFF modules off first, then restore ON modules.
        for _,want in {false,true} do
            for _,spec in moduleSwitches do
                local key=spec[1];local item=pending[key]
                if not item or app.s[key]~=want then continue end
                local current=spec[2](vb)==true
                if current==want then pending[key]=nil;continue end
                -- Game-changing modules require a compatible game and active match.
                if want and (key=="vbBallRadius" or key=="vbRepeatTouch" or key=="vbAutoTilt" or key=="vbAutoSet" or key=="vbAutoSpike" or key=="vbAutoDive" or key=="vbAutoServe") and (not vb:available() or player:GetAttribute("Gameplay_InGame")~=true) then continue end
                item.attempts+=1
                local good,why=pcall(spec[3],vb)
                if app.moduleGeneration~=generation then return end
                local now=spec[2](vb)==true
                if now==want then pending[key]=nil;changed=true
                elseif item.attempts>=8 then pending[key]=nil;app:log("Config",key.." could not be restored"..(if good then "" else ": "..tostring(why))) end
            end
        end
    end)
    app.moduleApplying=false
    if not ok then app:log("Config",err);app.modulePending=nil end
    if changed then syncModuleUI() end
end
function app:modeSet(mode)
    if mode~="Game" then return end
    if mode=="Game" and self.mode~=mode then self.moduleRestoreRequested=true end
    self.mode = mode
    if self.ui then self.ui:sync() end
end
function app:simVitals(hp, maximum, kind)
    self.sim.hp, self.sim.max = hp, maximum
    if kind == "respawn" then self.sim.gen += 1 end
    self:modeSet("Simulator")
end
function app:simulate(kind)
    self:modeSet("Simulator")
    local sim = self.sim
    if kind == "Damage −25" then sim.hp = math.max(0, sim.hp - 25)
    elseif kind == "Heal +25" then sim.hp = math.min(sim.max, sim.hp + 25)
    elseif kind == "Respawn" then sim.gen += 1; sim.hp = sim.max
    elseif kind == "Clear players" then table.clear(sim.players)
    elseif kind == "Add player" then
        if #sim.players < 10 then
            local id = #sim.players + 1
            table.insert(sim.players, {id = id, x = math.sin(id * 2), y = math.cos(id * 2)})
        end
    elseif kind == "Move players" then
        for _, p in sim.players do p.x = math.clamp(p.x * .8 + .18, -1, 1); p.y = math.clamp(p.y * .8 - .13, -1, 1) end
    end
end
function app:stopCue()
    if self.cues then self.cues:stop(); self.cues = nil end
end
function app:page(tab, ui)
    Pages.render(self, tab, ui)
end
function app:onMenu(open)
    if open and self.editingHUD then self.editingHUD=false;self.ui.drag=nil end
    if open and self.view then self.view:releaseLock(self.view:nativeLockAvailable()) end
end
function app:drag(input, key, widget, frame, source)
    local panel=key=="top"
    if panel then if not self.s.movePanels then return end
    elseif self.s.locked then return end
    if key=="cross" then return end
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local start=Vector2.new(input.Position.X,input.Position.Y)
    local vp=frame.AbsoluteSize
    local size=widget.AbsoluteSize
    local original=widget.AbsolutePosition-frame.AbsolutePosition
    local centered=key=="input" or key=="wallhop"
    local function normalized(pos,sz,center)
        if center then
            return math.clamp(math.round((pos.X+sz.X*.5)/math.max(1,vp.X)*100),0,100),math.clamp(math.round((pos.Y+sz.Y*.5)/math.max(1,vp.Y)*100),0,100)
        end
        return math.clamp(math.round(pos.X/math.max(1,vp.X-sz.X)*100),0,100),math.clamp(math.round(pos.Y/math.max(1,vp.Y-sz.Y)*100),0,100)
    end
    local migrated=false
    self.ui:begin(input,function(pos)
        local delta=pos-start
        if delta.Magnitude<1 and not migrated then return end
        local dest=original+delta
        dest=Vector2.new(math.clamp(dest.X,0,math.max(0,vp.X-size.X)),math.clamp(dest.Y,0,math.max(0,vp.Y-size.Y)))
        local x,y=normalized(dest,size,centered)
        local patch={[key.."X"]=x,[key.."Y"]=y}
        if panel then
            if not self.s.movePanels then return end
            patch[key.."Custom"]=true
        elseif not centered and self.s.layoutMode=="Sketch" then
            patch.layoutMode="Custom"
            local preview=source or (self.preview and self.preview.hud)
            if preview then
                for _,other in {"clock","profile","dock"} do
                    if other~=key then
                        local w=preview.widgets[other].p
                        local nx,ny=normalized(w.AbsolutePosition-frame.AbsolutePosition,w.AbsoluteSize,false)
                        patch[other.."X"]=nx;patch[other.."Y"]=ny
                    end
                end
            end
        end
        migrated=true
        self:patch(patch)
    end)
end

local hud = Hud.new(scope, overlay, false, function()
    if app.ui and not app.editingHUD and not app.stopping then app.ui:show(not app.ui.opened) end
end,nil,nil)
local avatar = Avatar.new(workspace, false)
local walkMotion = WalkMotion.new()
app.walkMotion = walkMotion
local peers = PeerVisuals.new(player,scope)
app.peers = peers
local motionProps = PreviewProps.new(workspace, true)
local world = World.new()
local view = View.new(player, pointer)
app.view = view
-- Restore the bank before constructing any interactive UI. A restore during
-- Storage.new must not re-enter UI:open while the store is still nil.
local store = Storage.new(app, scope)
app.store = store
if app.pendingStoreEdit then app.pendingStoreEdit=nil;store:edit() end
local ui = Controls.new(app, studioLayer, scope)
app.ui = ui

-- Read-only HUD explorer for visible scene objects. No source or remote access.
do
    local panel=U.new("Frame",{Name="GameExplorer",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(.98,0,.5,0),Size=UDim2.new(.36,0,.65,0),BackgroundTransparency=.12,Visible=false,ZIndex=10},overlay)
    U.new("UISizeConstraint",{MinSize=Vector2.new(230,260),MaxSize=Vector2.new(410,560)},panel)
    U.corner(panel,12)
    local stroke=U.stroke(panel,Color3.new(1,1,1),.5)
    local function label(name,pos,size)
        return U.new("TextLabel",{Name=name,Position=pos,Size=size,BackgroundTransparency=1,Text="",TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11},panel)
    end
    local header=label("Title",UDim2.fromOffset(12,4),UDim2.new(1,-95,0,29))
    header.Text="GAME EXPLORER / READ ONLY"
    local close=U.new("TextButton",{Text="×",TextSize=21,Position=UDim2.new(1,-32,0,5),Size=UDim2.fromOffset(26,26),BackgroundTransparency=.7,ZIndex=12},panel)
    U.corner(close,6)
    local back=U.new("TextButton",{Text="UP",TextSize=11,Position=UDim2.new(1,-77,0,5),Size=UDim2.fromOffset(40,26),BackgroundTransparency=.7,ZIndex=12},panel)
    U.corner(back,6)
    local search=U.new("TextBox",{PlaceholderText="Filter child objects",Text="",ClearTextOnFocus=false,Position=UDim2.fromOffset(10,37),Size=UDim2.new(1,-20,0,27),TextSize=12,BackgroundTransparency=.4,ZIndex=11},panel)
    U.corner(search,6)
    local pathLabel=label("Path",UDim2.fromOffset(10,67),UDim2.new(1,-20,0,22))
    pathLabel.TextTruncate=Enum.TextTruncate.AtEnd
    local list=U.new("ScrollingFrame",{Position=UDim2.fromOffset(10,92),Size=UDim2.new(1,-20,.48,-50),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ZIndex=11},panel)
    U.new("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},list)
    local detail=label("Details",UDim2.new(0,10,.48,48),UDim2.new(1,-20,.52,-58))
    detail.TextWrapped=true;detail.TextYAlignment=Enum.TextYAlignment.Top
    local selected=workspace
    local rows={}
    local lastKey=""
    local lastObjects={}
    local drag=nil
    header.Active=true
    panel.Active=true
    local function place()
        if drag then return end
        local size=overlay.AbsoluteSize-panel.AbsoluteSize
        panel.AnchorPoint=Vector2.zero
        panel.Position=UDim2.fromOffset(math.max(0,size.X)*app.s.gameExplorerX/100,math.max(0,size.Y)*app.s.gameExplorerY/100)
    end
    scope:on(header.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        drag={input=input,start=Vector2.new(input.Position.X,input.Position.Y),origin=panel.AbsolutePosition-overlay.AbsolutePosition}
    end)
    scope:on(UserInputService.InputChanged,function(input)
        if not drag or (input~=drag.input and not (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then return end
        local size=overlay.AbsoluteSize-panel.AbsoluteSize
        local target=drag.origin+Vector2.new(input.Position.X,input.Position.Y)-drag.start
        panel.Position=UDim2.fromOffset(math.clamp(target.X,0,math.max(0,size.X)),math.clamp(target.Y,0,math.max(0,size.Y)))
    end)
    scope:on(UserInputService.InputEnded,function(input)
        if not drag or input~=drag.input then return end
        drag=nil
        local size=overlay.AbsoluteSize-panel.AbsoluteSize
        local pos=panel.AbsolutePosition-overlay.AbsolutePosition
        app:patch({gameExplorerX=math.clamp(pos.X/math.max(1,size.X)*100,0,100),gameExplorerY=math.clamp(pos.Y/math.max(1,size.Y)*100,0,100)})
    end)
    local function allowedObject(obj)
        return obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Camera") or obj:IsA("Attachment") or obj:IsA("Terrain")
    end
    local function refresh(force)
        if not selected:IsDescendantOf(workspace) and selected~=workspace then selected=workspace end
        local st=app.s
        panel.BackgroundColor3=U.hex(st.uiPanelColor);stroke.Color=U.hex(st.uiStrokeColor)
        panel.BackgroundTransparency=1-st.uiGlassOpacity/100
        for _,obj in {header,pathLabel,detail,search,back,close} do obj.TextColor3=U.hex(st.uiFontColor) end
        pathLabel.Text=selected:GetFullName()
        local lines={selected.ClassName.." | "..selected.Name}
        if selected:IsA("BasePart") then
            table.insert(lines,"Position: "..tostring(selected.Position))
            table.insert(lines,"Size: "..tostring(selected.Size))
            table.insert(lines,"Velocity: "..tostring(selected.AssemblyLinearVelocity))
        end
        if selected:IsA("Model") then table.insert(lines,"Position: "..tostring(selected:GetPivot().Position)) end
        local active=game:GetService("ReplicatedStorage"):GetAttribute("ActiveBall")
        table.insert(lines,"Active ball: "..tostring(active))
        table.insert(lines,"Children: "..tostring(#selected:GetChildren()))
        detail.Text=table.concat(lines,"\n")
        local children={}
        local query=search.Text:lower()
        for _,obj in selected:GetChildren() do
            if allowedObject(obj) and obj.Name:lower():find(query,1,true) then table.insert(children,obj) end
        end
        table.sort(children,function(a,b) return a.Name<b.Name end)
        local keys={tostring(selected),query,st.uiFontColor,st.uiRowColor}
        for i=1,math.min(#children,100) do table.insert(keys,children[i].Name..":"..children[i].ClassName) end
        local key=table.concat(keys,"|")
        local same=key==lastKey and #lastObjects==math.min(#children,100)
        if same then for i,obj in lastObjects do if obj~=children[i] then same=false;break end end end
        if not force and same then return end
        table.clear(lastObjects)
        for i=1,math.min(#children,100) do lastObjects[i]=children[i] end
        lastKey=key
        for _,row in rows do row:Destroy() end
        table.clear(rows)
        for i=1,math.min(#children,100) do
            local obj=children[i]
            local row=U.new("TextButton",{Text="  "..obj.Name.."  ["..obj.ClassName.."]",TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,TextColor3=U.hex(st.uiFontColor),BackgroundColor3=U.hex(st.uiRowColor),BackgroundTransparency=.2,Size=UDim2.new(1,-5,0,24),LayoutOrder=i,ZIndex=12},list)
            U.corner(row,5);table.insert(rows,row)
            row.Activated:Connect(function()
                if obj.Parent==selected then selected=obj;search.Text="";list.CanvasPosition=Vector2.zero;refresh(true) end
            end)
        end
    end
    scope:on(close.Activated,function() app:set("gameExplorer",false);panel.Visible=false end)
    scope:on(back.Activated,function()
        if selected~=workspace and selected.Parent then selected=selected.Parent;search.Text="";refresh(true) end
    end)
    scope:on(search:GetPropertyChangedSignal("Text"),function() if panel.Visible then refresh(true) end end)
    local function safeRefresh(force)
        local ok,err=pcall(refresh,force)
        if not ok then detail.Text="Explorer error: "..tostring(err);lastKey="" end
    end
    local elapsed=0
    scope:on(RunService.Heartbeat,function(dt)
        local show=app.s.gameExplorer and not app.stopping
        if show~=panel.Visible then panel.Visible=show;if show then place();safeRefresh(true) else drag=nil end end
        if not show then return end
        elapsed+=dt
        if elapsed>=.5 then elapsed=0;place();safeRefresh(false) end
    end)
end
-- The high-order cursor is decorative. HUD and Studio buttons retain their
-- normal input behavior, including when the main menu is closed.
do
    local function pointerOnly(obj)
        if obj:IsA("GuiObject") then obj.Active=false;obj.Interactable=false end
    end
    pointerOnly(pointer)
    for _,obj in pointer:GetDescendants() do pointerOnly(obj) end
    scope:on(pointer.DescendantAdded,pointerOnly)
end
app.moduleRestoreRequested=true
local moduleRestoreElapsed=0
scope:on(RunService.Heartbeat,function(dt)
    moduleRestoreElapsed+=dt
    if moduleRestoreElapsed<.5 then return end
    moduleRestoreElapsed=0
    restoreModuleTick()
end)

-- Non-persistent editing session. Handles exist only while arranging the live HUD.
local editorGui=scope:add(U.new("ScreenGui",{Name="AETHER_HUD_Editor",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483646,ZIndexBehavior=Enum.ZIndexBehavior.Global,Enabled=false},pg))
local editor=U.frame(editorGui,"Editor",nil,nil,nil,1)
local header=U.frame(editor,"EditorBar",UDim2.new(.5,0,0,58),UDim2.new(.9,0,0,44),Color3.fromRGB(27,21,44),.04)
header.AnchorPoint=Vector2.new(.5,0);header.ZIndex=20
U.new("UISizeConstraint",{MaxSize=Vector2.new(440,44)},header)
U.corner(header,12);U.stroke(header,Color3.fromRGB(188,151,255),.3)
local instruction=U.label(header,"HUD EDIT",11,UDim2.fromOffset(10,0),UDim2.new(.32,-10,1,0));instruction.ZIndex=21
local panelToggle=U.button(header,"PANELS: LOCKED");panelToggle.Position=UDim2.new(.32,0,0,5);panelToggle.Size=UDim2.new(.43,-4,1,-10);panelToggle.ZIndex=22;panelToggle.Modal=false
local done=U.button(header,"DONE");done.Position=UDim2.new(.75,0,0,5);done.Size=UDim2.new(.25,-5,1,-10);done.Modal=false;done.ZIndex=22
scope:on(panelToggle.Activated,function()
    if not app.editingHUD then return end
    ui.drag=nil
    if app.hudEditMode=="Volleyball" then app:patch({keybindCustom=false,quickCustom=false})
    else app:set("movePanels",not app.s.movePanels) end
    app:updateEditor()
end)
local handles={}
local positions={"clock","profile","input","wallhop","top","keybind","quick"}
local function isAux(key) return key=="keybind" or key=="quick" end
local function isPanel(key) return key=="top" or isAux(key) end
local function widgetFor(key)
    if key=="input" then return hud.inputRoot end
    if key=="wallhop" then return hud.wallhop end
    if key=="top" then return ui.top end
    if key=="keybind" then return ui.bindPanel end
    if key=="quick" then return ui.quick end
    return hud.widgets[key].p
end
local function coord(key,topLeft,size,vp)
    if key=="input" or key=="wallhop" then
        return math.clamp(math.round((topLeft.X+size.X*.5)/math.max(1,vp.X)*100),0,100),math.clamp(math.round((topLeft.Y+size.Y*.5)/math.max(1,vp.Y)*100),0,100)
    end
    return math.clamp(math.round(topLeft.X/math.max(1,vp.X-size.X)*100),0,100),math.clamp(math.round(topLeft.Y/math.max(1,vp.Y-size.Y)*100),0,100)
end
function app:editHUD(on,mode,returnQuick)
    if self.stopping then return end
    if on then
        self.hudEditMode=mode or "HUD"
        if self.hudEditMode=="All" and not self.s.movePanels then self:set("movePanels",true) end
        self.hudEditReturnTab=ui.tab
        self.hudEditReturnQuick=returnQuick==true
        ui:show(false)
        if (self.hudEditMode=="Volleyball" or self.hudEditMode=="All") and not ui.quickAdapter then ui:setQuick(true) end
        ui:setQuick(false)
        self.editingHUD=true
        editorGui.Enabled=true
        self.view:releaseLock(self.view:nativeLockAvailable())
    else
        local backQuick=self.hudEditReturnQuick
        local backTab=self.hudEditReturnTab or "HUD"
        self.editingHUD=false
        self.hudEditMode=nil;self.hudEditReturnQuick=nil;self.hudEditReturnTab=nil
        editorGui.Enabled=false
        ui.drag=nil
        if self.store and self.store.dirty then pcall(function() self.store:save() end) end
        if backQuick then ui:setQuick(true) else ui:open(backTab) end
    end
end
scope:on(done.Activated,function() app:editHUD(false) end)
for _,key in positions do
    local b=U.button(editor,key:upper())
    b.Name="Move_"..key;b.TextSize=12;b.BackgroundTransparency=.84;b.TextColor3=Color3.fromRGB(255,242,255);b.ZIndex=9;b.Active=true;b.AutoButtonColor=false;b.Visible=false;b.Modal=false
    b.TextStrokeTransparency=.35
    U.stroke(b,Color3.fromRGB(224,183,255),0,2.5)
    handles[key]=b
    if key=="clock" or key=="profile" or key=="top" then
        local resize=U.button(b,"+");resize.Name="ResizeWidget";resize.AnchorPoint=Vector2.new(1,1);resize.Position=UDim2.fromScale(1,1);resize.Size=UDim2.fromOffset(23,23);resize.ZIndex=11
        scope:on(resize.InputBegan,function(input)
            if not app.editingHUD or app.hudEditMode=="Volleyball" then return end
            if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
            local prop=key.."Scale";local initial=app.s[prop];local target=widgetFor(key)
            local width=math.max(1,target.AbsoluteSize.X)
            ui:begin(input,function(pos,start)
                local value=math.clamp(math.round(initial*(1+(pos.X-start.X)/width)),if key=="top" then 60 else 50,if key=="top" then 180 else 160)
                if app.s[prop]~=value then app:set(prop,value) end
            end)
        end)
    end
    scope:on(b.InputBegan,function(input)
        if not app.editingHUD or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
        if ui.drag then return end
        local target=widgetFor(key)
        if not target.Visible or (key=="top" and not app.s.movePanels) then return end
        if app.hudEditMode~="All" and (app.hudEditMode=="Volleyball")~=isAux(key) then return end
        local vp=overlay.AbsoluteSize
        local size=target.AbsoluteSize
        local original=target.AbsolutePosition-overlay.AbsolutePosition
        -- Preserve all currently visible classic widget positions before leaving Sketch.
        local patch={}
        if app.s.layoutMode=="Sketch" and key~="input" and key~="wallhop" and not isPanel(key) then
            patch.layoutMode="Custom"
            for _,other in {"clock","profile","dock"} do
                local w=widgetFor(other)
                local x,y=coord(other,w.AbsolutePosition-overlay.AbsolutePosition,w.AbsoluteSize,vp)
                patch[other.."X"]=x;patch[other.."Y"]=y
            end
            app:patch(patch)
        end
        local start=Vector2.new(input.Position.X,input.Position.Y)
        ui:begin(input,function(pos)
            if not app.editingHUD then return end
            local dest=original+(pos-start)
            dest=Vector2.new(math.clamp(dest.X,0,math.max(0,vp.X-size.X)),math.clamp(dest.Y,0,math.max(0,vp.Y-size.Y)))
            local x,y=coord(key,dest,size,vp)
            if isPanel(key) then
                if key=="top" and not app.s.movePanels then return end
                if not app.s[key.."Custom"] or app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."Custom"]=true,[key.."X"]=x,[key.."Y"]=y}) end
            elseif app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."X"]=x,[key.."Y"]=y}) end
        end)
    end)
end
function app:updateEditor()
    editorGui.Enabled=self.editingHUD==true
    if not self.editingHUD then return end
    local auxMode=self.hudEditMode=="Volleyball"
    instruction.Text=if auxMode then "WIDGET EDIT" else "HUD EDIT"
    panelToggle.Text=if auxMode then "RESET POS" elseif self.s.movePanels then "PANELS: MOVE" else "PANELS: LOCKED"
    panelToggle.BackgroundColor3=if auxMode or self.s.movePanels then Color3.fromRGB(105,71,164) else Color3.fromRGB(52,40,77)
    for _,key in positions do
        local b,target=handles[key],widgetFor(key)
        b.Visible=target.Visible and (self.hudEditMode=="All" or auxMode==isAux(key)) and (if isAux(key) then true elseif key=="top" then self.s.topCapsule elseif key=="input" then self.s.inputOverlay elseif key=="wallhop" then self.s.wallhopHelper else self.s[key])
        local locked=key=="top" and not self.s.movePanels
        b.Active=not locked;b.Interactable=not locked
        b.Text=(if key=="keybind" then "KEYBINDS" elseif key=="quick" then "QUICK MENU" else key:upper())..(if locked then " · LOCKED" else " · MOVE")
        local rim=b:FindFirstChildOfClass("UIStroke")
        if rim then rim.Color=if locked then Color3.fromRGB(153,148,170) else Color3.fromRGB(224,183,255);rim.Transparency=if locked then .3 else 0 end
        if b.Visible then
            local xy=target.AbsolutePosition-editor.AbsolutePosition
            local sz=target.AbsoluteSize
            b.Position=UDim2.fromOffset(xy.X,xy.Y);b.Size=UDim2.fromOffset(sz.X,sz.Y)
        end
    end
end
function app:unload()
    if self.stopping then return end
    self.stopping=true
    self.editingHUD=false;editorGui.Enabled=false
    if store.dirty and not store.pending then pcall(function() store:save() end) end
    -- Defer destruction until the current GUI activation callback has returned.
    task.defer(function() scope:clear() end)
end
ui:open(app.s.lastPage or "Halos")
ui:show(false)
app:log("Startup", "AETHER modules initialized")

local humanoid, character, generation = nil, nil, 0
local function bind(char)
    generation += 1
    local bindGeneration = generation
    character = char
    humanoid = nil
    local found = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
    if generation == bindGeneration and character == char and player.Character == char then
        humanoid = if found and found:IsA("Humanoid") then found else nil
    end
end
scope:on(player.CharacterAdded, bind)
scope:on(player.CharacterRemoving, function(char)
    if character == char then
        view:releaseCamera(view:nativeLockAvailable())
        character, humanoid = nil, nil
    end
    avatar:clear()
    motionProps:clear()
end)
if player.Character then bind(player.Character) end

scope:on(UserInputService.InputBegan, function(input, processed)
    if app.stopping then return end
    if ui:handleQuickKey(input,processed) then return end
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        app.m2Presses=(app.m2Presses or 0)+1
        app.m2Last=string.format("M2 down | processed: %s | menu: %s",tostring(processed),tostring(ui.opened))
    end
    if app.bindingLockKey and ui.opened and ui.tab=="Interaction" then
        if input.UserInputType==Enum.UserInputType.Keyboard and not UserInputService:GetFocusedTextBox() then
            local name=input.KeyCode.Name
            if name~="Unknown" and table.find(S.lockKeys,name) then app.bindingLockKey=false;app:set("lockKey",name)
            else ui:message("Roblox did not report a usable key code.") end
        end
        return
    end
    if UserInputService:GetFocusedTextBox() then return end
    -- Observe an explicitly selected Shift even when a separate gameplay action also uses it.
    -- This listener never sinks or synthesizes input.
    local chosenShift=(input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift) and input.KeyCode.Name==app.s.lockKey
    local menuKey=S.menuKey(app.s)
    -- Our own workspace keyboard sink can mark the menu shortcut as processed.
    -- Keep the close shortcut usable without forwarding it to gameplay.
    local workspaceMenuKey=ui.opened and input.KeyCode.Name==menuKey and not game:GetService("GuiService").MenuIsOpen
    if processed and not chosenShift and not workspaceMenuKey then return end
    if app.editingHUD then if input.KeyCode.Name==menuKey then app:editHUD(false) end;return end
    if input.KeyCode.Name == menuKey then
        ui:show(not ui.opened)
    elseif input.KeyCode.Name == app.s.lockKey and app.mode=="Game" and not ui.opened and not game:GetService("GuiService").MenuIsOpen then
        local enable=not app.s.lock
        if enable then
            app:patch({lock=true,cameraMode="Follow"})
            if view:nativeLockAvailable() then ui:message("Native Shift Lock is enabled. Turn Shift Lock Switch OFF in Roblox settings.") end
        else
            app:set("lock",false)
            view:releaseLock(view:nativeLockAvailable())
        end
    end
end)

scope:on(UserInputService.InputEnded,function(input,processed)
    if app.stopping or input.UserInputType~=Enum.UserInputType.MouseButton2 then return end
    app.m2Releases=(app.m2Releases or 0)+1
    app.m2LastRelease="M2 up | processed: "..tostring(processed)
end)

local function targetsFromGame()
    local results = {}
    local cam = workspace.CurrentCamera
    local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not cam or not ownRoot then return results end
    local center = cam.ViewportSize * .5
    for _, other in Players:GetPlayers() do
        if other == player then continue end
        local c = other.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local life = c and c:FindFirstChildOfClass("Humanoid")
        if root and life and life.Health > 0 then
            local dist = (root.Position - ownRoot.Position).Magnitude
            if dist <= app.s.reach then
                local screen, inViewport = cam:WorldToViewportPoint(root.Position)
                local v = Vector2.new(screen.X, screen.Y) - center
                if screen.Z < 0 then v = -v end
                if v.Magnitude < .001 then v = Vector2.yAxis end
                local dir = v.Unit
                table.insert(results, {
                    id = tostring(other.UserId), label = other.DisplayName,
                    distance = dist, visible = inViewport and screen.Z > 0,
                    x = dir.X, y = dir.Y,
                })
            end
        end
    end
    return results
end
local targetTimer, cachedTargets = 0, {}
local function frame(dt, now)
    local result = app.frame
    if dt>0 then result.fps=U.approach(result.fps or 1/dt,1/dt,dt,.6) end
    result.name = player.DisplayName
    result.mode = app.mode:upper()
    if app.mode == "Simulator" then
        result.hp, result.max, result.gen = app.sim.hp, app.sim.max, app.sim.gen
        local list = {}
        for _, p in app.sim.players do
            table.insert(list, {id = tostring(p.id), label = "Test " .. p.id,
                distance = 100, visible = false, x = p.x, y = p.y})
        end
        result.targets = list
    else
        result.hp = if humanoid then humanoid.Health else nil
        result.max = if humanoid then humanoid.MaxHealth else nil
        result.gen = generation
        targetTimer += dt
        if targetTimer > .13 then targetTimer = 0; cachedTargets = targetsFromGame() end
        result.targets = cachedTargets
    end
    result.widgets = if app.cues then app.cues.widgets else {}
    if app.cues then
        local old = app.lastVitals
        local h, m = result.hp, result.max
        local changed = h ~= nil and (not old or old.hp ~= h or old.max ~= m or old.gen ~= result.gen)
        if changed then
            local event = if old and old.gen ~= result.gen then "Respawn"
                elseif old and h < old.hp then "Damage"
                elseif old and h > old.hp then "Heal" else "Vitals"
            local ok, err = pcall(function() app.cues:event(event, h, m, true) end)
            if not ok then app:log("Scripts", err); app:stopCue() end
        end
        if h ~= nil then app.lastVitals = {hp = h, max = m, gen = result.gen} end
    end
    local styled = app.s
    if app.cues and next(app.cues.overrides) then
        styled = table.clone(app.s)
        for k,v in app.cues.overrides do styled[k] = v end
    end
    result.editingHUD=app.editingHUD==true
    result.shiftLock=view.shiftReticleActive==true and not ui.opened and not app.editingHUD and app.mode=="Game"
    -- A menu animation fault must not prevent the HUD from laying out.
    local hudOK,hudError=pcall(hud.step,hud,styled,result,dt)
    if not hudOK and app.hudLayoutError~=hudError then app.hudLayoutError=hudError;app:log("HUD",hudError) elseif hudOK then app.hudLayoutError=nil end
    local uiOK,uiError=pcall(ui.animateBackground,ui,now)
    if not uiOK and app.menuLayoutError~=uiError then app.menuLayoutError=uiError;app:log("Menu",uiError) elseif uiOK then app.menuLayoutError=nil end
    avatar:step(if app.mode == "Game" then character else nil, styled, workspace:GetServerTimeNow())
    peers:step(styled, app.mode=="Game", walkMotion, dt)
    if peers.statusLabel and peers.statusLabel.Parent and peers.statusLabel.Text~=peers.status then peers.statusLabel.Text=peers.status end
    world:apply(styled)
    if ui:workspacePageVisible() and app.preview then
        if app.preview.hud then app.preview.hud:step(styled, result, dt) end
        if app.preview.pose then app.preview.pose(styled, dt) end
        if app.preview.avatar then app.preview.avatar:step(app.preview.rig, styled, app.preview.effectTime or now) end
        view:preview(app.preview.cursorHost,styled)
    end
    store:tick(os.clock())
end
-- Run the combined camera/lock pass after Roblox's native camera update.
local cameraRenderBinding="AETHER_Camera_"..game:GetService("HttpService"):GenerateGUID(false)
RunService:BindToRenderStep(cameraRenderBinding,Enum.RenderPriority.Camera.Value+1,function(dt)
    if app.stopping or not gui.Parent then return end
    local styled=app.s
    if app.cues and next(app.cues.overrides) then
        styled=table.clone(app.s)
        for k,v in app.cues.overrides do styled[k]=v end
    end
    local blocked=ui.opened or app.editingHUD==true
    local function aimStep(lockActive)
        if not app.volleyball then return end
        local ok,result=pcall(app.volleyball.stepSpikeCamera,app.volleyball,blocked,lockActive)
        if not ok then app.volleyball.play.cameraAim="Off";app.volleyball.play.cameraStatus="Aim error: "..tostring(result);app:log("Spike aim",result);return nil end
        return result
    end
    local ok,err=pcall(view.step,view,styled,if app.mode=="Game" then humanoid else nil,blocked,math.min(dt,.1),os.clock(),aimStep)
    if not ok then
        if app.cameraError~=err then app.cameraError=err;app:log("Camera",err) end
    else app.cameraError=nil end
end)
scope:add(function() RunService:UnbindFromRenderStep(cameraRenderBinding) end)
-- Cursor tracking is isolated from the expensive AETHER/EditableImage frame.
-- Use a unique binding: cleaning up an older reload cannot unbind the newer one.
local pointerRenderBinding = "AETHER_Pointer_" .. game:GetService("HttpService"):GenerateGUID(false)
RunService:BindToRenderStep(pointerRenderBinding, Enum.RenderPriority.Last.Value, function()
    if app.stopping or not gui.Parent then return end
    local ok, err = pcall(view.cursorStep, view, app.s)
    if not ok then
        pcall(view.restoreCursor,view)
        if not app.pointerError then
            app.pointerError = true
            warn("AETHER cursor position:", err)
        end
    else
        app.pointerError = false
    end
end)
scope:add(function() RunService:UnbindFromRenderStep(pointerRenderBinding) end)

-- Remove last frame's local visual layer before Animator evaluates.
scope:on(RunService.PreAnimation, function()
    if not app.stopping and gui.Parent then walkMotion:restoreLive();peers:restore() end
end)
-- Optional local air steering mechanic controlled by the Air Redirection toggle.
-- Does not create forces, alter gravity, increase WalkSpeed or change vertical velocity.
local function stepAirControl(dt)
    app.airProbe = nil
    app.airTiltDirection = nil
    if app.mode ~= "Game" then return "Simulator mode" end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then return "Character or humanoid missing" end
    if humanoid.Health <= 0 or humanoid.Sit or humanoid.PlatformStand then return "Dead, seated or PlatformStand" end
    local state = humanoid:GetState()
    local floor = humanoid.FloorMaterial
    local root = humanoid.RootPart or character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") or root.Anchored then
        app.airDiagnostic = "Skipped: root missing or anchored"
        return app.airDiagnostic
    end
    local v = root.AssemblyLinearVelocity
    local walkSpeed = math.max(0,humanoid.WalkSpeed)
    local speedSample = app.airGroundSpeed
    if not speedSample or speedSample.root ~= root or speedSample.humanoid ~= humanoid then
        speedSample = {root=root,humanoid=humanoid,speed=0,time=0}
        app.airGroundSpeed = speedSample
    end
    app.airPeakVertical = math.max(app.airPeakVertical or 0,math.abs(v.Y))
    local airborne = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
    local detection = state.Name
    -- Some character controllers report Running until after leaving the floor.
    -- Accept the floor sensor only in ordinary locomotion states.
    if not airborne and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed) then
        if floor == Enum.Material.Air then
            airborne = true
            detection = "FloorMaterial Air"
        elseif math.abs(v.Y)>2 then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {character}
            params.RespectCanCollide = true
            local standingHeight = humanoid.HipHeight+root.Size.Y/2
            if humanoid.RigType == Enum.HumanoidRigType.R6 then
                local leg = character:FindFirstChild("Left Leg")
                if leg and leg:IsA("BasePart") then standingHeight += leg.Size.Y end
            end
            local ground = workspace:Raycast(root.Position,Vector3.new(0,-math.max(standingHeight+.65,1),0),params)
            if not ground then airborne=true;detection="Ground clearance" end
        end
    end
    if not airborne then
        if (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed)
            and floor ~= Enum.Material.Air and walkSpeed > 0 then
            speedSample.speed = walkSpeed
            speedSample.time = os.clock()
        end
        return "State: "..state.Name.." | floor: "..floor.Name
    end
    app.airObserved = (app.airObserved or 0)+1
    app.airLastDetection = string.format("%s | state %s | floor %s | Y %.1f",detection,state.Name,floor.Name,v.Y)
    if not app.s.airControl then app.airDiagnostic="Skipped: disabled in settings";return app.airDiagnostic end
    local input = humanoid.MoveDirection
    local direction = Vector3.new(input.X,0,input.Z)
    local inputSource = "Humanoid"
    -- Read directional keys independently of AETHER menu visibility.
    -- Do not interpret text entry as movement.
    if UserInputService.KeyboardEnabled and not UserInputService:GetFocusedTextBox() then
        local function down(key,alternate)
            return UserInputService:IsKeyDown(key) or UserInputService:IsKeyDown(alternate)
        end
        local x = (if down(Enum.KeyCode.D,Enum.KeyCode.Right) then 1 else 0)-(if down(Enum.KeyCode.A,Enum.KeyCode.Left) then 1 else 0)
        local z = (if down(Enum.KeyCode.W,Enum.KeyCode.Up) then 1 else 0)-(if down(Enum.KeyCode.S,Enum.KeyCode.Down) then 1 else 0)
        local camera = workspace.CurrentCamera
        if camera and (x~=0 or z~=0) then
            local look = camera.CFrame.LookVector
            local forward = Vector3.new(look.X,0,look.Z)
            if forward.Magnitude<.01 then
                local up = camera.CFrame.UpVector
                forward = Vector3.new(up.X,0,up.Z)
            end
            if forward.Magnitude>.01 then
                forward=forward.Unit
                local right=forward:Cross(Vector3.yAxis)
                local raw=forward*z+right*x
                if raw.Magnitude>.01 then direction=raw.Unit;inputSource="Keyboard" end
            end
        end
    end
    app.airInputSource = inputSource
    if not app.s.reduce and not UserInputService:GetFocusedTextBox() then
        app.airTiltDirection = direction
    end
    local horizontal = Vector3.new(v.X,0,v.Z)
    local speed = horizontal.Magnitude
    if direction.Magnitude < .01 then app.airDiagnostic = "Skipped: MoveDirection is zero";return app.airDiagnostic end
    if app.s.airControlStrength <= 0 then app.airDiagnostic = "Skipped: strength is zero";return app.airDiagnostic end
    if dt <= 0 then app.airDiagnostic = "Skipped: physics delta time is zero";return app.airDiagnostic end
    -- Use a recent ground-speed sample for the same avatar when airborne.
    -- Do not invent a speed or retain a sample from a previous character.
    local groundSpeed = if os.clock()-speedSample.time <= 2 then speedSample.speed else 0
    local baseCap = if walkSpeed > 0 then walkSpeed elseif groundSpeed > 0 then groundSpeed else 0
    local cap = if baseCap > 0 then baseCap*math.clamp(app.s.airControlSpeed or 125,100,200)/100 else speed
    if cap < .01 then
        app.airDiagnostic = string.format("Skipped: no speed sample | WalkSpeed %.2f | speed %.2f | ground %.2f",walkSpeed,speed,groundSpeed)
        return app.airDiagnostic
    end
    local nextVelocity = U.airRedirect(horizontal,direction,cap,app.s.airControlStrength,dt)
    if (nextVelocity-horizontal).Magnitude < .0001 then
        app.airDiagnostic = string.format("Already aligned | %s | speed %.1f | input %.2f",state.Name,horizontal.Magnitude,direction.Magnitude)
        return app.airDiagnostic
    end
    root.AssemblyLinearVelocity = Vector3.new(nextVelocity.X,v.Y,nextVelocity.Z)
    app.airProbe = {root=root,expected=nextVelocity,speed=speed,cap=cap,walkSpeed=walkSpeed}
    app.airWrites = (app.airWrites or 0)+1
    app.airDiagnostic = string.format("Write issued | %s | speed %.1f",state.Name,horizontal.Magnitude)
    return app.airDiagnostic
end

-- Independent, read-only monitoring of the actual current avatar.
scope:on(UserInputService.JumpRequest,function()
    if not app.stopping and app.mode == "Game" and not app.ui.opened then
        app.airJumpRequests = (app.airJumpRequests or 0)+1
    end
end)
scope:on(RunService.Heartbeat,function()
    if app.stopping or not gui.Parent or app.mode ~= "Game" then return end
    local current = player.Character
    local h = current and current:FindFirstChildOfClass("Humanoid")
    local r = h and (h.RootPart or current:FindFirstChild("HumanoidRootPart"))
    if not r or not r:IsA("BasePart") then
        app.airTracking = "Live character or root unavailable"
        app.airMonitor = nil
        return
    end
    local pos = r.Position
    local m = app.airMonitor
    if not m or m.root ~= r then
        m = {root=r,origin=pos,minY=pos.Y,maxY=pos.Y,travel=0,peakY=0}
        app.airMonitor = m
    end
    m.minY = math.min(m.minY,pos.Y)
    m.maxY = math.max(m.maxY,pos.Y)
    m.travel = math.max(m.travel,(pos-m.origin).Magnitude)
    m.peakY = math.max(m.peakY,math.abs(r.AssemblyLinearVelocity.Y))
    app.airTracking = string.format("Root: %s | cached match: %s | anchored: %s",r.Name,tostring(current==character and h==humanoid),tostring(r.Anchored))
end)

-- Observe the result without fighting the experience's physics controller.
scope:on(RunService.PostSimulation,function()
    local probe = app.airProbe
    app.airProbe = nil
    if not probe or app.stopping or not gui.Parent or not probe.root.Parent then return end
    local v = probe.root.AssemblyLinearVelocity
    local difference = (Vector3.new(v.X,0,v.Z)-probe.expected).Magnitude
    app.airDiagnostic = string.format("Applied | speed %.1f | WalkSpeed %.1f | cap %.1f | physics delta %.1f",probe.speed,probe.walkSpeed,probe.cap,difference)
end)

-- Hold Space to request ordinary grounded jumps. No jump-power or state overrides.
local function stepBunnyHop()
    if app.mode ~= "Game" or not app.s.bunnyHop or UserInputService:GetFocusedTextBox() or not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        app.bunnyHopStatus = "Idle"
        app.bunnyHopNext = nil
        return
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not hum or not root or root.Anchored or hum.Health<=0 or hum.Sit or hum.PlatformStand then
        app.bunnyHopStatus = "Waiting for character"
        return
    end
    if app.bunnyHopHum ~= hum then
        app.bunnyHopHum = hum
        app.bunnyHopNext = nil
    end
    local state=hum:GetState()
    if hum.FloorMaterial == Enum.Material.Air or (state~=Enum.HumanoidStateType.Running and state~=Enum.HumanoidStateType.Landed) then
        app.bunnyHopStatus = "Waiting for landing"
        app.bunnyHopNext = nil
        return
    end
    if not hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
        app.bunnyHopStatus = "Jump disabled"
        return
    end
    if os.clock() < (app.bunnyHopNext or 0) then return end
    hum.Jump = true
    app.bunnyHopNext = os.clock()+.15
    app.bunnyHopCount = (app.bunnyHopCount or 0)+1
    app.bunnyHopStatus = "Jump requested"
end

-- Motion Studio poses follow the real humanoid state, after Animator evaluates.
scope:on(RunService.PreSimulation, function(dt)
    if app.stopping or not gui.Parent then return end
    local hopOk, hopErr = pcall(stepBunnyHop)
    if not hopOk then
        app.bunnyHopStatus = "Error: "..tostring(hopErr)
        if app.bunnyHopError~=hopErr then app:log("Bunny Hop",tostring(hopErr)) end
        app.bunnyHopError=hopErr
    else app.bunnyHopError=nil end
    app.airTicks = (app.airTicks or 0)+1
    local airOk, airResult = pcall(stepAirControl,dt)
    if airOk then
        app.airCurrent = airResult or "No result"
        app.airError = nil
    else
        app.airCurrent = "Error: "..tostring(airResult)
        app.airDiagnostic = app.airCurrent
        if app.airError ~= airResult then
            app.airError = airResult
            app:log("Air Redirection",tostring(airResult))
        end
    end
    app.airLastActive = app.airCurrent
    local characterToAnimate = if app.mode == "Game" then character else nil
    local ok, err = pcall(walkMotion.step, walkMotion, characterToAnimate, app.s, dt)
    if not ok and not app.walkError then
        app.walkError = true
        app:log("Motion", tostring(err))
        warn("AETHER walk cycle:", err)
    elseif ok then app.walkError = false end
    if ok then
        local tiltOk, tiltError = pcall(walkMotion.applyAirTilt,walkMotion,characterToAnimate,app.airTiltDirection,dt,if app.s.reduce then 0 else app.s.airTiltAngle,false)
        if not tiltOk and not app.airTiltError then app:log("Air Tilt",tostring(tiltError)) end
        app.airTiltError=not tiltOk
    end
    peers:animate(dt)
end)

-- Props follow the already evaluated local pose without modifying character parts.
scope:on(RunService.RenderStepped, function()
    if app.stopping or not gui.Parent then motionProps:clear();return end
    local config = walkMotion.liveConfig
    local active = app.mode == "Game" and character and humanoid and humanoid.Health > 0
        and app.s.walkAnimation and not app.s.reduce and walkMotion.liveStyle == app.s.walkStyle
        and config and config.props and walkMotion.liveSettings == app.s
    local ok, err = pcall(function()
        if active then motionProps:update(character, config.style, walkMotion.liveTime * 4, humanoid:GetState())
        else motionProps:clear() end
    end)
    if not ok then
        motionProps:clear()
        if not app.motionPropError then app.motionPropError = true;warn("AETHER motion props:", err) end
    else app.motionPropError = false end
end)

local elapsed = 0
scope:on(RunService.RenderStepped, function(dt)
    if app.stopping then return end
    if not gui.Parent then scope:clear(); return end
    elapsed += math.min(dt, .1)
    local ok, err = pcall(frame, math.min(dt, .1), elapsed)
    -- Keep drag handles synchronized even if another cosmetic module faults.
    if ui:workspacePageVisible() and app.preview and app.preview.hud and app.preview.hud.previewPanels then
        local good, problem=pcall(app.preview.hud.layoutPreview,app.preview.hud,app.s)
        if not good and not app.previewLayoutError then app.previewLayoutError=true;warn("AETHER preview panels:",problem) end
    end
    if app.editingHUD then
        local good, problem=pcall(app.updateEditor,app)
        if not good and not app.editorError then app.editorError=true;warn("AETHER HUD editor:",problem) end
    end
    if not ok then
        if not app.lastError or elapsed - app.lastError > 2 then
            app.lastError = elapsed
            app:log("Runtime", tostring(err))
            warn("AETHER runtime:", err)
        end
    end
end)
-- Individual cleanup callbacks: one failing subsystem cannot skip the others.
scope:add(function() app:stopCue() end)
scope:add(function() avatar:clear() end)
scope:add(function() walkMotion:destroy() end)
scope:add(function() motionProps:clear() end)
scope:add(function() world:clear() end)
scope:add(function() view:destroy() end)
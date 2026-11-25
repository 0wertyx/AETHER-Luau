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
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100000,
}, pg))
local overlay = U.frame(gui, "HUDLayer", nil, nil, nil, 1)
local pointerGui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Pointer", ResetOnSpawn = false,
    IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None,
    ClipToDeviceSafeArea = false, DisplayOrder = 100003,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, pg))
local pointer = U.frame(pointerGui, "PointerLayer", nil, nil, nil, 1)
pointer.Active=false;pointer.Interactable=false
local studioLayer = U.frame(gui, "StudioLayer", nil, nil, nil, 1)
studioLayer.ZIndex=2

local app = {
    bank = S.blank(), mode = "Game", logs = {}, preview = nil,
    hudTab = "hp", scriptTab = "AETHER Lua",
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
    self:stopCue()
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:restore(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self:stopCue()
    if self.ui and self.ui.tab then self.ui:open(self.ui.tab) end
end
function app:library(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self:dirty()
end
-- Volleyball controls are session-local and never serialized into cosmetic presets.
do
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local vb={originals={},corners={},auto=false,status="Waiting for compatible game",target=nil,tiltBasis="World",tiltScale=1,normalizeTilt=true,tiltWrites=0,tiltOverrides=0}
    app.volleyball=vb
    local attrs={
        BlockPower=true,BumpPower=true,DashPower=true,DiveSpeed=true,
        DrawPower=true,JumpPower=true,ServePower=true,SetPower=true
    }
    local tiltKey="Gameplay_TiltDirection"
    local function available()
        return app.mode=="Game"
            and type(ReplicatedStorage:GetAttribute("GamemodeId"))=="string"
            and typeof(player:GetAttribute(tiltKey))=="Vector3"
            and type(player:GetAttribute("Multiplier_BumpPower"))=="number"
    end
    function vb:available() return available() end
    function vb:tiltDebug()
        local current=player:GetAttribute(tiltKey)
        local function fmt(v)
            if typeof(v)~="Vector3" then return "-" end
            return string.format("%.3f, %.3f, %.3f",v.X,v.Y,v.Z)
        end
        return string.format("Actual: %s\nRequested: %s\nWrites: %d | observed overrides: %d",fmt(current),fmt(self.requestedTilt),self.tiltWrites,self.tiltOverrides)
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
        assert(available(),"Volleyball attributes not available")
        assert(attrs[name],"Unknown multiplier")
        assert(type(value)=="number" and value==value and value>=0 and value<math.huge,"Enter a finite nonnegative number")
        local key="Multiplier_"..name
        assert(type(player:GetAttribute(key))=="number","Multiplier unavailable")
        write(key,value)
        self.status=name.." set locally"
    end
    function vb:reset()
        self.auto=false
        for key in table.clone(self.originals) do restore(key) end
        self.target=nil
        self.status="Original values restored where unchanged"
    end
    local function flatten(p) return Vector3.new(p.X,0,p.Z) end
    function vb:clearCourt()
        self.auto=false;restore(tiltKey)
        table.clear(self.corners);self.target=nil;self.side=nil;self.map=nil;self.status="Calibration cleared"
    end
    function vb:capture(index)
        assert(available(),"Volleyball attributes not available")
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        assert(root and root:IsA("BasePart"),"Character unavailable")
        local map=ReplicatedStorage:GetAttribute("Map")
        if self.map~=map then self:clearCourt();self.map=map end
        self.auto=false;restore(tiltKey);self.target=nil
        self.corners[index]=flatten(root.Position)
        self.status="Court corner "..index.." saved"
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
    function vb:toggleAuto()
        if self.auto then self.auto=false;restore(tiltKey);self.target=nil;self.status="Auto Tilt off";return end
        assert(available(),"Volleyball attributes not available")
        assert(geometry(),"Capture three corners: A, adjacent B across width, C across net at same sideline")
        self.tiltWrites=0;self.tiltOverrides=0;self.requestedTilt=nil
        self.auto=true;self.status="Auto Tilt beta enabled"
    end
    local elapsed=0
    scope:on(RunService.Heartbeat,function(dt)
        elapsed+=dt
        if elapsed<.1 then return end
        elapsed=0
        if app.stopping or not gui.Parent then return end
        if not available() then
            if next(vb.originals) or vb.auto then vb:reset() end
            return
        end
        if not vb.auto then return end
        local actual=player:GetAttribute(tiltKey)
        if vb.requestedTilt and typeof(actual)=="Vector3" and (actual-vb.requestedTilt).Magnitude>.001 then
            vb.tiltOverrides+=1
        end
        local ok,err=pcall(function()
            if ReplicatedStorage:GetAttribute("Map")~=vb.map then vb:clearCourt();return end
            if player:GetAttribute("Gameplay_InGame")~=true then restore(tiltKey);vb.target=nil;vb.status="Waiting for match";return end
            local a,u,v,width,length=geometry()
            if not a then vb:clearCourt();return end
            local char=player.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then restore(tiltKey);return end
            local relative=flatten(root.Position)-a
            local px,pz=relative:Dot(u),relative:Dot(v)
            if px<-5 or px>width+5 or pz<-5 or pz>length+5 then
                restore(tiltKey);vb.target=nil;vb.status="Outside calibrated court";return
            end
            local half=length*.5
            -- Near the net, keep the last observed side instead of oscillating.
            if math.abs(pz-half)>1 then vb.side=if pz<half then -1 else 1 end
            local side=vb.side or (if pz<half then -1 else 1)
            local depth=if side==-1 then length*.75 else length*.25
            local look=flatten(root.CFrame.LookVector)
            local lateral=width*.5
            local dv=look:Dot(v)
            if math.abs(dv)>.05 and (depth-pz)*dv>0 then
                lateral=px+look:Dot(u)*(depth-pz)/dv
            end
            local margin=math.min(2,width*.2)
            lateral=math.clamp(lateral,margin,width-margin)
            local target=a+u*lateral+v*depth
            local heading=target-flatten(root.Position)
            if heading.Magnitude<.01 then return end
            -- Expose both plausible coordinate conventions; neither is verified in-game.
            local axis=heading.Unit
            if vb.tiltBasis=="Character" then
                axis=flatten(root.CFrame:VectorToObjectSpace(axis))
                if axis.Magnitude<.01 then return end
                axis=axis.Unit
            end
            local proposed=axis*vb.tiltScale+Vector3.yAxis
            if vb.normalizeTilt then proposed=proposed.Unit end
            if typeof(actual)=="Vector3" and (actual-proposed).Magnitude>.001 then
                write(tiltKey,proposed)
                vb.tiltWrites+=1
            end
            vb.requestedTilt=proposed
            vb.target=target
            vb.status=string.format("Beta target X %.1f Z %.1f",target.X,target.Z)
        end)
        if not ok then
            vb.auto=false
            pcall(restore,tiltKey)
            vb.status="Auto Tilt error: "..tostring(err)
        end
    end)
    scope:add(function() vb:reset() end)
end

function app:modeSet(mode)
    assert(mode == "Game" or mode == "Simulator", "Invalid AETHER mode")
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
function app:runCue()
    self:stopCue()
    local ok, vm = pcall(Cues.start, self.s.cue, self.grants)
    if ok then self.cues = vm; self:log("Scripts", "HUD script started")
    else self:log("Scripts", vm); error(vm, 0) end
end
-- Live updates are bounded data packages, never downloaded executable Luau.
local updateHttp=game:GetService("HttpService")
local updateState={version="1.0.0",publishedVersion="1.0.0",revision=0,status="Waiting for update relay",busy=false,history={},releases={},generation=0,connected=false,unread=false,testCount=0,isTest=false}
app.liveUpdate=updateState
local function validateUpdate(raw)
    assert(type(raw)=="table" and raw.format=="aether.live/1","Invalid update format")
    assert(type(raw.revision)=="number" and raw.revision%1==0 and raw.revision>=1 and raw.revision<=1000000,"Invalid revision")
    assert(type(raw.version)=="string" and #raw.version<=20 and raw.version:match("^%d+%.%d+%.%d+$"),"Invalid version")
    assert(type(raw.notes)=="string" and #raw.notes<=240,"Invalid release notes")
    assert(type(raw.presets)=="table","Missing preset data")
    local presets={};local count=0
    for group,items in raw.presets do
        assert(table.find({"Theme","Wings","Halos","Character","Neon","Ambient","Motion","HUD","Cursor","Camera","Fonts"},group) and type(items)=="table","Invalid preset group")
        presets[group]={}
        for name,values in items do
            count+=1
            assert(count<=24 and type(name)=="string" and #name>=1 and #name<=40 and not name:find("%c"),"Invalid preset name/count")
            presets[group][name]=S.settings(values,group)
        end
    end
    return {revision=raw.revision,version=raw.version,notes=raw.notes,presets=presets}
end
local function versionGreater(a,b)
    local ax,ay,az=a:match("^(%d+)%.(%d+)%.(%d+)$")
    local bx,by,bz=b:match("^(%d+)%.(%d+)%.(%d+)$")
    local aa={tonumber(ax),tonumber(ay),tonumber(az)}
    local bb={tonumber(bx),tonumber(by),tonumber(bz)}
    for i=1,3 do if aa[i]~=bb[i] then return aa[i]>bb[i] end end
    return false
end
function app:updateStatus(message)
    updateState.status=message
    self:log("Update",message)
    if self.ui then self.ui:sync() end
end
function app:applyLiveUpdate(raw,force)
    if updateState.busy or self.stopping then return end
    updateState.busy=true;updateState.generation+=1
    local gen=updateState.generation
    self:updateStatus("Validating update...")
    task.delay(.35,function()
        if self.stopping or gen~=updateState.generation then return end
        local ok,pack=pcall(validateUpdate,raw)
        if not ok then updateState.busy=false;self:updateStatus("Rejected: "..tostring(pack):sub(-100));return end
        if not force and (pack.revision<=updateState.revision or not versionGreater(pack.version,updateState.publishedVersion)) then updateState.busy=false;self:updateStatus("Already up to date");return end
        local before={version=updateState.version,publishedVersion=updateState.publishedVersion,revision=updateState.revision,notes=updateState.notes,presets=S.copy(S.presets),isTest=updateState.isTest}
        local staged=S.copy(S.presets)
        for group,items in pack.presets do
            staged[group]=staged[group] or {}
            for name,values in items do staged[group][name]=values end
        end
        -- Swap one validated data table. Preserve all settings, profile bank,
        -- current page, HUD, avatar, render callbacks and the session itself.
        S.presets=staged
        updateState.version=pack.version;updateState.isTest=force==true;if not force then updateState.revision=pack.revision;updateState.publishedVersion=pack.version end;updateState.notes=pack.notes
        local applied,err=pcall(function() self:updateStatus("Updated live to "..pack.version) end)
        if not applied then
            S.presets=before.presets;updateState.version=before.version;updateState.publishedVersion=before.publishedVersion;updateState.revision=before.revision;updateState.notes=before.notes;updateState.isTest=before.isTest
            updateState.status="Update rolled back: "..tostring(err):sub(-100)
        else
            table.insert(updateState.history,before)
            while #updateState.history>5 do table.remove(updateState.history,1) end
            if force then updateState.testCount+=1 end
            table.insert(updateState.releases,1,{version=pack.version,notes=pack.notes,source=if force then "LOCAL TEST "..tostring(updateState.testCount) else "WEBSITE",time=os.date("%H:%M:%S")})
            while #updateState.releases>12 do table.remove(updateState.releases) end
            updateState.unread=not (self.ui and self.ui.opened and self.ui.tab=="Updates")
        end
        updateState.busy=false
        if self.ui then self.ui:sync() end
    end)
end
function app:testLiveUpdate()
    local revision=updateState.revision+1
    self:applyLiveUpdate({format="aether.live/1",revision=revision,version=updateState.publishedVersion,notes="Live test: new Aurora glass theme and Lunar halo preset. Existing settings remain intact.",presets={Theme={["Live Aurora"]={accent="8DEBFF",secondary="D8ACFF",glassColor="22243E"}},Halos={["Live Lunar"]={halo=true,haloStyle="Lunar",haloColor="C4B5FF"}}}},true)
end
function app:checkLiveUpdate()
    if updateState.busy then return end
    local manifest=game:GetService("ReplicatedStorage"):FindFirstChild("AetherLiveManifestV1")
    if not manifest or not manifest:IsA("StringValue") or manifest.Value=="" then self:updateStatus("No update manifest available. Use Test update or enable the server relay.");return end
    if #manifest.Value>32000 then self:updateStatus("Manifest too large");return end
    local ok,raw=pcall(function() return updateHttp:JSONDecode(manifest.Value) end)
    if not ok then self:updateStatus("Invalid manifest JSON");return end
    self:applyLiveUpdate(raw,false)
end
function app:rollbackLiveUpdate()
    if updateState.busy then return end
    local before=table.remove(updateState.history)
    if not before then self:updateStatus("No previous update");return end
    S.presets=before.presets;updateState.version=before.version;updateState.publishedVersion=before.publishedVersion;updateState.revision=before.revision;updateState.notes=before.notes;updateState.isTest=before.isTest
    updateState.unread=false
    self:updateStatus("Rolled back to "..before.version)
end

function app:page(tab, ui)
    Pages.render(self, tab, ui)
end
function app:onMenu(open)
    if open and self.editingHUD then self.editingHUD=false;self.ui.drag=nil end
    if open and self.view then self.view:releaseLock(self.view:nativeLockAvailable()) end
    if self.refreshGameInput then self:refreshGameInput() end
end
function app:drag(input, key, widget, frame, source)
    local panel=key=="top" or key=="rail"
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
                for _,other in {"hp","clock","profile","dock"} do
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

local hud = Hud.new(scope, overlay, false, function(tab) app.ui:open(tab) end,nil,function(key) app:set(key,false) end)
local avatar = Avatar.new(workspace, false)
local walkMotion = WalkMotion.new()
app.walkMotion = walkMotion
local peers = PeerVisuals.new(player,scope)
app.peers = peers
local motionProps = PreviewProps.new(workspace, true)
local world = World.new()
local view = View.new(player, pointer)
app.view = view
local ui = Controls.new(app, studioLayer, scope)
app.ui = ui
-- Decorative layers must not claim game input, even with a centered mouse.
-- When the Studio menu is closed, preserve the HUD artwork but temporarily
-- make its controls noninteractive. Restore their original flags on open.
do
    local saved = setmetatable({}, {__mode="k"})
    local passing = false
    local function disable(obj)
        if not obj:IsA("GuiObject") then return end
        if not saved[obj] then saved[obj]={active=obj.Active,interactable=obj.Interactable} end
        obj.Active=false;obj.Interactable=false
    end
    local function pointerOnly(obj)
        if obj:IsA("GuiObject") then obj.Active=false;obj.Interactable=false end
    end
    pointerOnly(pointer)
    for _,obj in pointer:GetDescendants() do pointerOnly(obj) end
    scope:on(pointer.DescendantAdded,pointerOnly)
    for _,layer in {overlay,studioLayer} do
        scope:on(layer.DescendantAdded,function(obj) if passing then disable(obj) end end)
    end
    function app:refreshGameInput()
        local pass=self.s.gameInputPassthrough and self.mode=="Game" and not ui.opened and not self.editingHUD
        if pass==passing then return end
        passing=pass
        if pass then
            for _,layer in {overlay,studioLayer} do
                disable(layer)
                for _,obj in layer:GetDescendants() do disable(obj) end
            end
        else
            for obj,flags in saved do
                if obj.Parent then obj.Active=flags.active;obj.Interactable=flags.interactable end
            end
            table.clear(saved)
            ui.panel.Interactable=ui.opened
        end
    end
    scope:on(RunService.Heartbeat,function()
        if not app.stopping and gui.Parent then app:refreshGameInput() end
    end)
end
local store = Storage.new(app, scope)
app.store = store

-- Observe the first-party replicated manifest. A revision that arrives
-- during validation remains queued; rollback is not immediately undone.
local updateRS=game:GetService("ReplicatedStorage")
local relayConnection=nil
local relayStatusConnection=nil
local relayInstance=nil
local pendingManifest=nil
local lastManifest=nil
local function observeRelay(value)
    if value.Name~="AetherLiveManifestV1" or not value:IsA("StringValue") then return end
    if relayConnection then relayConnection:Disconnect() end
    if relayStatusConnection then relayStatusConnection:Disconnect() end
    relayInstance=value
    updateState.connected=true
    local function receive()
        if value.Value~="" and value.Value~=lastManifest then
            lastManifest=value.Value
            pendingManifest=value.Value
        end
    end
    relayConnection=value:GetPropertyChangedSignal("Value"):Connect(receive)
    local function refreshRelayStatus()
        updateState.relayStatus=tostring(value:GetAttribute("RelayStatus") or "CONNECTED / STATUS UNKNOWN")
        if app.ui then app.ui:sync() end
    end
    relayStatusConnection=value:GetAttributeChangedSignal("RelayStatus"):Connect(refreshRelayStatus)
    refreshRelayStatus()
    receive()
    app:updateStatus("Website update relay connected")
end
scope:on(updateRS.ChildAdded,observeRelay)
scope:on(updateRS.ChildRemoved,function(value)
    if value~=relayInstance then return end
    if relayConnection then relayConnection:Disconnect();relayConnection=nil end
    if relayStatusConnection then relayStatusConnection:Disconnect();relayStatusConnection=nil end
    relayInstance=nil;pendingManifest=nil;lastManifest=nil;updateState.connected=false;updateState.relayStatus=nil
    app:updateStatus("Website update relay disconnected")
end)
scope:add(function()
    if relayConnection then relayConnection:Disconnect() end
    if relayStatusConnection then relayStatusConnection:Disconnect() end
end)
local existingRelay=updateRS:FindFirstChild("AetherLiveManifestV1")
if existingRelay then observeRelay(existingRelay) end
scope:on(RunService.Heartbeat,function()
    if app.stopping or updateState.busy or not pendingManifest then return end
    local body=pendingManifest;pendingManifest=nil
    if #body>32000 then app:updateStatus("Manifest too large");return end
    local ok,raw=pcall(function() return updateHttp:JSONDecode(body) end)
    if not ok then app:updateStatus("Invalid manifest JSON");return end
    if type(raw)=="table" and type(raw.revision)=="number" and raw.revision<=updateState.revision then return end
    app:applyLiveUpdate(raw,false)
end)

-- Non-persistent editing session. Handles exist only while arranging the live HUD.
local editorGui=scope:add(U.new("ScreenGui",{Name="AETHER_HUD_Editor",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100002,ZIndexBehavior=Enum.ZIndexBehavior.Global,Enabled=false},pg))
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
    app:set("movePanels",not app.s.movePanels)
    app:updateEditor()
end)
local handles={}
local positions={"hp","clock","profile","dock","input","wallhop","top","rail"}
local function isPanel(key) return key=="top" or key=="rail" end
local function widgetFor(key)
    if key=="input" then return hud.inputRoot end
    if key=="wallhop" then return hud.wallhop end
    if key=="top" then return ui.top end
    if key=="rail" then return ui.rail end
    return hud.widgets[key].p
end
local function coord(key,topLeft,size,vp)
    if key=="input" or key=="wallhop" then
        return math.clamp(math.round((topLeft.X+size.X*.5)/math.max(1,vp.X)*100),0,100),math.clamp(math.round((topLeft.Y+size.Y*.5)/math.max(1,vp.Y)*100),0,100)
    end
    return math.clamp(math.round(topLeft.X/math.max(1,vp.X-size.X)*100),0,100),math.clamp(math.round(topLeft.Y/math.max(1,vp.Y-size.Y)*100),0,100)
end
function app:editHUD(on)
    if self.stopping then return end
    if on then
        ui:show(false)
        self.editingHUD=true
        editorGui.Enabled=true
        self.view:releaseLock(self.view:nativeLockAvailable())
    else
        self.editingHUD=false
        editorGui.Enabled=false
        ui.drag=nil
        ui:open("HUD")
    end
end
scope:on(done.Activated,function() app:editHUD(false) end)
for _,key in positions do
    local b=U.button(editor,key:upper())
    b.Name="Move_"..key;b.TextSize=12;b.BackgroundTransparency=.84;b.TextColor3=Color3.fromRGB(255,242,255);b.ZIndex=9;b.Active=true;b.AutoButtonColor=false;b.Visible=false;b.Modal=false
    b.TextStrokeTransparency=.35
    U.stroke(b,Color3.fromRGB(224,183,255),0,2.5)
    handles[key]=b
    scope:on(b.InputBegan,function(input)
        if not app.editingHUD or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
        local target=widgetFor(key)
        if not target.Visible or (isPanel(key) and not app.s.movePanels) then return end
        local vp=overlay.AbsoluteSize
        local size=target.AbsoluteSize
        local original=target.AbsolutePosition-overlay.AbsolutePosition
        -- Preserve all currently visible classic widget positions before leaving Sketch.
        local patch={}
        if app.s.layoutMode=="Sketch" and key~="input" and key~="wallhop" and not isPanel(key) then
            patch.layoutMode="Custom"
            for _,other in {"hp","clock","profile","dock"} do
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
                if not app.s.movePanels then return end
                if not app.s[key.."Custom"] or app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."Custom"]=true,[key.."X"]=x,[key.."Y"]=y}) end
            elseif app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."X"]=x,[key.."Y"]=y}) end
        end)
    end)
end
function app:updateEditor()
    editorGui.Enabled=self.editingHUD==true
    if not self.editingHUD then return end
    panelToggle.Text=if self.s.movePanels then "PANELS: MOVE" else "PANELS: LOCKED"
    panelToggle.BackgroundColor3=if self.s.movePanels then Color3.fromRGB(105,71,164) else Color3.fromRGB(52,40,77)
    for _,key in positions do
        local b,target=handles[key],widgetFor(key)
        b.Visible=target.Visible and (if key=="top" then self.s.topCapsule elseif key=="rail" then self.s.robloxRail elseif key=="input" then self.s.inputOverlay elseif key=="wallhop" then self.s.wallhopHelper else self.s[key])
        local locked=isPanel(key) and not self.s.movePanels
        b.Active=not locked;b.Interactable=not locked
        b.Text=key:upper()..(if locked then " · LOCKED" else " · MOVE")
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
    if store.dirty and store.ready and not store.pending then pcall(function() store:save() end) end
    -- Defer destruction until the current GUI activation callback has returned.
    task.defer(function() scope:clear() end)
end
ui:open("Dashboard")
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
    if processed and not chosenShift then return end
    local menuKey=S.menuKey(app.s)
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
    ui:animateBackground(now)
    hud:step(styled, result, dt)
    avatar:step(if app.mode == "Game" then character else nil, styled, workspace:GetServerTimeNow())
    peers:step(styled, app.mode=="Game", walkMotion, dt)
    if peers.statusLabel and peers.statusLabel.Parent and peers.statusLabel.Text~=peers.status then peers.statusLabel.Text=peers.status end
    world:apply(styled)
    view:step(styled, if app.mode=="Game" then humanoid else nil, ui.opened or app.editingHUD==true, dt, now)
    if app.preview then
        if app.preview.hud then app.preview.hud:step(styled, result, dt) end
        if app.preview.pose then app.preview.pose(styled, dt) end
        if app.preview.avatar then app.preview.avatar:step(app.preview.rig, styled, app.preview.effectTime or now) end
        view:preview(app.preview.cursorHost,styled)
    end
    store:tick(now)
end
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
    if app.preview and app.preview.hud and app.preview.hud.previewPanels then
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
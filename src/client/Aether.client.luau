--!strict
-- AETHER client entry: regular Roblox LocalScript, no external loader.
-- Modules are synchronized by Rojo into ReplicatedStorage.Aether.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
local World = module("World")
local View = module("View")
local Controls = module("Controls")
local Pages = module("Pages")
local Storage = module("Storage")
local Cues = module("Cues")
local Cursor = module("Cursor")

-- Prevent multiple copies if the script is restarted in Studio.
local pg = player:WaitForChild("PlayerGui")
local prior = pg:FindFirstChild("AETHER_Studio")
if prior then prior:Destroy() end
local scope = U.scope()
local gui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Studio", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50,
}, pg))
local overlay = U.frame(gui, "HUDLayer", nil, nil, nil, 1)
local pointer = U.frame(gui, "PointerLayer", nil, nil, nil, 1)
local cursor = Cursor.new(pg, scope)
local studioLayer = U.frame(gui, "StudioLayer", nil, nil, nil, 1)

local app = {
    bank = S.blank(), mode = "Game", logs = {}, preview = nil,
    hudTab = "hp", libraryKind = "Theme", scriptTab = "AETHER Lua",
    grants = {widgets = false, appearance = false, events = false},
    sim = {hp = 100, max = 100, gen = 0, players = {}},
    frame = {hp = nil, max = nil, gen = 0, name = player.DisplayName, mode = "GAME", targets = {}, widgets = {}},
    cues = nil, lastVitals = nil, altLock = false,
}
app.s = app.bank.settings

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
function app:page(tab, ui)
    Pages.render(self, tab, ui)
end
function app:onMenu(open)
    if open and self.view then self.view:releaseLock() end
end
function app:drag(input, key, widget, frame)
    if self.s.locked then return end
    local start = Vector2.new(input.Position.X, input.Position.Y)
    local x0, y0 = self.s[key .. "X"], self.s[key .. "Y"]
    self.ui:begin(input, function(pos)
        local delta = pos - start
        local w, h = math.max(frame.AbsoluteSize.X, 1), math.max(frame.AbsoluteSize.Y, 1)
        local x = math.clamp(math.round(x0 + delta.X / w * 100), 0, 100)
        local y = math.clamp(math.round(y0 + delta.Y / h * 100), 0, 100)
        if self.s[key .. "X"] ~= x or self.s[key .. "Y"] ~= y then
            self:patch({[key .. "X"] = x, [key .. "Y"] = y})
        end
    end)
end

local hud = Hud.new(scope, overlay, false, function(tab) app.ui:open(tab) end)
local avatar = Avatar.new(workspace, false)
local world = World.new()
local view = View.new(player, pointer)
app.view = view
local ui = Controls.new(app, studioLayer, scope)
app.ui = ui
local store = Storage.new(app, scope)
app.store = store
ui:open("Dashboard")
ui:show(false)
app:log("Startup", "AETHER modules initialized")

local humanoid, character, generation = nil, nil, 0
local function bind(char)
    generation += 1
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
end
scope:on(player.CharacterAdded, bind)
scope:on(player.CharacterRemoving, function(char)
    if character == char then character, humanoid = nil, nil end
    avatar:clear()
end)
if player.Character then bind(player.Character) end

scope:on(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift then ui:show(not ui.opened)
    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        app.altLock = not app.altLock
        app:set("lock", app.altLock)
    end
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
    hud:step(styled, result, dt)
    avatar:step(if app.mode == "Game" then character else nil, styled, now)
    world:apply(styled)
    view:step(styled, humanoid, ui.opened, dt, now)
    cursor:step(styled, ui.opened, now)
    if app.preview then
        if app.preview.hud then app.preview.hud:step(styled, result, dt) end
        if app.preview.avatar then app.preview.avatar:step(app.preview.rig, styled, now) end
        if app.preview.cursor then
            app.preview.cursor:shape(styled.cursorShape,60)
            app.preview.cursor:paint(U.hex(styled.cursorA),U.hex(styled.cursorB),styled.cursorGlow,6)
        end
    end
    store:tick(now)
end
local elapsed = 0
scope:on(RunService.RenderStepped, function(dt)
    if not gui.Parent then scope:clear(); return end
    elapsed += math.min(dt, .1)
    local ok, err = pcall(frame, math.min(dt, .1), elapsed)
    if not ok then
        if not app.lastError or elapsed - app.lastError > 2 then
            app.lastError = elapsed
            app:log("Runtime", tostring(err))
            warn("AETHER runtime:", err)
        end
    end
end)
scope:add(function()
    app:stopCue()
    avatar:clear()
    world:clear()
    view:destroy()
    cursor:destroy()
end)
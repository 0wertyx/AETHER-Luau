-- Disable the built-in Shift Lock option in the experience owner's server.
-- This does not bind, swallow or remap LeftShift or RightShift.
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
StarterPlayer.EnableMouseLockOption = false
local function configure(player)
    player.DevEnableMouseLock = false
end
Players.PlayerAdded:Connect(configure)
for _, player in Players:GetPlayers() do
    configure(player)
end

-- Opt-in, same-server cosmetic relay. No HTTP, persistence or cross-server tracking.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Schema=require(RS:WaitForChild("Aether"):WaitForChild("Schema"))
local remote=Instance.new("RemoteEvent");remote.Name="AetherPeerVisualsV1";remote.Parent=RS
local active,last={},{}
local function same(a,b)
 if not a or not b then return false end
 for k,v in a do if b[k]~=v then return false end end
 for k,v in b do if a[k]~=v then return false end end
 return true
end
local function remove(player)
 if not active[player] then return end
 active[player]=nil
 for other in active do if other.Parent==Players then remote:FireClient(other,"remove",player) end end
end
remote.OnServerEvent:Connect(function(player,op,data)
 if op=="leave" then remove(player);return end
 if op~="share" or type(data)~="table" then return end
 local now=os.clock()
 if last[player] and now-last[player]<.25 then return end
 last[player]=now
 local ok,packet=pcall(Schema.peerPacket,data)
 if not ok then return end
 local old=active[player]
 local changed=not old or not same(old.packet,packet)
 active[player]={packet=packet,time=now}
 if not old then
  for other,entry in active do if other~=player and other.Parent==Players then remote:FireClient(player,"update",other,entry.packet) end end
 end
 -- Acknowledge every accepted share, including unchanged heartbeat packets.
 remote:FireClient(player,"ready",2)
 if changed then
  for other in active do if other~=player and other.Parent==Players then remote:FireClient(other,"update",player,packet) end end
 end
end)
Players.PlayerRemoving:Connect(function(player) remove(player);last[player]=nil end)
while task.wait(5) do
 local now=os.clock()
 for player,entry in active do if now-entry.time>25 or player.Parent~=Players then remove(player) end end
end

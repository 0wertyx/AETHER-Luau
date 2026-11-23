-- Transient Studio plugin used only for this generated, nonce-marked test place.
if not plugin or not workspace:FindFirstChild("FIXTURE_NONCE") then return end
local r=game:GetService("RunService");if r:IsRunning() or not r:IsEdit() then return end
task.defer(function()
 task.wait(3);local ok,value=pcall(function() return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{fixture="FIXTURE_NONCE"}) end)
 print("AETHER_FULL_RESULT FIXTURE_NONCE "..game:GetService("HttpService"):JSONEncode({launched=ok,result=tostring(value)}))
end)

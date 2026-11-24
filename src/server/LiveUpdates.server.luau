-- Optional first-party data-only live update relay. Enable HTTP requests in
-- your own experience and set this script's EnabledRelay attribute to true.
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
if script:GetAttribute("EnabledRelay")~=true then return end
local url="https://raw.githubusercontent.com/0wertyx/AETHER-Luau/main/updates/live.json"
local manifest=RS:FindFirstChild("AetherLiveManifestV1")
if manifest and not manifest:IsA("StringValue") then return end
if not manifest then manifest=Instance.new("StringValue");manifest.Name="AetherLiveManifestV1";manifest.Parent=RS end
while script.Parent do
 local ok,body=pcall(function() return Http:GetAsync(url,true) end)
 if ok and #body<=32000 then
  local good,data=pcall(function() return Http:JSONDecode(body) end)
  if good and type(data)=="table" and data.format=="aether.live/1" and type(data.revision)=="number" and type(data.presets)=="table" then
   if manifest.Value~=body then manifest.Value=body end
  end
 end
 task.wait(15)
end

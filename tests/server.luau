if not game:GetService("RunService"):IsStudio() or not workspace:FindFirstChild("FIXTURE_NONCE") then return end
local P=game:GetService("Players");local ender=game:GetService("StudioTestService");local ev=Instance.new("RemoteEvent");ev.Name="FIXTURE_NONCE";ev.Parent=game:GetService("ReplicatedStorage");local driver,done
P.RespawnTime=90
local function add(p) if not driver then driver=p end;p:SetAttribute("AetherTestDriver",driver==p);p:SetAttribute("AetherShareBearing",true) end
P.PlayerAdded:Connect(add);for _,p in P:GetPlayers() do add(p) end
local function finish(msg) if done then return end;done=true;print("AETHER_FULL_SERVER FIXTURE_NONCE "..msg);ender:EndTest(msg) end
ev.OnServerEvent:Connect(function(p,op,value)
 if p~=driver or done then return end
 if op=="result" then finish(tostring(value):sub(1,1800));return end
 if op=="R6" or op=="R15" then local ok,err=pcall(function()
  local d=Instance.new("HumanoidDescription");local model=P:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType[op]);d:Destroy();local old=p.Character;model.Name=p.Name;model:SetAttribute("FixtureRig",op);model:PivotTo(CFrame.new(0,6,0));model.HumanoidRootPart.Anchored=true;model.Parent=workspace;p.Character=model;if old and old~=model then old:Destroy() end;model.Humanoid.MaxHealth=160;model.Humanoid.Health=160
 end);if not ok then finish("FAIL rig: "..tostring(err)) end
 elseif op=="hp" and type(value)=="number" and table.find({0,16,80,140},value) then p.Character.Humanoid.Health=value
 elseif op=="share" then for _,other in P:GetPlayers() do if other~=p then other:SetAttribute("AetherShareBearing",value==true) end end end
end)
task.delay(105,function() finish("FAIL fixture timeout") end)

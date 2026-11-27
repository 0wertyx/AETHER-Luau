local RS=game:GetService("ReplicatedStorage");local Http=game:GetService("HttpService");local S=require(script.Parent.Schema)
local Store={};Store.__index=Store
-- Optional host-provided file storage. Ordinary Roblox clients fall back to
-- the existing session / explicitly installed server store.
local FILES={"AETHER_config_v1_a.json","AETHER_config_v1_b.json"}
local MAX_BYTES=120000
local function readSlot(path)
 local ok,raw=pcall(readfile,path)
 if not ok or type(raw)~="string" or #raw>MAX_BYTES then return nil end
 local good,result=pcall(function()
  local envelope=Http:JSONDecode(raw)
  assert(envelope.format=="aether.device/1" and type(envelope.sequence)=="number" and envelope.sequence>=1 and envelope.sequence<=9007199254740990 and envelope.sequence==math.floor(envelope.sequence),"Invalid device bank")
  return {sequence=envelope.sequence,bank=S.bank(envelope.data)}
 end)
 return if good then result else nil
end
function Store:loadDevice()
 local best,index
 for i,path in FILES do
  local result=readSlot(path)
  if result and (not best or result.sequence>best.sequence) then best=result;index=i end
 end
 if not best then return false end
 self.app:restore(best.bank)
 self.deviceSequence=best.sequence;self.deviceSlot=index;self.dirty=false
 self:cacheBank();self.status="Device configuration restored"
 return true
end
function Store:writeDevice()
 local valid,raw=pcall(function()
  return Http:JSONEncode({format="aether.device/1",sequence=self.deviceSequence+1,data=S.bank(self.app.bank)})
 end)
 if not valid or #raw>MAX_BYTES then self.status="Device bank invalid or too large";return false end
 local slot=if self.deviceSlot==1 then 2 else 1
 local serial=self.serial
 self.lastWrite=os.clock()
 local ok=pcall(writefile,FILES[slot],raw)
 local checked=if ok then readSlot(FILES[slot]) else nil
 if not checked or checked.sequence~=self.deviceSequence+1 then
  self.status="Device save failed · previous config retained"
  return false
 end
 self.deviceSequence=checked.sequence;self.deviceSlot=slot
 if self.serial==serial then self.dirty=false end
 self.status="Saved on this device"
 return true
end
function Store.new(app,scope)
 local self=setmetatable({app=app,revision=0,serial=0,dirty=false,id=0,lastEdit=0,lastWrite=-100,status="Local session · JSON available",ready=false},Store)
 local pg=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
 local cache=pg:FindFirstChild("AETHER_SessionBank")
 if not cache then cache=Instance.new("StringValue");cache.Name="AETHER_SessionBank";cache.Parent=pg end
 self.cache=cache
 self.device=type(readfile)=="function" and type(writefile)=="function"
 self.deviceSequence=0;self.deviceSlot=0
 if cache:IsA("StringValue") and cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(cache.Value)) end)
  if ok then app:restore(bank);self.status="Local session restored" end
 end
 if self.device then
  if not self:loadDevice() then
   self.status="Device storage · first save pending"
   if cache:IsA("StringValue") and cache.Value~="" then self.dirty=true end
  end
  -- A local device bank is private and is never sent to an experience.
  return self
 end
 local function attach(r)
  if self.remote or r.Name~="AetherFullStoreV1" or not r:IsA("RemoteEvent") then return end;self.remote=r
  scope:on(r.OnClientEvent,function(id,ok,msg,rev,body)
   local p=self.pending;if not p or id~=p.id then return end;self.pending=nil;self.status=msg
   if not ok then if msg=="Revision conflict · reload or export" or p.op=="read" then self.ready=false end;app:log("Store",msg);return end
   self.revision=rev;if p.op=="read" then local good,bank=pcall(function() return S.bank(Http:JSONDecode(body)) end);if not good then self.status="Unreadable bank · local edits retained";return end
    if p.serial==self.serial and (p.force or not self.dirty) then app:restore(bank);self.dirty=false;self:cacheBank() end;self.ready=true
   elseif self.serial==p.serial then self.dirty=false end;app:log("Store",msg)
  end);self:read(false)
 end
 scope:on(RS.ChildAdded,attach);local r=RS:FindFirstChild("AetherFullStoreV1");if r then attach(r) end;return self
end
function Store:cacheBank()
 local ok,data=pcall(function() return Http:JSONEncode(S.bank(self.app.bank)) end)
 if not ok or #data>110000 then self.status="Bank invalid or too large";return false end
 if self.cache and self.cache:IsA("StringValue") then self.cache.Value=data;return true end
 return false
end
function Store:edit()
 self.serial+=1;self.dirty=true;self.lastEdit=os.clock()
 self:cacheBank()
 if self.device then
  self.status="Device changes pending"
  -- First edit is saved immediately; continuous slider edits are coalesced.
  if os.clock()-self.lastWrite>=.5 and not self.writing then self:save() end
 end
end
function Store:request(op,body,force)
 if not self.remote or not self.remote.Parent then self.status="Local session only · export a JSON bank";return false end
 if self.pending then return false end;self.id+=1;self.pending={id=self.id,op=op,serial=self.serial,force=force,start=os.clock()};self.status=if op=="read" then "Reading bank…" else "Saving bank…";self.remote:FireServer(self.id,op,self.revision,body);return true
end
function Store:read(force)
 if self.device then
  if self.writing then self.status="Device save in progress";return false end
  if not self:loadDevice() then self.status="No valid device configuration";return false end
  return true
 end
 if self.remote then return self:request("read",nil,force) end
 if force and self.cache and self.cache:IsA("StringValue") and self.cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(self.cache.Value)) end)
  if ok then self.app:restore(bank);self.status="Session bank restored";return true end
 end
 self.status="No saved session bank";return false
end
function Store:save()
 if self.device then
  if self.writing then return false end
  self.writing=true
  local ok,result=pcall(function() return self:writeDevice() end)
  self.writing=false
  if not ok then self.lastWrite=os.clock();self.status="Device save failed · previous config retained";return false end
  return result
 end
 if not self.ready then if self:cacheBank() then self.status="Saved for this game session";return true end;return false end
 local data=Http:JSONEncode(self.app.bank);if #data>110000 then self.status="Bank exceeds 110 KB · remove or export assets";return false end;self.lastWrite=os.clock();return self:request("write",data,false)
end
function Store:tick(now)
 if self.device then
  if self.dirty and not self.writing and os.clock()-self.lastWrite>=.5 and os.clock()-self.lastEdit>=.25 then
   task.defer(function() if self.dirty and not self.writing then self:save() end end)
   self.lastWrite=os.clock()
  end
  return
 end
 if self.pending and now-self.pending.start>18 then self.pending=nil;self.ready=false;self.status="Store timeout · reload or export" end
 if self.dirty and self.ready and not self.pending and now-self.lastEdit>2 and now-self.lastWrite>12 then self:save() end
end
return Store
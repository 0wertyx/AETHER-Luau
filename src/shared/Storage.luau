local RS=game:GetService("ReplicatedStorage");local Http=game:GetService("HttpService");local S=require(script.Parent.Schema)
local Store={};Store.__index=Store
-- Optional host-provided file adapter. Standard Roblox LocalScripts have no
-- device filesystem; keep the supported session/server/JSON fallback.
local function deviceAdapter()
 if type(readfile)~="function" or type(writefile)~="function" then return nil end
 return {read=readfile,write=writefile}
end
local function decodeSlot(raw)
 assert(type(raw)=="string" and #raw<=115000,"Invalid slot size")
 local obj=Http:JSONDecode(raw)
 assert(obj.format=="aether.device/1" and type(obj.seq)=="number" and obj.seq>=1 and obj.seq<=1e12 and obj.seq%1==0,"Invalid slot")
 return S.bank(obj.data),obj.seq
end
function Store:readDevice()
 local best,seq=nil,0
 for _,suffix in {"a","b"} do
  local ok,bank,n=pcall(function()
   return decodeSlot(self.device.read(self.devicePrefix.."_"..suffix..".json"))
  end)
  if ok and n>seq then best=bank;seq=n end
 end
 if not best then return nil end
 self.deviceSequence=seq
 return best
end
function Store:saveDevice()
 self.lastWrite=os.clock()
 local serial=self.serial
 local ok,err=pcall(function()
  local bank=S.bank(self.app.bank)
  local seq=self.deviceSequence+1
  local raw=Http:JSONEncode({format="aether.device/1",seq=seq,data=bank})
  assert(#raw<=115000,"Bank exceeds device limit; export or remove assets")
  local suffix=if seq%2==1 then "a" else "b"
  local path=self.devicePrefix.."_"..suffix..".json"
  self.device.write(path,raw)
  local verified=self.device.read(path)
  assert(verified==raw,"Device write verification failed")
  local _,actual=decodeSlot(verified)
  assert(actual==seq,"Device sequence mismatch")
  self.deviceSequence=seq
 end)
 if not ok then self.status="Device save failed · "..tostring(err);self.dirty=true;self:cacheBank();return false end
 if self.serial==serial then self.dirty=false;self.dirtySince=nil end
 self:cacheBank()
 self.status="Saved on device · verified #"..tostring(self.deviceSequence)
 return true
end
function Store.new(app,scope)
 local self=setmetatable({app=app,revision=0,serial=0,dirty=false,id=0,lastEdit=0,lastWrite=-100,status="Local session · JSON available",ready=false},Store)
 local player=game:GetService("Players").LocalPlayer
 self.device=deviceAdapter();self.deviceSequence=0;self.devicePrefix="AETHER_config_"..tostring(player.UserId)
 local pg=player:WaitForChild("PlayerGui")
 local cache=pg:FindFirstChild("AETHER_SessionBank")
 if not cache then cache=Instance.new("StringValue");cache.Name="AETHER_SessionBank";cache.Parent=pg end
 self.cache=cache
 if cache:IsA("StringValue") and cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(cache.Value)) end)
  if ok then app:restore(bank);self.status="Local session restored" end
 end
 if self.device then
  local bank=self:readDevice()
  if bank then app:restore(bank);self:cacheBank();self.status="Restored from device · #"..tostring(self.deviceSequence)
  else self.status="Device storage available · no valid saved bank" end
  self.ready=true
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
 self.serial+=1;self.dirty=true;self.lastEdit=os.clock();self.dirtySince=self.dirtySince or self.lastEdit
 if not self.device then self:cacheBank() end
end
function Store:request(op,body,force)
 if not self.remote or not self.remote.Parent then self.status="Local session only · export a JSON bank";return false end
 if self.pending then return false end;self.id+=1;self.pending={id=self.id,op=op,serial=self.serial,force=force,start=os.clock()};self.status=if op=="read" then "Reading bank…" else "Saving bank…";self.remote:FireServer(self.id,op,self.revision,body);return true
end
function Store:read(force)
 if self.device then
  local bank=self:readDevice()
  if not bank then self.status="No valid device bank · current settings retained";return false end
  self.app:restore(bank);self.dirty=false;self.dirtySince=nil;self:cacheBank()
  self.status="Restored from device · #"..tostring(self.deviceSequence);return true
 end
 if self.remote then return self:request("read",nil,force) end
 if force and self.cache and self.cache:IsA("StringValue") and self.cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(self.cache.Value)) end)
  if ok then self.app:restore(bank);self.status="Session bank restored";return true end
 end
 self.status="No saved session bank";return false
end
function Store:save()
 if self.device then return self:saveDevice() end
 if not self.ready then if self:cacheBank() then self.dirty=false;self.dirtySince=nil;self.status="Saved for this game session";return true end;return false end
 local data=Http:JSONEncode(self.app.bank);if #data>110000 then self.status="Bank exceeds 110 KB · remove or export assets";return false end;self.lastWrite=os.clock();return self:request("write",data,false)
end
function Store:tick(now)
 if self.device then
  if self.dirty and now-self.lastWrite>=.5 and (now-self.lastEdit>=.35 or (self.dirtySince and now-self.dirtySince>=2)) then self:saveDevice() end
  return
 end
 if self.pending and now-self.pending.start>18 then self.pending=nil;self.ready=false;self.status="Store timeout · reload or export" end
 if self.dirty and self.ready and not self.pending and now-self.lastEdit>2 and now-self.lastWrite>12 then self:save() end
end
return Store
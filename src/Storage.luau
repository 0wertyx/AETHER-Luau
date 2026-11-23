local RS=game:GetService("ReplicatedStorage");local Http=game:GetService("HttpService");local S=require(script.Parent.Schema)
local Store={};Store.__index=Store
function Store.new(app,scope)
 local self=setmetatable({app=app,revision=0,serial=0,dirty=false,id=Random.new():NextInteger(1,1000000000),lastEdit=0,lastWrite=-100,status="Local session · JSON available",ready=false},Store)
 local function attach(r)
  if self.remote or r.Name~="AetherFullStoreV1" or not r:IsA("RemoteEvent") then return end;self.remote=r
  scope:on(r.OnClientEvent,function(id,ok,msg,rev,body)
   local p=self.pending;if not p or id~=p.id then return end;self.pending=nil;self.status=msg
   if not ok then
    if msg=="Revision conflict · reload or export" or p.op=="read" then self.ready=false end
    -- A fresh mount can read while its predecessor's write/read is still settling.
    if msg=="Store busy · retry" and p.op=="read" and p.attempt<5 then self.retry={at=os.clock()+.4*2^p.attempt,attempt=p.attempt+1,force=p.force,serial=p.serial};self.status="Store busy · retrying read" end
    app:log("Store",self.status);return
   end
   self.revision=rev;if p.op=="read" then local good,bank=pcall(function() return S.bank(Http:JSONDecode(body)) end);if not good then self.status="Unreadable bank · local edits retained";return end
    if p.serial==self.serial and (p.force or not self.dirty) then app:restore(bank);self.dirty=false
    elseif rev>0 then self.ready=false;self.status="Saved bank exists · export local edits, then reload";app:log("Store",self.status);return end;self.ready=true
   elseif self.serial==p.serial then self.dirty=false end;app:log("Store",msg)
  end);self:read(false)
 end
 scope:on(RS.ChildAdded,attach);local r=RS:FindFirstChild("AetherFullStoreV1");if r then attach(r) end;return self
end
function Store:edit() self.serial+=1;self.dirty=true;self.lastEdit=os.clock() end
function Store:request(op,body,force,attempt,serial)
 if not self.remote or not self.remote.Parent then self.status="Local session only · export a JSON bank";return false end
 if self.pending then return false end;self.retry=nil;self.id+=1;self.pending={id=self.id,op=op,serial=serial or self.serial,attempt=attempt or 0,force=force,start=os.clock()};self.status=if op=="read" then "Reading bank…" else "Saving bank…";self.remote:FireServer(self.id,op,self.revision,body);return true
end
function Store:read(force) return self:request("read",nil,force) end
function Store:save()
 if not self.ready then self.status=if self.remote then "Read/reload before saving · export to keep local edits" else "Local session only · export a JSON bank";return false end
 local data=Http:JSONEncode(self.app.bank);if #data>110000 then self.status="Bank exceeds 110 KB · remove or export assets";return false end;self.lastWrite=os.clock();return self:request("write",data,false)
end
function Store:tick(now)
 if self.retry and not self.pending and now>=self.retry.at then local r=self.retry;self:request("read",nil,r.force,r.attempt,r.serial) end
 if self.pending and now-self.pending.start>18 then self.pending=nil;self.ready=false;self.status="Store timeout · reload or export" end
 if self.dirty and self.ready and not self.pending and now-self.lastEdit>2 and now-self.lastWrite>12 then self:save() end
end
return Store

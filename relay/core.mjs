// In-memory, authenticated, opt-in cosmetics exchange. No personal identifiers.
export const createRelay = function createRelay({rules,random,now=()=>Date.now(),authenticate,peerTTL=30000,roomTTL=900000,roomCap=256,peerCap=32,minInterval=750}){
 const rooms=new Map(),admins=new Map(),tokens=new Map();
 const fail=(status,error)=>({status,body:{error}});
 const ok=(body,status=200)=>({status,body});
 const plain=x=>x!==null&&typeof x==="object"&&!Array.isArray(x);
 const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
 const bound=(x,lo,hi,d)=>typeof x==="number"&&Number.isFinite(x)&&x>=lo&&x<=hi?x:d;
 function validate(raw){
  if(!plain(raw)||Object.keys(raw).length>256)throw Error("Invalid cosmetics");
  const result={};
  for(const k of Object.keys(raw).sort()){
   const v=raw[k];
   if(k==="motionStudioConfig"||k==="publishedMotion")continue;
   if(!Object.hasOwn(rules,k))throw Error("Unsupported field");
   const r=rules[k];
   const valid=r.type==="bool"?typeof v==="boolean":r.type==="color"?typeof v==="string"&&/^[0-9a-fA-F]{6}$/.test(v):r.type==="choice"?r.values.includes(v):Number.isInteger(v)&&v>=r.min&&v<=r.max;
   if(!valid)throw Error("Invalid cosmetic field");
   const clean=r.type==="color"?v.toUpperCase():v;
   if(clean!==r.default)result[k]=clean;
  }
  if(Object.hasOwn(raw,"publishedMotion")){
   if(typeof raw.publishedMotion!=="boolean")throw Error("Invalid animation flag");
   if(raw.publishedMotion)result.publishedMotion=true;
  }
  if(Object.hasOwn(raw,"motionStudioConfig")){
   if(typeof raw.motionStudioConfig!=="string"||raw.motionStudioConfig.length>2048)throw Error("Invalid motion config");
   const cfg=JSON.parse(raw.motionStudioConfig);
   if(!plain(cfg))throw Error("Invalid motion config");
   const style=result.walkStyle||rules.walkStyle.default;
   const speed=bound(plain(cfg.packRates)?cfg.packRates[style]:undefined,.25,2,bound(cfg.speed,.25,2,1));
   result.motionStudioConfig=JSON.stringify({speed,adaptive:cfg.adaptive!==false,origin:bound(cfg.origin,0,150,100),props:cfg.props!==false,packRates:{[style]:speed}});
  }
  return result;
 }
 function dropPeer(room,peer){
  if(peer.cosmetics!==null)room.revision++;
  room.peers.delete(peer.id);tokens.delete(peer.token);
 }
 function dropRoom(room){
  for(const p of room.peers.values())tokens.delete(p.token);
  admins.delete(room.admin);rooms.delete(room.id);
 }
 function sweep(){
  const t=now();
  for(const room of rooms.values()){
   if(t-room.last>roomTTL||t-room.created>21600000){dropRoom(room);continue;}
   for(const p of room.peers.values())if(t-p.last>peerTTL)dropPeer(room,p);
  }
 }
 function handle({method,path,token,body={}}){
  sweep();
  if(method==="GET"&&path==="/health")return ok({ok:true,version:1});
  if(method!=="POST")return fail(405,"method_not_allowed");
  if(!plain(body))return fail(400,"invalid_body");
  if(path==="/v1/rooms"){
   if(!authenticate(token))return fail(401,"unauthorized");
   if(rooms.size>=roomCap)return fail(503,"capacity");
   const room={id:random(),admin:random(),peers:new Map(),revision:0,created:now(),last:now()};
   rooms.set(room.id,room);admins.set(room.admin,room);
   return ok({room:room.id,adminToken:room.admin},201);
  }
  if(path==="/v1/peers"){
   const room=admins.get(token);
   if(!room)return fail(401,"unauthorized");
   if(room.peers.size>=peerCap)return fail(409,"room_full");
   const peer={id:random(),token:random(),last:now(),lastSync:-Infinity,cosmetics:null};
   room.peers.set(peer.id,peer);tokens.set(peer.token,{room,peer});room.last=now();
   return ok({slot:peer.id,peerToken:peer.token},201);
  }
  if(path==="/v1/close"){
   const room=admins.get(token);
   if(!room)return fail(401,"unauthorized");
   dropRoom(room);return ok({ok:true});
  }
  if(path!=="/v1/sync"&&path!=="/v1/leave")return fail(404,"not_found");
  const entry=tokens.get(token);
  if(!entry)return fail(401,"expired_or_invalid_token");
  const {room,peer}=entry;
  if(path==="/v1/leave"){dropPeer(room,peer);return ok({ok:true});}
  if(now()-peer.lastSync<minInterval)return fail(429,"rate_limited");
  peer.lastSync=now();
  if(Object.hasOwn(body,"cosmetics")){
   let clean;try{clean=validate(body.cosmetics);}catch{return fail(400,"invalid_cosmetics");}
   if(!equal(peer.cosmetics,clean)){peer.cosmetics=clean;room.revision++;}
  }
  peer.last=now();room.last=now();
  const result={revision:room.revision,ttlMs:peerTTL};
  if(body.since!==room.revision)result.peers=Array.from(room.peers.values()).filter(p=>p!==peer&&p.cosmetics!==null).map(p=>({slot:p.id,cosmetics:p.cosmetics}));
  return ok(result);
 }
 return {handle,sweep};
};

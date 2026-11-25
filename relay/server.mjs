import http from "node:http";
import { randomBytes, timingSafeEqual } from "node:crypto";
import { readFileSync } from "node:fs";
import { createRelay } from "./core.mjs";
const rules=JSON.parse(readFileSync(new URL("./cosmetics-schema.json",import.meta.url),"utf8"));
const secret=process.env.RELAY_ADMIN_SECRET||"";
if(secret.length<32)throw new Error("Set RELAY_ADMIN_SECRET (32+ random characters)");
const secureCompare=t=>{
 if(typeof t!=="string")return false;
 const a=Buffer.from(t),b=Buffer.from(secret);
 return a.length===b.length&&timingSafeEqual(a,b);
};
const relay=createRelay({rules,random:()=>randomBytes(24).toString("base64url"),authenticate:secureCompare});
const MAX_BYTES=8192;
const server=http.createServer({requestTimeout:10000,headersTimeout:5000,maxHeaderSize:8192},async(req,res)=>{
 const send=(status,body)=>{
  res.writeHead(status,{"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store","X-Content-Type-Options":"nosniff"});
  res.end(JSON.stringify(body));
 };
 try{
  const path=new URL(req.url,"http://localhost").pathname;
  const auth=req.headers.authorization||"";
  const token=auth.startsWith("Bearer ")?auth.slice(7):"";
  if(Number(req.headers["content-length"])>MAX_BYTES){send(413,{error:"body_too_large"});req.resume();return;}
  let bytes=0;const chunks=[];
  for await(const chunk of req){
   bytes+=chunk.length;
   if(bytes>MAX_BYTES){send(413,{error:"body_too_large"});return;}
   chunks.push(chunk);
  }
  let body={};
  if(bytes){try{body=JSON.parse(Buffer.concat(chunks).toString("utf8"));}catch{send(400,{error:"invalid_json"});return;}}
  const r=relay.handle({method:req.method,path,token,body});
  send(r.status,r.body);
 }catch{if(!res.headersSent)send(500,{error:"internal_error"});else res.end();}
});
server.maxConnections=512;
setInterval(()=>relay.sweep(),5000).unref();
server.listen(Number(process.env.PORT||8080),"0.0.0.0",()=>console.log("AETHER cosmetic relay ready"));

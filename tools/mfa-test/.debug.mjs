import { chromium } from 'playwright';
const BASE='http://code.example.tld:8099';
const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium',
  args:['--host-resolver-rules=MAP code.example.tld 127.0.0.1']});
const p=await (await b.newContext()).newPage();
p.on('pageerror',e=>console.log('PAGE ERROR:',e.message));
const email=`dbg4-${Date.now()}@example.tld`;
await p.goto(`${BASE}/`,{waitUntil:'load'});
await p.evaluate(async e=>{await fetch('/api/v1/sign-up',{method:'POST',headers:{'Content-Type':'application/json'},
  body:JSON.stringify({name:'Ada',email:e,password:'a long enough password here'})})},email);
await p.evaluate(()=>fetch('/api/v1/sign-out',{method:'POST'}));
await p.goto(`${BASE}/#/sign-in`,{waitUntil:'load'});
await p.reload({waitUntil:'load'});
await p.waitForTimeout(2000);
console.log('screen:', await p.locator('#content').getAttribute('data-screen'), 'url:', p.url());
console.log('html:', (await p.locator('#content').innerHTML()).slice(0,700));
await b.close();

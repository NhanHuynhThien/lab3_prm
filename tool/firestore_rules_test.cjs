// Cloud Rules Test API: simulations with complete get/getAfter mocks, no document writes.
// Requires an existing `firebase login` and globally installed firebase-tools.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const {execFileSync} = require('child_process');
const project = process.argv[2];
if (!project || !/^[a-z][a-z0-9-]+$/.test(project)) {
  console.error('Usage: node tool/firestore_rules_test.cjs <firebase-project-id>'); process.exit(2);
}
const root = '/databases/(default)/documents/users/A/';
const NOW = '2026-10-21T12:00:00Z', PAST = '2026-10-20T00:00:00Z', FUTURE = '2026-11-01T00:00:00Z';
const clone = value => structuredClone(value);
const hash = (account, key) => crypto.createHash('sha256').update(account+'\n'+key).digest('hex');
const accountPayload = {id:'a',alias:'Claude',provider:'Anthropic',product:'Claude',billingMode:'subscription',
  plan:'',budgetMicros:1000000,archived:false,createdAt:PAST,defaultModelId:null,defaultPurposes:['code'],
  timezone:'Asia/Ho_Chi_Minh',cycleStartDay:1,isDemo:false,dataSource:'manual',currency:'USD'};
const envelope = (payload, op, revision=1) => ({ownerId:'A',schemaVersion:1,revision,createdAt:NOW,updatedAt:NOW,payload:clone(payload),lastOperationId:op});
const account = () => ({...envelope(accountPayload,'a-create'),usageCount:0,quotaCount:0,lastUsageMutationId:null,lastQuotaMutationId:null});
const usage = () => envelope({id:'u',accountId:'a',title:'Code',purpose:'code',occurredAt:PAST,modelId:null,
  dataSource:'manual',costBasis:'unknown',isDemo:false,inputTokens:null,outputTokens:null,costMicros:null,note:'',currency:'USD'},'u-create');
const receipt = (collection,entityId,action,revision) => ({ownerId:'A',schemaVersion:1,intent:'test command',revision,createdAt:NOW,collection,entityId,action});
const named = [];
function test(name, expectation, target, method, before={}, after={}, uid='A') {
  const paths = new Set([...Object.keys(before),...Object.keys(after),target]);
  const mocks = [];
  for (const p of paths) {
    for (const [fn, map] of [['get',before],['getAfter',after]]) mocks.push({function:fn,args:[{exactValue:root+p}],
      result: map[p] ? {value:{data:map[p]}} : {undefined:{}}});
    for (const [fn, map] of [['exists',before],['existsAfter',after]]) mocks.push({function:fn,args:[{exactValue:root+p}],result:{value:!!map[p]}});
  }
  named.push({name, test:{expectation,request:{path:root+target,method,auth:uid ? {uid,token:{}} : null,
    time:NOW,...(after[target] ? {resource:{data:after[target]}} : {})},
    ...(before[target] ? {resource:{data:before[target]}} : {}),functionMocks:mocks}});
}
function transaction(name, before, after, changed) {
  for (const target of changed) {
    const method=after[target] ? before[target] ? 'update' : 'create' : 'delete';
    test(name+': '+target,'ALLOW',target,method,before,after);
    test(name+' foreign deny: '+target,'DENY',target,method,before,after,'B');
    test(name+' unauth deny: '+target,'DENY',target,method,before,after,null);
  }
}

for (const col of ['accounts','usage_sessions','quota_windows','quota_labels','mutations','settings']) {
  test('owner read '+col,'ALLOW',col+'/a','get');
  test('foreign read '+col,'DENY',col+'/a','get',{}, {},'B');
  test('unauth read '+col,'DENY',col+'/a','get',{}, {},null);
}
test('unknown collection deny','DENY','devices/a','get');
const snap={ownerId:'A',savedAt:NOW,json:'{"schemaVersion":1}'};
test('owner read snapshot','ALLOW','provider_snapshots/latest','get');
test('foreign read snapshot','DENY','provider_snapshots/latest','get',{}, {},'B');
test('owner save snapshot','ALLOW','provider_snapshots/latest','create',{}, {'provider_snapshots/latest':snap});
test('foreign save snapshot','DENY','provider_snapshots/latest','create',{}, {'provider_snapshots/latest':snap},'B');
test('snapshot other id deny','DENY','provider_snapshots/x','create',{}, {'provider_snapshots/x':snap});
test('snapshot extra field deny','DENY','provider_snapshots/latest','create',{}, {'provider_snapshots/latest':{...snap,raw:'x'}});
test('snapshot too large deny','DENY','provider_snapshots/latest','create',{}, {'provider_snapshots/latest':{...snap,json:'x'.repeat(600001)}});
const AUTO='auto_usage/auto-codex-0123456789abcdef-20261020';
const autoRow={ownerId:'A',provider:'codex',detectedPurpose:'debug',model:'gpt-5',inputTokens:1200,outputTokens:300,
  occurredAt:PAST,startedAt:PAST,syncedAt:NOW};
test('owner read auto usage','ALLOW',AUTO,'get');
test('foreign read auto usage','DENY',AUTO,'get',{}, {},'B');
test('companion create auto usage','ALLOW',AUTO,'create',{}, {[AUTO]:autoRow});
test('foreign create auto usage','DENY',AUTO,'create',{}, {[AUTO]:autoRow},'B');
test('auto usage bad id deny','DENY','auto_usage/u1','create',{}, {'auto_usage/u1':autoRow});
test('auto usage provider/id mismatch deny','DENY',AUTO,'create',{}, {[AUTO]:{...autoRow,provider:'claude'}});
test('auto usage extra field deny','DENY',AUTO,'create',{}, {[AUTO]:{...autoRow,prompt:'x'}});
test('auto usage negative tokens deny','DENY',AUTO,'create',{}, {[AUTO]:{...autoRow,inputTokens:-1}});
test('auto usage bad purpose deny','DENY',AUTO,'create',{}, {[AUTO]:{...autoRow,detectedPurpose:'invented'}});
test('auto usage stale sync time deny','DENY',AUTO,'create',{}, {[AUTO]:{...autoRow,syncedAt:PAST}});
test('phone edits auto purpose','ALLOW',AUTO,'update',{[AUTO]:autoRow}, {[AUTO]:{...autoRow,purpose:'code',title:'',note:'ok'}});
test('phone hides auto usage','ALLOW',AUTO,'update',{[AUTO]:autoRow}, {[AUTO]:{...autoRow,hidden:true}});
test('companion cannot unhide','DENY',AUTO,'update',{[AUTO]:{...autoRow,hidden:true}}, {[AUTO]:{...autoRow,hidden:false}});
test('companion refresh keeps hidden','ALLOW',AUTO,'update',{[AUTO]:{...autoRow,hidden:true}},
  {[AUTO]:{...autoRow,hidden:true,inputTokens:2000}});
test('auto usage delete deny','DENY',AUTO,'delete',{[AUTO]:autoRow});
test('companion retires superseded row','ALLOW',AUTO,'update',{[AUTO]:autoRow}, {[AUTO]:{...autoRow,superseded:true}});
test('superseded must be bool','DENY',AUTO,'update',{[AUTO]:autoRow}, {[AUTO]:{...autoRow,superseded:'yes'}});
let a=account(), before={}, after={'accounts/a':a,'mutations/a-create':receipt('accounts','a','create',1)};
transaction('account create',before,after,Object.keys(after));
for (const [name, mutate] of [
  ['owner',d=>d.ownerId='B'],['extra',d=>d.secret='x'],['negative budget',d=>d.payload.budgetMicros=-1],
  ['initial count',d=>d.usageCount=1],['schema',d=>d.schemaVersion=2],['currency',d=>d.payload.currency='VND'],
  ['alias size',d=>d.payload.alias='x'.repeat(81)],['purpose',d=>d.payload.defaultPurposes=['invented']]]) {
  const bad=clone(after);mutate(bad['accounts/a']);test('invalid account '+name,'DENY','accounts/a','create',{},bad);
}
before={'accounts/a':a};
after={'accounts/a':{...a,revision:2,lastOperationId:'a-edit',payload:{...a.payload,alias:'New'}},
  'mutations/a-edit':receipt('accounts','a','update',2)};
transaction('account edit',before,after,Object.keys(after));
for (const [name,mutate] of [['owner',d=>d.ownerId='B'],['createdAt',d=>d.createdAt=PAST],
  ['source',d=>{d.payload.dataSource='demo';d.payload.isDemo=true;}],['revision',d=>d.revision=9],
  ['counter tamper',d=>d.usageCount=10]]) {
  const bad=clone(after);mutate(bad['accounts/a']);test('immutable account '+name,'DENY','accounts/a','update',before,bad);
}
transaction('empty account delete',{'accounts/a':a},{'mutations/a-delete':receipt('accounts','a','delete',1)},['accounts/a','mutations/a-delete']);
test('forged receipt deny','DENY','mutations/forged','create',{}, {'mutations/forged':receipt('accounts','a','create',1)});
test('receipt delete deny','DENY','mutations/a-create','delete',{'mutations/a-create':receipt('accounts','a','create',1)},{});
test('receipt edit deny','DENY','mutations/a-create','update',{'mutations/a-create':receipt('accounts','a','create',1)}, {'mutations/a-create':receipt('accounts','a','create',2)});

const u=usage();
const counted={...a,usageCount:1,revision:2,lastUsageMutationId:'u',lastOperationId:'u-create'};
before={'accounts/a':a};after={'accounts/a':counted,'usage_sessions/u':u,'mutations/u-create':receipt('usage_sessions','u','create',1)};
transaction('usage create with counter',before,after,Object.keys(after));
test('usage without counter deny','DENY','usage_sessions/u','create',before,{...after,'accounts/a':a});
test('counter without usage deny','DENY','accounts/a','update',before,{'accounts/a':counted});
for (const [name, mutate] of [['unpaired tokens',p=>p.inputTokens=1],['negative tokens',p=>{p.inputTokens=-1;p.outputTokens=1;}],
  ['negative cost',p=>p.costMicros=-1],['false cost basis',p=>p.costBasis='actual'],['missing account',p=>p.accountId='b']]) {
  const bad=clone(after);mutate(bad['usage_sessions/u'].payload);test('invalid usage '+name,'DENY','usage_sessions/u','create',before,bad);
}
const zero=clone(after);Object.assign(zero['usage_sessions/u'].payload,{inputTokens:0,outputTokens:0,costMicros:0,costBasis:'manual'});
test('known zero is valid','ALLOW','usage_sessions/u','create',before,zero);
const archived={...counted,payload:{...counted.payload,archived:true}};
test('archive blocks new usage','DENY','usage_sessions/u','create',{'accounts/a':{...a,payload:{...a.payload,archived:true}}},after);
before={'accounts/a':archived,'usage_sessions/u':u};
after={...before,'usage_sessions/u':{...u,revision:2,lastOperationId:'u-edit',payload:{...u.payload,title:'Edited'}},
  'mutations/u-edit':receipt('usage_sessions','u','update',2)};
transaction('archived usage edit',before,after,['usage_sessions/u','mutations/u-edit']);
const moved=clone(after);moved['usage_sessions/u'].payload.accountId='b';test('usage account immutable','DENY','usage_sessions/u','update',before,moved);
before={'accounts/a':counted,'usage_sessions/u':u};
after={'accounts/a':{...counted,usageCount:0,revision:3,lastOperationId:'u-delete'},'mutations/u-delete':receipt('usage_sessions','u','delete',1)};
transaction('usage delete with counter',before,after,['accounts/a','usage_sessions/u','mutations/u-delete']);
test('nonempty account delete deny','DENY','accounts/a','delete',before,{});
test('usage delete without count deny','DENY','usage_sessions/u','delete',before,{'accounts/a':counted});

const qid=hash('a','weekly'), lid=hash('a','tuần');
const qp={accountId:'a',window:'Tuần',unit:'percent',windowKey:'weekly',source:'manual',sourceLabel:'Quan sát',note:'',usedPercent:75,observedAt:PAST,resetAt:FUTURE};
const q=envelope(qp,'q-create');
const qa={...a,quotaCount:1,revision:2,lastQuotaMutationId:qid,lastOperationId:'q-create'};
const label={ownerId:'A',accountId:'a',windowKey:'weekly'};
before={'accounts/a':a};
after={'accounts/a':qa,['quota_windows/'+qid]:q,['quota_labels/'+lid]:label,'mutations/q-create':receipt('quota_windows',qid,'create',1)};
transaction('quota create',before,after,Object.keys(after));
test('forged quota ID deny','DENY','quota_windows/fake','create',before,{...after,'quota_windows/fake':q});
test('quota count tamper deny','DENY','accounts/a','update',before,{'accounts/a':qa});
test('quota duplicate label deny','DENY','quota_windows/'+qid,'create',{...before,['quota_labels/'+lid]:{...label,windowKey:'different'}},after);
test('quota account delete deny','DENY','accounts/a','delete',{'accounts/a':qa},{});
const over=clone(after);over['quota_windows/'+qid].payload.usedPercent=101;
test('quota percent bounds deny','DENY','quota_windows/'+qid,'create',before,over);
before={'accounts/a':qa,['quota_windows/'+qid]:q,['quota_labels/'+lid]:label};
const renamed=hash('a','bảy ngày');
after={'accounts/a':{...qa,revision:3,lastOperationId:'q-edit'},
  ['quota_windows/'+qid]:{...q,revision:2,lastOperationId:'q-edit',payload:{...qp,window:'Bảy ngày'}},
  ['quota_labels/'+renamed]:label,'mutations/q-edit':receipt('quota_windows',qid,'update',2)};
transaction('quota rename',before,after,[...Object.keys(after),'quota_labels/'+lid]);
const kept=clone(after);kept['quota_labels/'+lid]=label;
test('quota rename must release old label','DENY','quota_windows/'+qid,'update',before,kept);
after={'accounts/a':{...qa,quotaCount:0,revision:3,lastOperationId:'q-delete'},'mutations/q-delete':receipt('quota_windows',qid,'delete',1)};
transaction('quota delete',before,after,['accounts/a','quota_windows/'+qid,'quota_labels/'+lid,'mutations/q-delete']);
test('orphan label create deny','DENY','quota_labels/'+lid,'create',{}, {['quota_labels/'+lid]:label});
test('live label delete deny','DENY','quota_labels/'+lid,'delete',before,{'accounts/a':qa,['quota_windows/'+qid]:q});
after={'settings/reporting':envelope({reportingTimezone:'Asia/Ho_Chi_Minh'},'s-create'),
  'mutations/s-create':receipt('settings','reporting','create',1)};
transaction('settings create',{},after,Object.keys(after));

(async()=>{
  let auth;
  try { auth=require('firebase-tools/lib/auth'); }
  catch { const globalRoot=process.platform==='win32' ? path.join(process.env.APPDATA,'npm','node_modules')
      : execFileSync('npm',['root','-g'],{encoding:'utf8'}).trim();
    auth=require(path.join(globalRoot,'firebase-tools/lib/auth.js')); }
  const account=auth.getGlobalDefaultAccount();
  if (!account) throw Error('Run firebase login first');
  const token=await auth.getAccessToken(account.tokens.refresh_token,account.tokens.scopes);
  const ruleSource=fs.readFileSync('firebase/firestore.rules','utf8');
  const response=await fetch(`https://firebaserules.googleapis.com/v1/projects/${project}:test`,{
    method:'POST',headers:{Authorization:'Bearer '+token.access_token,'Content-Type':'application/json'},
    body:JSON.stringify({source:{files:[{name:'firestore.rules',content:ruleSource}]},
      testSuite:{testCases:named.map(c=>c.test)}})});
  const result=await response.json();
  const failures=[];
  for (let i=0;i<named.length;i++) {
    const r=result.testResults?.[i];
    if(r?.state!=='SUCCESS') failures.push({name:named[i].name,state:r?.state,debug:r?.debugMessages,position:r?.errorPosition});
  }
  const summary={project,simulated:true,documentWrites:false,cases:named.length,
    sourceSha256:crypto.createHash('sha256').update(ruleSource).digest('hex'),
    passed:result.testResults?.filter(r=>r.state==='SUCCESS').length||0,
    issues:result.issues||[],failures,http:response.status,error:result.error?.message};
  if (process.env.RULES_TEST_REPORT) fs.writeFileSync(process.env.RULES_TEST_REPORT,JSON.stringify(summary,null,2));
  console.log(JSON.stringify(summary));
  if(!response.ok||failures.length||summary.issues.some(i=>i.severity==='ERROR')) process.exitCode=1;
})().catch(error=>{console.error('Rules Test API unavailable: '+(error.message==='Run firebase login first'?error.message:'check CLI credentials/network; credentials redacted'));process.exitCode=1;});

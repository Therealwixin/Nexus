"""Bounded public Warcraft Logs reader. Credentials never leave process memory.

A successful probe verifies access, not the quality or completeness of BiS data.
Optional rankings are reduced to anonymous item frequencies before writing files.
"""
import argparse,base64,collections,copy,datetime as dt,hashlib,json,os,time,urllib.request,urllib.error
from pathlib import Path
API='https://www.warcraftlogs.com/api/v2/client'
RANKINGS='query($id:Int!,$class:String!,$spec:String!,$difficulty:Int!){worldData{encounter(id:$id){id name journalID characterRankings(page:1,difficulty:$difficulty,className:$class,specName:$spec,metric:METRIC,includeCombatantInfo:true)}}}'

# Scope IDs are verified against worldData on every collection; no one-boss fallback.
SEASON_ZONES={'mythicplus':(55,10,8),'raid':(53,5,10)}
SEASON_ENCOUNTERS={'mythicplus':{12993,12825,61762,12813,112521,61877,12859,12923},'raid':{3470,3445,3455,3497,3420,3421,3429,3492,3379,3513}}
PAGES=2
MIN_CONTEXT=20
MIN_UNIQUE=200

def validate_snapshot(data):
 from catalog import SPECS
 if data.get('schema')!=2 or data.get('patch')!='12.1' or set(data.get('specs',{}))!={str(s['id']) for s in SPECS}:raise ValueError('Incomplete broad WCL snapshot')
 if not data.get('windowStart') or not data.get('windowEnd'):raise ValueError('Missing WCL sampling window')
 start=dt.datetime.fromisoformat(data['windowStart']);end=dt.datetime.fromisoformat(data['windowEnd'])
 if not start.tzinfo or not end.tzinfo or abs((end-start).total_seconds()-14*86400)>60:raise ValueError('Invalid WCL window')
 for spec in data['specs'].values():
  for mode,record in spec.items():
   if mode not in SEASON_ZONES or not record.get('retrievedAt'):raise ValueError('Missing WCL provenance')
   expected=SEASON_ZONES[mode][2]
   if record['expectedEncounterCount']!=expected or len(record['encounters'])!=expected:raise ValueError('Wrong seasonal scope')
   if {c['encounterID'] for c in record['encounters']}!=SEASON_ENCOUNTERS[mode]:raise ValueError('Missing/duplicate seasonal encounter')
   covered=sum(c['sampleSize']>=MIN_CONTEXT for c in record['encounters'])
   if record['coveredEncounterCount']!=covered:raise ValueError('False WCL coverage')
   if record['eligible']!=(covered==expected and record['sampleSize']>=MIN_UNIQUE):raise ValueError('Invalid evidence eligibility')
   if any(not str(k).isdigit() or not isinstance(v,int) or not 0<v<=record['sampleSize'] for k,v in record['items'].items()):raise ValueError('Invalid unique-character count')
   for c in record['encounters']:
    if not 0<=c['pagesRead']<=PAGES or any(not 0<n<=c['sampleSize'] for n in c['items'].values()):raise ValueError('Invalid context counts')

def runtime_snapshot(data):
 """Keep detailed per-encounter item maps in the audit JSON, not WoW RAM."""
 out=copy.deepcopy(data)
 for modes in out['specs'].values():
  for record in modes.values():
   record.pop('balancedUsage',None)
   for context in record['encounters']:context.pop('items',None)
 return out

def quota_guard(client,wait=False):
 while True:
  quota=client.query('{rateLimitData{limitPerHour pointsSpentThisHour pointsResetIn}}')['rateLimitData']
  if quota['pointsSpentThisHour']<quota['limitPerHour']*.8:return
  if not wait:raise ValueError('80% API budget reached; broad collection not complete')
  print('Waiting for WCL API quota reset; no partial coverage is labelled complete',flush=True)
  remaining=max(1,int(quota.get('pointsResetIn',3600))+5)
  while remaining:
   pause=min(60,remaining);time.sleep(pause);remaining-=pause

def load_scopes(client):
 scopes={}
 for mode,(zone_id,difficulty,expected) in SEASON_ZONES.items():
  zone=client.query('query($id:Int!){worldData{zone(id:$id){id name encounters{id name}}}}',{'id':zone_id})['worldData']['zone']
  if not zone or zone['id']!=zone_id or len(zone['encounters'])!=expected or {c['id'] for c in zone['encounters']}!=SEASON_ENCOUNTERS[mode]:raise ValueError('Seasonal WCL encounters changed; review scope before publishing')
  scopes[mode]=dict(zoneID=zone_id,difficulty=difficulty,name=zone['name'],encounters=zone['encounters'])
 return scopes

def usable_row(row,start,end,min_key=0):
 stamp=row.get('startTime')
 if not isinstance(stamp,(int,float)) or not start<=stamp<=end:return
 if min_key and (not isinstance(row.get('hardModeLevel'),(int,float)) or row['hardModeLevel']<min_key):return
 gear=row.get('gear') or row.get('combatantInfo',{}).get('gear')
 if not isinstance(gear,list):return
 ids=[i.get('id') or i.get('itemID') for i in gear if isinstance(i,dict)]
 ids=[i for i in ids if isinstance(i,int) and i>0]
 if len(ids)<14:return
 server=row.get('server') or {};name=row.get('name')
 if not name or not (server.get('id') or server.get('name')):return
 # Used only in memory for deduplication. Never serialize names, servers or reports.
 key=(str(name).casefold(),str(server.get('id') or server.get('name')).casefold(),str(server.get('region','')).casefold())
 return key,(stamp,set(ids),str(server.get('region','unknown')))

def retain_latest(target,key,value):
 old=target.get(key)
 if not old or (value[0],tuple(sorted(value[1])))>(old[0],tuple(sorted(old[1]))):target[key]=value

def reduce_characters(characters,known):
 counts=collections.Counter()
 for _,ids,_ in characters.values():counts.update(ids & known)
 return {str(i):n for i,n in sorted(counts.items())}

def checkpoint_key(known):
 return hashlib.sha256(json.dumps([sorted(known),RANKINGS,PAGES,MIN_CONTEXT,MIN_UNIQUE,'latest-loadout-v1'],sort_keys=True).encode()).hexdigest()

def read_checkpoint(path,known,now):
 if not path.exists():return
 try:
  data=json.loads(path.read_text(encoding='utf-8'));validate_snapshot(data)
  age=(now-dt.datetime.fromisoformat(data['generatedAt'])).total_seconds()
  if data.get('checkpointKey')!=checkpoint_key(known) or not 0<=age<=48*3600:return
  for modes in data['specs'].values():
   for mode,record in list(modes.items()):
    if any(c.get('error') for c in record['encounters']):del modes[mode]
  return data
 except (ValueError,TypeError,KeyError):return

def save_checkpoint(path,result):
 path.parent.mkdir(parents=True,exist_ok=True)
 temporary=path.with_suffix('.tmp');temporary.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');temporary.replace(path)

def collect_guides(client,root,guides_path=None,spec_ids=None,now=None,wait=False,checkpoint=False):
 from catalog import SPECS
 guides=json.loads((guides_path or root/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 if guides['patch']!='12.1':raise ValueError('Verify season scopes before collecting')
 scopes=load_scopes(client);known={i['id'] for i in guides['items'].values()}
 now=now or dt.datetime.now(dt.timezone.utc);start=now-dt.timedelta(days=14)
 begin,end=start.timestamp()*1000,now.timestamp()*1000
 result={'schema':2,'patch':'12.1','generatedAt':now.isoformat(),'collectionComplete':False,'source':'Warcraft Logs','windowStart':start.isoformat(),'windowEnd':now.isoformat(),'specs':{str(s['id']):{} for s in SPECS},'failures':[],
 'methodology':{'population':'Top-ranked DPS/HPS results per spec and encounter, current WCL default partition; not all logs or a random player sample','pagesPerEncounter':PAGES,'windowDays':14,'minimumKey':10,'minimumPerEncounter':MIN_CONTEXT,'minimumUniqueCharacters':MIN_UNIQUE,'deduplication':'Latest complete loadout per character within each spec/mode; names/server identities exist only in memory','selection':'No WCL frequency selects or ranks Overall BiS','scope':{m:{k:v for k,v in scope.items() if k!='encounters'} for m,scope in scopes.items()}}}
 path=root/'build/wcl/checkpoint.json'
 if checkpoint:
  resumed=read_checkpoint(path,known,now)
  if resumed:
   result=resumed;now=dt.datetime.fromisoformat(result['generatedAt'])
   begin=dt.datetime.fromisoformat(result['windowStart']).timestamp()*1000;end=now.timestamp()*1000
   print('Resuming anonymous completed spec/mode summaries; original sampling window retained',flush=True)
 result['checkpointKey']=checkpoint_key(known)
 healers={65,256,257,264,270,105,1468};requests=0
 for spec in SPECS:
  sid=str(spec['id'])
  if spec_ids and spec['id'] not in spec_ids:continue
  for mode,scope in scopes.items():
   if checkpoint and mode in result['specs'][sid]:continue
   pooled={};contexts=[];metric='hps' if spec['id'] in healers else 'dps'
   for encounter in scope['encounters']:
    characters={};pages=0;truncated=False;error=None;keys=[]
    try:
     for page in range(1,PAGES+1):
      if requests%8==0:quota_guard(client,wait)
      variables={'id':encounter['id'],'class':spec['className'].replace(' ',''),'spec':spec['name'].replace(' ',''),'difficulty':scope['difficulty']}
      data=client.query(RANKINGS.replace('page:1','page:'+str(page)).replace('METRIC',metric),variables)['worldData']['encounter']
      rankings=data['characterRankings'];pages+=1;requests+=1
      for row in rankings.get('rankings',[]):
       if str(row.get('class','')).casefold()!=variables['class'].casefold() or str(row.get('spec','')).casefold()!=variables['spec'].casefold():continue
       usable=usable_row(row,begin,end,10 if mode=='mythicplus' else 0)
       if usable:
        key,value=usable;retain_latest(characters,key,value)
        if mode=='mythicplus':keys.append(row['hardModeLevel'])
      truncated=bool(rankings.get('hasMorePages'))
      if not truncated:break
    except ValueError as exc:
     if 'budget' in str(exc):raise
     error='API query unavailable; no guessed samples'
    for key,value in characters.items():retain_latest(pooled,key,value)
    context={'encounterID':encounter['id'],'encounterName':encounter['name'],'sampleSize':len(characters),'items':reduce_characters(characters,known),'pagesRead':pages,'truncated':truncated}
    if keys:context['keyRange']=[min(keys),max(keys)]
    if error:context['error']=error
    contexts.append(context)
   if any(c.get('error') for c in contexts):raise ValueError('WCL context failed; keep checkpoint and previous published snapshot')
   record={'retrievedAt':now.isoformat(),'metric':metric,'sampleSize':len(pooled),'items':reduce_characters(pooled,known),'encounters':contexts,'expectedEncounterCount':len(contexts),'coveredEncounterCount':sum(c['sampleSize']>=MIN_CONTEXT for c in contexts),'zoneID':scope['zoneID'],'difficulty':scope['difficulty'],'regionCounts':dict(collections.Counter(v[2] for v in pooled.values()))}
   record['eligible']=record['coveredEncounterCount']==record['expectedEncounterCount'] and record['sampleSize']>=MIN_UNIQUE
   record['balancedUsage']={id:round(sum(c['items'].get(id,0)/c['sampleSize'] if c['sampleSize'] else 0 for c in contexts)/len(contexts),6) for id in record['items']}
   result['specs'][sid][mode]=record
   print('WCL spec',sid,mode,record['coveredEncounterCount'],'/',len(contexts),'contexts;',len(pooled),'unique characters; eligible',record['eligible'],flush=True)
   result['collectionComplete']=all(len(modes)==2 for modes in result['specs'].values())
   validate_snapshot(result)
   if checkpoint:save_checkpoint(path,result)
  result['collectionComplete']=all(len(modes)==2 for modes in result['specs'].values())
  validate_snapshot(result)
 validate_snapshot(result)
 return result

def request(url,payload,headers):
 req=urllib.request.Request(url,data=payload,headers=headers,method='POST')
 for attempt in range(7):
  try:
   with urllib.request.urlopen(req,timeout=30) as response:return json.load(response)
  except urllib.error.HTTPError as error:
   if error.code in {429,500,502,503,504} and attempt<6:
    retry=error.headers.get('Retry-After','') if error.headers else ''
    remaining=min(3600,max(2**(attempt+1),int(retry) if retry.isdigit() else 0))
    while remaining:
     pause=min(60,remaining);time.sleep(pause);remaining-=pause
    continue
   raise RuntimeError('Warcraft Logs HTTP '+str(error.code)+'; credentials and response body omitted') from None
  except (urllib.error.URLError,TimeoutError):
   if attempt<6:time.sleep(min(60,2**(attempt+1)));continue
   raise RuntimeError('Warcraft Logs network unavailable; credentials omitted') from None

class Client:
 def __init__(self):
  client_id=os.environ.get('WCL_CLIENT_ID','').strip();secret=os.environ.get('WCL_CLIENT_SECRET','').strip()
  if not client_id or not secret:raise ValueError('Set GitHub secrets WCL_CLIENT_ID and WCL_CLIENT_SECRET')
  if client_id==secret:raise ValueError('Client ID and Client Secret are identical; use the two distinct values from the same Warcraft Logs API application')
  auth=base64.b64encode((client_id+':'+secret).encode()).decode()
  response=request('https://www.warcraftlogs.com/oauth/token',b'grant_type=client_credentials',{'Authorization':'Basic '+auth,'Content-Type':'application/x-www-form-urlencoded'})
  self.token=response.get('access_token')
  self.last_query=0
  if not self.token:raise ValueError('OAuth token missing; response omitted')
 def query(self,query,variables=None):
  delay=1.1-(time.monotonic()-self.last_query)
  if delay>0:time.sleep(delay)
  self.last_query=time.monotonic()
  result=request(API,json.dumps({'query':query,'variables':variables or {}}).encode(),{'Authorization':'Bearer '+self.token,'Content-Type':'application/json'})
  if result.get('errors'):raise ValueError('Warcraft Logs query rejected; raw response omitted')
  if not result.get('data'):raise ValueError('Warcraft Logs returned no data')
  return result['data']

def aggregate(rankings):
 rows=rankings.get('rankings',[]) if isinstance(rankings,dict) else []
 counts=collections.Counter();samples=0
 for row in rows:
  gear=row.get('gear') or row.get('combatantInfo',{}).get('gear')
  if not isinstance(gear,list):continue
  ids={item.get('id') or item.get('itemID') for item in gear if isinstance(item,dict)}
  ids={i for i in ids if isinstance(i,int) and i>0}
  if ids:samples+=1;counts.update(ids)
 if samples<20:raise ValueError('Fewer than 20 usable gear samples; no candidate written')
 return {'sampleSize':samples,'items':[{'id':i,'count':n} for i,n in counts.most_common()]}

def audit_schema(client):
 """Inspect public API capabilities/cost without saving player records."""
 result={}
 for name in ['Encounter','Zone']:
  schema=client.query('query($name:String!){__type(name:$name){fields{name args{name type{kind name ofType{kind name}}}}}}',{'name':name})
  result[name]=[f for f in schema['__type']['fields'] if 'ranking' in f['name'].lower() or f['name'] in ['encounters','id','name']]
 result['quotaBefore']=client.query('{rateLimitData{limitPerHour pointsSpentThisHour pointsResetIn}}')['rateLimitData']
 result['pages']=[]
 for encounter in [12813,3429]:
  for page in [1,2]:
   q=RANKINGS.replace('page:1','page:'+str(page)).replace('METRIC','dps')
   data=client.query(q,{'id':encounter,'class':'Rogue','spec':'Subtlety','difficulty':10 if encounter==12813 else 5})['worldData']['encounter']['characterRankings']
   rows=data.get('rankings',[])
   result['pages'].append({'encounter':encounter,'page':page,'pageKeys':list(data),'rowKeys':list(rows[0]) if rows else [],'reportKeys':list(rows[0].get('report',{})) if rows else [],'characterKeys':list(rows[0].get('character',{})) if rows else [],'rows':len(rows),'hasMorePages':data.get('hasMorePages'),'timeRange':[min((r.get('startTime',0) for r in rows),default=0),max((r.get('startTime',0) for r in rows),default=0)]})
 result['quotaAfter']=client.query('{rateLimitData{limitPerHour pointsSpentThisHour pointsResetIn}}')['rateLimitData']
 result['groupSamples']=[]
 for encounter,difficulty,metric in [(12813,10,'dps'),(3429,5,'hps')]:
  data=client.query('{worldData{encounter(id:'+str(encounter)+'){characterRankings(page:1,difficulty:'+str(difficulty)+',metric:'+metric+',includeCombatantInfo:true,includeOtherPlayers:true)}}}')['worldData']['encounter']['characterRankings']
  rows=data.get('rankings',[]);objects=[]
  def walk(value):
   if isinstance(value,dict):
    if isinstance(value.get('gear'),list):objects.append(value)
    for key,child in value.items():
     if key!='gear':walk(child)
   elif isinstance(value,list):
    for child in value:walk(child)
  walk(rows)
  result['groupSamples'].append({'encounter':encounter,'rowKeys':list(rows[0]) if rows else [],'objectsWithGear':len(objects),'gearObjectKeys':list(objects[-1]) if objects else [],'specCounts':dict(collections.Counter(str(o.get('class'))+' / '+str(o.get('spec')) for o in objects))})
 dest=Path('build/wcl');dest.mkdir(parents=True,exist_ok=True)
 (dest/'api-schema.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 print('Public ranking schema/cost audit complete; no player identities retained')

def main():
 p=argparse.ArgumentParser();p.add_argument('--guide-snapshot',type=Path);p.add_argument('--collect-guides',action='store_true');p.add_argument('--discover-world',action='store_true');p.add_argument('--encounter',type=int,default=0);p.add_argument('--class-name',default='Rogue');p.add_argument('--spec-name',default='Subtlety');p.add_argument('--difficulty',type=int,default=5);a=p.parse_args()
 c=Client();quota=c.query('{rateLimitData{limitPerHour pointsSpentThisHour pointsResetIn}}')['rateLimitData']
 if quota['pointsSpentThisHour']>=quota['limitPerHour']*.8:quota_guard(c,os.environ.get('WCL_WAIT_FOR_QUOTA')=='true')
 now=dt.datetime.now(dt.timezone.utc).isoformat();out={'source':'Warcraft Logs','retrievedAt':now,'quota':quota,'authenticated':True,'scope':'public'}
 if os.environ.get('WCL_AUDIT_SCHEMA')=='true':audit_schema(c);return
 if a.collect_guides or os.environ.get('WCL_COLLECT_GUIDES')=='true':
  out=collect_guides(c,Path(__file__).resolve().parents[1],a.guide_snapshot,spec_ids={int(i) for i in os.environ.get('WCL_SPEC_IDS','').split(',') if i},wait=os.environ.get('WCL_WAIT_FOR_QUOTA')=='true',checkpoint=True)
  dest=Path('build/wcl');dest.mkdir(parents=True,exist_ok=True)
  (dest/'wcl-snapshot.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
  from refresh_gear import compact_lua
  (dest/'WCLData.lua').write_text('local _,R=...\nR.WCLData='+compact_lua(runtime_snapshot(out))+'\n',encoding='utf-8')
  print('Anonymous evidence snapshot complete; failures:',len(out['failures']));return
 if a.discover_world or os.environ.get('WCL_DISCOVER_WORLD')=='true':
  expansions=c.query('{worldData{expansions{id name}}}')['worldData']['expansions']
  current=[e for e in expansions if e['name'].casefold()=='midnight']
  if len(current)!=1:raise ValueError('Current expansion could not be identified; no guessed IDs used')
  zones=c.query('query($exp:Int!){worldData{zones(expansion_id:$exp){id name difficulties{id name} encounters{id name journalID}}}}',{'exp':current[0]['id']})['worldData']['zones']
  out.update(expansion=current[0],zones=zones)
 if a.encounter:
  q='query($id:Int!,$class:String!,$spec:String!,$difficulty:Int!){worldData{encounter(id:$id){id name journalID characterRankings(page:1,difficulty:$difficulty,className:$class,specName:$spec,includeCombatantInfo:true)}}}'
  cache=Path('.cache/wcl');cache.mkdir(parents=True,exist_ok=True)
  import hashlib
  key=hashlib.sha256(json.dumps(vars(a),sort_keys=True).encode()).hexdigest();file=cache/(key+'.json')
  if file.exists() and time.time()-file.stat().st_mtime<21600:out=json.loads(file.read_text(encoding='utf-8'))
  else:
   encounter=c.query(q,{'id':a.encounter,'class':a.class_name,'spec':a.spec_name,'difficulty':a.difficulty})['worldData']['encounter']
   if not encounter:raise ValueError('Encounter not found')
   frequencies=aggregate(encounter['characterRankings'])
   out.update(encounterID=encounter['id'],journalEncounterID=encounter['journalID'],encounterName=encounter['name'],className=a.class_name,specName=a.spec_name,difficulty=a.difficulty,frequencies=frequencies,methodology='One ranking page; observed item usage, not simulated BiS or acquisition source')
   file.write_text(json.dumps(out,indent=2),encoding='utf-8')
 dest=Path('build/wcl');dest.mkdir(parents=True,exist_ok=True);(dest/'public-sample.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
 print('Public Warcraft Logs access verified. '+('Anonymous gear candidate written.' if a.encounter else 'Probe only; no recommendations changed.'))
if __name__=='__main__':main()

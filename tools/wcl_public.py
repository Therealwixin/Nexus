"""Bounded public Warcraft Logs reader. Credentials never leave process memory.

A successful probe verifies access, not the quality or completeness of BiS data.
Optional rankings are reduced to anonymous item frequencies before writing files.
"""
import argparse,base64,collections,datetime as dt,json,os,time,urllib.request,urllib.error
from pathlib import Path
API='https://www.warcraftlogs.com/api/v2/client'

def request(url,payload,headers):
 req=urllib.request.Request(url,data=payload,headers=headers,method='POST')
 try:
  with urllib.request.urlopen(req,timeout=30) as response:return json.load(response)
 except urllib.error.HTTPError as error:raise RuntimeError('Warcraft Logs HTTP '+str(error.code)+'; credentials and response body omitted') from None

class Client:
 def __init__(self):
  client_id=os.environ.get('WCL_CLIENT_ID','').strip();secret=os.environ.get('WCL_CLIENT_SECRET','').strip()
  if not client_id or not secret:raise ValueError('Set GitHub secrets WCL_CLIENT_ID and WCL_CLIENT_SECRET')
  if client_id==secret:raise ValueError('Client ID and Client Secret are identical; use the two distinct values from the same Warcraft Logs API application')
  auth=base64.b64encode((client_id+':'+secret).encode()).decode()
  response=request('https://www.warcraftlogs.com/oauth/token',b'grant_type=client_credentials',{'Authorization':'Basic '+auth,'Content-Type':'application/x-www-form-urlencoded'})
  self.token=response.get('access_token')
  if not self.token:raise ValueError('OAuth token missing; response omitted')
 def query(self,query,variables=None):
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

def main():
 p=argparse.ArgumentParser();p.add_argument('--encounter',type=int,default=0);p.add_argument('--class-name',default='Rogue');p.add_argument('--spec-name',default='Subtlety');p.add_argument('--difficulty',type=int,default=5);a=p.parse_args()
 c=Client();quota=c.query('{rateLimitData{limitPerHour pointsSpentThisHour pointsResetIn}}')['rateLimitData']
 if quota['pointsSpentThisHour']>=quota['limitPerHour']*.8:raise ValueError('80% API budget threshold reached; no further requests')
 now=dt.datetime.now(dt.timezone.utc).isoformat();out={'source':'Warcraft Logs','retrievedAt':now,'quota':quota,'authenticated':True,'scope':'public'}
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

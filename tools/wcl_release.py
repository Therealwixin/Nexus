"""Weekly WCL cadence and independent, validated snapshot staging."""
import argparse,datetime as dt,json,os
from pathlib import Path
from refresh_gear import ROOT,compact_lua
from wcl_public import validate_snapshot,runtime_snapshot

def due(data,now=None,event=None):
 now=now or dt.datetime.now(dt.timezone.utc)
 validate_snapshot(data)
 age=(now-dt.datetime.fromisoformat(data['generatedAt'])).total_seconds()
 # A cheap daily check retries failures; successful collections run weekly.
 return event=='workflow_dispatch' or not data.get('collectionComplete') or age>=6*86400+23*3600

def stage(root=ROOT,now=None):
 source=root/'build/wcl/wcl-snapshot.json';data=json.loads(source.read_text(encoding='utf-8'))
 validate_snapshot(data)
 if not data.get('collectionComplete') or any(len(modes)!=2 for modes in data['specs'].values()):raise ValueError('Only a completed 40-spec WCL collection can be published')
 now=now or dt.datetime.now(dt.timezone.utc)
 if not -60<=(now-dt.datetime.fromisoformat(data['generatedAt'])).total_seconds()<=48*3600:raise ValueError('WCL collection window expired')
 guides=json.loads((root/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 if data['patch']!=guides['patch']:raise ValueError('WCL/guide patch mismatch')
 outputs={'data/wcl-snapshot.json':json.dumps(data,indent=2)+'\n','Nexus/WCLData.lua':'local _,R=...\nR.WCLData='+compact_lua(runtime_snapshot(data))+'\n'}
 for name,text in outputs.items():
  path=root/name;temporary=path.with_suffix('.tmp');temporary.write_text(text,encoding='utf-8');temporary.replace(path)
 print('Staged WCL only; next daily addon build includes it. Author guides untouched.')

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['due','stage']);a=p.parse_args()
 if a.action=='stage':stage()
 else:
  result=due(json.loads((ROOT/'data/wcl-snapshot.json').read_text(encoding='utf-8')),event=os.environ.get('EVENT_KIND'))
  if os.environ.get('GITHUB_OUTPUT'):
   with open(os.environ['GITHUB_OUTPUT'],'a',encoding='utf-8') as f:f.write('due='+str(result).lower()+'\n')
  print('Weekly WCL refresh due:',result)

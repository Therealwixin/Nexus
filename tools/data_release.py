"""Stage fully validated candidates in a disposable checkout; never edits installed WoW files."""
from pathlib import Path
import argparse,datetime as dt,json,os,re
from refresh_gear import ROOT,validate
from refresh_meta import validate_meta
from wowhead_sets import validate_guides
from set_version import set_version
def due(now=None,event=None):
 now=now or dt.datetime.now(dt.timezone.utc)
 previous=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
 checked=dt.datetime.fromisoformat(previous['generatedAt'].replace('Z','+00:00'))
 result=(event or os.environ.get('EVENT_KIND'))=='workflow_dispatch' or (now-checked).total_seconds()>=23*3600
 if os.environ.get('GITHUB_OUTPUT'):
  with open(os.environ['GITHUB_OUTPUT'],'a',encoding='utf-8') as f:f.write('due='+str(result).lower()+'\n')
 print('Data refresh due:',result)
 return result
def stage(keep_version=False):
 candidate=ROOT/'build/candidate'
 channel=os.environ.get('DATA_RELEASE_CHANNEL','beta')
 if channel not in {'beta','release'}:raise ValueError('DATA_RELEASE_CHANNEL must be beta or release')
 data=json.loads((candidate/'snapshot.json').read_text(encoding='utf-8'))
 meta=json.loads((candidate/'meta-snapshot.json').read_text(encoding='utf-8'))
 guides=json.loads((candidate/'guide-snapshot.json').read_text(encoding='utf-8'))
 validate(data);validate_meta(meta);validate_guides(guides)
 if guides['patch']!=data['upgradeRules']['patch']:raise ValueError('Guide patch mismatch')
 if data['upgradeRules']['patch']!=meta['patch']:raise ValueError('Gear/meta patches differ')
 now=dt.datetime.now(dt.timezone.utc)
 for item in [data,meta,guides]:
  age=(now-dt.datetime.fromisoformat(item['generatedAt'].replace('Z','+00:00'))).total_seconds()
  if not -60<=age<=24*3600:raise ValueError('Candidate must be collected within the last 24 hours')
 transfers=[('snapshot.json','data/snapshot.json'),('meta-snapshot.json','data/meta-snapshot.json'),('Data.lua','Nexus/Data.lua'),('MetaData.lua','Nexus/MetaData.lua'),('GuideData.lua','Nexus/GuideData.lua'),('guide-snapshot.json','data/guide-snapshot.json')]
 contents=[(ROOT/dest,(candidate/src).read_bytes()) for src,dest in transfers]
 for dest,content in contents:
  temp=dest.with_suffix(dest.suffix+'.tmp');temp.write_bytes(content);temp.replace(dest)
 if not keep_version:
  suffix='-beta.data.' if channel=='beta' else '-data.'
  base=re.search(r'^## Version: (\d+\.\d+\.\d+)',(ROOT/'Nexus/Nexus.toc').read_text(encoding='utf-8'),re.M).group(1)
  set_version(base+suffix+now.strftime('%Y%m%d%H%M'))
 print('Staged gear/meta candidates. Tests must pass before committing or publishing.')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['due','stage','version']);p.add_argument('--keep-version',action='store_true');a=p.parse_args()
 if a.action=='due':due()
 elif a.action=='version':print(re.search(r'^## Version: (.+)$',(ROOT/'Nexus/Nexus.toc').read_text(),re.M).group(1))
 else:stage(a.keep_version)

"""Update role-local M+ rankings, preserving source dates."""
from pathlib import Path
import copy,datetime as dt,hashlib,json,re
from catalog import SPECS
from collect_gear import fetch,source_date
from parsers import Page
from murlok_live import collect_pages
TANKS={73,66,250,268,104,581};HEALERS={65,256,257,264,270,105,1468}
def role(spec):return 'tank' if spec in TANKS else 'healer' if spec in HEALERS else 'dps'
def normalized(value):return re.sub('[^a-z0-9]','',value.lower())
def epoch(stamp):return int(dt.datetime.fromisoformat(stamp.replace('Z','+00:00')).timestamp())

def murlok(html,group):
 page=Page(html);known={(s['classSlug'],s['slug']):s['id'] for s in SPECS};entries=[]
 patch=re.search(r'Patch\s+(\d+\.\d+)',html)
 if not patch:raise ValueError('Meta patch unavailable')
 for a in page.root.all('a'):
  if 'meta-item' not in a.attrs.get('class','').split():continue
  parts=a.attrs.get('href','').strip('/').split('/')
  if len(parts)!=3 or (parts[0],parts[1]) not in known:raise ValueError('Unrecognized meta specialization')
  spec=known[(parts[0],parts[1])]
  if role(spec)!=group:raise ValueError('Meta role mismatch')
  numbers=re.findall(r'\d[\d,]*',a.text())
  if len(numbers)!=2:raise ValueError('Unrecognized ranking/score')
  entries.append(dict(specID=spec,rank=int(numbers[0].replace(',','')),score=int(numbers[1].replace(',','')),sourceURL='https://murlok.io'+a.attrs['href']))
 return entries,patch.group(1)
def validate_meta(data):
 if data.get('schema')!=1 or not data.get('patch'):raise ValueError('Invalid meta schema')
 if set(data.get('modes',{}))!={'mythicplus'}:raise ValueError('Only Mythic+ meta is supported')
 for mode,dataset in data['modes'].items():
  seen=set()
  if set(dataset.get('roles',{}))!={'dps','healer','tank'}:raise ValueError('Meta role coverage')
  for group,record in dataset['roles'].items():
   if not record.get('updatedAt') or not record.get('sourceURL'):raise ValueError('Meta provenance missing')
   expected={s['id'] for s in SPECS if role(s['id'])==group}
   entries=record.get('entries',[])
   if {e['specID'] for e in entries}!=expected or len(entries)!=len(expected):raise ValueError('Incomplete meta spec coverage')
   if [e['rank'] for e in entries]!=list(range(1,len(entries)+1)):raise ValueError('Meta ranks not contiguous')
   seen.update(e['specID'] for e in entries)
  if len(seen)!=40:raise ValueError('Incomplete meta mode')
def collect_meta(previous,cache,offline=False):
 result=copy.deepcopy(previous);now=dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ');result['generatedAt']=now;result['modes']={'mythicplus':result['modes']['mythicplus']}
 pages=None if offline else collect_pages(cache)
 for group in ['dps','healer','tank']:
  url=previous['modes']['mythicplus']['roles'][group]['sourceURL']
  try:
   html=fetch(url,cache,'meta-'+group+'.html',True) if offline else pages.get(group)
   if not html:raise ValueError('Rendered Murlok Meta unavailable')
   entries,patch=murlok(html,group)
   if patch!=result['patch']:raise ValueError('M+ meta patch mismatch')
   stamp=source_date(html,now)
   prior=previous['modes']['mythicplus']['roles'][group]['updatedAt']
   if epoch(stamp)<epoch(prior):raise ValueError('Source date regressed; retaining newer published snapshot')
   result['modes']['mythicplus']['roles'][group]=dict(entries=entries,sourceURL=url,updatedAt=stamp,retrievedAt=now,retrievedEpoch=epoch(now),updatedEpoch=epoch(stamp),sourceHash=hashlib.sha256(html.encode()).hexdigest(),refreshStatus='ok',lastAttemptAt=now)
  except (OSError,ValueError):
   result['modes']['mythicplus']['roles'][group].update(refreshStatus='unavailable',lastAttemptAt=now)
   print('M+ meta '+group+': source unavailable; retaining original dated snapshot')
 validate_meta(result)
 return result

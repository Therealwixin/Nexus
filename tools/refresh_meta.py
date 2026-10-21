"""Update role-local M+ rankings and Mythic raid representation, preserving source dates."""
from pathlib import Path
import copy,datetime as dt,hashlib,json,re
from catalog import SPECS
from collect_gear import fetch,source_date
from parsers import Page
from murlok_live import collect_pages,render_raid_page
TANKS={73,66,250,268,104,581};HEALERS={65,256,257,264,270,105,1468}
def role(spec):return 'tank' if spec in TANKS else 'healer' if spec in HEALERS else 'dps'
def normalized(value):return re.sub('[^a-z0-9]','',value.lower())
def epoch(stamp):return int(dt.datetime.fromisoformat(stamp.replace('Z','+00:00')).timestamp())

def verify_raid_dates(roles,previous,now,require_fresh=True):
 for group,record in roles.items():
  published=epoch(record['updatedAt'])
  if published<epoch(previous[group]['updatedAt']):raise ValueError('Raid source date regressed')
  age=epoch(now)-published
  if age < -300 or (require_fresh and age>36*3600):raise ValueError('Raid source is stale or future-dated')
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
def raid(html,patch):
 if not re.search(r'diff-option[^>]*>\s*<span>Mythic</span>',html):raise ValueError('Raid source is not Mythic')
 observed=re.search(r'Patch\s+(\d+\.\d+)',html)
 if not observed or observed.group(1)!=patch:raise ValueError('Raid meta patch mismatch')
 marker='window.__SSR_DATA__ = '
 if marker not in html:raise ValueError('Raid SSR data unavailable')
 state,_=json.JSONDecoder().raw_decode(html[html.index(marker)+len(marker):])
 records=[v['data'] for k,v in state.items() if 'raid-default-tierlist.json' in k and v.get('data',{}).get('raid')]
 if len(records)!=1:raise ValueError('Ambiguous raid dataset')
 data=records[0];stamp=data.get('timestamp')
 if not stamp:raise ValueError('Raid source date unavailable')
 known={(normalized(s['className']),normalized(s['name'])):s['id'] for s in SPECS};result={}
 for group,key in [('dps','dps_list'),('healer','healing_tier_list'),('tank','tank_tier_list')]:
  counts={}
  for row in data['raid'].get(key,[]):
   identity=(normalized(row['class']),normalized(row['spec']))
   spec=known.get(identity)
   if not spec or role(spec)!=group:raise ValueError('Unknown raid specialization/role')
   count=row.get('count')
   if not isinstance(count,int) or count<0:raise ValueError('Invalid parse count')
   counts[spec]=counts.get(spec,0)+count
  total=sum(counts.values())
  if total<=0:raise ValueError('Empty raid sample')
  entries=[dict(specID=spec,rank=i+1,count=count,share=round(100*count/total,4)) for i,(spec,count) in enumerate(sorted(counts.items(),key=lambda v:(-v[1],v[0])))]
  result[group]=dict(entries=entries,sampleSize=total,updatedAt=stamp,updatedEpoch=epoch(stamp))
 return result
def validate_meta(data):
 if data.get('schema')!=1 or not data.get('patch'):raise ValueError('Invalid meta schema')
 if set(data.get('modes',{}))!={'raid','mythicplus'}:raise ValueError('Both meta modes required')
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
 result=copy.deepcopy(previous);now=dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ');result['generatedAt']=now
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
 url=previous['modes']['raid']['roles']['dps']['sourceURL']
 try:
  try:
   html=fetch(url,cache,'meta-raid.html',offline);roles=raid(html,result['patch'])
  except (OSError,ValueError) as error:
   print('Raid direct collection failed: '+type(error).__name__)
   html=None if offline else render_raid_page(url)
   if not html:raise ValueError('Public raid page unavailable') from error
   roles=raid(html,result['patch'])
  verify_raid_dates(roles,previous['modes']['raid']['roles'],now,not offline)
  for group,record in roles.items():
   record.update(retrievedEpoch=epoch(now),sourceURL=previous['modes']['raid']['roles'][group]['sourceURL'],retrievedAt=now,sourceHash=hashlib.sha256(html.encode()).hexdigest(),refreshStatus='ok',lastAttemptAt=now)
  result['modes']['raid']['roles']=roles
 except (OSError,ValueError):
  for record in result['modes']['raid']['roles'].values():record.update(refreshStatus='unavailable',lastAttemptAt=now)
  print('Raid meta: source unavailable; retaining original dated snapshot')
 validate_meta(result)
 return result

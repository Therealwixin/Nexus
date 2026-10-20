"""Import authored gear options as alternatives, never as new UI categories."""
import concurrent.futures,copy,datetime as dt,json,re
from pathlib import Path
from catalog import SPECS
from parsers import Page
from collect_gear import fetch,source_date,SLOT_NAMES
from refresh_meta import role
ROOT=Path(__file__).resolve().parents[1]

def classes(node,value):return value in node.attrs.get('class','').split()
def guide_url(spec):
 kind={'healer':'healing','tank':'tank','dps':'dps'}[role(spec['id'])]
 return 'https://www.icy-veins.com/wow/'+spec['slug']+'-'+spec['classSlug']+'-pve-'+kind+'-gear-best-in-slot'

def parse(text,url,patch):
 page=Page(text);heading=page.root.first('h1')
 if not heading or not re.search(r'\b'+re.escape(patch)+r'(?:\.\d+)?\b',heading.text()):raise ValueError('Alternative guide patch mismatch')
 stamp=source_date(text,None);out={};seen={};metadata={}
 for node in page.root.all():
  found=re.match(r'wow/item/(\d+)',node.attrs.get('data-iv-tooltip',''))
  if found:
   icon=node.first('img');quality=re.search(r'\bq([0-7])\b',node.attrs.get('class',''))
   if icon and icon.attrs.get('alt'):metadata[int(found[1])]={'name':icon.attrs['alt'].removesuffix(' Icon'),'icon':int(icon.attrs['src'].rsplit('/',1)[-1].split('.')[0]),'quality':int(quality[1]) if quality else 4}
 for region in page.root.all('div'):
  if not classes(region,'image_block_content'):continue
  for card in region.all('div'):
   if not classes(card,'bis_item'):continue
   slot=next((n.text().strip().lower() for n in card.all('span') if classes(n,'bis_item_slot')),None)
   ids=SLOT_NAMES.get(slot or '');itemNode=next((n for n in card.all('span') if re.match(r'wow/item/\d+',n.attrs.get('data-iv-tooltip',''))),None)
   if not ids or not itemNode:continue
   tooltip=itemNode.attrs['data-iv-tooltip'];itemID=int(re.match(r'wow/item/(\d+)',tooltip)[1]);original=re.search(r'(?:[?&])original=(\d+)',tooltip)
   base=int(original[1]) if original else itemID
   drop=next((n for n in card.all('span') if classes(n,'bis_item_drop')),None)
   links=[n.attrs.get('href','') for n in drop.all('a')] if drop else []
   dungeon=any('dungeon-guide' in link for link in links)
   crafted=any('profession' in link or 'crafting' in link for link in links) or (drop and 'craft' in drop.text().lower())
   raid=any('raid-guide' in link for link in links)
   kind='dungeon' if dungeon else 'crafted' if crafted else 'raid' if raid and base==itemID else 'unknown'
   signature=(region.attrs.get('id'),slot);index=seen.get(signature,0);seen[signature]=index+1;slotID=str(ids[min(index,len(ids)-1)])
   # A Catalyst option is shown as the actual source item, preserving its stats.
   record=dict(id=base,source='Icy Veins',guideURL=url,updatedAt=stamp,acquisition=kind,dropSource=drop.text() if drop and base==itemID or drop and dungeon else '',**metadata.get(base,{'name':'Item #'+str(base),'quality':4}))
   if base!=itemID:record['catalystTargetID']=itemID
   bonus=re.search(r'(?:[?&])bonus=([0-9:]+)',tooltip)
   if bonus:record['previewBonusIDs']=[int(value) for value in bonus[1].split(':')]
   if crafted:record['crafted']=True
   out.setdefault(slotID,[])
   prior=next((r for r in out[slotID] if r['id']==base),None)
   if not prior:out[slotID].append(record)
   elif kind=='dungeon':prior.update(acquisition='dungeon',dropSource=record['dropSource'])
 if len(out)<14:raise ValueError('Incomplete alternative guide')
 return dict(sourceURL=url,updatedAt=stamp,slots=out)

def collect(cache,patch,offline=False):
 cache.mkdir(parents=True,exist_ok=True);out={};failures=[]
 def one(spec):
  url=guide_url(spec);text=fetch(url,cache,spec['classSlug']+'-'+spec['slug']+'-icyveins.html',offline)
  data=parse(text,url,patch);data['retrievedAt']=dt.datetime.now(dt.timezone.utc).isoformat()
  return str(spec['id']),data
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  jobs={pool.submit(one,s):s for s in SPECS}
  for job,spec in jobs.items():
   try:sid,data=job.result();out[sid]=data
   except (OSError,ValueError) as e:failures.append((spec['id'],str(e)))
 print('Alternative guides:',len(out),'of 40;',len(failures),'unavailable')
 if failures:print(failures)
 return out

def merge(guides,options,previous=None,snapshot=None):
 for sid,guide in guides['specs'].items():
  if sid in options or not previous or previous['patch']!=guides['patch']:continue
  old=previous['specs'].get(sid,{})
  for field in ['alternatives','alternativeGuideURL','alternativeGuideUpdatedAt','alternativeGuideCheckedAt']:
   if field in old:guide[field]=copy.deepcopy(old[field])
  guide['alternativeGuideRefreshStatus']='unavailable'
  for slot,keys in old.get('alternatives',{}).items():
   for key in keys:
    record=previous['items'][key];guides['items'][key]=copy.deepcopy(record)
    if record.get('acquisition')=='dungeon':
     target=guide['sourceLists']['mythicplus'].setdefault(slot,[])
     if record['id'] not in {guides['items'][k]['id'] for k in target}:target.append(key)
 for sid,data in options.items():
  guide=guides['specs'][sid];guide['alternativeGuideURL']=data['sourceURL'];guide['alternativeGuideUpdatedAt']=data['updatedAt'];guide['alternatives']={}
  guide['alternativeGuideCheckedAt']=data.get('retrievedAt',guides['generatedAt']);guide['alternativeGuideRefreshStatus']='ok'
  for slot,rows in data['slots'].items():
   keys=[]
   for record in rows:
    key=str(record['id'])+':alternative:'+sid+':icyveins'
    guides['items'][key]=record
    keys.append(key)
    if record['acquisition']=='dungeon':
     target=guide['sourceLists']['mythicplus'].setdefault(slot,[])
     if record['id'] not in {guides['items'][k]['id'] for k in target}:target.append(key)
   guide['alternatives'][slot]=keys
 if snapshot:
  evidence={}
  for item in guides['items'].values():
   if item.get('acquisition')=='dungeon' and not (item.get('catalystOption') and not item.get('acquisitionItemID')):
    evidence[item.get('acquisitionItemID',item['id'])]=item
  for sid,guide in guides['specs'].items():
   for slot,rows in snapshot['specs'][sid]['mythicplus']['slots'].items():
    target=guide['sourceLists']['mythicplus'].get(slot,[])
    for raw in rows:
     source=evidence.get(raw['id'])
     if not source or raw.get('crafted') or raw.get('source')!='Murlok.io' or raw['id'] in {guides['items'][k]['id'] for k in target}:continue
     item=copy.deepcopy(raw);item.update(acquisition='dungeon',dropSource=source.get('dropSource',''),sourceEvidenceURL=source.get('guideURL'))
     for key in ('targetIlvl','dropIlvl','ilvlBasis','catalyst','bisGuide'):item.pop(key,None)
     key=str(item['id'])+':alternative:'+sid+':observed-dungeon';guides['items'][key]=item;target.append(key);guide['sourceLists']['mythicplus'][slot]=target
 for guide in guides['specs'].values():
  for scope,slots in guide['sourceLists'].items():guide['sourceLists'][scope]={slot:keys for slot,keys in slots.items() if keys}
  for slot,keys in list(guide['sourceLists']['mythicplus'].items()):
   keys=[key for key in keys if not (guides['items'][key].get('catalystOption') and not guides['items'][key].get('acquisitionItemID'))]
   if keys:guide['sourceLists']['mythicplus'][slot]=keys
   else:del guide['sourceLists']['mythicplus'][slot]
 return guides

if __name__=='__main__':
 data=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 options=collect(ROOT/'.cache',data['patch']);merge(data,options,snapshot=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8')))
 from refresh_gear import compact_lua
 (ROOT/'build/candidate/guide-snapshot.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (ROOT/'build/candidate/GuideData.lua').write_text('local _,R=...\nR.GuideData='+compact_lua(data)+'\n',encoding='utf-8')

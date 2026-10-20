"""Parse named Wowhead gear sets and explicitly identified raid/dungeon targets.

A Mythic+ activity guide is not assumed to exclude raids or crafted items.
Only explicit acquisition evidence may enter source-restricted lists.
"""
from pathlib import Path
import argparse,collections,copy,datetime as dt,html,json,re
from collect_gear import markup,source_date,SLOT_NAMES
from catalog import SPECS
ROOT=Path(__file__).resolve().parents[1]
EQUIP_SLOTS={1:[1],2:[2],3:[3],5:[5],6:[6],7:[7],8:[8],9:[9],10:[10],11:[11,12],12:[13,14],13:[16],14:[17],15:[16],16:[15],17:[16],20:[5],21:[16],22:[17],23:[17],26:[16]}
DUAL_WIELD={251,259,260,261,263,577,269,268,72}
def clean(s):return html.unescape(' '.join(re.sub(r'\[[^\]]*\]|<[^>]*>','',s).split()))
def metadata(text):
 markers=list(re.finditer(r'WH\.Gatherer\.addData\(3,\s*\d+,\s*',text))
 if not markers:raise ValueError('Missing item metadata')
 raw={}
 for marker in markers:
  batch,_=json.JSONDecoder().raw_decode(text[marker.end():]);raw.update(batch)
 out={}
 for key,value in raw.items():
  if value.get('icon'):
   out[int(key)]={'id':int(key),'name':value.get('name_enus'),'icon':'Interface\\Icons\\'+value['icon'],'quality':value.get('quality'),'equipType':value.get('jsonequip',{}).get('slotbak')}

 return out

def source_kind(origin,catalyst=False):
 text=clean(origin).lower()
 if re.search(r'craft|blacksmith|leatherwork|tailor|jewelcraft',text) or re.search(r'\[skill=(164|165|197|755)\b',origin):return 'crafted'
 # Raid names and seasonal dungeon names are evidence from the source cell,
 # independent of the activity or section containing the recommendation.
 if re.search(r'\braid\b|coiled alt[ae]r|ula.tek|kith.?ix|vashnik|sszorak|lost explorers|ent[oa]mbed sentinels|nek.zali|nymrissa|twin fangs',text):return 'raid'
 if re.search(r'murder row|temple of sethraliss|kings?.? rest|ruby life pools|blinding vale|voidscar arena|den of nalorakk|altar of fangs|mythic\+',text):return 'dungeon'
 return 'unknown'

def row_slots(table,meta):
 result={};seen=collections.Counter();rows=re.findall(r'\[tr\b[^\]]*\](.*?)\[/tr\]',table,re.S)
 header=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',rows[0],re.S) if rows else []
 labels=[clean(x).lower() for x in header];item_index=labels.index('item') if 'item' in labels else 1;source_index=labels.index('source') if 'source' in labels else item_index+1
 for row in re.findall(r'\[tr\b[^\]]*\](.*?)\[/tr\]',table,re.S):
  cells=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',row,re.S)
  if len(cells)<2:continue
  label=clean(cells[0]).lower().strip(':');label=re.sub(r'\s*\([^)]*\)','',label);label=re.sub(r'\s*[#(]?\d+[)]?\s*$','',label).replace('main-hand','main hand').replace('off-hand','off hand')
  if label=='shield':label='offhand'
  ids=SLOT_NAMES.get(label)
  if not ids:continue
  matches=list(re.finditer(r'\[(?:item|icon-badge)=(\d+)\b([^\]]*)\]',cells[item_index])) if len(cells)>item_index else []
  if not matches:continue
  origin=cells[source_index] if len(cells)>source_index else ''
  # Each authored row denotes one equipped slot. Additional item links are alternatives.
  slot=ids[min(seen[label],len(ids)-1)];seen[label]+=1
  items=[]
  for match in matches:
   id=int(match[1]);original=re.search(r'original-item=(\d+)',match[2]);base=int(original[1]) if original else id
   item=copy.copy(meta.get(id,{'id':id,'name':'Item #'+str(id)}));item['source']='Wowhead';item['bisGuide']=True
   item['dropSource']=clean(origin);item['acquisition']=source_kind(origin)
   if base!=id:item.update(acquisitionItemID=base,catalyst=True)
   if ('Catalyst' in origin or 'Catalyzed' in row) and base==id:item['catalystOption']=True
   if item['acquisition']=='crafted':item['crafted']=True
   npc=re.search(r'\[npc=(\d+)',origin)
   if npc:item['npcID']=int(npc[1])
   items.append(item)
  result.setdefault(str(slot),[]).extend(items)
 return result

def parse_guide(text,url,retrieved,spec):
 body=markup(text);meta=metadata(text);updated=source_date(text,None)
 patch=re.search(r'Currently viewing the Live \((\d+\.\d+(?:\.\d+)?)\) version',text)
 if not patch:raise ValueError('Live guide patch unavailable')
 # The main gear tabs end before the next h2; later craft/upgrade tabs are not BiS sets.
 start=re.search(r'\[tabs\b[^\]]*name=bis_items[^\]]*\]',body)
 end=body.find('[/tabs]',start.end()) if start else -1
 region=body[start.end():end] if start and end>=0 else body
 sets=[]
 for match in re.finditer(r'\[tab\s+name="([^"]+)"[^\]]*\](.*?)\[/tab\]',region,re.S):
  name=html.unescape(match[1]);slots={}
  for table in re.findall(r'\[table\b[^\]]*\](.*?)\[/table\]',match[2],re.S):
   found=row_slots(table,meta)
   if len(found)>=14:slots=found;break
  if not slots:continue
  lower=name.lower();scope='mythicplus_only' if 'mythic' in lower and 'only' in lower else 'mythicplus_activity' if 'mythic' in lower else 'raid_activity' if 'raid' in lower else 'overall'
  sets.append({'name':name,'scope':scope,'slots':slots})
 if not sets:
  for table in re.findall(r'\[table\b[^\]]*\](.*?)\[/table\]',region,re.S):
   slots=row_slots(table,meta)
   if len(slots)>=14:sets.append({'name':'Overall BiS','scope':'overall','slots':slots});break
 if not sets:raise ValueError('No complete authored gear set: '+spec['name'])
 priority={'raid':{},'dungeon':{}}
 headings=list(re.finditer(r'\[h2\b[^\]]*\](.*?)\[/h2\]',body,re.S))
 for index,heading in enumerate(headings):
  title=clean(heading[1]).lower();kind='dungeon' if 'mythic+' in title and ('gear' in title or 'items' in title) else 'raid' if re.search(r'\braids?\b',title) and ('gear' in title or 'items' in title) else None
  if not kind:continue
  section=body[heading.end():headings[index+1].start() if index+1<len(headings) else len(body)]
  for value in re.findall(r'\[icon-badge=(\d+)\b',section):
   id=int(value)
   if id not in meta:raise ValueError('Priority item metadata missing')
   item=copy.copy(meta[id]);item.update(source='Wowhead',bisGuide=True,acquisition=kind,dropSource='Wowhead '+('Mythic+ dungeon' if kind=='dungeon' else 'raid')+' priority')
   slots=EQUIP_SLOTS.get(item['equipType'],[])
   if item['equipType']==13 and spec['id'] in DUAL_WIELD:slots=[16,17]
   if item['equipType']==17 and spec['id']==72:slots=[16,17]
   for slot in slots:
    rows=priority[kind].setdefault(str(slot),[])
    if id not in {x['id'] for x in rows}:rows.append(copy.copy(item))
 return {'sourceURL':url,'sourcePatch':patch[1],'updatedAt':updated,'retrievedAt':retrieved,'sets':sets,'priorities':priority}

def build_guides(snapshot,cache,retrieved=None):
 now=retrieved or dt.datetime.now(dt.timezone.utc).isoformat();out={'schema':1,'patch':snapshot['upgradeRules']['patch'],'generatedAt':now,'items':{},'specs':{}}
 evidence={};parsed={}
 for spec in SPECS:
  slug=spec['classSlug']+'-'+spec['slug'];url='https://www.wowhead.com/guide/classes/'+spec['classSlug']+'/'+spec['slug']+'/bis-gear'
  guide=parse_guide((cache/(slug+'-wowhead-gear.html')).read_text(encoding='utf-8'),url,now,spec);parsed[str(spec['id'])]=guide
  if '.'.join(guide['sourcePatch'].split('.')[:2])!=out['patch']:raise ValueError('Live guide patch differs from verified season rules')
  for kind,slots in guide['priorities'].items():
   for rows in slots.values():
    for item in rows:evidence.setdefault(item['id'],set()).add(kind)
 def intern(item):
  key=str(item['id'])+':'+str(item.get('acquisitionItemID',item['id']))+':'+item.get('acquisition','unknown')
  if item.get('source')=='Murlok.io':key+=':observed:'+str(item['evidenceSpec'])
  if key not in out['items']:out['items'][key]=item
  return key
 for spec in SPECS:
  sid=str(spec['id']);guide=parsed[sid];restricted={'raid':{},'mythicplus':{}};sets=[]
  # Explicit source-only authored sets lead, followed by priority targets and observed alternatives.
  for authored in guide['sets']:
   slots={}
   for slot,rows in authored['slots'].items():
    slots[slot]=[intern(i) for i in rows]
    for item in rows:
     kind=item['acquisition']
     if kind in {'raid','dungeon'}:
      target=restricted['raid' if kind=='raid' else 'mythicplus'].setdefault(slot,[])
      key=intern(item)
      if key not in target:target.append(key)
   sets.append(dict(name=authored['name'],scope=authored['scope'],slots=slots))
  for kind,slots in guide['priorities'].items():
   for slot,rows in slots.items():
    target=restricted['raid' if kind=='raid' else 'mythicplus'].setdefault(slot,[])
    # Direct section recommendations lead when no source-only set is present.
    only=any(s['scope']=='mythicplus_only' for s in sets) and kind=='dungeon'
    keys=[intern(i) for i in rows];target[:]=list(dict.fromkeys(target+keys if only else keys+target))
  for slot,rows in snapshot['specs'][sid]['mythicplus']['slots'].items():
   for raw in rows:
    if raw.get('crafted'):continue
    kinds=evidence.get(raw['id'],set())
    if len(kinds)!=1:continue
    kind=next(iter(kinds));item=copy.copy(raw);item['acquisition']=kind;item['evidenceSpec']=int(sid);item.pop('bisGuide',None)
    for old_field in ('targetIlvl','dropIlvl','ilvlBasis','catalyst'):item.pop(old_field,None)
    target=restricted['raid' if kind=='raid' else 'mythicplus'].setdefault(slot,[])
    key=intern(item)
    if raw['id'] not in {out['items'][x]['id'] for x in target}:target.append(key)
  # Restrict source evidence to rows, never infer a drop from activity or tier item ID.
  guide['sets']=sets;guide['sourceLists']=restricted;guide.pop('priorities')
  out['specs'][sid]=guide
 validate_guides(out)
 return out

def validate_guides(data):
 if data.get('schema')!=1 or set(data['specs'])!={str(s['id']) for s in SPECS}:raise ValueError('Incomplete guide coverage')
 for sid,spec in data['specs'].items():
  if not spec.get('sourceURL') or not spec.get('updatedAt') or not spec['sets']:raise ValueError('Missing guide provenance')
  if '.'.join(spec.get('sourcePatch','').split('.')[:2])!=data['patch']:raise ValueError('Guide patch differs from snapshot')
  for authored in spec['sets']:
   if len(authored['slots'])<14:raise ValueError('Incomplete authored set')
  for scope,slots in spec['sourceLists'].items():
   for slot,keys in slots.items():
    if not keys:raise ValueError('Empty source slot')
    for key in keys:
     item=data['items'][key]
     if item.get('acquisition')!=('raid' if scope=='raid' else 'dungeon') or item.get('crafted'):raise ValueError('Incorrect acquisition source')
     if item.get('catalyst') and item.get('acquisitionItemID',item['id'])==item['id']:raise ValueError('Catalyst lacks base-item evidence')
  for authored in spec['sets']:
   for keys in authored['slots'].values():
    if not keys or any(k not in data['items'] for k in keys):raise ValueError('Broken item reference')

def main():
 p=argparse.ArgumentParser();p.add_argument('--cache',type=Path,default=ROOT/'.cache');p.add_argument('--output',type=Path,default=ROOT/'build/candidate');a=p.parse_args()
 snapshot=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'));data=build_guides(snapshot,a.cache)
 from refresh_gear import compact_lua
 a.output.mkdir(parents=True,exist_ok=True);(a.output/'guide-snapshot.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(a.output/'GuideData.lua').write_text('local _,R=...\nR.GuideData='+compact_lua(data)+'\n',encoding='utf-8')
 print('Guide specs',len(data['specs']),'shared item records',len(data['items']))
if __name__=='__main__':main()

#!/usr/bin/env python3
"""Aggregate collection only. No individual Murlok or Raider.IO profiles are fetched."""
from __future__ import annotations
import argparse,concurrent.futures,datetime as dt,hashlib,json,os,re
from pathlib import Path
from urllib.parse import urlencode
from catalog import SPECS
from parsers import parse_murlok,parse_player,wowhead_metadata,fetch as source_fetch,export_lua,stable_content,RIO_SLOTS
ROOT=Path(__file__).resolve().parents[1]

def source_date(html,fallback):
 for pattern in [r'<time\b[^>]*datetime="([^"]+)"',r'"dateModified"\s*:\s*"([^"]+)"']:
  match=re.search(pattern,html)
  if match:
   value=dt.datetime.fromisoformat(match.group(1).replace('Z','+00:00'))
   if value.tzinfo is None:raise ValueError('Source date lacks timezone')
   return value.astimezone(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
 raise ValueError('Source publication date unavailable; refusing to relabel old content as fresh')
def fetch(url,cache,name,offline=False):
 file=cache/name
 if not offline and file.exists() and dt.datetime.now().timestamp()-file.stat().st_mtime<3600:
  return file.read_text(encoding='utf-8')
 return source_fetch(url,cache,name,offline)
SLOT_NAMES={'head':[1],'neck':[2],'shoulder':[3],'shoulders':[3],'back':[15],'cloak':[15],'chest':[5],'wrist':[9],'wrists':[9],'bracers':[9],'hands':[10],'gloves':[10],'waist':[6],'belt':[6],'legs':[7],'feet':[8],'boots':[8],'ring':[11,12],'rings':[11,12],'trinket':[13,14],'trinkets':[13,14],'weapon':[16],'main hand':[16],'mainhand':[16],'offhand':[17],'off hand':[17],'two-hand weapon':[16],'helm':[1],'cape':[15],'1h weapon':[16],'2h weapon':[16],'weapons':[16]}
def markup(text):
 for m in re.finditer(r'WH\.markup\.printHtml\(\s*(?=")',text):
  value,n=json.JSONDecoder().raw_decode(text[m.end():])
  if 'guide-body' in text[m.end()+n:m.end()+n+40]:return value
 raise ValueError('Guide body unavailable')
def plain(text):return ' '.join(re.sub(r'\[[^\]]*\]|<[^>]*>','',text).split())
def guide_slots(text,url,timestamp):
 body=markup(text);meta=wowhead_metadata(text)
 for table in re.findall(r'\[table\b[^\]]*\](.*?)\[/table\]',body,re.S):
  slots={};seen={}
  rows=re.findall(r'\[tr\b[^\]]*\](.*?)\[/tr\]',table,re.S)
  header=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',rows[0],re.S) if rows else []
  labels=[plain(c).lower() for c in header]
  item_index=labels.index('item') if 'item' in labels else 1
  source_index=labels.index('source') if 'source' in labels else item_index+1
  for row in rows:
   cells=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',row,re.S)
   if len(cells)<2:continue
   label=plain(cells[0]).lower().strip(':')
   label=re.sub(r'\s*[#(]?\d+[)]?\s*$','',label).replace('main-hand','main hand').replace('off-hand','off hand')
   label=re.sub(r'\s*\([^)]*\)','',label)
   if label=='shield':label='offhand'
   found=re.search(r'\[(?:item|icon-badge)=(\d+)',cells[item_index]) if len(cells)>item_index else None;ids=SLOT_NAMES.get(label)
   if not found or not ids:continue
   index=seen.get(label,0);slot=ids[min(index,len(ids)-1)];seen[label]=index+1
   item_id=int(found.group(1));origin=cells[source_index] if len(cells)>source_index else '';source=plain(origin);npc=re.search(r'\[npc=(\d+)',origin)
   value=dict(meta.get(str(item_id),{}),id=item_id,source='Wowhead',guideURL=url,updatedAt=timestamp,bisGuide=True,dropSource=source)
   if npc:value['npcID']=int(npc.group(1))
   if 'craft' in source.lower() or re.search(r'\[skill=(164|165|197)\]',origin):value['crafted']=True
   if 'Catalyzed' in row or 'Catalyst' in row or 'creationcatalyst' in row:value['catalyst']=True
   slots.setdefault(str(slot),[]).append(value)
  if len(slots)>=14:return slots,meta
 raise ValueError('No complete BiS table')
def consumables(text,url,timestamp):
 body=markup(text);meta=wowhead_metadata(text);out=[];seen=set()
 for row in re.findall(r'\[tr\b[^\]]*\](.*?)\[/tr\]',body,re.S):
  cells=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',row,re.S)
  if len(cells)<2:continue
  label=plain(cells[0]);ids=re.findall(r'\[item=(\d+)',cells[1])
  if not re.search(r'flask|potion|weapon buff|augment rune|food',label,re.I):continue
  for value in ids[:2]:
   item_id=int(value)
   if item_id in seen:continue
   seen.add(item_id);out.append(dict(meta.get(value,{}),id=item_id,category=label,source='Wowhead',url=url,updatedAt=timestamp))
 if not out:raise ValueError('No consumables')
 return out
def raid_drops(text):
 body=markup(text);out={}
 for name,part in re.findall(r'\[tab name="([^"]+)"[^\]]*\](.*?)\[/tab\]',body,re.S)[:8]:
  start=None
  for row in re.findall(r'\[tr\b[^\]]*\](.*?)\[/tr\]',part,re.S):
   cells=re.findall(r'\[td\b[^\]]*\](.*?)\[/td\]',row,re.S)
   if len(cells)>1 and plain(cells[0]).lower()=='mythic':
    m=re.match(r'(\d+)',plain(cells[1]));start=int(m.group(1)) if m else None
  if not start:continue
  for value in re.findall(r'\[item=(\d+)',part):out[int(value)]=dict(dropSource=name,dropIlvl=start,targetIlvl=max(334,start))
 return out
def variant(raw):
 fields=[str(raw['item_id']),'0','0','0','0','0','0','0','90','0','0','0',str(len(raw.get('bonuses',[])))]+[str(x) for x in raw.get('bonuses',[])]
 return 'item:'+':'.join(fields)
def rio_gear(data,timestamp):
 gear={};enchants={}
 for key,raw in data.get('gear',{}).get('items',{}).items():
  slot=RIO_SLOTS.get(key)
  if not slot or not raw.get('item_id'):continue
  gear[str(slot)]=dict(id=raw['item_id'],name=raw.get('name'),ilvl=raw.get('item_level'),link=variant(raw),icon='Interface\\Icons\\'+raw.get('icon','inv_misc_questionmark'),source='Raider.IO',updatedAt=data.get('gear',{}).get('updated_at') or timestamp)
  for enchant in raw.get('enchants_detail',[]):
   if enchant.get('id') and raw.get('enchant'):enchants[str(slot)]=dict(id=enchant['id'],name=enchant.get('name'),icon='Interface\\Icons\\'+enchant.get('icon','inv_misc_questionmark'),enchantID=raw['enchant'],source='Raider.IO')
 if len(gear)<14:raise ValueError('Incomplete Raider.IO loadout')
 return gear,enchants
def collect(spec,cache,timestamp,offline,previous=None):
 slug=spec['classSlug']+'-'+spec['slug'];url='https://murlok.io/'+spec['classSlug']+'/'+spec['slug']+'/m%2B'
 html=fetch(url,cache,slug+'-murlok.html',offline)
 dataset=parse_murlok(html,source_date(html,timestamp))
 dataset['retrievedAt']=timestamp
 dataset.update(sourceURL=url,primarySource='Murlok.io',specName=spec['name'],classID=spec['classID'])
 observed=[];enchant_samples=[];warnings=[]
 previous=previous or {}
 profile=dataset.get('statProfile')
 if profile:
  profile.update(updatedAt=dataset['updatedAt'],retrievedAt=timestamp,sourceURL=url,sampleSize=dataset['sampleSize'],patch=dataset['patch'],refreshStatus='ok')
 elif previous.get('statProfile'):
  import copy
  dataset['statProfile']=copy.deepcopy(previous['statProfile']);dataset['statProfile']['refreshStatus']='unavailable'
 dataset.pop('players',None)
 for slot,enchant in dataset['enchants'].items():
  prior=previous.get('enchants',{}).get(slot,{})
  if prior.get('name','').casefold()==enchant.get('name','').casefold():
   for key in ('id','icon','allowedEnchantIDs'):
    if key in prior:enchant[key]=prior[key]
 base='https://www.wowhead.com/guide/classes/'+spec['classSlug']+'/'+spec['slug'];guide_url=base+'/bis-gear';raid=None;meta={}
 try:
  guide_html=fetch(guide_url,cache,slug+'-wowhead-gear.html',offline);guide_date=source_date(guide_html,timestamp)
  raid_slots,meta=guide_slots(guide_html,guide_url,guide_date)
  raid=dict(patch=dataset['patch'],updatedAt=guide_date,retrievedAt=timestamp,sourceURL=guide_url,slots=raid_slots,primarySource='Wowhead',guideSet=True,specName=spec['name'],classID=spec['classID'],players=[],enchants=dataset['enchants'],gems=dataset['gems'],consumables=[])
 except (OSError,ValueError) as e:warnings.append('Wowhead BiS: '+type(e).__name__)
 for suffix in ('enchants-gems-pve-dps','enchants-gems-pve-tank','enchants-gems-pve-healer'):
  try:
   cu=base+'/'+suffix;prep_html=fetch(cu,cache,slug+'-'+suffix+'.html',offline)
   dataset['consumables']=consumables(prep_html,cu,source_date(prep_html,timestamp))
   if raid:raid['consumables']=dataset['consumables']
   break
  except (OSError,ValueError):continue
 if not dataset['consumables']:warnings.append('No fresh consumables')
 for slot,rows in dataset['slots'].items():
  guide_rows=raid and raid['slots'].get(slot,[]) or [];by_id={x['id']:x for x in guide_rows}
  for item in rows:
   item.update(meta.get(str(item['id']),{}));item['sampleSize']=dataset['sampleSize']
   if item['id'] in by_id:
    item.update({k:v for k,v in by_id[item['id']].items() if k in ('dropSource','npcID','catalyst','crafted')});item['bisGuide']=True
  for item in guide_rows:
   if item['id'] not in {x['id'] for x in rows}:rows.append(item)
 return spec,dataset,raid,observed,warnings

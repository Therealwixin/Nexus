"""Build an unpublished compact candidate. Never overwrite the installed addon.

Uses aggregate Murlok data and Wowhead guides; no player profile requests.
Live collection still needs validation against today's source markup.
"""
from pathlib import Path
import argparse,concurrent.futures,copy,datetime as dt,json,hashlib
from collect_gear import collect
from catalog import SPECS
ROOT=Path(__file__).resolve().parents[1]

def validate(data):
 expected={str(s['id']) for s in SPECS}
 if set(data.get('specs',{}))!=expected:raise ValueError('Incomplete specialization coverage')
 patch=data.get('upgradeRules',{}).get('patch')
 if not patch:raise ValueError('Missing verified season rules')
 for spec,modes in data['specs'].items():
  if set(modes)!={'raid','mythicplus'}:raise ValueError('Both modes required for '+spec)
  for mode,dataset in modes.items():
   if dataset.get('patch')!=patch:raise ValueError('Patch change requires manual season validation')
   if dataset.get('players'):raise ValueError('Player profiles are prohibited in compact builds')
   if not dataset.get('updatedAt') or len(dataset.get('slots',{}))<14:raise ValueError('Incomplete gear dataset')
   if not dataset.get('consumables') or not dataset.get('gems'):raise ValueError('Incomplete preparation data')
   for slot,items in dataset['slots'].items():
    if int(slot) not in {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17} or not items:raise ValueError('Invalid slot')
    for item in items:
     if not isinstance(item.get('id'),int) or item['id']<=0 or not item.get('source'):raise ValueError('Invalid item/provenance')

def compact_lua(value,key=None):
 if isinstance(value,dict):
  parts=[]
  for k,v in value.items():
   numeric=key in {'specs','slots','enchants','raid','mythicplus','alternatives'} and str(k).isdigit()
   parts.append('['+(str(k) if numeric else json.dumps(k,ensure_ascii=False))+']='+compact_lua(v,k))
  return '{'+','.join(parts)+'}'
 if isinstance(value,list):return '{'+','.join(compact_lua(v) for v in value)+'}'
 if value is True:return 'true'
 if value is False:return 'false'
 if value is None:return 'nil'
 return json.dumps(value,ensure_ascii=False)

def build_candidate(previous,cache,offline=False):
 timestamp=dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
 candidate=copy.deepcopy(previous);candidate['specs']={};candidate['generatedAt']=timestamp
 failures=[]
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  jobs={pool.submit(collect,spec,cache,timestamp,offline,previous['specs'][str(spec['id'])]['mythicplus']):spec for spec in SPECS}
  for job,spec in jobs.items():
   try:
    _,mp,raid,_,warnings=job.result()
    if warnings or not raid:raise ValueError('; '.join(warnings) or 'Missing raid guide')
    for dataset,mode in [(mp,'mythicplus'),(raid,'raid')]:
     dataset.pop('players',None)
     # Preserve verified seasonal metadata only for the same item and patch.
     old=previous['specs'][str(spec['id'])][mode]
     if old['patch']==dataset['patch']:
      known={i['id']:i for items in old['slots'].values() for i in items}
      for items in dataset['slots'].values():
       for item in items:
        for key in ('targetIlvl','dropIlvl','ilvlBasis','journalItemID','journalInstanceID','journalEncounterID'):
         if key in known.get(item['id'],{}):item[key]=known[item['id']][key]
    candidate['specs'][str(spec['id'])]={'mythicplus':mp,'raid':raid}
   except Exception as error:failures.append(spec['name']+': '+str(error))
 if failures:raise ValueError('No candidate written; original snapshot retained.\n'+'\n'.join(failures))
 validate(candidate)
 from parsers import stable_content
 candidate['contentHash']=hashlib.sha256(stable_content(candidate)).hexdigest()
 return candidate

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--cache',type=Path,default=ROOT/'.cache')
 p.add_argument('--offline',action='store_true')
 p.add_argument('--validate-only',action='store_true')
 args=p.parse_args()
 previous=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
 validate(previous)
 from refresh_meta import validate_meta,collect_meta
 previous_meta=json.loads((ROOT/'data/meta-snapshot.json').read_text(encoding='utf-8'))
 validate_meta(previous_meta)
 from wowhead_sets import build_guides,validate_guides
 if args.validate_only:
  guides=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'));validate_guides(guides)
  if guides['patch']!=previous['upgradeRules']['patch']:raise ValueError('Guide patch mismatch')
  print('Gear, guides and meta snapshots valid; no source requests.');return
 args.cache.mkdir(parents=True,exist_ok=True)
 candidate=build_candidate(previous,args.cache,args.offline)
 meta=collect_meta(previous_meta,args.cache,args.offline)
 guides=build_guides(candidate,args.cache)
 from alternative_guides import collect as collect_alternatives,merge as merge_alternatives
 old_guides=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 merge_alternatives(guides,collect_alternatives(args.cache,guides['patch'],args.offline),old_guides,candidate)
 from wowhead_sets import validate_guides
 validate_guides(guides)
 output=ROOT/'build/candidate';output.mkdir(parents=True,exist_ok=True)
 if not args.offline:
  from source_health import write
  write(output)
 (output/'snapshot.json').write_text(json.dumps(candidate,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (output/'Data.lua').write_text('-- Aggregate candidate. Review before release.\nlocal _,R=...\nR.Data='+compact_lua(candidate)+'\n',encoding='utf-8')
 (output/'meta-snapshot.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (output/'MetaData.lua').write_text('-- Role-local meta; source timestamps preserved.\nlocal _,R=...\nR.MetaData='+compact_lua(meta)+'\n',encoding='utf-8')
 (output/'guide-snapshot.json').write_text(json.dumps(guides,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (output/'GuideData.lua').write_text('local _,R=...\nR.GuideData='+compact_lua(guides)+'\n',encoding='utf-8')
 print('Unpublished candidate:',output)
if __name__=='__main__':main()

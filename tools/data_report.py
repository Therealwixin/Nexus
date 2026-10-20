"""Summarize actual published coverage without calling incomplete lists complete BiS."""
import json
from catalog import SPECS
from refresh_gear import ROOT

def report():
 data=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 wcl=json.loads((ROOT/'data/wcl-snapshot.json').read_text(encoding='utf-8'))
 def coverage(slots):
  selected={}
  for slot,keys in sorted(slots.items(),key=lambda x:int(x[0])):
   exclude=selected.get('11' if slot=='12' else '13') if slot in {'12','14'} else None
   rows=[data['items'][key]['id'] for key in keys if data['items'][key]['id']!=exclude]
   if rows:selected[slot]=rows[0]
  return len(selected)
 lines=['# Nexus data coverage — 2026-10-20','','All 40 live Wowhead gear guides were fetched normally and parsed. Their published dates and live patch are preserved in the snapshots. All guides include Mythic+ recommendations, but most are short dungeon priorities alongside an overall set. Restoration Druid has a named Mythic+ Only table; Mistweaver has an activity-oriented Mythic+ BiS set that includes raid gear.','','Overall follows the authored set. Raid/Mythic+ source filters contain explicit source-qualified guide recommendations and same-spec observed alternatives with independently established acquisition evidence. Crafted/unknown sources are excluded from these two filters. A Catalyst recommendation retains the original dungeon drop ID. These filtered lists are not a simulated optimal set and do not cover every slot. Counts below are occupied positions out of 16; two-handed setups can leave offhand empty.','','WCL adds one ranking page for The Coiled Altar (Mythic) and Murder Row (M+) per spec. Healers use HPS; others DPS. Only anonymous usage counts for known items are stored. Samples below 20 are omitted. This is encounter-specific observation, not all-season representative or personalized BiS. Six raid contexts lacked a usable sample; all 40 M+ contexts passed. Retrieved '+wcl['generatedAt']+'.','','| Spec | Overall slots | Raid-source slots | M+-source slots | WCL raid / M+ samples | Guide |','|---|---:|---:|---:|---|---|']
 for spec in SPECS:
  sid=str(spec['id']);g=data['specs'][sid];sets=g['sets'];main=next((s for s in sets if s['scope']=='overall'),sets[0]);e=wcl['specs'][sid]
  samples=' / '.join(str(e[m]['sampleSize']) if m in e else 'unavailable' for m in ['raid','mythicplus'])
  lines.append('| '+spec['className']+' '+spec['name']+' | '+str(coverage(main['slots']))+' | '+str(coverage(g['sourceLists']['raid']))+' | '+str(coverage(g['sourceLists']['mythicplus']))+' | '+samples+' | [Wowhead]('+g['sourceURL']+') |')
 return '\n'.join(lines)+'\n'

if __name__=='__main__':
 path=ROOT/'DATA-SOURCES.md';path.write_text(report(),encoding='utf-8',newline='\n');print(path)

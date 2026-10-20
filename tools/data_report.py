"""Report actual recommendation and observation coverage, without claiming consensus."""
from catalog import SPECS
from refresh_gear import ROOT
from test_lean import load_addon
import json

def report():
 data=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 observed=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
 wcl=json.loads((ROOT/'data/wcl-snapshot.json').read_text(encoding='utf-8'))
 lua,R,_=load_addon(ROOT/'Nexus');R.db=lua.table_from({'mode':'mythicplus'});R.character=lua.table()
 stats=lua.eval('function(R,id) R.SetViewSpec(id);local n,f,d=0,0,0;for _,s in ipairs(R.SLOTS) do if R.GetGearTarget(s.id) then n=n+1;local a=R.GetGearAlternatives(s.id);if #a==4 then f=f+1 end;for _,i in ipairs(a) do if i.acquisition=="dungeon" then d=d+1;break end end end end;return n,f,d end')
 lines=['# Nexus source coverage — '+data['generatedAt'][:10],'',
 'Overall follows the named authored Wowhead set. Authored Wowhead/Icy Veins alternatives precede observed Murlok options; one verified dungeon option is reserved where available. Up to four distinct options are shown. A guide recommendation, profile usage and ranked-log usage are different evidence types, not independent votes for universal BiS.','',
 'Murlok is a snapshot of top-rated M+ profiles (normally 50), not all players or all logs. Publication and retrieval dates remain separate. Catalyst comparisons use original source-item identity.','',
 'The legacy single-encounter WCL sample is withdrawn. The broad collector targets all 8 current-season dungeons and 10 raid encounters, two ranking pages per spec/encounter, a locally filtered 14-day window, M+ keys >=10, and the latest complete loadout per character. Eligibility requires >=20 usable unique characters in every planned encounter and >=200 unique characters per spec/mode. Ranked samples are not random, not all logs and never select Overall BiS. Incomplete coverage is explicitly excluded; duplicate character observations are not added to the pooled denominator.','',
 'Archon is not a gear feed until verified access is available. Its availability status is separate from WCL; the two must not be counted as independent corroboration.','',
 '| Spec | Overall slots | Four alternatives | Dungeon alternative | Murlok profiles | WCL raid / M+ coverage | Guides |',
 '|---|---:|---:|---:|---:|---|---|']
 for spec in SPECS:
  sid=str(spec['id']);g=data['specs'][sid];n,f,d=stats(R,spec['id']);sample=observed['specs'][sid]['mythicplus'].get('sampleSize','unknown')
  coverage=[]
  for mode in ['raid','mythicplus']:
   r=wcl.get('specs',{}).get(sid,{}).get(mode)
   coverage.append((str(r['coveredEncounterCount'])+'/'+str(r['expectedEncounterCount'])+'; n='+str(r['sampleSize'])+(' eligible' if r['eligible'] else ' excluded')) if r and wcl.get('schema')==2 else 'not collected')
  links='[Wowhead]('+g['sourceURL']+')'+(' · [Icy Veins]('+g['alternativeGuideURL']+')' if g.get('alternativeGuideURL') else '')
  lines.append('| '+spec['className']+' '+spec['name']+' | '+str(n)+' | '+str(f)+' | '+str(d)+' | '+str(sample)+' | '+' / '.join(coverage)+' | '+links+' |')
 return '\n'.join(lines)+'\n'

if __name__=='__main__':
 path=ROOT/'DATA-SOURCES.md';path.write_text(report(),encoding='utf-8');print(path)

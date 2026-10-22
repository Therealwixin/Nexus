"""Report actual recommendation and observation coverage, without claiming consensus."""
from catalog import SPECS
from refresh_gear import ROOT
from test_lean import load_addon
import json

def report():
 data=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'))
 observed=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
 lua,R,_=load_addon(ROOT/'Nexus');R.db=lua.table_from({'mode':'mythicplus'});R.character=lua.table()
 stats=lua.eval('function(R,id) R.SetViewSpec(id);local n,f,d=0,0,0;for _,s in ipairs(R.SLOTS) do if R.GetGearTarget(s.id) then n=n+1;local a=R.GetGearAlternatives(s.id);if #a==4 then f=f+1 end;for _,i in ipairs(a) do if i.acquisition=="dungeon" then d=d+1;break end end end end;return n,f,d end')
 lines=['# Nexus source coverage — '+data['generatedAt'][:10],'',
 'Mythic+ follows observed current-season Murlok usage. Raid mode and raid Meta are retired. All acquisition sources remain available for M+; one verified dungeon alternative is reserved where available. Up to four distinct options are shown. Guide recommendations and profile usage are different evidence types, not independent votes for universal BiS.','',
 'Murlok is a snapshot of top-rated M+ profiles (normally 50), not all players or all logs. Publication and retrieval dates remain separate. Catalyst comparisons use original source-item identity.','',
 '| Spec | Mythic+ slots | Four alternatives | Dungeon alternative | Murlok profiles | Guides |',
 '|---|---:|---:|---:|---:|---|']
 for spec in SPECS:
  sid=str(spec['id']);g=data['specs'][sid];n,f,d=stats(R,spec['id']);sample=observed['specs'][sid]['mythicplus'].get('sampleSize','unknown')
  links='[Wowhead]('+g['sourceURL']+')'+(' · [Icy Veins]('+g['alternativeGuideURL']+')' if g.get('alternativeGuideURL') else '')
  lines.append('| '+spec['className']+' '+spec['name']+' | '+str(n)+' | '+str(f)+' | '+str(d)+' | '+str(sample)+' | '+links+' |')
 return '\n'.join(lines)+'\n'

if __name__=='__main__':
 path=ROOT/'DATA-SOURCES.md';path.write_text(report(),encoding='utf-8');print(path)

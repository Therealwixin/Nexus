"""Lua 5.1 client simulation. Does not certify the real WoW renderer or taint."""
from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
try:
 from lupa.lua51 import LuaRuntime
except ImportError:
 sys.path.insert(0,str(ROOT.parent/'runtime'))
 from lupa.lua51 import LuaRuntime

def load_addon(root,full=True):
 lua=LuaRuntime(unpack_returned_tuples=True)
 if full:lua.execute((ROOT/'tests/wow_stub.lua').read_text(encoding='utf-8-sig'))
 ns=lua.table()
 loader=lua.eval('function(s,n,r) return assert(loadstring(s,n))("Nexus",r) end')
 lua.gccollect();start=lua.eval('collectgarbage("count")')
 files=[l for l in (root/'Nexus.toc').read_text(encoding='utf-8-sig').splitlines() if l and not l.startswith('#')] if full else ['Data.lua']
 for name in files:loader((root/name).read_text(encoding='utf-8-sig'),name,ns)
 lua.gccollect()
 return lua,ns,lua.eval('collectgarbage("count")')-start

if __name__=='__main__':
 lua,ns,memory=load_addon(ROOT/'Nexus')
 # Check every bundled non-tier Catalyst result against retained primary DBC rows.
 outputs={}
 for line in (ROOT/'tests/fixtures/catalyst-offpieces.inc').read_text(encoding='utf-8').splitlines():
  fields=line.split(', ');item=int(fields[1]);inventory=int(fields[10]);mask=int(fields[19],16)
  assert mask==1<<(mask.bit_length()-1)
  outputs[item]={'classID':mask.bit_length(),'slot':15 if inventory==16 else inventory,'armor':int(fields[12])}
 assert len(outputs)==52 and {r['classID'] for r in outputs.values()}==set(range(1,14))
 assert {key:dict(value) for key,value in ns.CatalystOffpieces['items'].items()}==outputs
 bonus_rows={}
 for line in (ROOT/'tests/fixtures/upgrade-track-bonuses.inc').read_text().splitlines():
  row=re.match(r'\s*\{\s*\d+,\s*(\d+),\s*(\d+),\s*(-?\d+),',line)
  if row:bonus_rows.setdefault(int(row[1]),{})[int(row[2])]=int(row[3])
 assert set(bonus_rows)==set(range(12841,12857))
 for bonus,row in ns.UpgradeBonusTracks['bonuses'].items():
  assert bonus_rows[bonus][34]==(617 if row['name']=='Hero' else 618)
  assert row['rank']==bonus-(12840 if row['name']=='Hero' else 12848)
 native=json.loads((ROOT/'tests/fixtures/upgrade-track-tooltips.json').read_text())
 levels={row['bonus']:int(re.search(r'<!--ilvl-->(\d+)',row['tooltip'])[1]) for row in native['cases']}
 for bonus,row in ns.UpgradeBonusTracks['bonuses'].items():
  endpoint=12846 if row['name']=='Hero' else 12854
  if row['rank']>6:endpoint=12848 if row['name']=='Hero' else 12856
  assert row['maximum']==levels[endpoint]
 lua.globals().TEST.R=ns
 lua.globals().TEST.liveCatalyst=lua.eval(__import__('refresh_gear').compact_lua(json.loads((ROOT/'tests/fixtures/live-catalyst-12.1.5.json').read_text(encoding='utf-8'))))
 lua.execute((ROOT/'tests/lean.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/look.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/bag_sockets.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/fixes.lua').read_text(encoding='utf-8'))
 lua.globals().TEST.variantEvidence=lua.eval(__import__('refresh_gear').compact_lua(json.loads((ROOT/'tests/fixtures/item-variant-evidence.json').read_text(encoding='utf-8'))))
 lua.execute((ROOT/'tests/item_levels.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/evidence.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/gear_identity.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/dungeon_alerts.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/activity_gear.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/gear_background.lua').read_text(encoding='utf-8'))
 lua.execute((ROOT/'tests/detail_scroll.lua').read_text(encoding='utf-8'))
 report={'simulationChecks':lua.globals().TEST.leanChecks,'layoutChecks':lua.globals().TEST.lookChecks,'loadedAddonKiB':round(memory,1)}
 baseline=Path('C:/Users/South/Downloads/Nexus-0.5.0-beta.5/Nexus')
 if baseline.exists():
  a,_,before=load_addon(baseline,False)
  b,_,after=load_addon(ROOT/'Nexus',False)
  report.update(originalDataKiB=round(before,1),compactDataKiB=round(after,1),dataMemoryReductionPercent=round((1-after/before)*100,1),originalDataBytes=(baseline/'Data.lua').stat().st_size,compactDataBytes=(ROOT/'Nexus/Data.lua').stat().st_size)
 print(json.dumps(report,indent=2))
 (ROOT/'TEST-RESULTS.json').write_text(json.dumps(report,indent=2)+'\n')


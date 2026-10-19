"""Deterministic tests for candidate generation and failed refresh preservation."""
from pathlib import Path
import copy,json,sys
from contextlib import nullcontext
from unittest.mock import patch
from refresh_gear import ROOT,build_candidate,compact_lua,validate
try:
 from lupa.lua51 import LuaRuntime
except ImportError:
 sys.path.insert(0,str(ROOT.parent/'runtime'))
 from lupa.lua51 import LuaRuntime

data=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
original=copy.deepcopy(data)
def fixture(spec,*args):
 modes=copy.deepcopy(data['specs'][str(spec['id'])])
 return spec,modes['mythicplus'],modes['raid'],[],[]
with nullcontext(ROOT/'tests') as cache:
 with patch('refresh_gear.collect',fixture):
  candidate=build_candidate(data,Path(cache))
 validate(candidate)
 assert data==original,'Candidate generation modified last known snapshot'
 lua=LuaRuntime(unpack_returned_tuples=True)
 loaded=lua.eval(compact_lua(candidate))
 assert loaded.specs[266].raid.slots[1][1].id==data['specs']['266']['raid']['slots']['1'][0]['id']
 assert loaded.specs[1480].mythicplus.slots[1][1].id>0
 def failure(*args):raise ValueError('Source unavailable')
 with patch('refresh_gear.collect',failure):
  try:build_candidate(data,Path(cache))
  except ValueError as error:assert 'original snapshot retained' in str(error)
  else:raise AssertionError('Failed sources accepted')
 assert data==original

# The collector must not request individual players even if aggregate HTML lists them.
import collect_gear
spec=collect_gear.SPECS[0]
mp=copy.deepcopy(data['specs'][str(spec['id'])]['mythicplus'])
mp['players']=[{'name':'Sample player','url':'https://example.invalid/individual-profile'}]
raid=data['specs'][str(spec['id'])]['raid']
requested=[]
def fetch(url,*args):requested.append(url);return '<time datetime="2026-10-16T00:00:00Z">fixture</time>'
with patch.object(collect_gear,'fetch',fetch),patch.object(collect_gear,'parse_murlok',lambda *a:copy.deepcopy(mp)),patch.object(collect_gear,'guide_slots',lambda *a:(copy.deepcopy(raid['slots']),{})),patch.object(collect_gear,'consumables',lambda *a:copy.deepcopy(mp['consumables'])):
 result=collect_gear.collect(spec,Path('.'),'2026-10-19T00:00:00Z',False,mp)
assert len(requested)==3 and all('raider.io' not in u and 'individual-profile' not in u for u in requested)
assert not result[1].get('players')
print('Maintenance: snapshot immutability, all-spec candidate, Lua roundtrip, source failure, zero profile requests: PASS')


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

# Retired source artifacts in an old candidate must not be promoted back into the addon.
import datetime as dt,tempfile
import data_release

tempbase=ROOT/'build/maintenance-tests';tempbase.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(dir=tempbase) as directory:
 root=Path(directory)
 for folder in ['data','Nexus','build/candidate']:(root/folder).mkdir(parents=True,exist_ok=True)
 (root/'Nexus/Nexus.toc').write_text('## Version: 0.6.7-beta.7\n',encoding='utf-8')
 for name in ['snapshot.json','meta-snapshot.json','guide-snapshot.json']:
  value=json.loads((ROOT/'data'/name).read_text(encoding='utf-8'));value['generatedAt']=dt.datetime.now(dt.timezone.utc).isoformat()
  (root/'build/candidate'/name).write_text(json.dumps(value),encoding='utf-8')
 for name in ['Data.lua','MetaData.lua','GuideData.lua']:(root/'build/candidate'/name).write_text('-- test candidate',encoding='utf-8')
 for name in ['SourceStatus.lua','WCLData.lua','source-status.json','wcl-snapshot.json']:(root/'build/candidate'/name).write_text('retired source',encoding='utf-8')
 with patch.object(data_release,'ROOT',root):data_release.stage(keep_version=True)
 assert not (root/'Nexus/SourceStatus.lua').exists() and not (root/'Nexus/WCLData.lua').exists()
 assert not (root/'data/source-status.json').exists() and not (root/'data/wcl-snapshot.json').exists()
for file in ['wcl.yml','wcl-refresh.yml']:assert not (ROOT/'.github/workflows'/file).exists()
assert 'source_health' not in (ROOT/'tools/refresh_gear.py').read_text(encoding='utf-8')
print('Maintenance: retired collectors/workflows removed; stale candidate artifacts cannot reappear PASS')

# A prior evening manual run must not suppress the following calendar day's run.
with tempfile.TemporaryDirectory(dir=tempbase) as directory:
 root=Path(directory);(root/'data').mkdir()
 (root/'data/snapshot.json').write_text(json.dumps({'generatedAt':'2026-10-20T22:00:00Z'}),encoding='utf-8')
 for file in ['meta-snapshot.json','guide-snapshot.json']:(root/'data'/file).write_text('{}',encoding='utf-8')
 with patch.object(data_release,'ROOT',root),patch.dict(data_release.os.environ,{'GITHUB_STEP_SUMMARY':'','GITHUB_OUTPUT':''}):
  assert data_release.due(dt.datetime(2026,10,21,4,17,tzinfo=dt.timezone.utc),'schedule')
  assert not data_release.due(dt.datetime(2026,10,20,23,17,tzinfo=dt.timezone.utc),'schedule')
  assert data_release.due(dt.datetime(2026,10,20,23,17,tzinfo=dt.timezone.utc),'workflow_dispatch')
  (root/'data/meta-snapshot.json').write_text(json.dumps({'refreshStatus':'unavailable'}),encoding='utf-8')
  assert data_release.due(dt.datetime(2026,10,20,23,17,tzinfo=dt.timezone.utc),'schedule')
print('Daily cadence PASS: next calendar day, same-day success skip, forced run and partial-source retry')

# Stable users must receive stable daily packages after the first stable release.
with patch.dict(data_release.os.environ,{'DATA_RELEASE_CHANNEL':''}):
 for current,expected in [('0.6.7-beta.7','beta'),('1.0.0','release'),('1.0.0-data.202610211000','release')]:
  assert data_release.release_channel(current)==expected
with patch.dict(data_release.os.environ,{'DATA_RELEASE_CHANNEL':'beta'}):
 assert data_release.release_channel('1.0.0')=='beta'
print('Release channel PASS: daily versions follow beta/stable channel with an explicit override')

try:build_candidate(data,ROOT/'tests',rendered_pages={})
except ValueError as error:assert 'Incomplete rendered Murlok coverage' in str(error)
else:raise AssertionError('Partial hydrated gear must not fall back to stale SSR')
print('Rendered gear coverage PASS: incomplete live batch cannot overwrite the last verified snapshot')

fresh_stamp=dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
rendered='<time datetime="'+fresh_stamp+'"></time>'
requested=[]
with patch.object(collect_gear,'fetch',fetch),patch.object(collect_gear,'parse_murlok',lambda html,stamp:dict(copy.deepcopy(mp),updatedAt=stamp)),patch.object(collect_gear,'guide_slots',lambda *a:(copy.deepcopy(raid['slots']),{})),patch.object(collect_gear,'consumables',lambda *a:copy.deepcopy(mp['consumables'])):
 refreshed=collect_gear.collect(spec,Path('.'),fresh_stamp,False,mp,rendered)[1]
 assert len(requested)==2 and all('murlok.io' not in url for url in requested),'Hydrated gear must bypass the old initial HTTP page'
 assert refreshed['updatedAt']==fresh_stamp and refreshed['statProfile']['updatedAt']==fresh_stamp
 try:collect_gear.collect(spec,Path('.'),fresh_stamp,False,mp,'<time datetime="2026-10-01T00:00:00Z"></time>')
 except ValueError:pass
 else:raise AssertionError('Stale rendered gear accepted')
print('Rendered gear provenance PASS: source dates used, SSR bypassed and stale pages rejected')

"""Broad WCL sampling regressions, with no credentials or live player data."""
import base64,collections,contextlib,copy,datetime as dt,io,json
from unittest.mock import patch
from pathlib import Path
from wcl_public import Client,validate_snapshot,collect_guides,usable_row,retain_latest,reduce_characters,SEASON_ZONES,runtime_snapshot
from test_lean import load_addon,ROOT
from refresh_gear import compact_lua

with patch.dict('os.environ',{'WCL_CLIENT_ID':' example-id\n','WCL_CLIENT_SECRET':' example-secret\r\n'}):
 with patch('wcl_public.request',return_value={'access_token':'test-token'}) as request:
  Client()
  assert request.call_args.args[2]['Authorization']=='Basic '+base64.b64encode(b'example-id:example-secret').decode()
with patch.dict('os.environ',{'WCL_CLIENT_ID':'same','WCL_CLIENT_SECRET':'same'}):
 with patch('wcl_public.request') as request:
  try:Client()
  except ValueError:pass
  else:raise AssertionError('Duplicate credentials accepted')
  assert not request.called

world=json.loads((ROOT/'tests/fixtures/wcl-season-world.json').read_text(encoding='utf-8'))
now=dt.datetime(2026,10,20,18,tzinfo=dt.timezone.utc);stamp=now.timestamp()*1000
gear=[{'id':270175}]+[{'id':900000+i} for i in range(13)]
class FixtureClient:
 def __init__(self,spent=1,empty=None):self.spent=spent;self.pages=0;self.empty=empty
 def query(self,q,variables=None):
  if 'rateLimitData' in q:return {'rateLimitData':{'limitPerHour':720,'pointsSpentThisHour':self.spent,'pointsResetIn':1}}
  if 'zone(id:' in q:
   z=next(z for z in world['zones'] if z['id']==variables['id']);return {'worldData':{'zone':z}}
  assert ' ' not in variables['class'] and ' ' not in variables['spec']
  self.pages+=1;page=2 if 'page:2' in q else 1
  rows=[] if variables['id']==self.empty else [dict(name='Do not serialize '+str(variables['id'])+' '+str(i),server={'id':1,'region':'EU'},startTime=stamp-10000+page,hardModeLevel=15,gear=gear,**{'class':variables['class'],'spec':variables['spec']}) for i in range(100)]
  return {'worldData':{'encounter':{'characterRankings':{'rankings':rows,'hasMorePages':bool(rows)}}}}
with contextlib.redirect_stdout(io.StringIO()):
 client=FixtureClient();collected=collect_guides(client,ROOT,spec_ids={71,261},now=now)
 assert client.pages==72,'Two specs each need two pages for all 18 encounters'
 for sid in ['71','261']:
  for mode,record in collected['specs'][sid].items():
   assert record['eligible'] and record['coveredEncounterCount']==SEASON_ZONES[mode][2]
   assert record['sampleSize']==100*SEASON_ZONES[mode][2],'Repeated page characters doubled denominator'
 assert 'Do not serialize' not in json.dumps(collected) and 'server' not in json.dumps(collected['specs'])
 partial=collect_guides(FixtureClient(empty=12813),ROOT,spec_ids={71},now=now)
 assert not partial['specs']['71']['mythicplus']['eligible'] and partial['specs']['71']['mythicplus']['coveredEncounterCount']==7
 client=FixtureClient(576)
 try:collect_guides(client,ROOT,spec_ids={71},now=now)
 except ValueError as error:assert 'budget' in str(error)
 else:raise AssertionError('API budget guard ignored')
 assert client.pages==0
start=stamp-14*86400000
row=dict(name='In-memory-only',server={'id':1},gear=gear,startTime=stamp-1,hardModeLevel=15)
assert usable_row(row,start,stamp,10)
for changed in [dict(row,startTime=start-1),dict(row,startTime=stamp+1),dict(row,hardModeLevel=9),dict(row,gear=gear[:13]),dict(row,startTime=None)]:assert not usable_row(changed,start,stamp,10)
latest={};key,value=usable_row(row,start,stamp);retain_latest(latest,key,value)
retain_latest(latest,key,(stamp,{123},'EU'))
assert reduce_characters(latest,{270175,123})=={'123':1},'Latest loadout must replace old votes'
validate_snapshot(collected)
runtime=runtime_snapshot(collected)
assert runtime['specs']['71']['mythicplus']['items']==collected['specs']['71']['mythicplus']['items']
assert 'items' not in runtime['specs']['71']['mythicplus']['encounters'][0], 'Detailed audit maps must not consume WoW RAM'
bad=copy.deepcopy(collected);bad['specs']['71']['mythicplus']['encounters'][0]['sampleSize']=0
try:validate_snapshot(bad)
except ValueError:pass
else:raise AssertionError('False coverage accepted')
lua,R,_=load_addon(ROOT/'Nexus');R.db=lua.table_from({'mode':'mythicplus'})
R.WCLData=lua.eval(compact_lua(collected))
record,count=R.GetWCLEvidence(270175,71,'mythicplus');assert record and count==800
R.WCLData=lua.eval(compact_lua(partial));assert R.GetWCLEvidence(270175,71,'mythicplus') is None
R.WCLData=lua.table_from({'schema':1,'patch':'12.1'});assert R.GetWCLEvidence(270175,71,'mythicplus') is None
print('WCL: 18-encounter scope, pagination, 14-day/key filters, latest-character deduplication, coverage gates, legacy rejection, credential checks and quota guard PASS')

# Real interrupted/resumed collection: persist aggregate mode summaries only.
import tempfile,urllib.error
from wcl_public import read_checkpoint,request
from wcl_release import due,stage
tempbase=ROOT/'build/wcl-tests';tempbase.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(dir=tempbase) as directory,contextlib.redirect_stdout(io.StringIO()):
 root=Path(directory);(root/'data').mkdir();(root/'Nexus').mkdir()
 guide_bytes=(ROOT/'data/guide-snapshot.json').read_bytes();(root/'data/guide-snapshot.json').write_bytes(guide_bytes)
 class InterruptedClient(FixtureClient):
  def query(self,q,variables=None):
   if variables and variables.get('difficulty')==5:raise RuntimeError('Warcraft Logs HTTP 429')
   return super().query(q,variables)
 interrupted=InterruptedClient()
 try:collect_guides(interrupted,root,spec_ids={71},now=now,checkpoint=True)
 except RuntimeError:pass
 else:raise AssertionError('Interruption not simulated')
 cp=root/'build/wcl/checkpoint.json';saved=json.loads(cp.read_text(encoding='utf-8'))
 assert interrupted.pages==16 and set(saved['specs']['71'])=={'mythicplus'}
 assert 'Do not serialize' not in cp.read_text(encoding='utf-8')
 resumed_client=FixtureClient()
 resumed=collect_guides(resumed_client,root,spec_ids={71},now=now+dt.timedelta(hours=1),checkpoint=True)
 assert resumed_client.pages==20,'Finished dungeon pages must not be requested again'
 assert resumed['specs']['71']['mythicplus']==saved['specs']['71']['mythicplus']
 assert resumed['windowEnd']==saved['windowEnd'] and resumed['generatedAt']==saved['generatedAt'],'Do not relabel an older sample as newly collected'
 known={i['id'] for i in json.loads(guide_bytes)['items'].values()}
 assert read_checkpoint(cp,known,now+dt.timedelta(hours=49)) is None,'Expired windows must start fresh'
 assert read_checkpoint(cp,known|{987654321},now) is None,'Changed item universe cannot reuse incompatible counts'
 final=root/'build/wcl/wcl-snapshot.json';final.write_text(json.dumps(resumed),encoding='utf-8')
 try:stage(root,now)
 except ValueError:pass
 else:raise AssertionError('An incomplete checkpoint became a published snapshot')
 complete=copy.deepcopy(resumed)
 for sid in complete['specs']:complete['specs'][sid]=copy.deepcopy(resumed['specs']['71'])
 complete['collectionComplete']=True
 assert not due(complete,now+dt.timedelta(days=1),'schedule')
 assert due(complete,now+dt.timedelta(days=7),'schedule')
 assert due(complete,now,'workflow_dispatch')
 assert due(resumed,now,'schedule'),'Unfinished initial collection must retry automatically'
 final.write_text(json.dumps(complete),encoding='utf-8');stage(root,now)
 assert (root/'data/guide-snapshot.json').read_bytes()==guide_bytes,'Independent WCL publish must not edit authored guides'
 assert json.loads((root/'data/wcl-snapshot.json').read_text())['collectionComplete']
 assert 'balancedUsage' not in (root/'Nexus/WCLData.lua').read_text()

limited=urllib.error.HTTPError('https://example.invalid',429,'limited',{'Retry-After':'70'},None)
with patch('wcl_public.urllib.request.urlopen',side_effect=[limited,io.BytesIO(b'{"ok":true}')]),patch('wcl_public.time.sleep') as sleep:
 assert request('https://example.invalid',b'{}',{})=={'ok':True}
 assert [c.args[0] for c in sleep.call_args_list]==[60,10],'Respect Retry-After in bounded waits'
client=Client.__new__(Client);client.token='test';client.last_query=100
with patch('wcl_public.time.monotonic',side_effect=[100.2,101.1]),patch('wcl_public.time.sleep') as sleep,patch('wcl_public.request',return_value={'data':{'ok':True}}):
 assert client.query('{test}')=={'ok':True}
 assert .89<sleep.call_args.args[0]<.91,'Pace queries to avoid API bursts'
daily=(ROOT/'.github/workflows/data-refresh.yml').read_text(encoding='utf-8')
weekly=(ROOT/'.github/workflows/wcl-refresh.yml').read_text(encoding='utf-8')
assert 'wcl_public.py' not in daily and 'WCL_CLIENT_' not in daily,'WCL must not block the daily collection'
assert 'group: nexus-data-publish' in daily and 'group: nexus-wcl-api' in weekly
assert weekly.index('group: nexus-data-publish')>weekly.index('  publish:'),'Only short WCL publication shares the daily lock'
assert 'always()' in weekly and 'actions/cache/save' in weekly,'Failed collections must save completed summaries'
print('WCL automation: weekly cadence, automatic retry, private-data-free resume, fixed/expired windows, isolated publication, HTTP 429 backoff and pacing PASS')

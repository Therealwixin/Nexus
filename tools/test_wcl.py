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

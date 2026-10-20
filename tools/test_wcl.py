from wcl_public import aggregate
rows={'rankings':[{'name':'Do not retain','gear':[{'id':123},{'id':124},{'id':123}]} for _ in range(20)]}
a=aggregate(rows)
assert a['sampleSize']==20 and a['items'][0]['count']==20
assert 'name' not in str(a) and 'Do not retain' not in str(a)
try:aggregate({'rankings':[]})
except ValueError:pass
else:raise AssertionError('Empty sample accepted')
print('WCL: anonymous frequencies, deduplication and small-sample rejection PASS')

# Pasted surrounding whitespace must not invalidate otherwise valid credentials.
import base64
from unittest.mock import patch
from wcl_public import Client
with patch.dict('os.environ',{'WCL_CLIENT_ID':'  example-id\n','WCL_CLIENT_SECRET':' example-secret\r\n'}):
 with patch('wcl_public.request',return_value={'access_token':'test-token'}) as req:
  Client()
  headers=req.call_args.args[2]
  assert headers['Authorization']=='Basic '+base64.b64encode(b'example-id:example-secret').decode()
with patch.dict('os.environ',{'WCL_CLIENT_ID':'same','WCL_CLIENT_SECRET':'same'}):
 with patch('wcl_public.request') as req:
  try:Client()
  except ValueError:pass
  else:raise AssertionError('Duplicate credentials accepted')
  assert not req.called
print('WCL: credential whitespace normalization and duplicate-value guard PASS')

import json,copy
from pathlib import Path
from wcl_public import validate_snapshot
from test_lean import load_addon,ROOT
data=json.loads((ROOT/'data/wcl-snapshot.json').read_text(encoding='utf-8'));validate_snapshot(data)
bad=copy.deepcopy(data)
first=next(r for s in bad['specs'].values() for r in s.values());first['items']['1']=first['sampleSize']+1
try:validate_snapshot(bad)
except ValueError:pass
else:raise AssertionError('Count above sample size accepted')
lua,R,_=load_addon(ROOT/'Nexus');lua.globals().TEST.R=R
lua.execute('''
local R=TEST.R;R.db={mode="mythicplus"}
for spec,modes in pairs(R.WCLData.specs) do for mode,record in pairs(modes) do
 for id,count in pairs(record.items) do
  local evidence,n=R.GetWCLEvidence(tonumber(id),spec,mode)
  assert(evidence==record and n==count,"WCL evidence lookup/provenance mismatch")
 end
end end
R.WCLData.patch="99.0";assert(R.GetWCLEvidence(270175,261,"raid")==nil,"Stale patch WCL evidence shown")
''')
print('WCL: snapshot bounds, per-spec/context Lua lookup, patch mismatch PASS')
from wcl_public import collect_guides
import contextlib,io
class FixtureClient:
 def __init__(self,spent=1):self.spent=spent;self.pages=0
 def query(self,q,variables=None):
  if 'rateLimitData' in q:return {'rateLimitData':{'limitPerHour':720,'pointsSpentThisHour':self.spent}}
  assert ' ' not in variables['class'] and ' ' not in variables['spec']
  assert ('metric:hps' in q)==(variables['spec'] in {'Holy','Discipline','Restoration','Mistweaver','Preservation'})
  self.pages+=1
  return {'worldData':{'encounter':{'name':'Fixture encounter','characterRankings':rows}}}
with contextlib.redirect_stdout(io.StringIO()):
 client=FixtureClient();collected=collect_guides(client,ROOT)
 assert client.pages==80 and sum(len(s) for s in collected['specs'].values())==80
 client=FixtureClient(576)
 try:collect_guides(client,ROOT)
 except ValueError:pass
 else:raise AssertionError('80 percent quota limit ignored')
 assert client.pages==0
print('WCL: bounded 40-spec collection, healer metric, class names and quota stop PASS')

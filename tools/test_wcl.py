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

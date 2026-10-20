from wcl_public import aggregate
rows={'rankings':[{'name':'Do not retain','gear':[{'id':123},{'id':124},{'id':123}]} for _ in range(20)]}
a=aggregate(rows)
assert a['sampleSize']==20 and a['items'][0]['count']==20
assert 'name' not in str(a) and 'Do not retain' not in str(a)
try:aggregate({'rankings':[]})
except ValueError:pass
else:raise AssertionError('Empty sample accepted')
print('WCL: anonymous frequencies, deduplication and small-sample rejection PASS')

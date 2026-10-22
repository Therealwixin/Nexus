"""M+ only Meta: complete role cohorts, source provenance and failed refresh preservation."""
import copy,datetime as dt,json
from pathlib import Path
from unittest.mock import patch
from catalog import SPECS
from refresh_meta import murlok,role,validate_meta,collect_meta
from collect_gear import source_date
from murlok_live import verify_date
roles={r:[s for s in SPECS if role(s['id'])==r] for r in ['dps','healer','tank']}
def page(group,stamp='2026-10-21T10:00:00Z'):
 html='Patch 12.1 <time datetime="'+stamp+'"></time>'
 for i,spec in enumerate(roles[group]):html+=f'<a class="meta-item" href="/{spec["classSlug"]}/{spec["slug"]}/m+">{i+1} {spec["name"]} {4000-i}</a>'
 return html
meta={'schema':1,'patch':'12.1','modes':{'mythicplus':{'source':'Murlok.io','method':'murlok_rank','roles':{}}}}
for group in roles:
 entries,p=murlok(page(group),group)
 assert p=='12.1' and len(entries)==len(roles[group])
 meta['modes']['mythicplus']['roles'][group]={'entries':entries,'updatedAt':'2026-10-21T10:00:00Z','sourceURL':'https://murlok.io/meta/'+group}
validate_meta(meta)
bad=copy.deepcopy(meta);bad['modes']['raid']={}
try:validate_meta(bad)
except ValueError:pass
else:raise AssertionError('Retired raid Meta must not be staged')
requested=[]
def fetch(url,*args):
 requested.append(url)
 assert 'murlok.io/meta/' in url,'Retired sources must never be requested'
 return page(url.rsplit('/',1)[-1])
with patch('refresh_meta.fetch',fetch):fresh=collect_meta(meta,Path('.'),True)
assert len(requested)==3 and all(v['refreshStatus']=='ok' for v in fresh['modes']['mythicplus']['roles'].values())
original=copy.deepcopy(fresh)
with patch('refresh_meta.collect_pages',lambda cache:{}):failed=collect_meta(fresh,Path('.'))
assert fresh==original
for group,record in failed['modes']['mythicplus']['roles'].items():
 assert record['refreshStatus']=='unavailable' and record['entries']==fresh['modes']['mythicplus']['roles'][group]['entries']
 assert record['updatedAt']==fresh['modes']['mythicplus']['roles'][group]['updatedAt'] and record['retrievedAt']==fresh['modes']['mythicplus']['roles'][group]['retrievedAt']
with patch('refresh_meta.collect_pages',lambda cache:{g:page(g) for g in roles}):rendered=collect_meta(meta,Path('.'))
assert all(v['refreshStatus']=='ok' for v in rendered['modes']['mythicplus']['roles'].values())
newer=copy.deepcopy(meta)
for record in newer['modes']['mythicplus']['roles'].values():record['updatedAt']='2026-10-22T01:00:00Z'
with patch('refresh_meta.collect_pages',lambda cache:{g:page(g) for g in roles}):regressed=collect_meta(newer,Path('.'))
assert all(v['refreshStatus']=='unavailable' and v['updatedAt']=='2026-10-22T01:00:00Z' for v in regressed['modes']['mythicplus']['roles'].values())
now=dt.datetime(2026,10,21,17,tzinfo=dt.timezone.utc)
assert verify_date(page('dps'),now)=='2026-10-21T10:00:00Z'
for stamp in ['2026-10-16T10:00:00Z','2026-10-22T10:00:00Z']:
 try:verify_date(page('dps',stamp),now)
 except ValueError:pass
 else:raise AssertionError('Stale/future rendered page accepted')
assert source_date('<time datetime="2026-10-13T17:00:00-05:00"></time>',None)=='2026-10-13T22:00:00Z'
import murlok_live
assert not hasattr(murlok_live,'render_raid_page')
print('Meta PASS: M+ only, all 40 specs, three role-local cohorts, zero retired-source requests, rendered pages and original dates retained on failure/regression')

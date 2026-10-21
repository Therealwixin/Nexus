"""Parser contracts: role coverage, hero-build aggregation, dates and unsupported difficulty."""
import json
from catalog import SPECS
from refresh_meta import murlok,raid,role,validate_meta
from collect_gear import source_date
roles={r:[s for s in SPECS if role(s['id'])==r] for r in ['dps','healer','tank']}
meta={'schema':1,'patch':'12.1','modes':{'mythicplus':{'roles':{}},'raid':{'roles':{}}}}
for group,specs in roles.items():
 html='Patch 12.1 <time datetime="2026-10-16T10:00:00Z"></time>'
 for i,spec in enumerate(specs):html+=f'<a class="meta-item" href="/{spec["classSlug"]}/{spec["slug"]}/m+">{i+1} {spec["name"]} {4000-i}</a>'
 entries,patch=murlok(html,group)
 assert patch=='12.1' and len(entries)==len(specs)
 meta['modes']['mythicplus']['roles'][group]={'entries':entries,'updatedAt':source_date(html,None),'sourceURL':'https://murlok.io/meta/'+group}
raw={}
for group,key in [('dps','dps_list'),('healer','healing_tier_list'),('tank','tank_tier_list')]:
 raw[key]=[{'class':s['className'],'spec':s['name'],'count':count} for s in roles[group] for count in [4,6]]
data={'https://stats2.u.gg/wow/builds/example/raid-default-tierlist.json':{'data':{'raid':raw,'timestamp':'2026-10-19T03:00:00Z'}}}
html='Patch 12.1.5 <div class="diff-option"><span>Mythic</span></div> window.__SSR_DATA__ = '+json.dumps(data)+';'
result=raid(html,'12.1')
for group,record in result.items():
 assert record['sampleSize']==len(roles[group])*10
 assert all(row['count']==10 for row in record['entries'])
 record['sourceURL']='https://u.gg/wow/tier-list/'+group
meta['modes']['raid']['roles']=result;validate_meta(meta)
try:raid(html.replace('Mythic','Normal'),'12.1')
except ValueError:pass
else:raise AssertionError('Wrong raid difficulty accepted')
assert source_date('<time datetime="2026-10-13T17:00:00-05:00"></time>',None)=='2026-10-13T22:00:00Z'
try:source_date('No publication timestamp','2026-10-19T00:00:00Z')
except ValueError:pass
else:raise AssertionError('Retrieval time used as source date')
print('Meta: role coverage, hero-build aggregation, difficulty and authentic source timestamps: PASS')
from refresh_meta import collect_meta
from unittest.mock import patch
from pathlib import Path
import copy
original=copy.deepcopy(meta)
def partial_source(url,*args):
 if 'u.gg' in url:raise OSError('HTTP 403')
 group=url.rsplit('/',1)[-1]
 text='Patch 12.1 <time datetime="2026-10-16T10:00:00Z"></time>'
 for i,s in enumerate(roles[group]):text+=f'<a class="meta-item" href="/{s["classSlug"]}/{s["slug"]}/m+">{i+1} {s["name"]} {4000-i}</a>'
 return text
with patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page',return_value=None):updated=collect_meta(meta,Path('.'),True)
assert meta==original
assert all(r['refreshStatus']=='ok' and r.get('retrievedAt') for r in updated['modes']['mythicplus']['roles'].values())
for group,r in updated['modes']['raid']['roles'].items():
 assert r['refreshStatus']=='unavailable' and r['updatedAt']==meta['modes']['raid']['roles'][group]['updatedAt']
 assert r['entries']==meta['modes']['raid']['roles'][group]['entries']
 assert r.get('retrievedAt')==meta['modes']['raid']['roles'][group].get('retrievedAt')
print('Meta: blocked independent source retains original dates and values; other sources still refresh PASS')

# Production collection must use the hydrated page and refuse stale/regressed data.
from murlok_live import verify_date
import datetime as dt
now=dt.datetime(2026,10,21,17,tzinfo=dt.timezone.utc)
assert verify_date('<time datetime="2026-10-21T10:00:00Z"></time>',now)=='2026-10-21T10:00:00Z'
for stamp in ['2026-10-16T10:00:00Z','2026-10-22T10:00:00Z']:
 try:verify_date('<time datetime="'+stamp+'"></time>',now)
 except ValueError:pass
 else:raise AssertionError('Old SSR/future timestamp accepted as current rendered Meta')
with patch('refresh_meta.collect_pages',lambda cache:{}),patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page',return_value=None):
 failed=collect_meta(meta,Path('.'))
for r in failed['modes']['mythicplus']['roles'].values():
 assert r['refreshStatus']=='unavailable' and not r.get('retrievedAt')
with patch('refresh_meta.collect_pages',lambda cache:{g:partial_source('https://murlok.io/meta/'+g) for g in roles}),patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page',return_value=None):
 rendered=collect_meta(meta,Path('.'))
assert all(r['refreshStatus']=='ok' for r in rendered['modes']['mythicplus']['roles'].values())
newer=copy.deepcopy(meta)
for r in newer['modes']['mythicplus']['roles'].values():r['updatedAt']='2026-10-21T10:00:00Z'
with patch('refresh_meta.collect_pages',lambda cache:{g:partial_source('https://murlok.io/meta/'+g) for g in roles}),patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page',return_value=None):
 regressed=collect_meta(newer,Path('.'))
assert all(r['refreshStatus']=='unavailable' and r['updatedAt']=='2026-10-21T10:00:00Z' for r in regressed['modes']['mythicplus']['roles'].values())
print('Meta: hydrated-page requirement, 36h freshness guard, future/stale rejection and no source-date regression PASS')

# A normal rendered public U.GG page may replace a blocked initial response;
# parsing/difficulty validation still applies, and offline mode never launches it.
fresh_html=html.replace('2026-10-19T03:00:00Z',dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))
with patch('refresh_meta.collect_pages',lambda cache:{}),patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page',return_value=fresh_html) as browser:
 fallback=collect_meta(meta,Path('.'))
assert browser.call_count==1 and all(r['refreshStatus']=='ok' for r in fallback['modes']['raid']['roles'].values())
with patch('refresh_meta.fetch',partial_source),patch('refresh_meta.render_raid_page') as browser:
 collect_meta(meta,Path('.'),True)
assert browser.call_count==0
print('Raid fallback PASS: one public rendered-page attempt, same validation, no browser in offline tests')
from refresh_meta import verify_raid_dates
for stamp in ['2026-10-16T00:00:00Z','2026-10-22T00:00:00Z']:
 bad=copy.deepcopy(result)
 for record in bad.values():record['updatedAt']=stamp
 try:verify_raid_dates(bad,result,'2026-10-21T17:00:00Z')
 except ValueError:pass
 else:raise AssertionError('Stale, regressed or future raid data accepted')
print('Raid dates PASS: stale, regressed and future source snapshots rejected')

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

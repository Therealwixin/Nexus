"""Aggregate stat parsing, daily retention and native-stat/DR/UI regression tests."""
import copy,json
from pathlib import Path
from unittest.mock import patch
from test_lean import ROOT,load_addon
from murlok_stats import parse_stats,validate_profile
from parsers import Page
from stat_rules import parse_rules,validate_rules

data=json.loads((ROOT/'data/snapshot.json').read_text(encoding='utf-8'))
for modes in data['specs'].values():validate_profile(modes['mythicplus']['statProfile'],data['upgradeRules']['patch'])
validate_rules(data['statRules'],data['upgradeRules']['patch'])
html=(ROOT/'tests/fixtures/murlok-stats.html').read_text(encoding='utf-8')
parsed=parse_stats(Page(html))
assert parsed['minor']['values']['speed']['rating']==0 and parsed['secondary']['values']['mastery']['percent']==77
assert parsed['secondary']['priority']==['mastery','crit','haste','versatility']
try:parse_stats(Page(html.replace('33% Critical Strike','33% Unknown')))
except ValueError:pass
else:raise AssertionError('Unknown or incomplete stats must not become zero targets')
rules_text=(ROOT/'tests/fixtures/stat-dr-curves.inc').read_text(encoding='utf-8')
assert parse_rules(rules_text,'12.1')['curves']==data['statRules']['curves']
try:parse_rules(rules_text,'12.2')
except ValueError:pass
else:raise AssertionError('Wrong patch rules accepted')
bad=copy.deepcopy(data['statRules']);bad['curves']['secondary'][2][1]=999
try:validate_rules(bad,'12.1')
except ValueError:pass
else:raise AssertionError('Malformed or rising DR efficiency accepted')
lua,R,_=load_addon(ROOT/'Nexus');lua.globals().TEST.R=R
lua.execute((ROOT/'tests/stats.lua').read_text(encoding='utf-8'))
print('Stats data PASS: 40 dated M+ profiles, zero-rating minor stats, published priority and current-build DR provenance')

# A markup failure preserves the previous stat sample and its actual dates.
import collect_gear
spec=collect_gear.SPECS[0];modes=data['specs'][str(spec['id'])]
previous=copy.deepcopy(modes['mythicplus']);before=copy.deepcopy(previous)
missing=copy.deepcopy(previous);missing.pop('statProfile',None)
with patch.object(collect_gear,'fetch',return_value='<time datetime="2026-10-20T00:00:00Z"></time>'),patch.object(collect_gear,'parse_murlok',return_value=missing),patch.object(collect_gear,'guide_slots',return_value=(copy.deepcopy(modes['raid']['slots']),{})),patch.object(collect_gear,'consumables',return_value=copy.deepcopy(previous['consumables'])):
 result=collect_gear.collect(spec,Path('.'),'2026-10-20T19:00:00Z',False,previous)[1]['statProfile']
 assert result['refreshStatus']=='unavailable' and result['updatedAt']==before['statProfile']['updatedAt'] and result['retrievedAt']==before['statProfile']['retrievedAt']
 assert previous==before,'Failed stat refresh must not mutate the last verified source'
print('Stats refresh PASS: failed markup retains previous dated aggregate without player requests or false freshness')

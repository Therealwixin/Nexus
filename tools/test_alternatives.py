"""Overall-only UI and bounded diverse alternatives across all specs."""
from test_lean import load_addon,ROOT
lua,R,_=load_addon(ROOT/'Nexus');lua.globals().TEST.R=R
lua.execute('''
local R=TEST.R;R.db={mode="mythicplus",gearSource="raid",language="EN"};R.character={}
assert(R.GearSource()=="overall","Old saved source selector must not hide Overall")
local slots,four,dungeons,missing=0,0,0,0
for sid,guide in pairs(R.GuideData.specs) do
 R.SetViewSpec(sid)
 assert(guide.alternatives and next(guide.alternatives),"Missing authored alternatives")
 for _,slot in ipairs(R.SLOTS) do
  local main=R.GetGearTarget(slot.id);local options=R.GetGearAlternatives(slot.id);local seen={};local dungeon=false
  assert(#options<=4,"More than four alternatives")
  for _,item in ipairs(options) do
   assert(not seen[item.id],"Duplicate alternative");seen[item.id]=true
   assert(not main or item.id~=main.id and item.id~=main.acquisitionItemID,"BiS source piece is not a distinct alternative")
   if item.acquisition=="dungeon" then dungeon=true end
  end
  local eligible=false
  for _,key in ipairs(guide.sourceLists.mythicplus[slot.id] or {}) do
   local raw=R.GuideData.items[key];local id=raw.acquisitionItemID or raw.id
   if not main or id~=main.id and id~=main.acquisitionItemID then eligible=true end
  end
  assert(not eligible or dungeon,"Available dungeon alternative was crowded out by raid options")
  if main then slots=slots+1;if #options==4 then four=four+1 end;if dungeon then dungeons=dungeons+1 else missing=missing+1 end end
 end
end
print("Alternatives: "..slots.." occupied slots; "..four.." have four options; "..dungeons.." include dungeon options; "..missing.." honestly have no verified extra dungeon option")
''')
print('Alternatives: maximum four, no duplicate/BiS options, reserved dungeon option, saved-setting migration PASS')
from alternative_guides import parse,merge
import copy,json
html='<h1>Gear 12.1.5</h1><time datetime="2026-10-20T00:00:00Z"></time><div class="image_block_content" id="bis_0_1">'
for i,slot in enumerate(['Helm','Neck','Shoulders','Back','Chest','Wrist','Hands','Waist','Legs','Feet','Ring','Ring','Trinket','Trinket','Main Hand','Off Hand']):
 html+=f'<div class="bis_item"><span class="q4" data-iv-tooltip="wow/item/{100+i}?original={200+i}&amp;bonus=12854:8790"><img src="https://example.invalid/123.webp" alt="Tier Icon"></span><span class="bis_item_slot">{slot}</span><span class="bis_item_drop"><a href="/wow/murder-row-dungeon-guide">Murder Row</a></span></div>'
html+='</div>'
parsed=parse(html,'https://example.invalid/guide','12.1')
assert parsed['slots']['1'][0]['id']==200 and parsed['slots']['1'][0]['catalystTargetID']==100 and parsed['slots']['1'][0]['acquisition']=='dungeon'
assert parsed['slots']['1'][0]['name']!='Tier'
assert parsed['slots']['1'][0]['previewBonusIDs']==[12854,8790], 'Published variant bonuses must survive daily collection'
old=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'));fresh=copy.deepcopy(old)
for g in fresh['specs'].values():g.pop('alternatives',None)
merge(fresh,{},old)
assert fresh['specs']['261']['alternatives']==old['specs']['261']['alternatives'] and fresh['specs']['261']['alternativeGuideRefreshStatus']=='unavailable'
print('Alternative guides: original source-item identity and failed-source preservation PASS')

from item_variants import effect_catalog,apply_effects
bonus_text='// Item bonuses, wow build 12.1.5.70448\n'
bonus_text+='\n'.join('{ %d, %d, 49, 1, 0, 0, 0, 0 },'%(n,n) for n in range(1000,2001))
bonus_text+='\n{1,13847,4,1,0,0,0,0},{2,13847,23,2,0,0,0,0},{3,14049,23,3,0,0,0,0},{4,9999,23,4,0,0,0,0},{5,9999,49,5,0,0,0,0}'
safe,provenance=effect_catalog(bonus_text,'12.1')
assert safe=={13847,14049},'Mixed scaling/effect lists must never override maximum ilvl'
try:effect_catalog(bonus_text,'12.2')
except ValueError:pass
else:raise AssertionError('Wrong build must fail closed')
g={'items':{'source':{'id':1,'previewBonusIDs':[13847,12854]},'tier':{'id':2,'acquisitionItemID':1},'other':{'id':3},'conflict':{'id':4,'previewBonusIDs':[13847]},'conflict2':{'id':4,'previewBonusIDs':[14049]},'unknown':{'id':5,'acquisitionItemID':4},'craft':{'id':6,'crafted':True,'previewBonusIDs':[13847]},'plaincraft':{'id':6,'crafted':True}}}
apply_effects(g,safe,provenance)
assert g['items']['tier']['previewEffectBonusIDs']==[13847]
assert not g['items']['other'].get('previewEffectBonusIDs') and not g['items']['unknown'].get('previewEffectBonusIDs')
assert not g['items']['plaincraft'].get('previewEffectBonusIDs'),'Optional crafted effects must not transfer between recommendations'
assert g['variantEvidence']['build']=='12.1.5.70448'
print('Daily effect classification: exact source identity, no scaling leakage, ambiguous variants rejected PASS')

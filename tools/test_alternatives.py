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
 html+=f'<div class="bis_item"><span class="q4" data-iv-tooltip="wow/item/{100+i}?original={200+i}"><img src="https://example.invalid/123.webp" alt="Tier Icon"></span><span class="bis_item_slot">{slot}</span><span class="bis_item_drop"><a href="/wow/murder-row-dungeon-guide">Murder Row</a></span></div>'
html+='</div>'
parsed=parse(html,'https://example.invalid/guide','12.1')
assert parsed['slots']['1'][0]['id']==200 and parsed['slots']['1'][0]['catalystTargetID']==100 and parsed['slots']['1'][0]['acquisition']=='dungeon'
assert parsed['slots']['1'][0]['name']!='Tier'
old=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'));fresh=copy.deepcopy(old)
for g in fresh['specs'].values():g.pop('alternatives',None)
merge(fresh,{},old)
assert fresh['specs']['261']['alternatives']==old['specs']['261']['alternatives'] and fresh['specs']['261']['alternativeGuideRefreshStatus']=='unavailable'
print('Alternative guides: original source-item identity and failed-source preservation PASS')

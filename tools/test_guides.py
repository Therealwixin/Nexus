"""Guide semantics, acquisition evidence and numeric Lua slot roundtrip."""
import copy,json
from wowhead_sets import ROOT,row_slots,metadata,source_kind,validate_guides
from refresh_gear import compact_lua
from test_lean import load_addon

raw='WH.Gatherer.addData(3, 1, '+json.dumps({'1':{'icon':'one','name_enus':'One'}})+'); WH.Gatherer.addData(3, 10, '+json.dumps({'2':{'icon':'two','name_enus':'Two','jsonequip':{'slotbak':11}}})+');'
assert set(metadata(raw))=={1,2}
table='[tr][td]Slot[/td][td]Item[/td][td]Enchant[/td][td]Source[/td][/tr][tr][td]Hands[/td][td][item=2 original-item=1][/td][td]Enchant[/td][td]Murder Row[/td][/tr]'
item=row_slots(table,metadata(raw))['10'][0]
assert item['acquisition']=='dungeon' and item['acquisitionItemID']==1 and item['catalyst']
assert source_kind('Crafting')=='crafted' and source_kind('Unknown boss')=='unknown'
data=json.loads((ROOT/'data/guide-snapshot.json').read_text(encoding='utf-8'));validate_guides(data)
bad=copy.deepcopy(data)
key=next(k for k,i in bad['items'].items() if i.get('acquisition')=='dungeon')
bad['items'][key]['crafted']=True
try:validate_guides(bad)
except ValueError:pass
else:raise AssertionError('Crafted item accepted in source-only list')
lua,R,_=load_addon(ROOT/'Nexus');lua.globals().TEST.R=R
lua.execute('''
local R=TEST.R;R.db={mode="mythicplus",gearSource="overall",language="EN"}
local checked=0
for spec,guide in pairs(R.GuideData.specs) do
 R.SetViewSpec(spec)
 for _,scope in ipairs({"overall","raid","mythicplus"}) do
  R.db.gearSource=scope;local count=0
  for _,slot in ipairs(R.SLOTS) do
   local target=R.GetGearTarget(slot.id)
   if target then count=count+1;assert(target.name and target.icon,"Missing display metadata") end
   for _,item in ipairs(R.GetGearCandidates(slot.id)) do
    if scope~="overall" then assert(item.acquisition==(scope=="raid" and "raid" or "dungeon") and not item.crafted) end
    if item.catalyst then assert(item.journalItemID==item.acquisitionItemID and item.id~=item.journalItemID) end
   end
  end
  assert(count>0,"Numeric Lua source slot keys lost")
  if scope=="overall" then assert(count>=14,"Authored set incomplete in game") end
  if scope~="overall" then for _,pair in ipairs({{11,12},{13,14}}) do
   local a,b=R.GetGearTarget(pair[1]),R.GetGearTarget(pair[2]);assert(not a or not b or a.id~=b.id,"Duplicate ring/trinket selected")
  end end
 end
 checked=checked+1
end
assert(checked==40)
local A=R.DungeonAlerts;local shown={};local reads=0
R.SpecID=function()return 261 end;R.ScanEquipment=function()end;R.RequestItem=function()end
A.Context=function()return {gameMapID=123,name="Fixture dungeon"}end
A.SeasonalMap=function()return 1,true end
A.ReadLoot=function()reads=reads+1;return {[100]=true},false end
A.Show=function(_,entries)shown=entries end
R.GetGearCandidates=function(slot)if slot==10 then return {{id=200,acquisitionItemID=100,catalyst=true}} end;return {} end
R.Ownership=function()return "MISSING" end
A.visit=nil;A.pending=nil;A:CheckVisit()
assert(#shown==1 and shown[1].item.id==200 and reads==1,"Dungeon warning did not match original Catalyst drop")
R.Ownership=function(id)return id==100 and "EQUIPPED" or "MISSING" end
A.visit.notified={};shown={};A:CheckVisit();assert(#shown==0,"Already-owned Catalyst base should not be announced missing")
''')
print('Guides: 40-spec Lua rendering data, source restrictions, original Catalyst items, header variations and metadata batches PASS')

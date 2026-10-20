"""Retain published effect bonuses without importing their ilvl/upgrade modifiers."""
import re
from collect_gear import fetch

BONUS_URL='https://raw.githubusercontent.com/simulationcraft/simc/midnight/engine/dbc/generated/item_bonus.inc'

def effect_catalog(text,patch):
 build=re.search(r'wow build (\d+\.\d+\.\d+\.\d+)',text)
 if not build or not build[1].startswith(patch+'.'):raise ValueError('Item bonus build does not match guide patch')
 types={}
 for match in re.finditer(r'\{\s*\d+,\s*(\d+),\s*(\d+),',text):
  types.setdefault(int(match[1]),set()).add(int(match[2]))
 if len(types)<1000:raise ValueError('Incomplete item bonus table')
 # ItemEffect (23), optionally its ItemNameDescription (4). Never retain a
 # mixed list that also changes scaling, upgrade rank, stats or crafting quality.
 safe={id for id,kinds in types.items() if 23 in kinds and kinds<={4,23}}
 return safe,dict(sourceURL=BONUS_URL,build=build[1])

def load_catalog(cache,patch,offline=False):
 return effect_catalog(fetch(BONUS_URL,cache,'item-bonus.inc',offline),patch)

def apply_effects(guides,safe,provenance):
 variants={}
 for row in guides['items'].values():
  row.pop('previewEffectBonusIDs',None)
  effects=tuple(sorted(set(row.get('previewBonusIDs',[]))&safe))
  if effects:
   row['previewEffectBonusIDs']=list(effects)
   if not row.get('crafted') and row.get('acquisition')!='crafted':
    variants.setdefault(row.get('acquisitionItemID',row['id']),set()).add(effects)
 for row in guides['items'].values():
  options=variants.get(row.get('acquisitionItemID',row['id']),set())
  if not row.get('crafted') and row.get('acquisition')!='crafted' and 'previewEffectBonusIDs' not in row and len(options)==1:
   row['previewEffectBonusIDs']=list(next(iter(options)))
 guides['variantEvidence']=provenance

"""Report optional source availability honestly; never turn a bot check into gear data."""
import datetime as dt,json,urllib.request,urllib.error
from pathlib import Path
URLS={'Raider.IO':'https://raider.io/api/v1/mythic-plus/affixes?region=eu&locale=en','Archon':'https://www.archon.gg/wow/builds/subtlety/rogue/mythic-plus/gear-and-tier-set/high-keys/all-dungeons/this-week'}

def collect():
 now=dt.datetime.now(dt.timezone.utc).isoformat();out={'generatedAt':now,'sources':{}}
 for name,url in URLS.items():
  record={'checkedAt':now,'url':url,'status':'unavailable','purpose':'Seasonal affixes; not gear recommendations' if name=='Raider.IO' else 'Aggregate gear feed not integrated'}
  try:
   request=urllib.request.Request(url,headers={'User-Agent':'Nexus-addon-data/0.3 (+offline WoW gear snapshots)'})
   with urllib.request.urlopen(request,timeout=20) as response:text=response.read(3000000).decode('utf-8')
   if name=='Raider.IO':
    data=json.loads(text);affixes=data.get('affix_details')
    if not isinstance(affixes,list) or not affixes:raise ValueError('Missing affix schema')
    record.update(status='available',affixes=[{'id':a['id'],'name':a['name']} for a in affixes])
   else:
    record.update(status='blocked' if 'not a bot' in text.lower() or 'verify you are human' in text.lower() else 'not_integrated')
  except (ValueError,OSError,KeyError) as error:
   record['status']='blocked' if getattr(error,'code',None) in {401,403,429} else 'unavailable'
  out['sources'][name]=record
 return out

def write(output):
 from refresh_gear import compact_lua
 data=collect();output.mkdir(exist_ok=True,parents=True)
 (output/'source-status.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 (output/'SourceStatus.lua').write_text('local _,R=...\nR.SourceStatus='+compact_lua(data)+'\n',encoding='utf-8')
 print('Optional sources:',{k:v['status'] for k,v in data['sources'].items()})
if __name__=='__main__':write(Path(__file__).resolve().parents[1]/'build/candidate')

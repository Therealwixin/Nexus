"""Extract small current-build DR curves from primary SimulationCraft DBC data."""
import datetime as dt,re,urllib.request
SOURCE='https://raw.githubusercontent.com/simulationcraft/simc/midnight/engine/dbc/generated/item_scaling.inc'
ROW=re.compile(r'\{\s*(21024|21025),\s*\d+,\s*([0-9.]+)f,\s*([0-9.]+)f,')

def parse_rules(text,patch):
 build=re.search(r'wow build (\d+\.\d+\.\d+\.\d+)',text)
 if not build or not build[1].startswith(patch+'.'):raise ValueError('DR data build mismatch')
 curves={name:[[float(m[2]),float(m[3])] for m in ROW.finditer(text) if m[1]==id] for name,id in [('secondary','21024'),('minor','21025')]}
 rules=dict(patch=patch,build=build[1],sourceURL=SOURCE,curves=curves)
 validate_rules(rules,patch)
 return rules

def validate_rules(rules,patch):
 if rules.get('patch')!=patch or not rules.get('build','').startswith(patch+'.') or rules.get('sourceURL')!=SOURCE or set(rules.get('curves',{}))!={'secondary','minor'}:raise ValueError('Invalid DR rule provenance')
 for points in rules['curves'].values():
  if len(points)<4 or points[0]!=[0,0]:raise ValueError('Incomplete DR curve')
  slopes=[]
  for a,b in zip(points,points[1:]):
   if b[0]<=a[0] or b[1]<=a[1]:raise ValueError('Invalid DR points')
   slopes.append((b[1]-a[1])/(b[0]-a[0]))
  if abs(slopes[0]-1)>.001 or any(not 0<s<=1.001 for s in slopes) or any(b>a+.001 for a,b in zip(slopes,slopes[1:])):raise ValueError('Unexpected DR curve')

def load_rules(cache,patch,offline=False):
 file=cache/'stat-dr-curves.inc'
 if offline:return parse_rules(file.read_text(encoding='utf-8'),patch)
 lines=[];size=0
 request=urllib.request.Request(SOURCE,headers={'User-Agent':'Nexus-addon-data/0.6'})
 with urllib.request.urlopen(request,timeout=30) as response:
  for raw in response:
   size+=len(raw)
   if size>8_000_000:raise ValueError('DR source exceeded read budget')
   line=raw.decode('utf-8')
   if 'wow build' in line or ROW.search(line):lines.append(line)
   # CurvePoint rows are sorted by curve ID. Stop after both requested curves.
   match=re.match(r'\s*\{\s*(\d+),',line)
   if match and int(match[1])>21025:break
 text=''.join(lines);rules=parse_rules(text,patch)
 file.write_text(text,encoding='utf-8')
 rules.update(retrievedAt=dt.datetime.now(dt.timezone.utc).isoformat(),refreshStatus='ok')
 return rules

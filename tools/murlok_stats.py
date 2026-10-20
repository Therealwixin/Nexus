"""Published aggregate stat bars only; never fetch individual player profiles."""
import datetime as dt,math,re

LABELS={'Critical Strike':'crit','Haste':'haste','Mastery':'mastery','Versatility':'versatility','Avoidance':'avoidance','Leech':'leech','Speed':'speed'}

def validate_profile(profile,patch):
 if profile.get('patch')!=patch or not 20<=profile.get('sampleSize',0)<=100:raise ValueError('Invalid stat sample provenance')
 if not profile.get('sourceURL','').startswith('https://murlok.io/'):raise ValueError('Invalid stat source')
 for field in ['updatedAt','retrievedAt']:
  if not dt.datetime.fromisoformat(profile[field].replace('Z','+00:00')).tzinfo:raise ValueError('Missing stat timezone')
 for group,expected in [('secondary',{'crit','haste','mastery','versatility'}),('minor',{'avoidance','leech','speed'})]:
  record=profile[group]
  if set(record['values'])!=expected or len(record['priority'])!=len(expected) or set(record['priority'])!=expected:raise ValueError('Incomplete stat profile')
  for value in record['values'].values():
   if not isinstance(value['rating'],int) or not 0<=value['rating']<10_000_000 or not isinstance(value['percent'],(int,float)) or not math.isfinite(value['percent']) or not 0<=value['percent']<10_000:raise ValueError('Invalid aggregate stat value')

def parse_stats(page):
 result={}
 for block in page.root.all('div'):
  if 'guide-stats' not in block.attrs.get('class','').split():continue
  heading=block.first('h3');group={'Optimal Secondary Stats':'secondary','Additional Minor Stats':'minor'}.get(heading.text() if heading else '')
  if not group:continue
  values={}
  for row in block.all('li'):
   if 'guide-stats-chart-item' not in row.attrs.get('class','').split():continue
   spans=list(row.all('span'))
   if len(spans)<2:raise ValueError('Incomplete stat bar')
   match=re.fullmatch(r'([0-9]+(?:\.[0-9]+)?)% (.+)',spans[0].text())
   rating=re.fullmatch(r'\+([0-9, ]+)',spans[1].text())
   if not match or match[2] not in LABELS or not rating:raise ValueError('Unknown stat bar')
   key=LABELS[match[2]]
   if key in values:raise ValueError('Duplicate stat bar')
   values[key]={'rating':int(rating[1].replace(',','').replace(' ','')),'percent':float(match[1])}
  order=block.first('ol');priority=[LABELS.get(row.text()) for row in order.all('li')] if order else []
  expected={'crit','haste','mastery','versatility'} if group=='secondary' else {'avoidance','leech','speed'}
  if set(values)!=expected or set(priority)!=expected or len(priority)!=len(expected):raise ValueError('Incomplete stat profile')
  result[group]={'values':values,'priority':priority}
 if set(result)!={'secondary','minor'}:raise ValueError('Missing aggregate stats')
 return result

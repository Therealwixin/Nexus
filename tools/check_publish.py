"""Check configuration without printing credential values."""
import os,re
project=os.environ.get('PROJECT_ID','')
if not re.fullmatch(r'[1-9]\d*',project):raise SystemExit('Set CURSEFORGE_PROJECT_ID to the numeric project ID.')
if not os.environ.get('CF_API_TOKEN'):raise SystemExit('Missing repository secret CF_API_TOKEN.')
print('Publishing configuration present. Token value is not logged.')

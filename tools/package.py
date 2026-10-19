"""Create the installable ZIP and verify paths/TOC without external services."""
from pathlib import Path
import argparse,re,zipfile
ROOT=Path(__file__).resolve().parents[1]
def package(output):
 addon=ROOT/'Nexus';toc=(addon/'Nexus.toc').read_text(encoding='utf-8')
 version=re.search(r'^## Version: (.+)$',toc,re.M).group(1)
 if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?',version):raise ValueError('Unsafe version')
 for line in toc.splitlines():
  if line and not line.startswith('#'):
   target=(addon/line).resolve()
   if not target.is_relative_to(addon.resolve()) or not target.is_file():raise ValueError('Invalid TOC path')
 output.mkdir(parents=True,exist_ok=True)
 destination=output/f'Nexus-{version}.zip'
 with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(addon.rglob('*')):
   if p.is_file():z.write(p,p.relative_to(ROOT).as_posix())
 with zipfile.ZipFile(destination) as z:
  if z.testzip():raise ValueError('Corrupt ZIP')
  if 'Nexus/Nexus.toc' not in z.namelist():raise ValueError('Wrong addon root')
 print(destination)
 return destination
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=ROOT/'dist');args=p.parse_args();package(args.output)

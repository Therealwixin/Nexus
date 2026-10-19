from pathlib import Path
import re,sys
ROOT=Path(__file__).resolve().parents[1]
def set_version(version):
 if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?',version):raise ValueError('Invalid Nexus version')
 path=ROOT/'Nexus/Nexus.toc'
 text,count=re.subn(r'(?m)^## Version: .*$',lambda m:'## Version: '+version,path.read_text(encoding='utf-8'))
 if count!=1:raise ValueError('Expected one TOC version')
 path.write_text(text,encoding='utf-8')
if __name__=='__main__':set_version(sys.argv[1])

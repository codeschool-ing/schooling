import importlib, inspect, sys
MODS = ["json","pathlib","collections","datetime","string","textwrap","re","os","shutil","subprocess","logging","argparse","csv","sqlite3","urllib.request","http.client","email.message","unittest","itertools","functools","random","statistics","decimal","fractions","zipfile","tarfile","tempfile","glob","fnmatch","difflib","heapq","bisect","queue","threading","enum","dataclasses","typing","contextlib","io","base64","hashlib","hmac","secrets","uuid","time","calendar","locale","gettext","shlex","pprint"]
seen=set(); out=[]
def add(doc):
    if not doc: return
    doc=inspect.cleandoc(doc)
    if doc in seen: return
    seen.add(doc); out.append(doc)
for m in MODS:
    mod=importlib.import_module(m)
    add(mod.__doc__)
    for name in sorted(vars(mod)):
        if name.startswith('_'): continue
        obj=getattr(mod,name)
        if getattr(obj,'__module__',None)!=mod.__name__: continue
        add(getattr(obj,'__doc__',None))
        if inspect.isclass(obj):
            for an in sorted(vars(obj)):
                if an.startswith('_'): continue
                add(getattr(vars(obj)[an],'__doc__',None) if not isinstance(vars(obj)[an],(int,str,float)) else None)
sys.stdout.write("\n\n".join(out)+"\n")

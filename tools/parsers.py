#!/usr/bin/env python3
"""Build a local Lua snapshot. Only this external tool accesses websites.

Murlok -> observed equipment frequencies and up to fifty concrete player profiles.
Raider.IO -> dated player rating/gear snapshots, kept separately from Murlok.
Wowhead -> item metadata and explicitly identified guide recommendations.
Archon/WCL -> optional normalized, authorized JSON feeds; never fabricated.
Uses the Python standard library only. Source failures retain last good data.
"""
from __future__ import annotations
import argparse
import copy
import datetime as dt
from html.parser import HTMLParser
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from urllib.parse import urlencode, urlsplit, urlunsplit, quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
GEAR_SLOTS = {"Head":[1], "Neck":[2], "Shoulders":[3], "Back":[15], "Chest":[5],
              "Wrist":[9], "Hands":[10], "Waist":[6], "Legs":[7], "Feet":[8],
              "Rings":[11,12], "Trinkets":[13,14], "Main Hand":[16], "Off Hand":[17]}
RIO_SLOTS = {"head":1,"neck":2,"shoulder":3,"back":15,"chest":5,"wrist":9,"hands":10,
             "waist":6,"legs":7,"feet":8,"finger1":11,"finger2":12,"trinket1":13,
             "trinket2":14,"mainhand":16,"offhand":17}
MURLOK_URL = "https://murlok.io/warlock/demonology/m%2B"
WOWHEAD_URL = "https://www.wowhead.com/guide/classes/warlock/demonology/bis-gear"
WOWHEAD_CONSUMABLES_URL = "https://www.wowhead.com/guide/classes/warlock/demonology/enchants-gems-pve-dps"

class Node:
    def __init__(self, tag="root", attrs=(), parent=None):
        self.tag, self.attrs, self.parent, self.children = tag, dict(attrs), parent, []
    def all(self, tag=None):
        for child in self.children:
            if isinstance(child, Node):
                if tag is None or child.tag == tag:
                    yield child
                yield from child.all(tag)
    def text(self):
        return " ".join(" ".join(c.text() if isinstance(c, Node) else c for c in self.children).split())
    def first(self, tag):
        return next(self.all(tag), None)

class Page(HTMLParser):
    VOID = {"area","base","br","col","embed","hr","img","input","link","meta","param","source","track","wbr"}
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.feed(text)
    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs, self.stack[-1])
        self.stack[-1].children.append(node)
        if tag not in self.VOID:
            self.stack.append(node)
    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in self.VOID:
            self.handle_endtag(tag)
    def handle_endtag(self, tag):
        for index in range(len(self.stack)-1, 0, -1):
            if self.stack[index].tag == tag:
                self.stack = self.stack[:index]
                break
    def handle_data(self, text):
        self.stack[-1].children.append(text)
    def section(self, identifier):
        return next((n for n in self.root.all() if n.attrs.get("id") == identifier), None)

def item_from_anchor(anchor, count=False):
    match = re.search(r"item=(\d+)", anchor.attrs.get("href", ""))
    heading = anchor.first("h4") or anchor.first("h3")
    if not match or not heading:
        return None
    item = {"id":int(match.group(1)), "name":heading.text(), "source":"Murlok.io"}
    image = anchor.first("img")
    icon = image and re.search(r"/icons/\d+/(\d+)\.", image.attrs.get("src", ""))
    if icon:
        item["icon"] = int(icon.group(1))
    if count:
        values = [n.text() for n in anchor.all("li") if n.text().isdigit()]
        if not values:
            raise ValueError("Murlok frequency missing; refusing a misleading snapshot")
        item["count"] = int(values[-1])
    labels = [n.text() for n in anchor.all("li")]
    if "Craft" in labels:
        item["crafted"] = True
    return item

def groups(page, section_id, counts=True):
    section = page.section(section_id)
    if not section:
        raise ValueError("Missing Murlok section " + section_id)
    result = {}
    for heading in section.all("h3"):
        container = heading.parent
        if container.tag != "div" or not any(n.tag == "ol" for n in container.children if isinstance(n, Node)):
            continue
        items = [item_from_anchor(a, counts) for a in container.all("a")]
        result[heading.text()] = [x for x in items if x]
    return result

def parse_murlok(text, timestamp):
    page = Page(text)
    patch_match = re.search(r"Patch (\d+\.\d+)", text)
    if not patch_match:
        raise ValueError("Murlok patch is not identifiable")
    top = page.section("top-ratings")
    if not top:
        raise ValueError("Murlok ranking sample missing")
    anchors = [a for a in top.all("a") if "/character/" in a.attrs.get("href", "")]
    sample_size = len(anchors)
    if not 20 <= sample_size <= 100:
        raise ValueError("Unexpected Murlok sample size")
    slots = {}
    for heading, candidates in groups(page, "gear").items():
        candidates = [x for x in candidates if x["id"] > 0]
        if heading not in GEAR_SLOTS or not candidates:
            continue
        for index, slot in enumerate(GEAR_SLOTS[heading]):
            # Rings/trinkets share one source population. Pick two distinct items.
            preferred = min(index, len(candidates)-1)
            slots[str(slot)] = [dict(candidates[preferred])] + [dict(x) for j,x in enumerate(candidates) if j != preferred]
    if len(slots) < 14:
        raise ValueError("Too few gear slots; retain the previous good snapshot")
    players = []
    for anchor in anchors[:50]:
        href = anchor.attrs["href"]
        region, realm, name = href.split("/")[2:5]
        h3s = [n.text() for n in anchor.all("div") if "h3" in n.attrs.get("class", "").split()]
        if len(h3s) < 3:
            raise ValueError("Unexpected Murlok player structure")
        ilvl = re.search(r"(\d+) ilvl", anchor.text())
        players.append({"name":h3s[1],"slug":name,"realm":realm,"region":region,
                        "score":int(h3s[-1]),"ilvl":int(ilvl.group(1)) if ilvl else None,
                        "url":"https://murlok.io"+href,"source":"Murlok.io","updatedAt":timestamp,"gear":{}})
    enchants = {}
    for heading, candidates in groups(page, "enchantments").items():
        if heading not in GEAR_SLOTS or not candidates:
            continue
        for slot in GEAR_SLOTS[heading]:
            # Some Murlok enchant links intentionally have item=0. Do not invent IDs.
            enchants[str(slot)] = dict(candidates[0])
    gems = [dict(x,group="gems",**({"uniqueGem":"diamond"} if "diamond" in x.get("name","").lower() else {})) for values in groups(page,"gems").values() for x in values if x["id"] > 0]
    return {"patch":patch_match.group(1),"updatedAt":timestamp,"sourceURL":MURLOK_URL,
            "sampleSize":sample_size,"slots":slots,"players":players,"enchants":enchants,
            "gems":gems,"consumables":[]}

def parse_player(text, timestamp):
    slots = {}
    for heading, values in groups(Page(text), "gear", False).items():
        for index, slot in enumerate(GEAR_SLOTS.get(heading, [])):
            if index < len(values) and values[index]["id"] > 0:
                item = dict(values[index]); item["updatedAt"] = timestamp
                slots[str(slot)] = item
    if len(slots) < 14:
        raise ValueError("Player loadout is incomplete")
    return slots

def wowhead_metadata(text):
    marker = re.search(r"WH\.Gatherer\.addData\(3,\s*1,\s*", text)
    if not marker:
        raise ValueError("Wowhead item metadata missing")
    data, _ = json.JSONDecoder().raw_decode(text[marker.end():])
    return {k:{"name":v.get("name_enus"),"icon":"Interface\\Icons\\"+v["icon"],"quality":v.get("quality")}
            for k,v in data.items() if v.get("icon")}

def wowhead_consumables(text, timestamp):
    metadata=wowhead_metadata(text)
    body=None
    for match in re.finditer(r'WH\.markup\.printHtml\(\s*(?=")',text):
        value,length=json.JSONDecoder().raw_decode(text[match.end():])
        if "guide-body" in text[match.end()+length:match.end()+length+30]:
            body=value
            break
    if not body:
        raise ValueError("Wowhead guide content missing")
    rows=re.findall(r'\[tr\]\[td[^\]]*\](Flask|Combat Potion|Health Potion|Weapon Buff|Augment Rune|Food)\[/td\]\[td[^\]]*\]\[item=(\d+)\]',body)
    if len(rows)!=6:
        raise ValueError("Unexpected consumable cheat sheet; refuse a partial import")
    return [dict(metadata[item_id],id=int(item_id),category=category,source="Wowhead",
                 url=WOWHEAD_CONSUMABLES_URL,updatedAt=timestamp) for category,item_id in rows]

def fetch(url, cache, name, offline=False):
    file = cache/name
    if offline:
        return file.read_text(encoding="utf-8")
    parts = urlsplit(url)
    url = urlunsplit((parts.scheme, parts.netloc, quote(parts.path, safe="/%:+"), parts.query, parts.fragment))
    request = Request(url,headers={"User-Agent":"Nexus-addon-data/0.3 (+offline WoW gear snapshots)"})
    with urlopen(request,timeout=20) as response:
        text = response.read(3_000_001).decode("utf-8")
    if len(text.encode("utf-8")) > 3_000_000:
        raise ValueError("Source exceeded size limit")
    file.write_text(text,encoding="utf-8")
    return text

def lua(value, depth=0):
    if value is None:
        return "nil"
    if isinstance(value,bool):
        return "true" if value else "false"
    if isinstance(value,(int,float)):
        return repr(value)
    if isinstance(value,str):
        escaped=value.replace("\\","\\\\").replace('"','\\"')
        escaped="".join("\\%03d" % ord(c) if ord(c)<32 else c for c in escaped)
        return '"'+escaped+'"'
    if isinstance(value,list):
        value = {i+1:x for i,x in enumerate(value)}
    if isinstance(value,dict):
        indent="    "*depth
        pieces=[]
        for key,item in value.items():
            if isinstance(key,str) and key.isdigit():
                key=int(key)
            pieces.append("    "*(depth+1)+"["+lua(key)+"] = "+lua(item,depth+1)+",")
        return "{\n"+"\n".join(pieces)+"\n"+indent+"}"
    raise TypeError(type(value))

def stable_content(snapshot):
    def clean(value):
        if isinstance(value,dict):
            return {k:clean(v) for k,v in value.items() if k not in {"generatedAt","updatedAt","retrievedAt","contentHash"}}
        if isinstance(value,list):
            return [clean(x) for x in value]
        return value
    return json.dumps(clean(snapshot),ensure_ascii=False,sort_keys=True).encode("utf-8")

def export_lua(snapshot):
    """Share identical player item variants without changing the JSON source data."""
    output=copy.deepcopy(snapshot);shared=[];indices={}
    for modes in output['specs'].values():
        for dataset in modes.values():
            for player in dataset.get('players',[]):
                for field in ('gear','rioGear'):
                    for slot,item in player.get(field,{}).items():
                        value={k:v for k,v in item.items() if k!='updatedAt'}
                        key=json.dumps(value,sort_keys=True,ensure_ascii=False)
                        if key not in indices:
                            shared.append(value);indices[key]=len(shared)
                        player[field][slot]=indices[key]
    output['playerItems']=shared
    restore='''
-- One shared table per actual item variant; profile dates stay on each player.
for _,modes in pairs(R.Data.specs) do
 for _,dataset in pairs(modes) do
  for _,player in ipairs(dataset.players or {}) do
   for _,field in ipairs({"gear","rioGear"}) do
    for slot,index in pairs(player[field] or {}) do player[field][slot]=R.Data.playerItems[index] end
   end
  end
 end
end
'''
    return '-- Generated outside WoW. Source populations remain distinct.\nlocal _, R = ...\nR.Data = '+lua(output)+'\n'+restore

def optional_feed(url, source, cache, timestamp):
    if not url:
        return None
    parsed=json.loads(fetch(url,cache,source+"-feed.json"))
    if parsed.get("schema") != 1 or parsed.get("source") != source or not parsed.get("specs"):
        raise ValueError("Authorized feed does not follow docs/DATA_SCHEMA.md")
    return parsed

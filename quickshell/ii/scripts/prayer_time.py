#!/usr/bin/env python3
import urllib.request
import json
import sys
from datetime import datetime

METHOD = 5  # Egyptian General Authority

def get_timings():
    url = f"https://api.aladhan.com/v1/timingsByCity?city=Beni+Suef&country=Egypt&method={METHOD}"
    with urllib.request.urlopen(url, timeout=5) as r:
        data = json.loads(r.read())
    return data["data"]["timings"]

PRAYERS = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
ARABIC  = {"Fajr": "الفجر", "Dhuhr": "الظهر", "Asr": "العصر", "Maghrib": "المغرب", "Isha": "العشاء"}

def get_next_prayer():
    try:
        timings = get_timings()
        now = datetime.now()
        for prayer in PRAYERS:
            t = timings[prayer]
            h, m = map(int, t.split(":"))
            prayer_dt = now.replace(hour=h, minute=m, second=0, microsecond=0)
            if prayer_dt > now:
                diff = prayer_dt - now
                total_min = diff.seconds // 60
                hrs = total_min // 60
                mins = total_min % 60
                remaining = f"{hrs}س {mins}د" if hrs > 0 else f"{mins}د"
                print(json.dumps({"name": ARABIC[prayer], "time": t, "remaining": remaining}, ensure_ascii=False))
                return
        # كل الصلوات فاتت، الفجر بكره
        t = timings["Fajr"]
        print(json.dumps({"name": "الفجر", "time": t, "remaining": "غداً"}, ensure_ascii=False))
    except:
        print(json.dumps({"name": "...", "time": "--:--", "remaining": ""}, ensure_ascii=False))

def get_all_prayers():
    try:
        timings = get_timings()
        now = datetime.now()
        result = []
        found_next = False
        for prayer in PRAYERS:
            t = timings[prayer]
            h, m = map(int, t.split(":"))
            prayer_dt = now.replace(hour=h, minute=m, second=0, microsecond=0)
            is_next = (prayer_dt > now) and not found_next
            if is_next:
                found_next = True
            result.append({"name": ARABIC[prayer], "time": t, "next": is_next})
        print(json.dumps(result, ensure_ascii=False))
    except:
        print(json.dumps([], ensure_ascii=False))

if "--all" in sys.argv:
    get_all_prayers()
else:
    get_next_prayer()

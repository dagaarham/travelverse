"""Downloads one freely licensed photo per seeded place into assets/places/.

Run by .github/workflows/fetch-photos.yml. Photos come from Wikimedia Commons
(via each place's Wikipedia article image, falling back to a Commons search)
and are resized to 900px wide so the whole set stays small enough to bundle
in the APK. Credits are written to assets/places/CREDITS.md.
"""
import io
import json
import re
import sys
import time
import urllib.parse
from pathlib import Path

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / 'lib/data/seed/places_seed.dart'
OUT = ROOT / 'assets/places'
UA = 'TouchGrassStudentApp/1.0 (https://github.com/dagaarham/travelverse; NMIMS MAD mini project)'
FREE = re.compile(r'(cc[- ]by|cc0|public domain|pd|gfdl|attribution)', re.I)
NOT_A_PHOTO = re.compile(r'(map|satellite|nasa|modis|landsat|locator|diagram|logo|stamp|painting|drawing|plan)', re.I)

# Places whose article image was not a good photo of the place: search Commons
# with a better query instead. Re-running the script refetches only these and
# any place that has no photo yet.
OVERRIDES = {
    'chokhi-dhani': 'Chokhi Dhani Jaipur village resort',
    'pangong-lake': 'Pangong Tso lake Ladakh',
    'rann-of-kutch': 'White Rann of Kutch salt desert',
    'johari-bazaar': 'Johari Bazaar Jaipur',
    'lonavala': 'Lonavala hills monsoon',
    'fontainhas': 'Fontainhas Panaji houses',
}

s = requests.Session()
s.headers['User-Agent'] = UA


def api(host, **params):
    params.update(format='json', formatversion=2)
    for attempt in range(5):
        r = s.get(f'https://{host}/w/api.php', params=params, timeout=30)
        if r.status_code == 429:
            time.sleep(5 * (attempt + 1))
            continue
        r.raise_for_status()
        return r.json()
    r.raise_for_status()


def strip_html(text):
    return re.sub(r'<[^>]+>', '', text or '').strip()


def commons_info(filename):
    """Returns (thumb_url, license, artist, page_url) for a Commons file, or None."""
    d = api('commons.wikimedia.org', action='query', titles=f'File:{filename}', prop='imageinfo',
            iiprop='url|extmetadata|mime', iiurlwidth=1200)
    pages = d.get('query', {}).get('pages', [])
    if not pages or pages[0].get('missing') or 'imageinfo' not in pages[0]:
        return None
    ii = pages[0]['imageinfo'][0]
    if ii.get('mime') not in ('image/jpeg', 'image/png', 'image/webp'):
        return None
    meta = ii.get('extmetadata', {})
    lic = strip_html(meta.get('LicenseShortName', {}).get('value', ''))
    if not FREE.search(lic):
        return None
    artist = strip_html(meta.get('Artist', {}).get('value', '')) or 'Unknown'
    return ii.get('thumburl') or ii['url'], lic, artist[:120], ii.get('descriptionurl', '')


def article_image(title):
    d = api('en.wikipedia.org', action='query', titles=urllib.parse.unquote(title).replace('_', ' '),
            prop='pageimages', piprop='name', redirects=1)
    pages = d.get('query', {}).get('pages', [])
    return pages[0].get('pageimage') if pages else None


def search_commons(query):
    d = api('commons.wikimedia.org', action='query', list='search', srnamespace=6, srlimit=10,
            srsearch=f'{query} filetype:bitmap')
    for hit in d.get('query', {}).get('search', []):
        name = hit['title'].removeprefix('File:')
        if name.lower().endswith(('.jpg', '.jpeg', '.png')) and not NOT_A_PHOTO.search(name):
            info = commons_info(name)
            if info:
                return name, info
    return None


def save(url, dest):
    for attempt in range(5):
        r = s.get(url, timeout=60)
        if r.status_code == 429:
            time.sleep(5 * (attempt + 1))
            continue
        r.raise_for_status()
        break
    img = Image.open(io.BytesIO(r.content)).convert('RGB')
    img.thumbnail((900, 900))
    img.save(dest, 'JPEG', quality=80, optimize=True, progressive=True)
    return dest.stat().st_size


def load_previous_credits():
    """Credits rows from an earlier run, keyed by place name."""
    path = OUT / 'CREDITS.md'
    rows = {}
    if path.exists():
        for line in path.read_text().splitlines():
            m = re.match(r'\| (.+?) \| \[(.+?)\]\((.*?)\) \| (.*?) \| (.*?) \|$', line)
            if m:
                name, fname, page, artist, lic = m.groups()
                rows[name] = (name, fname, artist, lic, page)
    return rows


def main():
    src = SEED.read_text()
    q = r"'((?:[^'\\]|\\.)+)'"
    places = re.findall(rf"id: {q},\s*name: {q},\s*city: {q}.*?wikiTitle: {q}", src, re.S)
    places = [tuple(v.replace("\\'", "'") for v in p) for p in places]
    print(f'{len(places)} places in seed')
    OUT.mkdir(parents=True, exist_ok=True)
    previous = load_previous_credits()
    credits, missing = [], []
    for pid, name, city, wiki in places:
        dest = OUT / f'{pid}.jpg'
        if dest.exists() and pid not in OVERRIDES and name in previous:
            credits.append(previous[name])
            continue
        try:
            chosen = None
            if pid in OVERRIDES:
                chosen = search_commons(OVERRIDES[pid])
            else:
                fname = article_image(wiki)
                if fname and not NOT_A_PHOTO.search(fname):
                    info = commons_info(fname)
                    if info:
                        chosen = (fname, info)
            chosen = chosen or search_commons(f'{name} {city}') or search_commons(name)
            if not chosen:
                missing.append(pid)
                print(f'MISSING {pid}')
                continue
            fname, (url, lic, artist, page) = chosen
            size = save(url, dest)
            credits.append((name, fname, artist, lic, page))
            print(f'ok {pid}: {fname} ({lic}) {size // 1024} KB')
        except Exception as e:  # noqa: BLE001 - report and keep going
            missing.append(pid)
            print(f'ERROR {pid}: {e}')
        time.sleep(0.5)

    lines = ['# Place photo credits', '',
             'All place photos are from Wikimedia Commons under the licences listed, resized for the app.', '',
             '| Place | Photo | Author | Licence |', '|---|---|---|---|']
    for name, fname, artist, lic, page in credits:
        artist = artist.replace('|', '/').replace('\n', ' ')
        lines.append(f'| {name} | [{fname}]({page}) | {artist} | {lic} |')
    (OUT / 'CREDITS.md').write_text('\n'.join(lines) + '\n')
    print(json.dumps({'saved': len(credits), 'missing': missing}))
    if missing:
        sys.exit(1)


if __name__ == '__main__':
    main()

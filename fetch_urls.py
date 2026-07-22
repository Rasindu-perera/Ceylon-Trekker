import urllib.request
import json
titles = ['Sigiriya', 'Ella,_Sri_Lanka', 'Horton_Plains_National_Park', 'Bambarakanda_Falls', 'Knuckles_Mountain_Range', 'Galle_Fort', 'Diyaluma_Falls', 'Adam%27s_Peak', 'Yala_National_Park', 'Polonnaruwa', 'Pidurangala_Vihara', 'Ohiya', 'Ravana_Falls', 'Anuradhapura', 'Meemure', 'Nine_Arch_Bridge', 'Dunhinda_Falls', 'Sinharaja_Forest_Reserve', 'Dambulla_cave_temple', 'Baker%27s_Falls']
for t in titles:
    req = urllib.request.Request(f'https://en.wikipedia.org/api/rest_v1/page/summary/{t}', headers={'User-Agent': 'CeylonTrekkerApp/1.0'})
    try:
        resp = json.loads(urllib.request.urlopen(req).read())
        print(f"{t}: {resp.get('thumbnail', {}).get('source')}")
    except Exception as e:
        print(f'{t}: Error {e}')

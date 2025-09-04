# pb_identity_plate

VIP **změna jména přes item** + **sundání/připevnění SPZ** pro kriminálníky. Stavěno pro **ESX**, **ox_inventory**, **ox_lib**, **okokNotify** a **oxmysql**.

## Funkce
- VIP změna jména přes item (`vip_name_change`) s **blacklistem** slov, délkou, kontrolou formátu a volitelným **ACE vip** oprávněním.
- Uložení jména přes `esx_identity` (doporučeno), nebo přímo do tabulky `users` (konfigurovatelné).
- Sundání SPZ a opětovné připevnění , validace, progress + animace.
- Stav SPZ v **state bagu** (uložení původní SPZ).
- **Discord logy** (volitelné) + **okokNotify** pro notifikace.

## Instalace
1. Nakopíruj složku `pb_identity_plate` do `resources/`.
2. V `server.cfg`:
   ```cfg
   ensure pb_identity_plate
   ```
3. Přidej itemy:
   - ox_inventory – doplň do `data/items.lua` 

////////////////////////////////////////////////

['license_plate'] = {
		label = 'SPZ',
		weight = 200,
		stack = false,
	},

['plate_kit'] = {
		label = 'Sada na sudávání SPZ',
		weight = 200,
		stack = false
	},

['vip_name_change'] = {
		label = 'Sada na sudávání SPZ',
		weight = 200,
		stack = false
	},

////////////////////////////////////////////////

4. V `config.lua` nastav:
   - `vip.item`, `vip.cooldownMinutes`, `vip.blacklist` (slova bez diakritiky, case-insensitive).
   - `identity.mode` – `esx_identity` | `users_table` | `xplayer_setname`.
   - `plates.removeItem` / `plates.attachItem`, `durationMs`, atd.
   - `discordWebhook` (pokud chceš logy).

## VIP Změna jména – poznámky
- Pokud používáš `esx_identity`, skript uloží `firstname` a `lastname` do DB a volitelně zavolá `xPlayer.setName` (pokud existuje).  
- Černá listina:
  - Diakritika a velikost písmen se ignoruje (např. „Policie“ = `policie`).
  - Rozsah a formát jména je v `Config.vip.name`.

## Bezpečnost a anti-abuse
- VIP změna jména má **cooldown** (výchozí 24h). Item se odebere pouze při úspěchu.
- SPZ akce validují
- Všechny změny potvrzuje server (žádné čistě klientské přepisování bez autorizace).

## Discord Logy
Nastav `Config.discordWebhook`. Skript posílá embed s hráčem a detailem akce.

## Kompatibilita
- ESX (legacy).
- ox_lib (progress, input, notify fallback přes okokNotify).
- ox_inventory (RegisterUsableItem).

# The country database, and what it is used under

`dbip-country-lite.mmdb` is **DB-IP's IP-to-Country Lite database**, redistributed
here under the **Creative Commons Attribution 4.0 International licence**
(CC BY 4.0).

> IP Geolocation by DB-IP — <https://db-ip.com>

That line is the attribution the licence requires, and it is the price of the
whole arrangement: it is what makes redistributing the file legal, which is what
makes the country resolvable in-process, which is what keeps the caller's
address from ever leaving this machine (K-05).

- Licence: <https://creativecommons.org/licenses/by/4.0/>
- Source: <https://db-ip.com/db/download/ip-to-country-lite>

## It is not MaxMind's, deliberately

GeoLite2 is the better-known database and could not be used. It may not be
redistributed, so the file could not live here: it would mean a licence key kept
as a CI secret, a download step in the build, and a binary nobody could produce
from a checkout without a network. The build stops being reproducible, and the
first person to try it on an aeroplane finds out.

## Replacing it

Quarterly. Same name, so nothing in the code changes:

```sh
curl -sfo internal/platform/geo/dbip/dbip-country-lite.mmdb.gz \
  "https://download.db-ip.com/free/dbip-country-lite-$(date +%Y-%m).mmdb.gz" &&
gunzip -f internal/platform/geo/dbip/dbip-country-lite.mmdb.gz
```

`TestTheDatabaseIsNotTooOldToBelieve` fails when the file is more than a year
old. That bound is deliberately loose: what it is there to catch is not a
missed quarter but a database nobody has touched in a year, still answering
every query with complete confidence.

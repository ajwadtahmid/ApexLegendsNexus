# Apex Legends API Documentation

**Base URL (Official API):** `https://api.mozambiquehe.re`
**Provider:** [apexlegendsapi.com](https://apexlegendsapi.com)
**Authentication:** Include your API key as `auth` query parameter, or as an `Authorization: YOUR_API_KEY` header.

---

## Proxy Routes Available

This server proxies the following Apex Legends API endpoints. All requests require the `x-client-token` header if `CLIENT_TOKEN` is set in your environment.

| Endpoint | Method | Status | Description |
| --- | --- | --- | --- |
| `/healthz` | GET | ✅ | Health check for uptime monitors |
| `/maprotation` | GET | ✅ | Current and next map rotations (cached 30s) |
| `/player` | GET | ✅ | Player stats by name (PC, PS4, X1) |
| `/player/uid` | GET | ✅ | Player stats by UID (all platforms) |
| `/origin` | GET | ✅ | Get player UID (Origin/PC only) |
| `/nametouid` | GET | ✅ | Convert player name to UID |
| `/servers` | GET | ✅ | Server/infrastructure status (cached 60s) |
| `/predator` | GET | ✅ | Apex Predator RP/AP requirements (cached 5min) |
| `/news` | GET | ✅ | Latest news feed (cached 10min, supports `lang` param) |
| `/games` | GET | ✅ | Match history (requires API whitelist) |

### Not Implemented

| Endpoint | Reason |
| --- | --- |
| `/crafting` | ⚠️ **Obsolete** — not used by this application |
| `/store` | 🔐 **Whitelist-only** — requires API key whitelist (unavailable to new users) |
| `/leaderboard` | 🔐 **Whitelist-only** — requires API key whitelist |
| `/bridge?history=1` | 🔐 **Unavailable** — legacy match history API (currently unavailable to new users) |

---

## Platform Codes

The official API uses these platform codes consistently across endpoints:

| Code | Meaning |
| --- | --- |
| `PC` | PC (Origin or Steam) |
| `PS4` | PlayStation 4 / 5 |
| `X1` | Xbox One / Series X\|S |
| `SWITCH` | Nintendo Switch (UID lookups only on most endpoints) |

> ⚠️ Do **not** use `PSN` or `XBOX` — those are not recognised by the API. The codes above are the ones used in every endpoint that takes a `platform` parameter.

---

## Rate Limiting

- **New API key:** 1 request per 2 seconds.
- **After linking your Discord account** in the [API portal](https://portal.apexlegendsapi.com): 2 requests per second.
- The current rate is returned in the `X-Current-Rate` response header.
- Higher rates can be requested via Discord ticket for legitimate cases.

---

## 1. Player Statistics (by name)

### GET `/bridge`

Retrieve detailed player stats including level, rank, and current legend stats.

**Parameters:**
- `player` (string, required): Player username (Origin name for PC players, even on Steam)
- `platform` (string, required): `PC`, `PS4`, `X1`, or `SWITCH`
- `auth` (string, required): API key
- `merge` (any, optional): Merge same-type trackers (e.g. limited-edition kills → kills)
- `removeMerged` (any, optional): Remove the source trackers that were merged
- `skipRank` (any, optional): Skip ranking data in the response

**Response Format:**
```json
{
  "global": {
    "name": "Taisheen",
    "level": 35,
    "uid": "1010155908909",
    "platform": "PC",
    "rank": {
      "rankName": "Unranked",
      "rankScore": 0,
      "rankDiv": 0
    }
  },
  "legends": {
    "selected": {
      "LegendName": "Lifeline",
      "data": [
        { "name": "BR Kills", "value": 0, "key": "kills" },
        { "name": "Damage", "value": 0, "key": "damage" },
        { "name": "Wins", "value": 0, "key": "wins" },
        { "name": "Headshots", "value": 0, "key": "headshots" }
      ]
    }
  },
  "realtime": {
    "isOnline": 0,
    "isInGame": 1
  }
}
```

✅ **Status:** Working

---

## 2. Player Statistics (by UID)

### GET `/bridge` (with `uid` instead of `player`)

Recommended over name-based lookup for any player you'll query repeatedly — UIDs are stable across name changes.

**Parameters:**
- `uid` (string, required): Player UID
- `platform` (string, required): `PC`, `PS4`, `X1`, or `SWITCH`
- `auth` (string, required): API key
- Same optional flags as the by-name version (`merge`, `removeMerged`, `skipRank`).

**Response:** Identical shape to query-by-name.

✅ **Status:** Working

---

## 3. Map Rotation

### GET `/maprotation?version=2`

Get current and next map rotations for Battle Royale (pubs & ranked) and any active LTM (Control, Gun Run, Mixtape, etc.).

**⚠️ IMPORTANT:** You **must** use `version=2` to get all modes. Without it, only Battle Royale pubs is returned.

**Parameters:**
- `version` (string): `2` for all modes (required for complete data)
- `auth` (string, required): API key

**Response Format:**
```json
{
  "battle_royale": {
    "current": {
      "map": "Kings Canyon",
      "remainingMins": 60,
      "remainingSecs": 3626,
      "DurationInMinutes": 90,
      "asset": "https://apexlegendsstatus.com/assets/maps/Kings_Canyon.png"
    },
    "next": {
      "map": "Olympus",
      "DurationInMinutes": 90,
      "asset": "https://apexlegendsstatus.com/assets/maps/Olympus.png"
    }
  },
  "ranked": {
    "current": {
      "map": "Kings Canyon",
      "remainingMins": 150,
      "DurationInMinutes": 270,
      "asset": "https://apexlegendsstatus.com/assets/maps/Kings_Canyon.png"
    },
    "next": {
      "map": "Olympus",
      "DurationInMinutes": 270,
      "asset": "https://apexlegendsstatus.com/assets/maps/Olympus.png"
    }
  },
  "ltm": {
    "current": {
      "map": "Caustic Treatment",
      "eventName": "Control",
      "remainingMins": 0,
      "isActive": true,
      "asset": "https://apexlegendsstatus.com/assets/maps/Kings_Canyon.png"
    },
    "next": {
      "map": "Skulltown",
      "eventName": "Gun Run",
      "isActive": true,
      "asset": "https://apexlegendsstatus.com/assets/maps/Arena_Skulltown.png"
    }
  }
}
```

✅ **Status:** Working

> The `ltm` block reflects whatever Limited Time Mode is active at the moment — that may be Control, Gun Run, Three Strikes, a seasonal Mixtape, etc. The `eventName` field carries the human-readable mode name. Check `isActive` before showing it in the UI.

---

## 5. Server Status

### GET `/servers`

Check status of API services and infrastructure.

**Parameters:**
- `auth` (string, required): API key

**Response Format:**
```json
{
    "Origin_login": {
        "EU-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 42,
            "QueryTimestamp": 1778319004
        },
        "EU-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 3,
            "QueryTimestamp": 1778319001
        },
        "US-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 2,
            "QueryTimestamp": 1778319001
        },
        "US-Central": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 2,
            "QueryTimestamp": 1778319002
        },
        "US-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 2,
            "QueryTimestamp": 1778319002
        },
        "SouthAmerica": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 2,
            "QueryTimestamp": 1778319003
        },
        "Asia": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 2,
            "QueryTimestamp": 1778319003
        }
    },
    "EA_novafusion": {
        "EU-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 63,
            "QueryTimestamp": 1778319004
        },
        "EU-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 18,
            "QueryTimestamp": 1778319001
        },
        "US-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319002
        },
        "US-Central": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319002
        },
        "US-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319002
        },
        "SouthAmerica": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319003
        },
        "Asia": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 14,
            "QueryTimestamp": 1778319003
        }
    },
    "EA_accounts": {
        "EU-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 39,
            "QueryTimestamp": 1778319005
        },
        "EU-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 18,
            "QueryTimestamp": 1778319001
        },
        "US-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 16,
            "QueryTimestamp": 1778319002
        },
        "US-Central": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 16,
            "QueryTimestamp": 1778319002
        },
        "US-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319003
        },
        "SouthAmerica": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 16,
            "QueryTimestamp": 1778319003
        },
        "Asia": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319004
        }
    },
    "ApexOauth_Crossplay": {
        "EU-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 83,
            "QueryTimestamp": 1778319006
        },
        "EU-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319001
        },
        "US-West": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319002
        },
        "US-Central": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319002
        },
        "US-East": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319003
        },
        "SouthAmerica": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 16,
            "QueryTimestamp": 1778319003
        },
        "Asia": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 15,
            "QueryTimestamp": 1778319004
        }
    },
    "selfCoreTest": {
        "Status-website": {
            "Status": "SLOW",
            "HTTPCode": 200,
            "ResponseTime": 114,
            "QueryTimestamp": 1778319006
        },
        "Stats-API": {
            "Status": "SLOW",
            "HTTPCode": 200,
            "ResponseTime": 2141,
            "QueryTimestamp": 1778319008
        },
        "Overflow-#1": {
            "Status": "DOWN",
            "HTTPCode": 503,
            "ResponseTime": -1,
            "QueryTimestamp": 1778319008
        },
        "Overflow-#2": {
            "Status": "UP",
            "HTTPCode": 200,
            "ResponseTime": 1,
            "QueryTimestamp": 1778319008
        },
        "Origin-API": {
            "Status": "SLOW",
            "HTTPCode": 200,
            "ResponseTime": 1984,
            "QueryTimestamp": 1778319010
        },
        "Playstation-API": {
            "Status": "DOWN",
            "HTTPCode": 404,
            "ResponseTime": -1,
            "QueryTimestamp": 1778319013
        },
        "Xbox-API": {
            "Status": "SLOW",
            "HTTPCode": 200,
            "ResponseTime": 7095,
            "QueryTimestamp": 1778319020
        }
    },
    "otherPlatforms": {
        "Playstation-Network": {
            "Status": "UP",
            "QueryTimestamp": 1778319021
        },
        "Xbox-Live": {
            "Status": "UP",
            "QueryTimestamp": 1778319024
        }
    }
}
```

✅ **Status:** Working

> 📌 **Attribution required:** When displaying server-status data in your UI, the API's terms of use require either a clickable link to `https://apexlegendsstatus.com` or a visible "Data from apexlegendsstatus.com" credit.

---

## 6. Apex Predator Requirements

### GET `/predator`

Get current RP/AP requirements to reach Apex Predator across platforms, plus the count of Masters and Predators on each platform.

**Parameters:**
- `auth` (string, required): API key

**Response Format:**
```json
{
  "RP": {
    "PC":     { "foundRank": -1, "val": 16000, "totalMastersAndPreds": 110, "updateTimestamp": 1778216401 },
    "PS4":    { "foundRank": -1, "val": 16000, "totalMastersAndPreds": 45,  "updateTimestamp": 1778216401 },
    "X1":     { "foundRank": -1, "val": 16000, "totalMastersAndPreds": 78,  "updateTimestamp": 1778216401 },
    "SWITCH": { "foundRank": -1, "val": 16000, "totalMastersAndPreds": 12,  "updateTimestamp": 1778216401 }
  }
}
```

> The platform keys returned (`PC`, `PS4`, `X1`, `SWITCH`) match the platform codes the API expects in other endpoints — keep your client's platform values aligned with these.

✅ **Status:** Working

---

## 6. Player UID Lookup (Origin)

### GET `/origin`

Get a player's UID without fetching full statistics. PC / Origin only.

**Parameters:**
- `player` (string, required): Player username
- `auth` (string, required): API key

**Response Format:**
```json
{
  "name": "Taisheen",
  "uid": "1010155908909",
  "pid": "1004974508909",
  "avatar": "https://secure.download.dm.origin.com/production/avatar/prod/1/599/416x416.JPEG"
}
```

✅ **Status:** Working

---

## 7. Name to UID Conversion

### GET `/nametouid`

Convert a player name to a UID across PC, PlayStation, and Xbox.

**Parameters:**
- `player` (string, required): Player username
- `platform` (string, required): `PC`, `PS4`, or `X1`
- `auth` (string, required): API key

**Response Format:**
```json
{
  "name": "Timmy",
  "uid": "1000996157490",
  "pid": "1005978357490",
  "avatar": ""
}
```

✅ **Status:** Working

---

## 8. Player UID Lookup (Origin)

### GET `/origin`

Get a player's UID without fetching full statistics. **PC / Origin only.**

**Parameters:**
- `player` (string, required): Player username
- `auth` (string, required): API key

**Response Format:**
```json
{
  "name": "Taisheen",
  "uid": "1010155908909",
  "pid": "1004974508909",
  "avatar": "https://secure.download.dm.origin.com/production/avatar/prod/1/599/416x416.JPEG"
}
```

✅ **Status:** Working

---

## 9. News

### GET `/news`

Returns the latest news from the in-game news feed in the given language.

**Parameters:**
- `lang` (string, optional): Language code, defaults to `en-US`
- `auth` (string, required): API key

> ℹ️ The news feed sometimes returns an empty array when no news has been published recently. An empty response is **normal** — not an outage. Render a "No recent news" empty state in your UI.

✅ **Status:** Working (may return empty data)

---

## 10. Crafting Rotation

### GET `/crafting`

Returns the current items that can be crafted in replicators.

**Parameters:**
- `auth` (string, required): API key

⚠️ **Status:** Obsolete — not implemented in this proxy

> This endpoint is available on the official API but is **not used** by this application and is not proxied. It is listed here for reference only.

---

## ⚠️ Whitelist-Only & Special Endpoints

### Leaderboards (GET `/leaderboard`)
- **Status:** ❌ Not implemented — Whitelist required
- Returns top 500 players for each statistic/legend. Updated every 6 hours.
- Attribution required: visible "Data provided by Apex Legends Status" with a clickable link to `https://apexlegendsstatus.com`.
- To request whitelist access, open a ticket on the [official Discord](https://discord.gg/qd9cZQm).

### Store (GET `/store`)
- **Status:** ❌ Not implemented — Whitelist required
- Returns the current in-game shop data.
- To request whitelist access, open a ticket on the [official Discord](https://discord.gg/qd9cZQm).

### Match History — "New" API (GET `/games`)
- **Status:** ✅ Implemented (requires whitelist)
- Retrieve match history for a player. Free with a strict cap of 5 unique tracked players per hour.
- **Parameters:**
  - `uid` (string, required): Player UID
  - `mode` (string, optional): Match mode filter
  - `start` (number, optional): Start timestamp
  - `end` (number, optional): End timestamp
  - `limit` (number, optional): Result limit
- **Proxy endpoint:** `GET /games?uid=<uid>&mode=<mode>&start=<start>&end=<end>&limit=<limit>`

### Match History — "Legacy" API (GET `/bridge?history=1`)
- **Status:** ❌ Not implemented — Currently unavailable to new users
- Legacy match history endpoint. Use the "New" API (`/games`) instead.

**Note:** If your app receives a 403 from these endpoints, it's not a bug — it means your API key has not been whitelisted for that endpoint. Contact the provider to request access.

---

## Error Codes

| Code | Meaning |
| --- | --- |
| 400 | Try again in a few minutes |
| 403 | Unauthorized / unknown API key, or whitelist-only endpoint |
| 404 | Player not found |
| 405 | External API error |
| 410 | Unknown platform provided |
| 429 | Rate limit reached |
| 500 | Internal error |

---

## Implementation Notes

1. **Always use `version=2` for map rotation** to get Battle Royale, Ranked, and active LTM together.
2. **Stick to the official platform codes:** `PC`, `PS4`, `X1`, `SWITCH`. Anything else returns 410.
3. **Default rate limit is 1 req per 2 seconds** until you link Discord, then 2 req/second.
4. **Timestamps are Unix epoch seconds** — convert to a `Date` for display.
5. **Send the API key server-side only** — embedding it in a mobile app bundle exposes it to anyone who downloads the app.
6. **Honour the attribution requirements** — server status and leaderboard data require a credit/link to `apexlegendsstatus.com` per the API's terms of use.
7. **The API ships with no uptime guarantee.** Plan graceful failure modes for any feature that depends on it.

---

## Last Updated
Verified against the official documentation at [apexlegendsapi.com](https://apexlegendsapi.com).
Working endpoints used by this app: `/bridge`, `/maprotation`, `/servers`, `/predator`, `/origin`, `/nametouid`, `/news`.

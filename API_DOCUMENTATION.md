# Apex Legends API Documentation

**Base URL:** `https://api.mozambiquehe.re`  
**Authentication:** Include your API key as `auth` query parameter

---

## 1. Player Statistics

### GET `/bridge`

Retrieve detailed player stats including level, rank, and current legend stats.

**Parameters:**
- `player` (string): Player username
- `platform` (string): `PC`, `PSN`, `XBOX`, or `SWITCH`
- `auth` (string): API key

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
        {
          "name": "BR Kills",
          "value": 0,
          "key": "kills"
        },
        {
          "name": "Damage",
          "value": 0,
          "key": "damage"
        },
        {
          "name": "Wins",
          "value": 0,
          "key": "wins"
        },
        {
          "name": "Headshots",
          "value": 0,
          "key": "headshots"
        }
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

## 2. Map Rotation (Battle Royale & Ranked)

### GET `/maprotation?version=2`

Get current and next map rotations for Battle Royale (pubs & ranked) and Control modes.

**⚠️ IMPORTANT:** You MUST use `version=2` to get all modes. Version 1 only returns Battle Royale pubs.

**Parameters:**
- `version` (string): `2` for all modes (required for complete data)
- `auth` (string): API key

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

---

## 3. Server Status

### GET `/servers`

Check status of API services and infrastructure.

**Parameters:**
- `auth` (string): API key

**Response Format:**
```json
{
  "ApexOauth_Crossplay": {
    "status": "OK",
    "statusCode": "OK",
    "playerCount": 0
  },
  "EA_accounts": {
    "status": "OK",
    "statusCode": "OK",
    "playerCount": 0
  },
  "EA_novafusion": {
    "status": "OK",
    "statusCode": "OK",
    "playerCount": 0
  },
  "Origin_login": {
    "status": "OK",
    "statusCode": "OK",
    "playerCount": 0
  }
}
```

✅ **Status:** Working

---

## 4. Apex Predator Requirements

### GET `/predator`

Get current RP/AP requirements to reach Apex Predator across platforms.

**Parameters:**
- `platform` (string): `PC`, `PSN`, `X1` (Xbox), or `SWITCH`
- `auth` (string): API key

**Response Format:**
```json
{
  "RP": {
    "PC": {
      "foundRank": -1,
      "val": 16000,
      "totalMastersAndPreds": 110,
      "updateTimestamp": 1778216401
    },
    "PS4": {
      "foundRank": -1,
      "val": 16000,
      "totalMastersAndPreds": 45,
      "updateTimestamp": 1778216401
    },
    "X1": {
      "foundRank": -1,
      "val": 16000,
      "totalMastersAndPreds": 78,
      "updateTimestamp": 1778216401
    },
    "SWITCH": {
      "foundRank": -1,
      "val": 16000,
      "totalMastersAndPreds": 12,
      "updateTimestamp": 1778216401
    }
  }
}
```

✅ **Status:** Working

---

## 5. Player UID Lookup

### GET `/origin`

Get a player's UID without fetching full statistics.

**Parameters:**
- `player` (string): Player username
- `platform` (string): `PC`, `PSN`, `XBOX`, or `SWITCH`
- `auth` (string): API key

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

## 6. Name to UID Conversion

### GET `/nametouid`

Convert player name to UID across platforms.

**Parameters:**
- `player` (string): Player username
- `auth` (string): API key

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

## ⚠️ BROKEN/UNAVAILABLE ENDPOINTS

### Leaderboard (GET `/leaderboard`)
- **Status:** ❌ Currently returns error
- **Note:** API endpoint appears to be temporarily unavailable or rate-limited

### Store (GET `/store`)
- **Status:** ❌ Currently returns error
- **Note:** Store data endpoint is not responding. Try again later.

### News (GET `/news`)
- **Status:** ⚠️ Returns empty array
- **Note:** No news data available from API at this time

---

## Implementation Notes

1. **Always use `version=2` for map rotation** to get Battle Royale, Ranked, and Control modes
2. **Broken endpoints will show warnings in UI** - users should try again later
3. **Platform codes:** `PC`, `PSN` (PlayStation), `X1` (Xbox), `SWITCH`
4. **Timestamps** are in Unix format - convert to readable dates as needed
5. **All API calls include auth header** via interceptor in api_service.dart

---

## Last Updated
Tested: 2026-05-08
API Key Status: Valid
Working Endpoints: 6/9
Broken Endpoints: 2/9
Empty/Partial Endpoints: 1/9

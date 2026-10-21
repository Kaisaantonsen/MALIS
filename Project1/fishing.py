"""Fishing Season simulator (MALIS, Project 1).

Three things you can do with this file:

1. Read game logs
    log = load_log("fishing_log_xxx.json")         # your own log, downloaded from the game
    logs = load_logs("class_logs.json")            # the class logs (a list of logs)

2. Play a bay (Parts II and III)
    bay = FishingBay.from_log(log, season=1)       # the exact bay this player played
    bay = FishingBay(season=1, seed=123)           # a new random bay (any integer seed)

    while not bay.done:
        spot = ...                                 # your agent chooses a spot, 0 to 4
        catch = bay.fish(spot)                     # catch of the day, in kg
    print(bay.total, bay.best_possible())

   Seasons: 1 = 30 days, 2 = 10 days, 3 = 30 days. A bay from a log gives the
   same catch as in the game for every day and every spot.
   Longer seasons: FishingBay(season=3, seed=123, days=200, shift_day=101).

3. Play a contextual bay (Part IV)
    bay = ContextualBay(seed=123)                  # 300 days
    while not bay.done:
        x = bay.observe()                          # today's conditions, before choosing
        spot = ...                                 # use x to choose a spot
        catch = bay.fish(spot)

   x is a dict with wind_kmh (0 to 40), waves_m (0 to 3) and tide_m (0 to 2).
   bay.observe_array() gives the same values as a numpy array.

Rules: agents only use observe(), fish() and what they have seen so far.
Do not read attributes starting with "_" (hidden averages) while playing.
After the season, bay.reveal() gives the true averages.
"""
import json
import math
import os
import random

import numpy as np

SPOTS = ["Old Pier", "Rocky Point", "Seagrass Bed", "Deep Channel", "Lighthouse Reef"]
N_SPOTS = len(SPOTS)
SD = 2.5                      # day to day variability of the catch (kg)
MEAN_LOW, MEAN_HIGH = 2.0, 10.0
SEASONS = {
    1: {"key": "standard", "days": 30, "shift_day": None},
    2: {"key": "short", "days": 10, "shift_day": None},
    3: {"key": "changing", "days": 30, "shift_day": 16},
}

# ---------------------------------------------------------------------------
# Reading logs
# ---------------------------------------------------------------------------

def load_log(path):
    """Read one game log (the JSON file downloaded at the end of the game)."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_logs(path):
    """Read several logs: a JSON file holding a list of logs, or a folder of JSON logs."""
    if os.path.isdir(path):
        return [load_log(os.path.join(path, n)) for n in sorted(os.listdir(path)) if n.endswith(".json")]
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else [data]


def choices(log, season):
    """Spots chosen (list of ints) and catches (list of floats) in one season of a log."""
    r = log["rounds"][season - 1]
    return [c["spot"] for c in r["choices"]], [c["catch_kg"] for c in r["choices"]]


# ---------------------------------------------------------------------------
# Bay generator. Identical to the one in the browser game, so a bay can be
# rebuilt exactly from the seed stored in a log.
# ---------------------------------------------------------------------------
_MASK = 0xFFFFFFFF


def _imul(a, b):
    return (a * b) & _MASK


def _fnv1a32(s):
    h = 0x811C9DC5
    for ch in s:
        h ^= ord(ch)
        h = _imul(h, 0x01000193)
    return h


def _mulberry32(a):
    state = [a & _MASK]

    def rng():
        state[0] = (state[0] + 0x6D2B79F5) & _MASK
        a = state[0]
        t = _imul(a ^ (a >> 15), 1 | a)
        t = ((t + _imul(t ^ (t >> 7), 61 | t)) & _MASK) ^ t
        return ((t ^ (t >> 14)) & _MASK) / 4294967296

    return rng


def _normal(rng):
    u1, u2 = rng(), rng()
    return math.sqrt(-2 * math.log(1 - u1)) * math.cos(2 * math.pi * u2)


def _round1(x):
    return math.floor(x * 10 + 0.5) / 10


def _build(seed, season, days, shift_day):
    rng = _mulberry32(_fnv1a32("bay" + str(seed) + "|round" + str(season)))
    draw = lambda: _round1(MEAN_LOW + (MEAN_HIGH - MEAN_LOW) * rng())
    means = [draw() for _ in SPOTS]
    means2 = [draw() for _ in SPOTS] if shift_day else None
    table = []
    for d in range(1, days + 1):
        row = []
        for k in range(N_SPOTS):
            m = means2[k] if (means2 and d >= shift_day) else means[k]
            row.append(max(0.0, _round1(m + SD * _normal(rng))))
        table.append(row)
    return means, means2, table


# ---------------------------------------------------------------------------
# The game
# ---------------------------------------------------------------------------

class FishingBay:
    """One season of Fishing Season: 5 spots, one choice per day."""

    def __init__(self, season=1, seed=None, days=None, shift_day=None):
        """season: 1, 2 or 3. seed: any integer (random if None).

        days and shift_day change the length of the season and the day the fish
        populations change (None: no change), to experiment with longer seasons.
        Leave them out to get exactly the seasons of the game.
        """
        if season not in SEASONS:
            raise ValueError("season must be 1, 2 or 3")
        self.season = season
        self.seed = random.randrange(2 ** 32) if seed is None else int(seed)
        if days is None and shift_day is None:
            days, shift_day = SEASONS[season]["days"], SEASONS[season]["shift_day"]
        elif days is None:
            days = SEASONS[season]["days"]
        if shift_day is not None and not 2 <= shift_day <= days:
            raise ValueError("shift_day must be between 2 and days")
        self.days = days
        self.n_spots = N_SPOTS
        self._shift_day = shift_day
        self._means, self._means2, self._table = _build(self.seed, season, days, shift_day)
        self.reset()

    @classmethod
    def from_log(cls, log, season):
        """The bay played in a game log, for the given season (1, 2 or 3)."""
        return cls(season=season, seed=log["bay_seed"])

    def reset(self):
        """Start the season again, same bay, same catches."""
        self.day = 0               # days already fished
        self.total = 0.0
        self.history = []          # list of (spot, catch)

    @property
    def done(self):
        return self.day >= self.days

    def fish(self, spot):
        """Fish at spot (0 to 4) today. Returns the catch in kg and moves to the next day."""
        if self.done:
            raise RuntimeError("the season is over")
        if not 0 <= spot < N_SPOTS:
            raise ValueError("spot must be between 0 and 4")
        catch = self._table[self.day][spot]
        self.day += 1
        self.total = _round1(self.total + catch)
        self.history.append((int(spot), catch))
        return catch

    def reveal(self):
        """True average catch of each spot (two lists for season 3: before and after the change)."""
        if self._means2 is None:
            return {"means": list(self._means)}
        return {"means": list(self._means), "means_after_change": list(self._means2),
                "change_day": self._shift_day}

    def best_possible(self):
        """Expected total of a player who always fishes the best spot (knowing the true averages)."""
        if self._means2 is None:
            return _round1(max(self._means) * self.days)
        before = self._shift_day - 1
        return _round1(max(self._means) * before + max(self._means2) * (self.days - before))


# ---------------------------------------------------------------------------
# Contextual version (Part IV)
# ---------------------------------------------------------------------------

class ContextualBay:
    """300 days. Each morning you observe wind, waves and tide before choosing a spot.

    The average catch of each spot depends on the conditions, differently for each
    spot. How exactly is hidden and changes with the seed.
    """
    FEATURES = ["wind_kmh", "waves_m", "tide_m"]
    _SCALE = np.array([40.0, 3.0, 2.0])

    def __init__(self, seed=None, days=300):
        self.seed = random.randrange(2 ** 32) if seed is None else int(seed)
        self.days = days
        self.n_spots = N_SPOTS
        rng = np.random.default_rng(self.seed)
        self._base = rng.uniform(3.0, 8.0, N_SPOTS)
        self._weights = rng.uniform(-6.0, 6.0, (N_SPOTS, 3))
        self._conditions = rng.uniform(0.0, 1.0, (days, 3)) * self._SCALE
        z = self._conditions / self._SCALE
        self._mean_table = np.clip(self._base + z @ self._weights.T, 0.0, None)
        noise = rng.normal(0.0, SD, (days, N_SPOTS))
        self._table = np.round(np.clip(self._mean_table + noise, 0.0, None), 1)
        self.reset()

    def reset(self):
        self.day = 0
        self.total = 0.0
        self.history = []          # list of (conditions dict, spot, catch)

    @property
    def done(self):
        return self.day >= self.days

    def observe(self):
        """Today's conditions as a dict."""
        if self.done:
            raise RuntimeError("the season is over")
        return {k: round(float(v), 1) for k, v in zip(self.FEATURES, self._conditions[self.day])}

    def observe_array(self):
        """Today's conditions as a numpy array [wind_kmh, waves_m, tide_m]."""
        return np.array(list(self.observe().values()))

    def fish(self, spot):
        if self.done:
            raise RuntimeError("the season is over")
        if not 0 <= spot < N_SPOTS:
            raise ValueError("spot must be between 0 and 4")
        x = self.observe()
        catch = float(self._table[self.day, spot])
        self.day += 1
        self.total = _round1(self.total + catch)
        self.history.append((x, int(spot), catch))
        return catch

    def reveal(self):
        """True average catch of every spot on every day (array of shape days x 5)."""
        return np.round(self._mean_table, 2)

    def best_possible(self):
        """Expected total when always fishing the best spot for the day's conditions."""
        return _round1(float(self._mean_table.max(axis=1).sum()))

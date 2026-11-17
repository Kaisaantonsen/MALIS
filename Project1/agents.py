"""Agents for Fishing Season (MALIS, Project 1).

This file is a skeleton. Write all your agents in it.

Do NOT modify the classes Agent and ContextualAgent, nor the function play():
they define how every agent interacts with the simulator, and they are used
to run your agents during grading.

How an agent works
------------------
For each season, play(agent, bay) calls:

    agent.reset()                     once, before the first day
    spot = agent.choose()             every day: return a spot, 0 to 4
    agent.update(spot, catch)         every day: the catch you observed

An agent only learns through update(). It must not look at the bay itself.

Contextual agents (Part IV, optional) follow the same pattern, but receive the
morning conditions x (numpy array [wind_kmh, waves_m, tide_m]):

    spot = agent.choose(x)
    agent.update(x, spot, catch)

Example
-------
    from fishing import FishingBay
    from agents import RandomAgent, play

    bay = FishingBay(season=1, seed=0)
    total = play(RandomAgent(seed=0), bay)
"""
import math
import random

import numpy as np

from fishing import ContextualBay, FishingBay

# ---------------------------------------------------------------------------
# Provided: do not modify
# ---------------------------------------------------------------------------


class Agent:
    """Base class for the agents of Parts II and III.

    Parameters
    ----------
    n_spots : int
        Number of fishing spots (5 in the game).
    seed : int or None
        Seed of the agent's own random generator, self.rng. Use self.rng for
        any random decision, so that results can be reproduced.
    """

    def __init__(self, n_spots=5, seed=None):
        self.n_spots = n_spots
        self.rng = np.random.default_rng(seed)

    def reset(self):
        """Called once at the start of every season. Clear what the agent learned."""

    def choose(self):
        """Return the spot to fish today, an int between 0 and n_spots - 1."""
        raise NotImplementedError

    def update(self, spot, catch):
        """Called after each day with the spot chosen and the catch observed (kg)."""


class ContextualAgent:
    """Base class for the agents of Part IV (contextual bay).

    Same as Agent, except that choose() and update() also receive x, the
    conditions of the day: numpy array [wind_kmh, waves_m, tide_m].
    """

    def __init__(self, n_spots=5, seed=None):
        self.n_spots = n_spots
        self.rng = np.random.default_rng(seed)

    def reset(self):
        """Called once at the start of every season. Clear what the agent learned."""

    def choose(self, x):
        """Return the spot to fish today given the conditions x."""
        raise NotImplementedError

    def update(self, x, spot, catch):
        """Called after each day with the conditions, the spot chosen and the catch observed."""


def play(agent, bay):
    """Play one full season of bay with agent. Returns the total catch (kg).

    Works with FishingBay and Agent, or with ContextualBay and ContextualAgent.
    The bay is reset first, so the same bay can be played by several agents.
    """
    contextual = isinstance(bay, ContextualBay)
    if contextual and not isinstance(agent, ContextualAgent):
        raise TypeError("a ContextualBay must be played by a ContextualAgent")
    if not contextual and not isinstance(agent, Agent):
        raise TypeError("a FishingBay must be played by an Agent")
    bay.reset()
    agent.reset()
    while not bay.done:
        if contextual:
            x = bay.observe_array()
            spot = int(agent.choose(x))
            catch = bay.fish(spot)
            agent.update(x, spot, catch)
        else:
            spot = int(agent.choose())
            catch = bay.fish(spot)
            agent.update(spot, catch)
    return bay.total


# ---------------------------------------------------------------------------
# Provided example agents (baselines)
# ---------------------------------------------------------------------------


class RandomAgent(Agent):
    """Chooses a spot uniformly at random every day. Learns nothing."""

    def choose(self):
        return int(self.rng.integers(self.n_spots))


class RandomContextualAgent(ContextualAgent):
    """Ignores the conditions and chooses a spot uniformly at random every day."""

    def choose(self, x):
        return int(self.rng.integers(self.n_spots))


# ---------------------------------------------------------------------------
# Your agents
# ---------------------------------------------------------------------------


class HumanRuleAgent(Agent):
    """Task 4: the best human strategy of the team (Synne, Season 2).

    Rule, as it can be applied by hand: "try every spot once, then
    alternate between the two spots with the best average catch".

    How it chooses
    --------------
    1. Tour. Days 1 to n_spots: fish spot 0, then 1, ..., then n_spots - 1.
    2. Alternate. Every following day, rank the spots by their average catch
       so far and keep the two best. If yesterday's spot was the best one,
       fish the second best; otherwise fish the best one. The averages are
       updated every day, so the two spots of the pair can change.
       Ties are broken by the lowest spot number.

    Memory
    ------
    totals : array of n_spots floats
        Sum of the catches at each spot.
    counts : array of n_spots ints
        Number of days each spot was fished.
    last : int or None
        Spot fished yesterday (None before the first day).

    Parameters
    ----------
    n_spots : int
        Number of fishing spots (5 in the game).
    seed : int or None
        Unused: the rule is deterministic. Kept for the common interface.
    """

    def __init__(self, n_spots=5, seed=None):
        super().__init__(n_spots=n_spots, seed=seed)
        self.reset()

    def reset(self):
        self.totals = np.zeros(self.n_spots)
        self.counts = np.zeros(self.n_spots, dtype=int)
        self.last = None

    def choose(self):
        # 1. Tour: the first spot not tried yet.
        untried = np.flatnonzero(self.counts == 0)
        if untried.size > 0:
            return int(untried[0])
        # 2. Alternate between the two best averages (stable sort: ties -> lowest number).
        averages = self.totals / self.counts
        best, second = np.argsort(-averages, kind="stable")[:2]
        return int(second if self.last == best else best)

    def update(self, spot, catch):
        self.totals[spot] += catch
        self.counts[spot] += 1
        self.last = spot


class CatchBasedAgent(Agent):
    """
    Rule-based agent that changes spots based on recent catches.
    (First version of the human rule, kept for comparison.)

    How it chooses
    --------------
    It starts at a random spot and stays there while catches are improving.
    Two catches below the low threshold at the same spot cause it to switch,
    even if they are not consecutive. It also switches after two consecutive
    catches above the high threshold. The low threshold is set by the first
    catch at a spot and stays fixed. The high threshold rises when catches
    improve. For catches between the thresholds, it switches if the catch is
    no better than the previous catch at the current spot.

    Memory
    ------
    current_spot : int
        The spot chosen for the current day.
    previous_catch : float or None
        The last catch at the current spot, or None after switching.
    high_threshold : float or None
        The best catch so far at the current spot plus delta.
    low_threshold : float or None
        The first catch at the current spot minus delta.
    high_catch_count : int
        Number of consecutive high catches at the current spot.
    low_catch_count : int
        Number of low catches at the current spot.

    Parameters
    ----------
    n_spots : int
        Number of available fishing spots.
    delta : float
        Amount used to set the low threshold from the first catch and the
        high threshold from improving catches.
    seed : int or None
        Seed for repeatable random spot choices.
    """

    def __init__(self, n_spots, delta=0.5, seed=None):
        super().__init__(n_spots=n_spots, seed=seed)
        self.delta = delta
        self.reset()

    def reset(self):
        self.current_spot = int(self.rng.integers(self.n_spots))
        self.previous_catch = None
        self.high_threshold = None
        self.low_threshold = None
        self.high_catch_count = 0
        self.low_catch_count = 0

    def choose(self):
        return self.current_spot

    def update(self, spot, catch):
        if self.previous_catch is None:
            self.previous_catch = catch
            self.high_threshold = catch + self.delta
            self.low_threshold = max(0.0, catch - self.delta)
            return

        if catch > self.high_threshold:
            self.high_catch_count += 1

            if self.high_catch_count >= 2:
                self.switch_spot()
                return

        elif catch < self.low_threshold:
            self.high_catch_count = 0
            self.low_catch_count += 1

            if self.low_catch_count >= 2:
                self.switch_spot()
                return

        elif catch <= self.previous_catch:
            self.switch_spot()
            return

        else:
            self.high_catch_count = 0

        self.previous_catch = catch
        self.high_threshold = max(self.high_threshold, catch + self.delta)

    def switch_spot(self):
        possible_spots = [i for i in range(self.n_spots) if i != self.current_spot]

        if possible_spots:
            self.current_spot = int(self.rng.choice(possible_spots))

        self.previous_catch = None
        self.high_threshold = None
        self.low_threshold = None
        self.high_catch_count = 0
        self.low_catch_count = 0


# Task 4: add below at least two agents implementing methods from the reading
# (Sutton and Barto, Chapter 2), as subclasses of Agent. Document each class:
# what it keeps in memory, how it chooses, what its parameters mean.

class EpsilonGreedyAgent(Agent):
    """
        Epsilon-greedy bandit agent from section 2.2 (Sutton and Barto, Chapter 2).

        How it chooses
        --------------
        With probability epsilon, it selects a random spot.
        Otherwise, it selects a spot with the highest estimated reward.
        If multiple spots have the same highest estimated reward,
        one is selected randomly.

        Memory
        ------
        q : list
            Estimated average reward for each fishing spot.
        counts : list
            Number of times each spot has been selected.

        Parameters
        ----------
        n_spots : int
            Number of available fishing spots.
        epsilon : float
            Probability of choosing a random spot instead of
            the current estimated best spot.

        The update() method updates the estimated reward after each catch,
        using the method from Section 2.4.
    """

    def __init__(self, n_spots=5, seed=None, epsilon=0.1):
        super().__init__(n_spots, seed)
        self.epsilon = epsilon
        self.reset()

    def reset(self):
        self.Q = np.zeros(self.n_spots)
        self.N = np.zeros(self.n_spots, dtype=int)

    def choose(self):
        if self.rng.random() < self.epsilon:
            return int(self.rng.integers(self.n_spots))

        best_spots = np.flatnonzero(self.Q == np.max(self.Q))
        return int(self.rng.choice(best_spots))

    def update(self, spot, catch):
        self.N[spot] += 1
        self.Q[spot] += (catch - self.Q[spot]) / self.N[spot]


class UCBAgent(Agent):
    """
        The Upper-Confidence-Bound (UCB) bandit agent from section 2.7 (Sutton and Barto, Chapter 2).

        How it chooses
        --------------
        It first chooses a spot that has not been tried yet.
        Otherwise, it chooses the shot with the highest UCB score:
            
            Q(a) + c * sqrt(log(t) / N(a))

        The score considers both the estimated reward
        and how often the spot has been selected.

        Memory
        ------
        q : list
            Estimated average reward for each fishing spot.
        counts : list
            Number of times each spot has been selected.
        t : int
            Total number of selections made so far.

        Parameters
        ----------
        n_spots : int
            Number of available fishing spots.
        c : float
            Controls the degree of exploration.

        The update() method updates the estimated reward after each catch,
        using the method from Section 2.4.
    """

    def __init__(self, n_spots=5, seed=None, c=2.0):
        super().__init__(n_spots, seed)
        self.c = c
        self.reset()

    def reset(self):
        self.Q = np.zeros(self.n_spots)
        self.N = np.zeros(self.n_spots, dtype=int)
        self.t = 0

    def choose(self):
        unvisited = np.flatnonzero(self.N == 0)

        if len(unvisited) > 0:
            return int(self.rng.choice(unvisited))

        scores = self.Q + self.c * np.sqrt(np.log(self.t + 1) / self.N)

        best_spots = np.flatnonzero(scores == np.max(scores))
        return int(self.rng.choice(best_spots))

    def update(self, spot, catch):
        self.t += 1
        self.N[spot] += 1
        self.Q[spot] += (catch - self.Q[spot]) / self.N[spot]


# Task 6 (optional): add your contextual agents below, as subclasses of
# ContextualAgent.


class LinearRegressionAgent(ContextualAgent):
    """Task 6: one linear regression per spot, used to choose where to fish.

    Model
    -----
    For each spot a, the catch is predicted from the morning conditions by

        catch ~ theta_a . phi(x),    phi(x) = [1, wind/40, waves/3, tide/2]

    (the conditions are divided by their maximum so that the three are on
    the same 0-to-1 scale). theta_a is the least-squares solution on the days
    spot a was fished, with a small ridge term so that it always exists:

        theta_a = A_a^-1 b_a,   A_a = ridge * I + sum phi phi^T,   b_a = sum catch * phi

    How it chooses
    --------------
    1. Warm-up. The first n_init * n_spots days, fish every spot n_init times
       (spot 0, 1, ..., 4, then again), so that every regression has data.
    2. Then fish the spot with the highest score

           score_a = theta_a . phi(x)  +  bonus * sqrt(phi(x)^T A_a^-1 phi(x))

       The first term is the predicted catch. The second term is the
       uncertainty of that prediction (large when spot a has few catches in
       conditions like today's), as in the UCB rule of Part III (LinUCB).
       bonus = 0 gives the agent that acts only on its predictions.

    Memory
    ------
    A : array (n_spots, 4, 4)     sum of phi phi^T per spot, plus ridge * I
    b : array (n_spots, 4)        sum of catch * phi per spot
    counts : array of n_spots     number of days each spot was fished

    Parameters
    ----------
    n_init : int
        Visits to each spot during the warm-up.
    bonus : float >= 0
        Weight of the uncertainty term (in kg). 0 = predictions only.
    ridge : float > 0
        Regularisation of the regressions.
    """

    SCALE = np.array([40.0, 3.0, 2.0])          # maximum wind (km/h), waves (m), tide (m)

    def __init__(self, n_spots=5, seed=None, n_init=5, bonus=0.0, ridge=1.0):
        super().__init__(n_spots=n_spots, seed=seed)
        self.n_init = n_init
        self.bonus = bonus
        self.ridge = ridge

    def features(self, x):
        """phi(x) = [1, wind/40, waves/3, tide/2]."""
        return np.concatenate(([1.0], np.asarray(x, dtype=float) / self.SCALE))

    def reset(self):
        d = 1 + len(self.SCALE)
        self.A = np.array([self.ridge * np.eye(d) for _ in range(self.n_spots)])
        self.b = np.zeros((self.n_spots, d))
        self.counts = np.zeros(self.n_spots, dtype=int)

    def predict(self, x):
        """Predicted catch (kg) at every spot for the conditions x."""
        phi = self.features(x)
        return np.array([np.linalg.solve(self.A[a], self.b[a]) @ phi for a in range(self.n_spots)])

    def choose(self, x):
        # 1. Warm-up: the first spot that has fewer than n_init catches.
        warm_up = np.flatnonzero(self.counts < self.n_init)
        if warm_up.size > 0:
            return int(warm_up[0])
        # 2. Predicted catch + bonus * uncertainty of the prediction.
        phi = self.features(x)
        score = self.predict(x)
        if self.bonus > 0:
            uncertainty = np.array([np.sqrt(phi @ np.linalg.solve(self.A[a], phi)) for a in range(self.n_spots)])
            score = score + self.bonus * uncertainty
        best = np.flatnonzero(score == score.max())
        return int(self.rng.choice(best))

    def update(self, x, spot, catch):
        phi = self.features(x)
        self.A[spot] += np.outer(phi, phi)
        self.b[spot] += catch * phi
        self.counts[spot] += 1


class NoContextAgent(ContextualAgent):
    """Plays a contextual bay with an agent of Part III, which ignores the conditions.

    Used to compare with the best agent of Part III on the same bays:
    NoContextAgent(UCBAgent(c=2, seed=0)).
    """

    def __init__(self, agent):
        super().__init__(n_spots=agent.n_spots)
        self.agent = agent

    def reset(self):
        self.agent.reset()

    def choose(self, x):
        return self.agent.choose()

    def update(self, x, spot, catch):
        self.agent.update(spot, catch)

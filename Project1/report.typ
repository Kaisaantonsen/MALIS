#set page(paper: "a4", margin: 2.5cm)
#set text(font: "New Computer Modern", size: 11pt)
#set par(justify: true)

#show figure: set block(breakable: true)
#set figure.caption(separator: [ --- ])

#let fig(img, caption: none, label: none, width: 80%) = {
  figure(
    image(img, width: width),
    caption: caption,
  )
  if label != none {
    label
  }
}

#align(center)[
  #text(size: 18pt, weight: "bold")[MALIS Project 1: Reinforcement Learning
  and Multi-Armed Bandits]
  #v(0.25em)
    #text(size: 11pt)[
      *Group 30*: Kaisa Gurine Antonsen, Synne Vineshaugen Raad, Fayad Toukourou
    ]
]
= Part II: Human play 
== Task 2
*Season 1*
\ Kaisa: For the first season, my fishing spots were random. I visited all the spots, and did not focus on a specific one. This matches my strategy note: "My decision on where to fish was totally random".\ 
\ Synne: I chose fishing spots quite randombly, but returned to the ones that gave the highest catches. My most visited spot was Old Pier. This matches my strategy note: "I chose a bit random, but I went back to the spots that gave me the most kg". Overall, I used a mix of exploration and exploitation.\ 
\ Fayad: I didn't have a set strategy beforehand. Sometimes, if the catch was good, I fished there again the next day, but if I caught a lot of fish, I also changed to another spot. My choices mostly match my strategy note: "I did not have any strategy, when I see that I did not caught a lot of fishes, I fish in the same spot the next day, and likewise, when I see that I caught lot of fishes at one spot, I change the spot".

\ 
*Season 2*
\ Kaisa: I fished mostly in the three spots further out at sea (Seagrass Bed, Deep Channel, Lighthouse Reef), and returned to Deep Channel the most as it gave the highest catch. This matches my strategy note, which was: "I decided to fish mostly on the three spots farest out in the sea, based on the feeling that I often got lighter catches by the land".\ 
\ Synne: First, I visited all the fishing spots. After that, I mainly switched between Rocky Point and Seagrass Bed, which both produced relatively high catches. My strategy note: "First I tried all the spots, then for the rest I chose the two spots which gave the most kg", matches my actual choices.\ 
\ Fayad: I did almost the same as in season 1. If the catch was high, I changed spot immediately, but if the catch was lower, I stayed longer. My strategy note was: "It was quite the same, I fish on the same spot multiple times when I see that I did not caught lot of fishes and change spot when I catch a lot at once", which my choices match. 

\ 
*Season 3*
\ Kaisa: I went back to making mostly random choices. I continuted switching between all five fishing spots and did not stick to one for very long. The same applied after day 16. The choices I made reflects my strategy note: "This round it was back to random decisions of fishing spots. This is because I did not see a pattern".\ 
\ Synne: I first visited all the spots. After getting a good catch, I sometimes returned to that spot. When the fishing conditions changed, I mainly chose Old Pier and Seagrass Bed. My strategy note "If a spot gave me a lot of fish, then I chose that same spot several times until it gave me a very low amount again", partially reflects my choices. However, I did end up switching mostly between Old Pier and Seagrass Bed.\ 
\ Fayad: I continued to use a strategy based on how much fish I caught. When I got a low catch, I sometimes went back to the same spot. If the catch didn't improve, I changed location for a while. If the catch was high, I sometimes revisited it once more before changing. My strategy note was: "When I fish at one spot and doesn't get lot of fishes, I continue to fish at the same spot. If it doesn't increase much the amount of fishes, I change the spot and come back later. If in a spot I caught lot of fishes, I fish once more and change spot". This makes sense in terms of the choices I made. 

\ 
*Abstracted team strategies*
- Random exploration: Choose fishing spots randomly, without prioritising specific locations.
- Exploration and exploitation: Test every fishing spot, then priortize those with the highest previous catches. 
- Catch-based switching: Base fishing decisions on previous catches, deciding whether to stay or switch locations.

\ 

== Task 3
*Cumulative pseudo-regret*

To evaluate decision quality independently of luck, we use cumulative pseudo-regret. This measures the difference between the expected catch from always choosing the best fishing spot and the expected catch from the spots actually selected by the player.

For each day, regret is calculated using the true mean catches rather than the observed catches. Therefore, random variations in the amount of fish caught do not directly affect the measure. Lower cumulative regret indicates better decisions, with zero regret corresponding to always selecting the optimal spot.

In Season 3, the mean catches change on day 16. We therefore use the true means corresponding to each day when calculating regret.

$
  R_T = sum_(t=1)^T (
    max_i mu_(i,t) - mu_(a_t,t)
  )
$

Here, $T$ is the number of days, $mu_(i,t)$ is the true mean catch at spot $i$ on day $t$, and $a_t$ is the spot selected by the player.


Interpretation:
- Low regret means the player consistently selected good fishing spots.
- High regret means the player often selected spots with lower expected catches.
- A regret of zero means the player always selected the best spot.

#pagebreak()
*Decision efficiency*

Cumulative pseudo-regret measures the total loss in reference expected catch, but it depends on the number of days in a season. Since Season 2 lasts only 10 days, compared with 30 days in Seasons 1 and 3, we also use decision efficiency to compare performance across seasons of different lengths.


$
  eta = frac(
    sum_(t=1)^T mu_(a_t, t),
    sum_(t=1)^T max_i mu_(i,t)
  ) times 100%
$

This measures how much of the optimal reference expected catch the player's decisions achieved.


*Luck*

Even if a player chooses a good spot, the actual catch may be low due to random variation. We define luck as:

$ L_T = sum_(t=1)^T (r_t - mu_(a_t, t)) $

Where $r_t$ is the actual observed catch at day $t$.

Interpretation:
- Positive luck means the player recieved a higher catch than the reference expectation.
- Negative luck means the actual catch was below the reference ecpectation.
- Luck of zero means the player received exactly the expected catch.

*Simulation Validation*

To demonstrate that our performance measure separates decision quality from luck, we simulated the same uniformly random strategy on 500 randomly generated bays for each season using `FishingBay`. For each simulation, we calculated the expected catch of the selected spots, the optimal expected catch, cumulative pseudo-regret, and luck.

Cumulative pseudo-regret depends on the hidden mean parameters rather than the observed catches, so it excludes direct reward noise. Across the 500 simulations, mean luck was close to zero (0.92, 0.34, and 1.02 kg for Seasons 1-3), while the standard deviations were 12.97, 7.58, and 13.20 kg. This demonstrates that actual catches can vary substantially even when the same strategy is used, supporting the use of pseudo-regret to evaluate decision quality separately from observed luck.


#let random-results = csv("random_results.csv", row-type: dictionary)

#let fmt(value, decimals: 1) = {
  let factor = calc.pow(10, decimals)
  let rounded = calc.round(float(value) * factor) / factor
  str(rounded)
}

#figure(
  text(size: 8pt)[
    #table(
      columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      align: center,
      inset: 6pt,
      stroke: 0.6pt + black,

      ..(
        ("Season", "Expected", "Optimal",
        "Efficiency", "Regret", "Mean luck", "Luck SD")
        .map(name => table.cell(
          fill: rgb("#9fb6c6"),
          text(weight: "bold", name)
        ))
      ),

      ..random-results.map(row => (
        [#row.at("Season")],
        [#fmt(row.at("Expected"))],
        [#fmt(row.at("Optimal"))],
        [#fmt(row.at("Efficiency (%)"), decimals: 2)%],
        [#fmt(row.at("Regret"))],
        [#fmt(row.at("Luck"))],
        [#fmt(row.at("Luck SD"))],
      )).flatten(),
    )
  ],
  caption: [Performance of a uniformly random strategy
    averaged over 500 simulated bays per season.
    All catch-related values are in kg.],
) <random-results>


#pagebreak()
*Human player performance*

#let results = csv("human_results.csv", row-type: dictionary)


// Convert student IDs to names
#let player-name(id) = {
  if id == "antonsen" { "Kaisa" }
  else if id == "raad" { "Synne" }
  else if id == "toukouro" { "Fayad" }
  else { id }
}

#figure(
  text(size: 8pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      align: center,
      inset: 5pt,
      stroke: 0.6pt + black,

      // Header
      ..(
        ("Player", "Season", "Actual", "Expected",
         "Optimal", "Efficiency", "Regret", "Luck")
        .map(name => table.cell(
          fill: rgb("#9fb6c6"),
          text(weight: "bold", name)
        ))
      ),

      // Generate all rows from CSV
      ..results.map(row => (
        [#player-name(row.at("Player"))],
        [#row.at("Season")],
        [#fmt(row.at("Actual"))],
        [#fmt(row.at("Expected"))],
        [#fmt(row.at("Optimal"))],
        [#fmt(row.at("Efficiency (%)"), decimals: 2)%],
        [#fmt(row.at("Regret"))],
        [#fmt(row.at("Luck"))],
      )).flatten(),
    )
  ],
  caption: [Human player performance across all three seasons.
    Catch, expected, optimal, regret and luck are measured in kg.],
) <human-results>



*Comparison across seasons*

In Season 2, the shorter 10-day horizon reduced the time available for exploration and exploitation. Kaisa shifted from random exploration to favoring offshore spots, while Fayad continued catch-based strategy. Synne adopted the clearest explore-then-exploit strategy, testing all five spots before concentrating on the two with the highest initial catches. Her decision efficiency increased from 60.14% in Season 1 to 76.46% in Season 2, whereas Kaisa's and Fayad's efficiencies decreased.

In Season 3, the hidden mean catches changed on day 16, potentially making previously learned information outdated. Kaisa continued selecting spots without a clear adaptation pattern, and her efficiency decreased from 80.72% before the change to 71.84% afterward. Synne gradually focused on Old Pier and Seagrass Bed, exclusively alternating between them from day 23, approximately seven days after the change. Fayad selected the new optimal spot, Deep Channel, on day 16 and repeatedly returned to it. His efficiency remained approximately 84% in both periods, although this does not prove that he immediately detected the change.

Overall, Synne showed the clearest behavioral adjustment to the shorter season and a gradual response to the environmental change. Fayad maintained the highest efficiency in Season 3, while Kaisa showed no clear systematic adaptation. Since each human played only one bay per season, these comparisons are descriptive rather than conclusive evidence of general strategy performance.



= Part III: Bandit algorithms 
== Task 4
=== Description of our agents\ 
*Human-Ruled Agent*\
This agent follows specific rules based on its catches. It switches spots after two low catches at the same spot (doesn't have to be consecutive), two high catches in a row, or when a catch between the thresholds is no better than the previous catch at that spot.

\
*Epsilon-Greedy Agent*\
Adapted from Sutton and Barto’s Reinforcement Learning. With probability ε, the agent chooses a spot at random. Otherwise, it chooses the spot with the highest estimated average catch. Ties are broken randomly.

\
*Upper Confidence Bound (UCB) Agent*\
The agent first tries every spot once. Then it chooses the spot with the highest UCB score:
$Q(a) + c * sqrt(log(t) / N(a))$
Here, $Q(a)$ is the estimated average catch for spot $a$, $N(a)$ is how often it has been selected, and $t$ is the total number of selections. The bonus encourages the agent to try spots that have been selected less.

\
== Task 5
*Random bayes*

We evaluated four agents on 1,000 randomly generated bays per season, using the same bay seeds to ensure fair comparisons. Performance was measured using cumulative pseudo-regret, where lower values indicate better decisions. @random-bays presents the mean regret and standard deviation.


#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    align: center,
    inset: 6pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[*Agent*],
      table.cell(fill: rgb("#9fb6c6"))[*Season 1*],
      table.cell(fill: rgb("#9fb6c6"))[*Season 2*],
      table.cell(fill: rgb("#9fb6c6"))[*Season 3*],
    ),

    [Random], [79.32 ± 29.86], [27.18 ± 11.25], [78.54 ± 21.47],
    [Human Rule], [78.86 ± 32.14], [26.38 ± 13.81], [79.08 ± 24.93],
    [ε-greedy], [55.14 ± 48.35], [24.16 ± 19.83], [66.13 ± 39.45],
    [*UCB*], [*25.06 ± 11.17*], [*17.12 ± 5.96*], [*43.23 ± 20.73*],
  ),
  caption: [Mean cumulative pseudo-regret ± standard deviation (kg) across 1,000 randomly generated bays per season. Lower values indicate better performance.],
) <random-bays>


UCB consistently achieved the lowest mean regret across all seasons, demonstrating an effective balance between exploration and exploitation. Its relatively low standard deviation also indicates more consistent performance. ε-greedy generally outperformed random selection but showed considerably greater variability. The human-inspired strategy performed similarly to the random baseline.

Season 2 had lower cumulative regret partly because it lasted only 10 days, compared with 30 days for the other seasons. Season 3 introduced changing reward distributions, making adaptation more challenging.

*Our team's bays*

We reconstructed the nine original fishing bays using FishingBay.from_log() and evaluated each agent under the same conditions as the human players. @team-bays compares their cumulative pseudo-regret.


#figure(
  text(size: 8pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr),
      align: center,
      inset: 4pt,
      stroke: 0.5pt + black,

      table.header(
        table.cell(fill: rgb("#9fb6c6"))[*Player*],
        table.cell(fill: rgb("#9fb6c6"))[*Season*],
        table.cell(fill: rgb("#9fb6c6"))[*Human*],
        table.cell(fill: rgb("#9fb6c6"))[*Random*],
        table.cell(fill: rgb("#9fb6c6"))[*Human Rule*],
        table.cell(fill: rgb("#9fb6c6"))[*ε-greedy*],
        table.cell(fill: rgb("#9fb6c6"))[*UCB*],
      ),

      [Kaisa], [1], [69.8], [74.0], [52.8], [50.4], [*22.6*],
      [Kaisa], [2], [29.3], [44.2], [50.4], [40.3], [*22.3*],
      [Kaisa], [3], [64.5], [46.2], [59.7], [95.6], [*36.2*],

      [Synne], [1], [110.0], [107.3], [102.5], [90.0], [*18.5*],
      [Synne], [2], [23.3], [50.0], [50.7], [78.0], [*16.7*],
      [Synne], [3], [74.4], [97.4], [104.5], [*48.0*], [49.6],

      [Fayad], [1], [50.6], [45.1], [50.7], [*6.4*], [22.5],
      [Fayad], [2], [*25.9*], [36.9], [51.4], [58.0], [31.7],
      [Fayad], [3], [40.4], [52.7], [53.0], [26.3], [*25.6*],
    )
  ],
  caption: [Cumulative pseudo-regret (kg) for human players and agents on the original fishing bays. Bold values indicate the lowest regret in each row.],
) <team-bays>


UCB outperformed the human players in eight of nine cases. The exception was Fayad in Season 2, where the human achieved 25.9 kg regret compared with UCB's 31.7 kg. ε-greedy performed particularly well on Fayad's Season 1 bay and Synne's Season 3 bay. Overall, UCB demonstrated the strongest performance, although individual results varied depending on the bay and random seed.


*Seasons 2 and 3*

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: center,
    inset: 5pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[*Agent*],
      table.cell(fill: rgb("#9fb6c6"))[*Season 2*],
      table.cell(fill: rgb("#9fb6c6"))[*Season 3*],
    ),

    [ε-greedy], [+7.0 ± 0.6], [+22.9 ± 1.2],
    [Human Rule], [+9.3 ± 0.4], [+35.9 ± 0.8],
    [Random], [+10.1 ± 0.3], [+35.3 ± 0.8],
  ),
  caption: [Extra cumulative pseudo-regret compared with UCB (kg), mean ± standard error over the same 1,000 bays. UCB: 17.1 kg in Season 2, 43.2 kg in Season 3.],
) <seasons-2-3>

Comparing each agent with UCB on the same bays, UCB is the best agent in both seasons (every difference exceeds 10 standard errors). In Season 2, UCB tries every spot once, then exploits the best average from day 6, while ε-greedy rarely leaves its first spot. In Season 3, UCB and ε-greedy fall to random level on day 16; UCB recovers faster because its exploration bonus grows for spots not visited recently. The human rule keeps no estimate per spot and stays at random level throughout.

*Parameter*

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center,
    inset: 5pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[*ε*],
      table.cell(fill: rgb("#9fb6c6"))[*0*],
      table.cell(fill: rgb("#9fb6c6"))[*0.05*],
      table.cell(fill: rgb("#9fb6c6"))[*0.1*],
      table.cell(fill: rgb("#9fb6c6"))[*0.2*],
      table.cell(fill: rgb("#9fb6c6"))[*0.3*],
      table.cell(fill: rgb("#9fb6c6"))[*0.5*],
    ),

    [Season 1], [78.0], [62.5], [55.1], [49.2], [*48.5*], [53.5],
    [Season 2], [26.2], [25.0], [24.2], [23.0], [*22.3*], [22.6],
    [Season 3], [78.7], [71.7], [66.1], [*60.4*], [60.8], [62.0],
  ),
  caption: [Mean cumulative pseudo-regret (kg) of ε-greedy over 1,000 bays per season. Bold: lowest regret.],
) <epsilon>

The regret of ε-greedy decreases up to ε = 0.2–0.3 in every season, then rises at 0.5. The optimum is high because the estimates start at zero: with ε = 0 the agent never leaves its first spot, so random days are its only way to explore. Even at its best, ε-greedy stays far behind UCB (48.5 vs 25.1 kg in Season 1).

= Part IV: Contextual bandits
== Task 6

#figure(
  text(size: 8pt)[
  #table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center,
    inset: 5pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[*`n_init`*],
      table.cell(fill: rgb("#9fb6c6"))[*Warm-up days*],
      table.cell(fill: rgb("#9fb6c6"))[*Mean regret (kg)*],
      table.cell(fill: rgb("#9fb6c6"))[*Mean efficiency*],
      table.cell(fill: rgb("#9fb6c6"))[*Worst bay*],
      table.cell(fill: rgb("#9fb6c6"))[*Bays below 80%*],
    ),

    [1], [5], [231.4], [92.0%], [36.4%], [8.5%],
    [2], [10], [142.7], [94.9%], [50.2%], [3.5%],
    [3], [15], [149.4], [94.8%], [62.0%], [2.5%],
    [*5*], [25], [166.4], [94.4%], [*85.4%*], [*0%*],
    [10], [50], [257.2], [91.4%], [83.4%], [0%],
    [20], [100], [456.7], [84.9%], [76.8%], [4.0%],
  )
  ],
  caption: [Regression agent acting only on its predictions after `n_init` visits per spot, over 200 contextual bays (300 days).],
) <n-init>

#figure(
  table(
    columns: (auto, 1fr, auto),
    align: center,
    inset: 5pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[**],
      table.cell(fill: rgb("#9fb6c6"))[*Days at spot 0 / 1 / 2 / 3 / 4*],
      table.cell(fill: rgb("#9fb6c6"))[*Efficiency*],
    ),

    [Days each spot is truly the best], [296 / 2 / 0 / 0 / 2], [–],
    [1 visit per spot], [1 / 4 / 3 / 1 / 291], [36.4%],
    [5 visits per spot], [280 / 5 / 5 / 5 / 5], [94.9%],
  ),
  caption: [Bay 156, where acting only on the predictions fails.],
) <bay-156>

#figure(
  text(size: 8pt)[
  #table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    align: center,
    inset: 5pt,
    stroke: 0.5pt + black,

    table.header(
      table.cell(fill: rgb("#9fb6c6"))[*Agent*],
      table.cell(fill: rgb("#9fb6c6"))[*Mean regret (kg)*],
      table.cell(fill: rgb("#9fb6c6"))[*Mean efficiency*],
      table.cell(fill: rgb("#9fb6c6"))[*Worst bay*],
      table.cell(fill: rgb("#9fb6c6"))[*Bays below 80%*],
    ),

    [Random], [1305.0], [57.1%], [29.8%], [100%],
    [UCB, no context (best of Part III)], [190.8], [93.1%], [70.0%], [6.0%],
    [Regression, 1 visit], [231.4], [92.0%], [36.4%], [8.5%],
    [*Regression, 5 visits (final)*], [*166.4*], [*94.4%*], [*85.4%*], [*0%*],
  )
  ],
  caption: [Comparison over 200 contextual bays.],
) <contextual>

Each spot's mean catch is linear in wind, waves and tide, with spot-specific weights, so we fit one linear regression per spot. The agent fishes every spot `n_init` times, then the spot with the highest predicted catch. Acting only on the predictions fails when the regressions start with too little data: with one visit per spot, 8.5% of the bays fall below 80% efficiency. In bay 156, the single catch at the best spot was low, so its prediction stayed low (about 1 kg instead of 9.2 kg) and the agent never returned to correct it. A wrong prediction confirms itself, because the agent only collects data where it already expects good catches. Our fix is 5 visits per spot: no bay falls below 80%, at the cost of 24 kg of mean regret compared with 2 visits. The final agent has 13% less regret than UCB and a much better worst case, but it never re-checks a spot after the warm-up.

= Team member contributions

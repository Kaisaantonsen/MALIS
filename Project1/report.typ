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

= Part IV: Contextual bandits
== Task 6

= Team member contributions

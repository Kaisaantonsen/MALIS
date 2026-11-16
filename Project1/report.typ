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
We chose the cumulative regret as our performance metric. The reasoning for this is that even though a player chooses a good fishing spot, due to random variation, might still receives a small catch. 

For each day:

$ R_t = max_i mu_i - mu_(a_t) $

Where:
- $mu_i$ is the true average catch at fishing spot $i$
- $a_t$ is the fishing spot chosen by the player on day $t$
- $max_i mu_i$ is the best possible average catch that day


The cumulative regret is:

$ R_T = sum_(t=1)^T R_t $

Interpretation:
- Low regret means the player consistently selected good fishing spots.
- High regret means the player often selected spots with lower expected catches.
- A regret of zero means the player always selected the best spot.




= Part III: Bandit algorithms 
== Task 4
== Task 5

= Part IV: Contextual bandits
== Task 6

= Team member contributions

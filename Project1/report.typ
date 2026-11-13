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
\ Kaisa: 
\ Synne: 
\ Fayad: 

*Season 2*
\ Kaisa: 
\ Synne: 
\ Fayad: 

*Season 3*
\ Kaisa: 
\ Synne:
\ Fayad: 

== Task 3 

= Part III: Bandit algorithms 
== Task 4
== Task 5

= Part IV: Contextual bandits
== Task 6

= Team member contributions

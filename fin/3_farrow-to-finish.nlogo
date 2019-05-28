breed [ sows sow ]
breed [ piglets piglet ]
breed [ pigs pig ]

globals [
  region-boundaries
  #-days
  #-infectedS
  #-infectedP
  #-totalS
  #-totalP
  #-deatha
  #-deathp
  #-not-infected-sold
  #-infected-sold
  #-piglets-litter
  percent1
  percent2
  percent3
  percent4
  percent5
  percent6
  percents
  farm-infected
]

turtles-own [
  my-sows
  susceptible
  infected
  recovered
  immuned
  dead
  preg-period
  be-pregnant
  breed-ready
  #-piglets
  breed-sow
  piglets-age
  this-sow
  sow-infected
]
patches-own [
  region
  countdown
]

to setup
  clear-all
  setup-regions
  setup-regions-pigs 6
  setup-sows
  set-default-shape turtles "pig"
  reset-ticks
  set #-days 0
  set #-infectedS 0
  set #-infectedP 0
  set #-totalS 5
  set #-totalP 0
  set #-deatha 0
  set #-deathp 0
  set #-not-infected-sold 0
  set #-infected-sold 0
  set #-piglets-litter 0
  set percent1 0
  set percent2 0
  set percent3 0
  set percent4 0
  set percent5 0
  set percent6 0
  set farm-infected false
end

to setup-regions
ask patches with [ pxcor != min-pxcor and pycor != max-pycor and pycor != min-pycor and pxcor != max-pxcor] [
    ;set region patches with [ pxcor != min-pxcor and pycor != max-pycor and pycor != min-pycor and pxcor != max-pxcor]
    set pcolor gray - 1
  ]
  ask patches with [ pycor = min-pycor or pxcor = min-pxcor or pxcor = max-pxcor or pxcor = -8 ] [
    set pcolor blue - 3
  ]
  ask patches with [ pycor = max-pycor ] [
    set pcolor red + 1
  ]
  ;set region-sow patches with [ pxcor < 0 ]
  ;set region-pigs patches with [ pxcor > 0 ]
end

to setup-regions-pigs [ num-regions ]
  ; First, draw some dividers at the intervals reported by `region-divisions`:
  foreach region-divisions num-regions draw-region-division
  ; Store our region definitions globally for faster access:
  set region-boundaries calculate-region-boundaries num-regions
  ; Set the `region` variable for all patches included in regions:
  let region-numbers (range 1 (num-regions + 1))
  (foreach region-boundaries region-numbers [ [boundaries region-number] ->
    ask patches with [ pxcor >= first boundaries and pxcor <= last boundaries ] [
      set region region-number
    ]
  ])
end

to-report calculate-region-boundaries [ num-regions ]
  ; The region definitions are built from the region divisions:
  let divisions region-divisions num-regions
  ; Each region definition lists the min-pxcor and max-pxcor of the region.
  ; To get those, we use `map` on two "shifted" copies of the division list,
  ; which allow us to scan through all pairs of dividers
  ; and built our list of definitions from those pairs:
  report (map [ [d1 d2] -> list (d1 + 1) (d2 - 1) ] (but-last divisions) (but-first divisions))
end

to-report region-divisions [ num-regions ]
  ; This procedure reports a list of pxcor that should be outside every region.
  ; Patches with these pxcor will act as "dividers" between regions.
  report n-values (num-regions + 1) [ n ->
    [ pxcor ] of patch ( -8 + (n * ((max-pxcor - -8) / num-regions))) 0
  ]
end

to draw-region-division [ x ]
  ; This procedure makes the division patches grey
  ; and draw a vertical line in the middle. This is
  ; arbitrary and could be modified to your liking.
  ask patches with [ pxcor = x ] [
    set pcolor blue - 3
  ]
  ask patches with [ pycor = max-pycor ] [
    set pcolor red + 1
  ]
  create-turtles 1 [
    ; use a temporary turtle to draw a line in the middle of our division
    setxy x max-pycor - 1
    set heading 0
    set color blue - 3
    pen-down
    forward world-height
    set xcor xcor + 1 / patch-size
    right 180
    set color blue + 3
    forward world-height
    die ; our turtle has done its job and is no longer needed
  ]
end


to setup-sows
  let region-sow patches with [ pxcor < -8 and pxcor > min-pxcor and pycor > min-pycor and pycor < max-pycor ]
  create-sows 5 [
    move-to one-of region-sow
    set size 5
    set color pink
    set susceptible true
    set infected false
    set recovered false
    set immuned false
    set dead false
    set breed-sow false
    set be-pregnant true
  ]

  ask turtles
  [if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
        set ycor min-pycor + 1 ] ]

              if auto-infect [
    ask sows with [ color = pink ] [
      if ( random 5 < 1 ) [
       infect ]
  ] ]
end

to go
  if any? turtles with [ infected ] [
    set farm-infected true ]
  if ( farm-infected ) [
  ask turtles [ move
  if ( infected ) [
      set color red ]
      pooping
      recover
    lose-immune
    death
    check-threshold
    if ( not immuned ) and ( not infected ) and ( pcolor = brown )
    [ if ( piglets-age <= 28 ) [             ;;70 days old
      if ( random 100 < transmission-rate-to-p ) [ infect ] ]
      if ( piglets-age > 28 ) [
        if ( random 100 < transmission-rate-a ) [ infect ] ] ]
    if ( recovered ) and ( immuned ) and ( pcolor = brown ) [
      set susceptible true
      set infected false
      set color pink ]
  ]
 ask sows with [ breed-sow = true and be-pregnant = false] [
    set color magenta + 3
    set preg-period preg-period + 1
    if ( infected ) [ pooping ]
    if ( preg-period = 120 )                ;;4 months gestation
    [ farrow-infected
      set breed-ready 0
      set be-pregnant false
   set breed-sow false ]
  ]
  ask sows with [ breed-sow = false and be-pregnant = false ] [
    set breed-ready breed-ready + 1
    if ( breed-ready = 30 )               ;;1 month after pregnancy
    [ set breed-sow false
   set be-pregnant true ]
  ]
  ask sows with [ not breed-sow ] [ set color pink ]
  ask piglets [
    set piglets-age piglets-age + 1
  if ( sow-infected = false ) [
      if ( piglets-age <= 7 ) [       ;7 days old
       if ( random 100 < 25 ) [
        if ( random 100 < 100 ) [ if ( infected ) [             ;death rate of suckling piglets 100%
        set #-deathp #-deathp + 1
            die ] ] ] ] ]
    if ( sow-infected = true ) [
      ifelse ( piglets-age <= 28 ) [ set susceptible false
        set infected false
          set immuned true
    set color pink ]
      [ set susceptible true
        set immuned false
      set infected false ]
    ]
  if ( piglets-age = 170 )                    ;;170 days old
    [ ifelse ( infected ) [ set #-infected-sold #-infected-sold + 1 ]
      [ set #-not-infected-sold #-not-infected-sold + 1 ]
      die ]
  ]
      ask piglets with [ piglets-age = 28 ]                 ;70 days old
      [ check-where-pigs-put ]
  ]

   if ( not farm-infected ) [
  ask turtles [ move ]
 ask sows with [ breed-sow = true and be-pregnant = false] [
    set color magenta + 3
    set preg-period preg-period + 1
    if ( preg-period = 120 )                ;;4 months gestation
    [ farrow
      set breed-ready 0
      set be-pregnant false
   set breed-sow false ]
  ]
  ask sows with [ breed-sow = false and be-pregnant = false ] [
    set breed-ready breed-ready + 1
    if ( breed-ready = 30 )               ;;1 month after pregnancy
    [ set breed-sow false
   set be-pregnant true ]
  ]
  ask sows with [ not breed-sow ] [ set color pink ]
  ask piglets [
    set piglets-age piglets-age + 1
      if ( piglets-age = 28 ) [ check-where-pigs-put ]
  if ( piglets-age = 170 )                    ;;170 days old
      [ set #-not-infected-sold #-not-infected-sold + 1
        die ] ]
  ]

  ask patches with [ pcolor = brown ] [
     ifelse countdown > duration
    [ set pcolor gray - 1
    set countdown 0]
    [ set countdown ( countdown + 1 ) ]
]
  if ( Clean = "Everyday" ) [ clean-region-everyday ]
  if ( Clean = "too-much-poop" ) [ clean-region ]
  if get-pregnant? [
  ask sows with [ breed-sow = false and be-pregnant = true ][
    if ( random 5 < 1 ) [ if ( random 7 < 1) [   ;1 week interval
      set color magenta + 3
        set breed-sow true
        set be-pregnant false
    set preg-period 0
    ]
  ] ] ]
  sell-piglet
  sell-adult
  tick
  update-time
  ;if not any? turtles [ stop ]
  if ( #-days = 365 ) [ stop ]
end

to update-time
  ; one tick = 1 hour in simulated time
  set #-days ticks
  set #-infectedS count sows with [ infected = true ]
  set #-infectedP count piglets with [ infected = true ]
  set #-totalS count sows
  set #-totalP count piglets
end

to move ; turtle procedure
  right random 30
  left random 30
  forward 0.4
  keep-in-region
      if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
      set ycor min-pycor + 1 ]
end

to check-where-pigs-put
  ifelse ( count piglets with [ region = 1 ] = 0 )
  [ ask piglets with [ piglets-age = 28 ] [                 ;70 days old
    move-to one-of patches with [ region = 1 ]
      set piglets-age 28                                     ;70 days old
      set size 3
  ] ]
  [ ifelse ( count piglets with [ region = 2 ] = 0 )
    [ ask piglets with [ piglets-age = 28 ] [
      move-to one-of patches with [ region = 2 ]
      set piglets-age 28
      set size 3
    ] ]
     [ ifelse ( count piglets with [ region = 3 ] = 0 )
    [ ask piglets with [ piglets-age = 28 ] [
        move-to one-of patches with [ region = 3 ]
      set piglets-age 28
      set size 3
      ] ]
      [ ifelse ( count piglets with [ region = 4 ] = 0 )
    [ ask piglets with [ piglets-age = 28 ] [
        move-to one-of patches with [ region = 4 ]
      set piglets-age 28
      set size 3
        ] ]
        [ ifelse ( count piglets with [ region = 5 ] = 0 )
    [ ask piglets with [ piglets-age = 28 ] [
        move-to one-of patches with [ region = 5 ]
      set piglets-age 28
      set size 3
          ] ]
        [ ifelse ( count piglets with [ region = 6 ] = 0 )
    [ ask piglets with [ piglets-age = 28 ] [
        move-to one-of patches with [ region = 6 ]
      set piglets-age 28
      set size 3
            ] ]
            [ show "Where put?" ] ] ] ] ] ]
end

to-report empty-region
  ifelse ( count piglets with [ region = 1 ] = 0 )
  [ report ( region = 1 ) ]
  [ ifelse ( count piglets with [ region = 2 ] = 0 )
    [ report ( region = 2 ) ]
   [ ifelse ( count piglets with [ region = 3 ] = 0 )
    [ report ( region = 3 ) ]
      [ ask piglets-here [show "Successfully put"]
      report ( region = 4 ) ]
    ]
    ]
end

to get-pregnant
  ask sows with [ breed-sow = false and be-pregnant = true ] [ if ( random 5 < 1 )
  [ set breed-sow true
      set be-pregnant false
set color magenta + 3
set preg-period 0  ] ]
end

to farrow-infected
          ifelse ( infected ) [
      hatch-piglets litter [
      set color pink
      set size 2
      set susceptible false
      set infected false
      set recovered false
      set immuned true
      set dead false
      set piglets-age 0
      set sow-infected true
      set #-piglets-litter #-piglets-litter + 1
  ]  ]
          [ hatch-piglets litter [
      set color red
      set size 2
      set susceptible false
      set infected true
      set recovered false
      set immuned false
      set dead false
      set piglets-age 0
    set sow-infected false
    set #-piglets-litter #-piglets-litter + 1
          ] ]
end

to farrow
     hatch-piglets litter [
      set color pink
      set size 2
      set susceptible true
      set infected false
      set recovered false
      set immuned false
      set dead false
      set piglets-age 0
    set sow-infected false
    set #-piglets-litter #-piglets-litter + 1
          ]
end

to-report litter
  report random-poisson 11
end

to clean-region
  (foreach (range 1 (length region-boundaries + 1)) [ region-number ->
  let region-patches patches with [ region = region-number ]
  if ( ( count region-patches with [ pcolor = brown ] ) > count region-patches with [ pcolor = gray - 1 ] ) [
   ask region-patches [set pcolor gray - 1 ]
    ask patches with [ pycor = max-pycor ] [
    set pcolor red + 1
  ]
    ask patches with [ pycor = min-pycor ] [
    set pcolor blue - 3
  ] ] ] )
  let region-sow patches with [ pxcor < -8 and pxcor > min-pxcor and pycor > min-pycor and pycor < max-pycor ]
  if ( count region-sow with [ pcolor = brown ] > count region-sow with [ pcolor = gray - 1 ] ) [
        ask region-sow [set pcolor gray - 1 ] ]
end

to clean-region-everyday
  (foreach (range 1 (length region-boundaries + 1)) [ region-number ->
  let region-patches patches with [ region = region-number ]
  if ( ( ticks mod 1 ) = 0 ) [
   ask region-patches [set pcolor gray - 1 ]
    ask patches with [ pycor = max-pycor ] [
    set pcolor red + 1
  ]
    ask patches with [ pycor = min-pycor ] [
    set pcolor blue - 3
  ] ] ] )
  let region-sow patches with [ pxcor < -8 and pxcor > min-pxcor and pycor > min-pycor and pycor < max-pycor ]
  if ( ( ticks mod 1 ) = 0 ) [
        ask region-sow [set pcolor gray - 1 ] ]
end

to pooping
  ask sows with [ infected ] [
    if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
      set ycor min-pycor + 1 ]
  ask ( patch-set patch-here neighbors ) with [ pcolor = gray - 1 ] [ if ( random 100 < virus-shed-a ) [
    let this-patch patch-set neighbors
    set pcolor brown
    set countdown 0
     ]
  ] ]
  ask piglets with [ infected ] [
    if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
      set ycor min-pycor + 1 ]
    ifelse ( piglets-age > 28 ) [
    ask ( patch-set patch-here neighbors ) with [ pcolor = gray - 1 ] [ if ( random 100 < virus-shed-a ) [
    let this-patch self
    set pcolor brown
    set countdown 0
    ] ] ]
    [
      ask ( patch-set patch-here ) with [ pcolor = gray - 1 ] [ if ( random 100 < virus-shed-p ) [
    let this-patch self
    set pcolor brown
    set countdown 0
    ] ]
  ] ]
end

to sell-piglet
  if ( random 100 < selling-rate-p ) [ if any? piglets with [ piglets-age <= 28 ] [
    ask one-of piglets with [ piglets-age <= 28 ] [
      ifelse ( infected ) [
        set #-infected-sold #-infected-sold + 1 ]
      [ set #-not-infected-sold #-not-infected-sold + 1 ]
      die ] ] ]
end

to sell-adult
  if ( random 100 < selling-rate-a ) [ if any? piglets with [ piglets-age > 28 ] [
    ask one-of piglets with [ piglets-age > 28 ] [
      ifelse ( infected ) [
        set #-infected-sold #-infected-sold + 1 ]
      [ set #-not-infected-sold #-not-infected-sold + 1 ]
      die ] ] ]
end

to infect
      if ( susceptible ) and ( not immuned ) and ( not infected ) and ( not recovered )
  [
    set susceptible false
        set immuned false
        set infected true
        set recovered false
    set color red
]
end

to check-threshold
  ;if any? turtles with [ infected ] [
    let threshold-rate 1
  let region-sow patches with [ pxcor < -8 and pxcor > min-pxcor and pycor > min-pycor and pycor < max-pycor ]
    ;let threshold-rate 50
    let infP1 count turtles with [ infected and region = 1]
    let totP1 count turtles with [region = 1]
    ifelse (totP1 != 0) [
      set percent1 ( ( infP1 / totP1 ) * 100 ) ] [ set percent1 0 ]
    if ( percent1 > threshold-rate ) [
    if any? turtles with [ region = 2 ] [
      infect-other 2 ]
  ]

    let infP2 count turtles with [ infected and region = 2]
    let totP2 count turtles with [region = 2]
    ifelse (totP2 != 0) [
      set percent2 ( ( infP2 / totP2 ) * 100 ) ] [ set percent2 0 ]
     if ( percent2 > threshold-rate ) [
      if any? turtles with [ region = 1 ] [
      infect-other 1 ]
        if any? turtles with [ region = 3 ] [
          infect-other 3 ]
    ]
    let infP3 count turtles with [ infected and region = 3]
    let totP3 count turtles with [region = 3]
    ifelse (totP3 != 0) [
      set percent3 ( ( infP3 / totP3 ) * 100 ) ] [set percent3 0 ]
    if ( percent3 > threshold-rate ) [
          if any? turtles with [ region = 2 ] [
      infect-other 2 ]
            if any? turtles with [ region = 4 ] [
              infect-other 4 ]
  ]
  let infP4 count turtles with [ infected and region = 4]
    let totP4 count turtles with [region = 4]
    ifelse (totP4 != 0) [
      set percent4 ( ( infP4 / totP4 ) * 100 ) ] [set percent4 0 ]
    if ( percent4 > threshold-rate ) [
              if any? turtles with [ region = 3 ] [
      infect-other 3 ]
                if any? turtles with [ region = 5 ] [
      infect-other 5 ] ]

  let infP5 count turtles with [ infected and region = 5]
    let totP5 count turtles with [region = 5]
    ifelse (totP5 != 0) [
      set percent5 ( ( infP5 / totP5 ) * 100 ) ] [set percent5 0 ]
    if ( percent5 > threshold-rate ) [
                  if any? turtles with [ region = 4 ] [
      infect-other 4 ]
                    if any? turtles with [ region = 6 ] [
      infect-other 6] ]

  let infP6 count turtles with [ infected and region = 6]
    let totP6 count turtles with [region = 6]
    ifelse (totP6 != 0) [
      set percent1 ( ( infP6 / totP6 ) * 100 ) ] [set percent6 0 ]
    if ( percent1 > threshold-rate ) [
                      if any? turtles with [ region = 5 ] [
      infect-other 5 ] ]

  let infs count turtles with [ infected and patches = region-sow ]
    let tots count turtles with [ patches = region-sow]
    ifelse (tots != 0) [
      set percents ( ( infs / tots ) * 100 ) ] [set percents 0 ]
    if ( percents > threshold-rate ) [
    ifelse any? turtles with [ region = 1 ] [
      infect-other 1 ]
    [ ifelse any? turtles with [ region = 2 ] [
      infect-other 2 ] [
    ifelse any? turtles with [ region = 3 ] [
        infect-other 3 ] [
    ifelse any? turtles with [ region = 4 ] [
          infect-other 4 ] [
    ifelse any? turtles with [ region = 5 ] [
            infect-other 5 ] [
    if any? turtles with [ region = 6 ] [
              infect-other 6 ] ] ] ] ] ]
  ]
  ;]
end

to infect-other [ region-# ]
  if ( region = region-# ) [
  if any? piglets-here
    [ ask one-of piglets-here  [
      if ( susceptible ) and ( not immuned ) and ( not infected ) and ( random 100 < P ) [     ;probability of transfer
     set susceptible false
        set immuned false
        set infected true
        set recovered false
    set color red
  ] ]
  ] ]
end

to recover
 if ( infected = true ) [
    ;if ( random 10 < 1 ) [
    if ( random 100 < recovery ) [
      set recovered true
      set infected false
      set color pink
      set immuned true
      set susceptible false
    ] ]
;  ]
end

to lose-immune
    if ( infected = false and immuned = true) [
    if ( piglets-age > 28 ) [
    if ( random 100 < lose-immunity-a ) [
        set recovered false
        set infected false
        set color pink
       set immuned false
        set susceptible true ]
    ]
  if ( turtles = sows ) [
      if ( random 100 < lose-immunity-s ) [
        set recovered false
        set infected false
        set color pink
       set immuned false
        set susceptible true ]
  ]
  ]
end

to death
  ask piglets with [ infected = true ]
    [ if ( random 7 < 1 ) [
    if ( random 100 < death-rate-a ) [
      set #-deatha #-deatha + 1
        set dead true
      die]
  ] ]
end

to put-sows
  let region-sow patches with [ pxcor < -8 and pxcor > min-pxcor and pycor > min-pycor and pycor < max-pycor ]
    create-sows Additional-sows [
      move-to one-of region-sow
      set color pink
      set size 5
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
    set breed-sow false
    set be-pregnant true
  ]
end

to put-pigs
  create-piglets Additional-pigs [
    move-to one-of patches with [ region = in-region ]
    set color pink
      set size 3
      set susceptible true
      set infected false
      set recovered false
      set immuned false
      set dead false
    set piglets-age 28
  ]
end

to keep-in-region
 if ( pxcor < -8 ) [
  ifelse xcor < min-pxcor + 1 [
    set xcor min-pxcor + 1 ] [
    if xcor > -9 [
      set xcor -9 ] ]
  ]
  (foreach (range 1 (length region-boundaries + 1)) [ region-number ->
  if region = region-number [
    ; Get our region boundaries from the global region list:
    let region-min-pxcor first item (region-number - 1) region-boundaries
    let region-max-pxcor last item (region-number - 1) region-boundaries
    ; The total width is (min - max) + 1 because `pxcor`s are in the middle of patches:
    let region-width (region-max-pxcor - region-min-pxcor) + 1
    ifelse xcor < region-min-pxcor [
      set xcor region-min-pxcor
    ]  [
      if xcor > region-max-pxcor [
        set xcor region-max-pxcor
      ]
    ]
  ] ] )


end
@#$#@#$#@
GRAPHICS-WINDOW
222
10
1023
240
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-30
30
-8
8
0
0
1
ticks
30.0

BUTTON
108
10
163
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
209
299
311
332
auto-infect
auto-infect
1
1
-1000

BUTTON
165
10
220
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
10
105
43
duration
duration
0
30
15.0
1
1
days
HORIZONTAL

SLIDER
4
191
107
224
recovery
recovery
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
102
83
219
116
lose-immunity-a
lose-immunity-a
0
100
2.0
1
1
%
HORIZONTAL

MONITOR
525
242
582
287
P in S1
count piglets with [region = 1]
17
1
11

MONITOR
592
243
649
288
P in S2
count piglets with [region = 2]
17
1
11

MONITOR
222
246
279
291
days
#-days
17
1
11

MONITOR
378
246
440
291
# piglets
count piglets
2
1
11

MONITOR
678
244
735
289
P in S3
count piglets with [region = 3]
17
1
11

BUTTON
242
333
311
366
Initial infect
if ( random 5 < 1 ) [ infect ]
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

PLOT
323
347
936
505
Piglet Population
Time (days)
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected piglets" 1.0 0 -2674135 true "" "plot count piglets with [piglets-age <= 28 and infected = true]"
"Suscep piglets" 1.0 0 -13345367 true "" "plot count piglets with [piglets-age > 28 and infected = false]"
"Dead piglets" 1.0 0 -16777216 true "" "plot #-deathp"

MONITOR
281
247
376
292
Pregnant sows
count sows with [ breed-sow = true ]
17
1
11

MONITOR
753
293
810
338
Death
#-deathp + #-deatha
17
1
11

MONITOR
522
292
628
337
Sold infected
#-infected-sold
17
1
11

MONITOR
636
293
742
338
Sold not infected
#-not-infected-sold
17
1
11

MONITOR
763
243
820
288
P in S4
count piglets with [region = 4]
17
1
11

MONITOR
842
243
899
288
P in S5
count piglets with [region = 5]
17
1
11

MONITOR
930
243
987
288
P in S6
count piglets with [region = 6]
17
1
11

MONITOR
443
244
513
289
Total piglets
#-piglets-litter
17
1
11

SLIDER
6
84
98
117
P
P
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
5
119
111
152
virus-shed-p
virus-shed-p
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
4
154
111
187
virus-shed-a
virus-shed-a
0
100
70.0
1
1
%
HORIZONTAL

SLIDER
2
263
155
296
transmission-rate-to-p
transmission-rate-to-p
0
100
85.0
1
1
%
HORIZONTAL

SLIDER
1
229
140
262
transmission-rate-a
transmission-rate-a
0
100
75.0
1
1
%
HORIZONTAL

BUTTON
103
350
185
383
NIL
put-sows
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
2
334
102
394
Additional-sows
4.0
1
0
Number

BUTTON
204
410
281
443
NIL
put-pigs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
102
396
200
456
in-region
5.0
1
0
Number

INPUTBOX
2
396
96
456
Additional-pigs
10.0
1
0
Number

BUTTON
123
299
203
332
NIL
get-pregnant
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
2
299
119
332
get-pregnant?
get-pregnant?
0
1
-1000

PLOT
11
509
701
659
Adult Population
Time (days)
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Suscep Adults" 1.0 0 -13345367 true "" "plot count piglets with [piglets-age > 28 and infected = false] + count sows with [infected = false]"
"Infected Adults" 1.0 0 -2674135 true "" "plot count piglets with [piglets-age > 28 and infected = true] + count sows with [infected = true]"
"Dead Adults" 1.0 0 -16777216 true "" "plot #-deatha"

CHOOSER
127
189
219
234
Clean
Clean
"off" "Everyday" "too-much-poop"
0

SLIDER
103
47
218
80
lose-immunity-s
lose-immunity-s
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
113
118
218
151
selling-rate-p
selling-rate-p
0
100
2.0
1
1
%
HORIZONTAL

SLIDER
114
154
218
187
selling-rate-a
selling-rate-a
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
1
47
104
80
death-rate-a
death-rate-a
0
100
1.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

pig
true
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148
Circle -7500403 true true 105 25 90
Circle -7500403 true true 129 9 42
Polygon -7500403 true true 210 30 195 60 180 45
Polygon -7500403 true true 90 30 105 60 120 45
Circle -7500403 true true 72 119 156
Polygon -7500403 true true 165 255 180 285 165 300 150 300 135 285 135 270 150 270 150 285 165 285 165 270 165 255

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

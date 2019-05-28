breed [ pigs pig ]
globals [
  region-boundaries ; a list of regions definitions, where each region is a list of its min pxcor and max pxcor
  #-days
  #-infectedP
  #-in-regionP
  #-deaths
  percent1
  percent2
  percent3
  percent4
  percent5
  #-infected-sold
  #-not-infected-sold
]

patches-own [
  region ; the number of the region that the patch is in, patches outside all regions have region = 0
  countdown
  empty
]

turtles-own
[
  my-pig
  susceptible
  infected
  recovered
  immuned
  dead
  pigs-age
]

to setup
  clear-all
  setup-regions 5
  color-regions
  setup-initial-pigs
  set-default-shape pigs "pig"
  reset-ticks
  set #-days 0
  set #-not-infected-sold 0
  set #-infected-sold 0
  set #-deaths 0
end

to color-regions
  ; The patches with region = 0 act as dividers and are
  ; not part of any region. All other patches get colored
  ; according to the region they're in.
  ask patches with [ region != 0 and pycor != max-pycor and pycor != min-pycor] [
    set pcolor gray - 1
  ]
  ask patches with [ pycor = min-pycor ] [
    set pcolor blue - 3
 ;;   set plabel-color pcolor + 1
   ; set plabel region
  ]
end

to setup-initial-pigs
  ; This procedure simply creates turtles in the different regions.
  ; The `foreach` pattern shown can be used whenever you
  ; need to do something for each different region.
  let init#-per-region ( list pig-R1 pig-R2 pig-R3 pig-R4 pig-R5 )
  (foreach (range 1 (length region-boundaries + 1)) init#-per-region [ [ region-number n ] ->
    let region-patches patches with [ region = region-number ]
    ask region-patches [ set empty false ]
    create-pigs n [
      move-to one-of region-patches
      set color pink
      set size 3
      set susceptible true
      set infected false
      set recovered false
      set immuned false
      set dead false
      set pigs-age 28  ;28 days old
    ]
    ]
  )
  ask pigs
  [if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
        set ycor min-pycor + 1 ] ]

              if auto-infect [
    let infected-region random 4
    ask pigs [ if any? pigs with [ color = pink ]
      [ infect infected-region ]
] ]

end

to go
  ask pigs [ move
    set pigs-age pigs-age + 1
  if ( infected = true ) [ pooping
      recover
    death ]
    lose-immune
    if ( not immuned ) and ( not infected ) and ( pcolor = brown )
    [ if ( pigs-age > 28 ) [
      if ( random 100 < transmission-rate-a ) [
   set susceptible false
   set infected true
   set immuned false
   set recovered false
   set color red ] ] ]
    if ( recovered ) and ( immuned ) and ( pcolor = brown ) [
      set susceptible true
      set infected false
      set color pink ]
  check-threshold
  if ( pigs-age = 170 )  ;170 days old
    [ ifelse ( infected )
      [ set #-infected-sold #-infected-sold + 1 ]
      [ set #-not-infected-sold #-not-infected-sold + 1 ]
      die ]
  ]
  ask patches with [ pcolor = brown ] [
     ifelse countdown > duration
    [ set pcolor gray - 1
    set countdown 0]
    [ set countdown ( countdown + 1 ) ]
]
   if ( Clean = "Everyday" ) [ clean-region-everyday ]
  if ( Clean = "too-much-poop" ) [ clean-region ]
  if put-pigs?
  [ put-pigs ]
buy-pig
  sell-pig
  tick
  update-time
  ;if not any? pigs with [ susceptible ] [ stop ]
  if ( #-days = 365 ) [ stop ]
end

to update-time
  set #-days ticks
end

to move ; turtle procedure

  ; Turtles will move differently in different models, but
  ; the general pattern shown here should be applied for all
  ; movements of turtles that need to stay in a specific region.

  ; First, save the region that the turtle is currently in:
  let current-region region
  ; Then, after saving the region, we can move the turtle:
  right random 30
  left random 30
  forward 0.4
  ; Finally, after moving, make sure the turtle
  ; stays in the region it was in before:
  keep-in-region current-region

;ask turtles
  if ycor > max-pycor - 1 [
      set ycor max-pycor - 1 ]
      if ycor < min-pycor + 1 [
      set ycor min-pycor + 1 ]

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
end

to pooping
  ask pigs with [ infected ] [
    ifelse ( pigs-age > 28 ) [  ;70 days old
    ask ( patch-set patch-here neighbors ) with [ pcolor = gray - 1 ] [ if ( random 100 < virus-shed-a ) [
    let this-patch self
    set pcolor brown
    set countdown 0
    ] ] ]
    [
      ask ( patch-set patch-here ) with [ pcolor = gray - 1 ] [ if ( random 100 < 65 ) [
    let this-patch self
    set pcolor brown
    set countdown 0
    ] ]
  ] ]
end

to setup-regions [ num-regions ]
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

to check-threshold
  ;let threshold-rate 50
  ;if any? turtles with [ infected ] [
    let threshold-rate 1
    set #-infectedP count pigs with [ infected and region = 1]
    set #-in-regionP count pigs with [region = 1]
    ifelse (#-in-regionP != 0) [
      set percent1 ( ( #-infectedP / #-in-regionP ) * 100 ) ] [ set percent1 0 ]
    if ( percent1 > threshold-rate ) [
    infect-other 2 ]


    set #-infectedP count pigs with [ infected and region = 2]
    set #-in-regionP count pigs with [region = 2]
    ifelse (#-in-regionP != 0) [
      set percent2 ( ( #-infectedP / #-in-regionP ) * 100 ) ] [ set percent2 0 ]
     if ( percent2 > threshold-rate ) [
      infect-other 1
    infect-other 3 ]

    set #-infectedP count pigs with [ infected and region = 3]
    set #-in-regionP count pigs with [region = 3]
    ifelse (#-in-regionP != 0) [
      set percent3 ( ( #-infectedP / #-in-regionP ) * 100 ) ] [set percent3 0 ]
    if ( percent3 > threshold-rate ) [
      infect-other 2
    infect-other 4 ]

  set #-infectedP count pigs with [ infected and region = 4]
    set #-in-regionP count pigs with [region = 4]
    ifelse (#-in-regionP != 0) [
      set percent4 ( ( #-infectedP / #-in-regionP ) * 100 ) ] [set percent4 0 ]
    if ( percent4 > threshold-rate ) [
      infect-other 3
    infect-other 5 ]

  set #-infectedP count pigs with [ infected and region = 5]
    set #-in-regionP count pigs with [region = 5]
    ifelse (#-in-regionP != 0) [
      set percent5 ( ( #-infectedP / #-in-regionP ) * 100 ) ] [set percent5 0 ]
    if ( percent5 > threshold-rate ) [
    infect-other 4 ]
  ;]
end

to infect [ region-# ]
  if ( region = region-# )
    [ ask one-of pigs-here  [
      if ( susceptible ) and ( not immuned ) and ( not infected ) and ( random 100 < 10 ) [
        set susceptible false
        set immuned false
        set infected true
        set recovered false
        set color red
  ] ]
  ]
end

to infect-other [ region-# ]
  if ( region = region-# )
    [ ask one-of pigs-here  [
      if ( susceptible ) and ( not immuned ) and ( not infected ) and ( random 100 < P ) [
         set susceptible false
        set immuned false
        set infected true
        set recovered false
        set color red
  ] ]
  ]
end

to buy-pig
;  let region-numb random 5
  if ( random 100 < buying-rate ) [
    create-pigs 1 [
    move-to one-of patches with [ region = 5 ]
    set size 3
    set color pink
    set susceptible true
    set infected false
    set recovered false
    set immuned false
    set dead false
      set pigs-age 28
  ] ]
end

to sell-pig
  if ( random 100 < selling-rate ) [ if any? pigs [
    ask one-of pigs [
      ifelse ( infected ) [
        set #-infected-sold #-infected-sold + 1 ]
      [ set #-not-infected-sold #-not-infected-sold + 1 ]
      die ]
  ] ]
end

to recover
  ask pigs [ if ( infected = true ) [
    if ( random 100 < recovery ) [
      set susceptible false
      set recovered true
      set infected false
      set color pink
      set immuned true
    ]
  ] ]
end

to lose-immune
  ask pigs [
    if ( infected = false ) [
    if ( random 100 < lose-immunity ) [
      if ( pcolor = brown ) [
        set recovered false
        set infected false
        set color pink
       set immuned false
        set susceptible true ]
    ]
    ]
  ]
end

to death
  ask pigs with [ infected = true ] [
    if ( random 7 < 1 ) [
    if ( random 100 < death-rate ) [
      set dead true
      set #-deaths #-deaths + 1
      die ]
  ] ]
end

to put-pigs
  ifelse ( count pigs with [ region = 1 ] = 0 )
  [ ;if (region-# = 1) [ let n pig-R1
    create-pigs Add-pigs-in-vacant-region [
      move-to one-of patches with [ region = 1 ]
      set color pink
      set size 3
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
      set pigs-age 28
  ] ]
  [ ifelse ( count pigs with [ region = 2 ] = 0 )
    [ ;if (region-# = 1) [ let n pig-R1
    create-pigs Add-pigs-in-vacant-region [
      move-to one-of patches with [ region = 2 ]
      set color pink
      set size 3
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
      set pigs-age 28
    ] ]
     [ ifelse ( count pigs with [ region = 3 ] = 0 )
    [ ;if (region-# = 1) [ let n pig-R1
    create-pigs Add-pigs-in-vacant-region [
      move-to one-of patches with [ region = 3 ]
      set color pink
      set size 3
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
      set pigs-age 28
    ] ]
         [ ifelse ( count pigs with [ region = 4 ] = 0 )
    [ ;if (region-# = 1) [ let n pig-R1
    create-pigs Add-pigs-in-vacant-region [
      move-to one-of patches with [ region = 4 ]
      set color pink
      set size 3
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
      set pigs-age 28
    ] ]
             [ ifelse ( count pigs with [ region = 5 ] = 0 )
    [ ;if (region-# = 1) [ let n pig-R1
    create-pigs Add-pigs-in-vacant-region [
      move-to one-of patches with [ region = 5 ]
      set color pink
      set size 3
      set infected false
      set susceptible true
      set immuned false
      set recovered false
      set dead false
      set pigs-age 28
    ] ]
          [ show "Cannot put pigs" ] ]
      ] ]
  ]
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
    [ pxcor ] of patch (min-pxcor + (n * ((max-pxcor - min-pxcor) / num-regions))) 0
  ]
end

to draw-region-division [ x ]
  ; This procedure makes the division patches grey
  ; and draw a vertical line in the middle. This is
  ; arbitrary and could be modified to your liking.
  ask patches with [ pxcor = x ] [
    set pcolor blue + 1.5
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

to keep-in-region [ which-region ] ; turtle procedure
  ; This is the procedure that make sure that turtles don't leave the region they're
  ; supposed to be in. It is your responsibility to call this whenever a turtle moves.
  if region != which-region [
    ; Get our region boundaries from the global region list:
    let region-min-pxcor first item (which-region - 1) region-boundaries
    let region-max-pxcor last item (which-region - 1) region-boundaries
    ; The total width is (min - max) + 1 because `pxcor`s are in the middle of patches:
    let region-width (region-max-pxcor - region-min-pxcor) + 1
    ifelse xcor < region-min-pxcor [
      set xcor region-min-pxcor
    ]  [
      if xcor > region-max-pxcor [
        set xcor region-max-pxcor
      ]
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
518
10
1141
274
-1
-1
15.0
1
10
1
1
1
0
1
0
1
-20
20
-8
8
0
0
1
ticks
30.0

BUTTON
4
10
67
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

SLIDER
5
120
97
153
pig-R1
pig-R1
0
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
203
98
236
pig-R3
pig-R3
0
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
162
98
195
pig-R2
pig-R2
0
15
5.0
1
1
NIL
HORIZONTAL

BUTTON
68
10
131
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

BUTTON
4
45
59
78
infect R1
infect 1
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
0

BUTTON
63
45
118
78
infect R2
infect 2
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
0

BUTTON
120
54
175
87
infect R3
infect 3
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
0

PLOT
453
281
1112
516
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
"Infected pigs" 1.0 0 -2674135 true "" "plot count pigs with [infected = true]\n"
"Suscep pigs" 1.0 0 -13345367 true "" "plot count pigs with [infected = false]"
"Dead pigs" 1.0 0 -16777216 true "" "plot #-deaths"

SLIDER
103
159
195
192
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
102
197
194
230
Recovery
Recovery
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
103
236
200
269
death-rate
death-rate
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
103
273
208
306
lose-immunity
lose-immunity
0
100
2.0
1
1
%
HORIZONTAL

MONITOR
404
10
499
55
R1 percentage
count pigs with [ region = 1 and infected ] / count pigs with [ region = 1 ]
3
1
11

MONITOR
150
10
212
55
# of days
#-days
1
1
11

MONITOR
405
121
500
166
R3 percentage
count pigs with [ region = 3 and infected ] / count pigs with [ region = 3 ]
3
1
11

MONITOR
298
10
400
55
# infected in R1
count pigs with [ region = 1 and infected ]
17
1
11

MONITOR
223
10
295
55
Total # R1
count pigs with [ region = 1 ]
17
1
11

MONITOR
222
64
294
109
Total # R2
count pigs with [ region = 2 ]
17
1
11

MONITOR
298
65
400
110
# infected in R2
count pigs with [ region = 2 and infected ]
17
1
11

MONITOR
405
67
500
112
R2 percentage
count pigs with [ region = 2 and infected ] / count pigs with [ region = 2 ]
3
1
11

MONITOR
224
116
296
161
Total # R3
count pigs with [ region = 3 ]
17
1
11

MONITOR
299
118
401
163
# infected in R3
count pigs with [ region = 3 and infected ]
17
1
11

BUTTON
120
88
185
121
Add pigs
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

SLIDER
7
245
99
278
pig-R4
pig-R4
0
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
288
98
321
pig-R5
pig-R5
0
15
0.0
1
1
NIL
HORIZONTAL

BUTTON
4
81
59
114
infect R4
infect 4\n
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
0

BUTTON
62
82
117
115
infect R5
infect 5
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
0

MONITOR
405
172
500
217
R4 percentage
count pigs with [ region = 4 and infected ] / count pigs with [ region = 4 ]
3
1
11

MONITOR
404
223
499
268
R5 percentage
count pigs with [ region = 5 and infected ] / count pigs with [ region = 5 ]
3
1
11

SWITCH
103
123
203
156
auto-infect
auto-infect
1
1
-1000

SLIDER
103
312
203
345
duration
duration
0
20
15.0
1
1
days
HORIZONTAL

MONITOR
224
168
296
213
Total # R4
count pigs with [ region = 4 ]
17
1
11

MONITOR
224
220
296
265
Total # R5
count pigs with [ region = 5 ]
17
1
11

MONITOR
300
169
402
214
# infected in R4
count pigs with [ region = 4 and infected ]
17
1
11

MONITOR
300
222
402
267
# infected in R5
count pigs with [ region = 5 and infected ]
17
1
11

INPUTBOX
221
326
376
386
Add-pigs-in-vacant-region
11.0
1
0
Number

SWITCH
104
349
210
382
put-pigs?
put-pigs?
0
1
-1000

MONITOR
225
274
335
319
Sold Not Infected
#-not-infected-sold
17
1
11

MONITOR
338
275
425
320
Sold Infected
#-infected-sold
17
1
11

SLIDER
4
324
101
357
buying-rate
buying-rate
0
100
3.0
1
1
%
HORIZONTAL

SLIDER
5
362
99
395
selling-rate
selling-rate
0
100
1.0
1
1
%
HORIZONTAL

CHOOSER
104
387
196
432
Clean
Clean
"off" "Everyday" "too-much-poop"
0

MONITOR
386
324
443
369
Death
#-deaths
17
1
11

SLIDER
197
389
303
422
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
305
390
446
423
transmission-rate-a
transmission-rate-a
0
100
75.0
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

pig1
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

pig2
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

pig3
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

pig4
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
Circle -7500403 true true 120 90 0
Circle -7500403 true true 78 93 85
Circle -7500403 true true 138 93 85

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

poop
true
0
Circle -6459832 true false 105 105 60
Circle -6459832 true false 86 86 67
Circle -6459832 true false 120 75 30
Circle -6459832 true false 135 90 30
Circle -6459832 true false 144 114 42
Circle -6459832 true false 159 99 42
Circle -6459832 true false 144 69 42
Circle -6459832 true false 45 90 0
Circle -6459832 true false 174 84 42
Circle -6459832 true false 174 114 42
Circle -6459832 true false 129 54 42

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

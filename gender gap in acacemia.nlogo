extensions[csv]

globals [turnover
         extra-plan
         newRTDB
         newpo-slots
         POMSforPO
         totalptiorg
         resources
         resourcesT-1
         shareOfFemales
         competitions


         pubdataM
         pubdataF]

turtles-own [age
             gender
             POMS
             curriculum
             productivityT-1
             productivity
             sons
             sonsT-1
             ageOfSons
             winner
             ]


breed [rtdbs rtdb]
rtdbs-own [yearsOfContract]

breed [rtis rti]

breed [pas pa]
pas-own[eligiblePO
        myEvaluation
        from-outside]

breed [pos po]
pos-own[evaluatorsPO
        from-outside]

links-own [evaluation]


to setup
  ca
  reset-ticks

  create-rtdbs 84 [set POMS 0.5
                   set age precision (random-normal 39 9.4) 0
                   set gender "M"
                   set yearsOfContract 0]
  ask n-of 35 rtdbs [set gender "F"]
  ask n-of (count rtdbs / 3) rtdbs [set yearsOfContract 1]
  ask n-of (count rtdbs / 3) rtdbs with [yearsOfContract != 1] [set yearsOfContract 2]


  create-rtis 210 [set POMS 0.5
                   set age precision (random-normal 50 8.5) 0
                   set gender "M"]
  ask n-of 104 rtis [set gender "F"]


  create-pas 437 [set POMS 0.7
                  set age precision (random-normal 52 6.2) 0
                  set gender "M"]

  ask n-of 172 pas [set gender "F"]


  create-pos 269 [set POMS 1
                  let alpha 59 * 59 / 25
                  let lambda 1 / (25 / 59)
                  set age precision (random-gamma alpha lambda) 0
                  set gender "M"]
  ask n-of 67 pos [set gender "F"]


  if calibration [

  create-rtdbs 21 [set POMS 0.5
                   set age precision (random-normal 39 9.4) 0
                   set gender "M"
                   set yearsOfContract 0]
  ask n-of 6 rtdbs [set gender "F"]
  ask n-of (count rtdbs / 3) rtdbs [set yearsOfContract 1]
  ask n-of (count rtdbs / 3) rtdbs with [yearsOfContract != 1] [set yearsOfContract 2]


  create-rtis 407 [set POMS 0.5
                   set age precision (random-normal 50 8.5) 0
                   set gender "M"]
  ask n-of 187 rtis [set gender "F"]


  create-pas 319 [set POMS 0.7
                  set age precision (random-normal 52 6.2) 0
                  set gender "M"]

  ask n-of 112 pas [set gender "F"]

  create-pos 252 [set POMS 1
                  let alpha 63 * 63 / 25
                  let lambda 1 / (25 / 62)
                  set age precision (random-gamma alpha lambda) 0
                  set gender "M"]
  ask n-of 53 pos [set gender "F"
                   let alpha 57 * 57 / 16
                   let lambda 1 / (16 / 57)
                   set age precision (random-gamma alpha lambda) 0]
  ]

  ask turtles with [age <= 31][set age 31]
  ask turtles with [age >= 70][set age 70]

 set pubdataM remove-item 0 csv:from-file "scival_males.csv"
 set pubdataF remove-item 0 csv:from-file "scival_females.csv"


  ask turtles with [gender = "M"] [set productivity item 0 one-of pubdataM]
  ask turtles with [gender = "F"] [set productivity item 0 one-of pubdataF]


  if no-diff-in-curriculum? [ask turtles [set productivity item 0 one-of pubdataM]
                             ]
  ask turtles [set curriculum age + productivity]

  set shareofFemales precision (count rtdbs with [gender = "F"] / count rtdbs) 2

end


to setSeed
  random-seed mySeed
end

to go

  ask turtles [set age age + 1
               set sonsT-1 sons]


  ask turtles [set productivityT-1 productivity
               set productivity productivityT-1 * (1 + random-normal 0.02 variance-incr-in-prod)
               if productivity < productivityT-1 [set productivity productivityT-1]
               ]

  let newMothers n-of (0.5 * count turtles with [gender = "F" and age < 45 and sons < 3]) turtles with [gender = "F" and age < 45 and sons < 3]
  ask newMothers [set sons sons + 1
                  set ageOfSons ageOfSons + 1
                  if sons > sonsT-1 [set ageOfSons 0]
                  if ageOfSons < duration-child-penalization [set productivity productivityT-1 *(1 + random-normal 0.014 variance-incr-in-prod)
                                                              if productivity < productivityT-1 [set productivity productivityT-1]
                                                              ]
                 ]

  if motherhood-bonus? [let bonus (mean[productivity] of turtles - mean[productivityT-1] of turtles)
                        ask turtles with [ageOfSons < 5] [set productivity (productivity + bonus)]
                       ]


  ask turtles [set curriculum age + productivity]
  set totalptiorg sum [POMS] of turtles with [age = 70]
  set turnover 1
  set extra-plan precision (totalptiorg * 0.15) 0
  set resources (totalptiorg * turnover)  + extra-plan + resourcesT-1

  ;PROMOTING RTDB -> PA --->  ex l.240
  let POMSforRTDB3anno (count rtdbs with [yearsOfContract = 3] * 0.2)
  ask rtdbs with [yearsOfContract = 3][set breed pas
                                       set POMS POMS + 0.2]

  set resources resources - POMSforRTDB3anno


 ;SPAWNING RTDB
  let retiring count turtles with [age = 70]
  set newRTDB retiring

  let POMSforRTDB newRTDB * 0.5
  while [POMSforRTDB > resources][set newRTDB newRTDB - 1
                                         set POMSforRTDB newRTDB * 0.5]


  ifelse shareOfFemales < 0.5 [set shareOfFemales shareOfFemales + 0.005]
                              [set shareOfFemales 0.5]
  ask rtdbs [set yearsOfContract yearsOfContract + 1]


  create-rtdbs newRTDB [set age precision (random-normal 39 9.4) 0 - 4
                        set POMS 0.5
                        set yearsOfContract 0
                        set gender "M"
                        set productivity item 0 one-of pubdataM
                        set curriculum age + productivity
                        ]

  ifelse balanced-entrance-of-new-staff? [ask n-of (shareOfFemales * count rtdbs with [yearsOfContract = 0]) rtdbs with [yearsOfContract = 0][set gender "F"
                                                                                                                                              set productivity item 0 one-of pubdataF
                                                                                                                                              set curriculum age + productivity
                                                                                                                                              if no-diff-in-curriculum? [set productivity item 0 one-of pubdataM
                                                                                                                                                                         set curriculum age + productivity]
                                                                                                                                                          ]
                                         ]
                                         [ask n-of ( (0.40 + random-float 0.04) * count rtdbs with [yearsOfContract = 0]) rtdbs with [yearsOfContract = 0][set gender "F"
                                                                                                                                                           set productivity item 0 one-of pubdataF
                                                                                                                                                           set curriculum age + productivity
                                                                                                                                                           if no-diff-in-curriculum? [set productivity item 0 one-of pubdataM
                                                                                                                                                                                      set curriculum age + productivity]
                                                                                                                                                           ]
                                        ]

   set resources resources - POMSforRTDB



 ;COMPETITIONS PA -> PO
  if resources > 0 [

  set POMSforPO resources
  set competitions precision (POMSforPO / 0.3) 0
  set resources resources - POMSforPO
  let threshold min[age] of pas + median[productivity] of turtles
  ask turtles [set winner false]



  ifelse gender-quotas-in-full? [let male-competitions precision (competitions * 0.4) 0
                                 let female-competitions precision (competitions * 0.4) 0
                                 let open-competitions (competitions - male-competitions - female-competitions)

      repeat male-competitions [ask pos [set evaluatorsPO false]
                                ask pas [set eligiblePO false]
                                ask links [die]

                                ;eliging the committees
                                ask n-of min-women-in-committees pos with [gender = "F"] [set evaluatorsPO true]
                                ask n-of (3 - min-women-in-committees) pos [set evaluatorsPO true]
                                let commissionPO pos with [evaluatorsPO = true]

                                ask pas with [gender = "M" and curriculum > threshold][set eligiblePO true]

                                let competitorsPO pas with [eligiblePO = true]
                                ask competitorsPO [setxy random-xcor random-ycor]

                                ;evaluation
                                ask commissionPO [create-links-to competitorsPO
                                ;evaluation of the committees
                                ask my-links [set evaluation ([curriculum] of end2) * (0.9 + random-float 0.2)]
                                                 ]
                                ask competitorsPO [set myEvaluation mean[evaluation] of my-links]
                                ask competitorsPO with [myEvaluation = max[myEvaluation] of competitorsPO] [set breed pos
                                                                                                           set winner true]
                               ]

      repeat female-competitions [ask pos [set evaluatorsPO false]
                                  ask pas [set eligiblePO false]
                                  ask links [die]

                                  ;eliging the committees
                                  ask n-of min-women-in-committees pos with [gender = "F"] [set evaluatorsPO true]
                                  ask n-of (3 - min-women-in-committees) pos [set evaluatorsPO true]
                                  let commissionPO pos with [evaluatorsPO = true]

                                  ask pas with [gender = "F" and curriculum > threshold * female-reluctance-to-apply][set eligiblePO true]

                                 let competitorsPO pas with [eligiblePO = true]
                                 ask competitorsPO [setxy random-xcor random-ycor]

                         ;evaluation
                         ask commissionPO [create-links-to competitorsPO
                                          ;evaluation of the committees
                                           ask my-links [set evaluation ([curriculum] of end2) * (0.9 + random-float 0.2)]
                                          ]
                        ask competitorsPO [set myEvaluation mean[evaluation] of my-links]
                        ask competitorsPO with [myEvaluation = max[myEvaluation] of competitorsPO] [set breed pos
                                                                                                    set winner true]
                                 ]

      repeat open-competitions [ask pos [set evaluatorsPO false]
                                ask pas [set eligiblePO false]
                                ask links [die]

                               ;eliging the committees
                               ask n-of min-women-in-committees pos with [gender = "F"] [set evaluatorsPO true]
                               ask n-of (3 - min-women-in-committees) pos [set evaluatorsPO true]
                               let commissionPO pos with [evaluatorsPO = true]

                              ;identifying who applies for the competitions
                              ifelse no-diff-in-curriculum? [ask pas with [curriculum > threshold] [set eligiblePO true]
                                                            ]
                                    [ask pas with [gender = "M" and curriculum > threshold][set eligiblePO true]
                                     ask pas with [gender = "F" and curriculum > threshold * female-reluctance-to-apply] [set eligiblePO true]
                                                            ]

                             let competitorsPO pas with [eligiblePO = true]
                             ask competitorsPO [setxy random-xcor random-ycor]

                           ;evaluation
                           ask commissionPO [create-links-to competitorsPO
                                         ;evaluation of the committees to male candidates
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 3 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 + random-float max-bias))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 2 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 + random-float (max-bias / 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 1 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 - (max-bias) + random-float (max-bias * 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 0 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 - random-float max-bias))]
                                                                                     ]
                                         ;evaluation of the committees to female candidates
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 3 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 - random-float max-bias))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 2 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 - random-float (max-bias / 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 1 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 *(1 - max-bias + random-float (max-bias * 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 0 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 + random-float max-bias))]
                                                                                     ]
                                          ]
                         ask competitorsPO [set myEvaluation mean[evaluation] of my-links]
                         ask  competitorsPO with [myEvaluation = max[myEvaluation] of competitorsPO] [set breed pos
                                                                                                      set winner true]

                                           ]


  ]


  [repeat competitions [ask pos [set evaluatorsPO false]
                        ask pas [set eligiblePO false]
                        ask links [die]

                        ;eliging the committees
                        ask n-of min-women-in-committees pos with [gender = "F"] [set evaluatorsPO true]
                        ask n-of (3 - min-women-in-committees) pos [set evaluatorsPO true]
                        let commissionPO pos with [evaluatorsPO = true]

                        ;identifying who applies for the competitions
      ifelse no-diff-in-curriculum? [ask pas with [curriculum > threshold] [set eligiblePO true]
                                     ]
                                    [ask pas with [gender = "M" and curriculum > threshold][set eligiblePO true]
                                     ask pas with [gender = "F" and curriculum > threshold * female-reluctance-to-apply] [set eligiblePO true]
                                    ]

                         let competitorsPO pas with [eligiblePO = true]
                         ask competitorsPO [setxy random-xcor random-ycor]

                         ;evaluation
                         ask commissionPO [create-links-to competitorsPO
                                         ;evaluation of the committees to male candidates
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 3 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 + random-float max-bias))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 2 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 + random-float (max-bias / 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 1 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 - (max-bias) + random-float (max-bias * 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 0 [
                                          ask my-links with [[gender] of end2 = "M"][set evaluation ([curriculum] of end2 * (1 - random-float max-bias))]
                                                                                     ]
                                         ;evaluation of the committees to female candidates
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 3 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 - random-float max-bias))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 2 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 - random-float (max-bias / 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 1 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 *(1 - max-bias + random-float (max-bias * 2)))]
                                                                                     ]
                                          if count pos with [evaluatorsPO = true and gender = "M"] = 0 [
                                          ask my-links with [[gender] of end2 = "F"][set evaluation ([curriculum] of end2 * (1 + random-float max-bias))]
                                                                                     ]
                                          ]
                         ask competitorsPO [set myEvaluation mean[evaluation] of my-links]



      ask  competitorsPO with [myEvaluation = max[myEvaluation] of competitorsPO] [set breed pos
                                                                                   set winner true]

                         ]

  ]
  ]

  set resourcesT-1 resources
  ask turtles with [age >= 70][die]


  if calibration and ticks >= 6 [stop]
  if ticks >= years [stop]
  tick
  if ticks >= years [csv-export]

end

to csv-export
  if csv-output [export-all-plots (word "gender quotas academia " random-float 1.0  ".csv") ]
end
@#$#@#$#@
GRAPHICS-WINDOW
23
10
207
195
-1
-1
5.333333333333334
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
19
328
82
361
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

BUTTON
95
349
158
383
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

SWITCH
186
442
394
475
balanced-entrance-of-new-staff?
balanced-entrance-of-new-staff?
1
1
-1000

SLIDER
15
398
107
431
years
years
10
150
100.0
10
1
NIL
HORIZONTAL

SWITCH
14
439
115
472
csv-output
csv-output
1
1
-1000

PLOT
426
10
1646
200
total population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5987164 true "" "plot count turtles "
"pen-1" 1.0 0 -13345367 true "" "plot count turtles with [gender = \"M\"]"
"pen-2" 1.0 0 -2064490 true "" "plot count turtles with [gender = \"F\"]"

PLOT
426
215
871
375
tenure-tracked assistant professors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count rtdbs with [gender = \"M\"]"
"pen-1" 1.0 0 -7500403 true "" "plot count rtdbs"
"pen-2" 1.0 0 -2064490 true "" "plot count rtdbs with [gender = \"F\"]"

PLOT
427
390
868
553
permanent assistant professors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count rtis with [gender = \"M\"]"
"pen-1" 1.0 0 -7500403 true "" "plot count rtis "
"pen-2" 1.0 0 -2064490 true "" "plot count rtis with [gender = \"F\"]"

PLOT
887
215
1331
373
associate professors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count pas with [gender = \"M\"]"
"pen-1" 1.0 0 -7500403 true "" "plot count pas"
"pen-2" 1.0 0 -2064490 true "" "plot count pas with [gender = \"F\"]"

PLOT
885
388
1333
554
full professors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count pos with [gender = \"M\"]"
"pen-1" 1.0 0 -7500403 true "" "plot count pos "
"pen-2" 1.0 0 -2064490 true "" "plot count pos with [gender = \"F\"]"

BUTTON
96
310
159
343
NIL
go
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
108
240
168
300
mySeed
1312.0
1
0
Number

BUTTON
14
258
91
291
NIL
setSeed
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
6
238
156
256
use it before setup!
11
0.0
1

MONITOR
1589
10
1646
55
tot
count turtles
17
1
11

MONITOR
1282
388
1332
433
pos
count pos
17
1
11

MONITOR
1282
216
1332
261
pas
count pas
17
1
11

MONITOR
821
216
871
261
rtdbs
count rtdbs
17
1
11

MONITOR
818
390
868
435
rtis
count rtis
17
1
11

TEXTBOX
801
262
951
280
time zero: 84
11
0.0
1

TEXTBOX
1259
262
1409
280
time zero: 437
11
0.0
1

TEXTBOX
1264
436
1414
454
time zero: 269
11
0.0
1

PLOT
1345
217
1646
370
curriculum
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "if ticks > 0 [plot mean[curriculum] of turtles with [gender = \"M\"]]"
"pen-1" 1.0 0 -2064490 true "" "if ticks > 0 [plot mean[curriculum] of turtles with [gender = \"F\"]]"

TEXTBOX
792
437
942
455
time zero: 210
11
0.0
1

SWITCH
188
368
343
401
motherhood-bonus?
motherhood-bonus?
0
1
-1000

SLIDER
185
326
350
359
min-women-in-committees
min-women-in-committees
0
3
1.0
1
1
NIL
HORIZONTAL

MONITOR
1284
509
1334
554
pos F
count pos with [gender = \"F\"]
17
1
11

MONITOR
1283
461
1333
506
pos M
count pos with [gender = \"M\"]
17
1
11

PLOT
1346
386
1649
552
full professors promoted per year
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -2064490 true "" "plot count pos with  [winner = true and gender = \"F\"]"
"pen-1" 1.0 0 -13345367 true "" "plot count pos with  [winner = true and gender = \"M\"]"

SWITCH
185
288
357
321
no-diff-in-curriculum?
no-diff-in-curriculum?
1
1
-1000

SWITCH
187
405
343
438
gender-quotas-in-full?
gender-quotas-in-full?
0
1
-1000

MONITOR
1218
388
1275
433
F %
count pos with [gender = \"F\"] / count pos
2
1
11

MONITOR
1274
280
1331
325
% F
count pas with [gender = \"F\"]/ count pas
2
1
11

SLIDER
224
87
372
120
variance-incr-in-prod
variance-incr-in-prod
0.01
0.05
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
225
126
392
159
duration-child-penalization
duration-child-penalization
1
7
7.0
1
1
NIL
HORIZONTAL

SLIDER
226
168
395
201
female-reluctance-to-apply
female-reluctance-to-apply
1
1.2
1.1
0.1
1
NIL
HORIZONTAL

SLIDER
226
205
318
238
max-bias
max-bias
0
1
0.1
0.05
1
NIL
HORIZONTAL

TEXTBOX
189
262
339
280
policy tests
13
0.0
1

TEXTBOX
223
64
373
82
sensitivity analysis
13
0.0
1

SWITCH
221
18
321
51
calibration
calibration
1
1
-1000

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vanilla" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vanilla - diff in cv" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policy A" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policy B" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policy C" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policy D" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policy E" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 1a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight-of-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 2a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight-of-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 5a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight-of-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 6a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 7a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 8a" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 1b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 2b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 5b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 6b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 7b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 8b" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 1c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 2c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 5c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 6c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 7c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 8c" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 1d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 2d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 5d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 6d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 7d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity 8d" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration - zero bias" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration-bias" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight-of-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration-bias20" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [gender = "M"]</metric>
    <metric>count turtles with [gender ="F"]</metric>
    <metric>count rtdbs with [gender = "M"]</metric>
    <metric>count rtdbs with [gender ="F"]</metric>
    <metric>count rtis with [gender = "M"]</metric>
    <metric>count rtis with [gender ="F"]</metric>
    <metric>count pas with [gender = "M"]</metric>
    <metric>count pas with [gender ="F"]</metric>
    <metric>count pos with [gender = "M"]</metric>
    <metric>count pos with [gender ="F"]</metric>
    <enumeratedValueSet variable="max-bias">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motherhood-bonus?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balanced-entrance-of-new-staff?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gender-quotas-in-full?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mySeed">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-women-in-committees">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-diff-in-curriculum?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-output">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-reluctance-to-apply">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="years">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration-child-penalization">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variance-incr-in-prod">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibration">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

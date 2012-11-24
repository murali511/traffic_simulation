;;each of this is an agent and has its parameters

globals
[
  grid-x-inc               ;; the amount of patches in between two roads in the x direction
  grid-y-inc               ;; the amount of patches in between two roads in the y direction
  acceleration             ;; the constant that controls how much a car speeds up or slows down by if
                           ;; it is to accelerate or decelerate
  phase                    ;; keeps track of the phase
  num-cars-stopped         ;; the number of cars that are stopped during a single pass thru the go procedure
  num-buses-stopped        ;; the number of buses that are stopped at a bus bay
  
  ;vehicles slowed at brown busstop
  num-cars-slowed         ;; the number of cars that are stopped during a single pass thru the go procedure
  num-buses-slowed        ;; the number of buses that are stopped at a bus bay
  
  ;vehicles stopped because of yellow busstop
  num-cars-stopped-at-yellowstop
  
  current-light            ;; the currently selected light
  current-busstop          ;; the current selected busstop
  
  ;; patch agentsets 
  intersections ;; agentset containing the patches that are intersections
  intersections-west ;; agentset containing the patches that are intersections
  intersections-south ;; agentset containing the patches that are intersections
  intersections-north ;; agentset containing the patches that are intersections
  busstops      ;;agentset containing the patches that are busstops
  roads         ;; agentset containing the patches that are roads
  roaddividers  ;; agentset containing the patches that are road dividers
  oppositeroads         ;; agentset containing the patches that are opposite roads
 
  ;count of remaining vehicles
  remainingcars
  remainingbuses
  
]


turtles-own
[
  speed     ;; the speed of the turtle
   negativespeed ;; the speed of turtles on opposite directions
  bus-speed     ;; the speed of the bus
  ;;up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  ;;up-bus?   ;; true if the bus moves downwards and false if it moves to the right
  up-vehicle? ;; true if the vehicle moves downwards and false if it moves to right
  down-vehicle? ;; true if the vehicle moves upwards and false if it moves to left
  up-bus? ;; true if the vehicle moves downwards and false if it moves to right
  down-bus? ;; true if the vehicle moves upwards and false if it moves to left

  wait-time ;; the amount of time since the last time a turtle has moved
  bus-wait-time ;; the amount of time since the last time a turtle has moved   
   
]
;;breed of cars that move from left ro right
breed[newcars newcar]
;;breed of cars that move from right to left 
breed[oppositecars oppositecar]
breed[newbuses newbus]
breed[oppositebuses oppsitebus]

newcars-own
[
 newcarcolor  
]
oppositecars-own
[
 oppositecarcolor  
]
newbuses-own
[
  newbuscolor
]
oppositebuses-own
[
  oppositebuscolor
]

patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
  intersection-west?   ;; true if the patch is at the intersection of two roads
  intersection-south?   ;; true if the patch is at the intersection of two roads
  intersection-north?   ;; true if the patch is at the intersection of two roads      
  green-light-up? ;; true if the green light is above the intersection.  otherwise, false.
                  ;; false for a non-intersection patches.
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-phase        ;; the phase for the intersection.  -1 for non-intersection patches.
  auto?           ;; whether or not this intersection will switch automatically.
                  ;; false for non-intersection patches.
]


;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

;; Initialize the display by giving the global and patch variables initial values.
;; Create num-cars of turtles if there are enough road patches for one turtle to
;; be created per road patch. Set up the plots.
to setup
  ca
  setup-globals

  ;; First we ask the patches to draw themselves and set up a few variables
  setup-patches
  make-current one-of  intersections-west 
  make-busstop one-of intersections
;  user-message(word "total roads" count roads word "total opproads" count oppositeroads word "total cars" num-cars word"total buses" num-buses)stop
  if (num-cars > ( count roads - 4) or num-cars > (count oppositeroads - 4))
  [
    user-message (word "There are too many cars for the amount of "
                       "road.  Either increase the amount of roads "
                       "by increasing the GRID-SIZE-X or "
                       "GRID-SIZE-Y sliders, or decrease the "
                       "number of cars by lowering the NUMBER slider.\n"
                       "The setup has stopped.")
    stop
  ]
  if (num-buses > ( count roads -  4) or num-buses > (count oppositeroads - 4))
  [
    user-message (word "There are too many buses for the amount of "
                       "road.  Either increase the amount of roads "
                       "by increasing the GRID-SIZE-X or "
                       "GRID-SIZE-Y sliders, or decrease the "
                       "number of buses by lowering the NUMBER slider.\n"
                       "The setup has stopped.")
    stop
  ]
  
  if ((num-cars + num-buses) >= ( count roads - 4) or (num-cars + num-buses) >= (count oppositeroads - 4))
  [
    user-message (word "There are too many cars and buses for the amount of "
                       "road.  Either increase the amount of roads "
                       "by increasing the GRID-SIZE-X or "
                       "GRID-SIZE-Y sliders, or decrease the "
                       "number of cars or buses by lowering the NUMBER slider.\n"
                       "The setup has stopped.")
    stop
  ]

  ;; Now create the turtles and have each created turtle call the functions setup-cars and set-car-color
  
    setup-cars
    setup-oppositecars   
    ;;create buses   
    setup-buses
    setup-oppositebuses
  ;; give the turtles an initial speed

 ask  newcars [ set-car-speed ]
  ask oppositecars  [ set-oppositecar-speed ]
 ask newbuses[ set-bus-speed ]
 ask oppositebuses[ set-oppositebus-speed ]
  reset-ticks
end

;; Initialize the global variables to appropriate values
to setup-globals
  set current-light nobody ;; just for now, since there are no lights yet
  set phase 0
  set num-cars-stopped 0
  set num-buses-stopped 0
  set num-cars-slowed 0
  set num-buses-slowed 0
    
  set num-cars-stopped-at-yellowstop 0
  set grid-x-inc world-width / grid-size-x
  set grid-y-inc world-height / grid-size-y
 
  ;; don't make acceleration 0.1 since we could get a rounding error and end up on a patch boundary
  set acceleration 0.099
end

;; Make the patches have appropriate colors, set up the roads and intersections agentsets,
;; and initialize the traffic lights to one setting
to setup-patches
  ;; initialize the patch-owned variables and color the patches to a base-color
  ask patches
  [
    set intersection? false
    set intersection-west? false
    set intersection-north? false
    set intersection-south? false
    set auto? false
    set green-light-up? true
    set my-row -1
    set my-column -1
    set my-phase -1
    set pcolor brown + 3
  ]

  ;; initialize the global variables that hold patch agentsets
  ;;set up roads , and dividers
   set roads patches with
    [( (floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor) mod grid-y-inc) = 0) )]
    
   set oppositeroads patches with
    [((floor((pxcor + max-pxcor - floor(grid-x-inc + 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor - 2) mod grid-y-inc ) = 0) )]
    
    set roaddividers patches with
    [(( (floor((pxcor + max-pxcor - floor(grid-x-inc)) mod grid-x-inc) = 0) ) or
    (floor((pycor + max-pycor - 1) mod grid-y-inc) = 0) )]
    
    ;;set up intersections
  set intersections roads  with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor) mod grid-y-inc) = 0) ]
  set intersections-west oppositeroads  with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc + 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor - 2) mod grid-y-inc) = 0) ]
  set intersections-south roads  with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc ) = 0) and
    (floor((pycor + max-pycor - 2) mod grid-y-inc ) = 0) ]  
  set intersections-north oppositeroads  with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc + 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor ) mod grid-y-inc  ) = 0) ]      
  ;;set patch colors
  ask roads 
  [ 
    set pcolor white 
  ]
  ask oppositeroads 
  [
   
      set pcolor 9.9
   
  ]
  ask roaddividers 
  [
  
      set pcolor black + 5
   
  ]
  setup-intersections
end

;; Give the intersections appropriate values for the intersection?, my-row, and my-column
;; patch variables.  Make all the traffic lights start off so that the lights are red
;; horizontally and green vertically.
to setup-intersections
  ask intersections
  [
    set intersection? true
    set green-light-up? true
    set my-phase 0
    set auto? true
    set my-row floor((pycor + max-pycor) / grid-y-inc)
    set my-column floor((pxcor + max-pxcor) / grid-x-inc)
    set-signal-colors
    ;set pcolor 36
    
  ]
  ask intersections-west
  [
    set intersection-west? true
    set green-light-up? true
    set my-phase 0
    set auto? true
     ;   set pcolor 36
 ]
   ask intersections-south
  [
    set intersection-south? true
    set green-light-up? true
    set my-phase 0
    set auto? true
      ; set pcolor 36
 ]
   ask intersections-north
  [
    set intersection-north? true
    set green-light-up? true
    set my-phase 0
    set auto? true
       ; set pcolor 36
 ]
 
 
end

;; Initialize the turtle variables to appropriate values and place the turtle on an empty road patch.
to setup-cars  ;; turtle procedure
  set-default-shape turtles "car"  

 set  remainingcars  random (num-cars ) 
 if remainingcars = 0
   [
     set remainingcars 1
     ]  
  create-newcars remainingcars
  [
  set speed 0
  set wait-time 0
  put-on-empty-road
  set-car-color
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set up-vehicle? true 
      ]
    [ set up-vehicle? false]
  ]
  [
    ; if the turtle is on a vertical road (rather than a horizontal one)
    ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
    [ 
      set up-vehicle? true 
      ]
    [ set up-vehicle? false   ]
      
   
   ifelse ((floor((pycor + max-pycor) mod grid-y-inc) = 0) )
    [ set up-vehicle? false       ]
    [ set up-vehicle? true  
      ]
    
  ]
  ifelse up-vehicle?
  [ set heading 0 ]
  [ set heading 90 ]  
  record-data     
  ]
end
to setup-oppositecars
    set-default-shape turtles "othercar"  
    set remainingcars ( num-cars - remainingcars)
   if remainingcars = 0
   [
     set remainingcars 1
     ]
  create-oppositecars  ( remainingcars )
  [
  set speed 0
  set wait-time 0
  ;;set up-car? true
  put-on-empty-oppositeroad
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set down-vehicle? true 
      ]
    [ set down-vehicle? false ]
  ]
  [
            
     ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc + 1)) mod grid-x-inc) = 0  )
    [ set down-vehicle? true 
    ]
    [ set down-vehicle? false ]
    
     ifelse ((floor((pycor + max-pycor - 2) mod grid-y-inc ) = 0))
    [ set down-vehicle? false 
      ]
    [ set down-vehicle? true 
      ]
  ]
  
  ifelse down-vehicle?
  [ set heading 0]
  [ set heading 90] 
  
  set-oppositecar-color
  record-data
    ;record-slowed-cardata  
  ]
end

;; Initialize the buses variables to appropriate values and place the turtle on an empty road patch.
to setup-buses  ;; turtle procedure
  set-default-shape turtles "bus"  
  set remainingbuses random(num-buses )
   if remainingbuses = 0
    [
      set remainingbuses 1
      ]  
  
  create-newbuses ( remainingbuses )
  [
  set speed 0
  set bus-wait-time 0
  set size 1.3
  
  put-on-empty-road
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set up-vehicle? true ]
    [ set up-vehicle? false ]
  ]
  [
    ; if the turtle is on a vertical road (rather than a horizontal one)
    ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
    [ set up-vehicle? true ]
    [ set up-vehicle? false ]
    
    ifelse ((floor((pycor + max-pycor) mod grid-y-inc) = 0) )
    [ set up-vehicle? false ]
    [ set up-vehicle? true ]
  ]
  ifelse up-vehicle?
  [ set heading 0]
  [ 
    set shape "horizontalbus" 
        set speed 0 
    set heading 90 
    
  ]
  
  set-bus-color
  record-busdata
  ;record-slowed-busdata
  ]
end
to setup-oppositebuses
    set-default-shape turtles "other-bus"  
    set remainingbuses (num-buses - remainingbuses)
      
    if remainingbuses = 0
    [
      set remainingbuses 1
      ]  
  create-oppositebuses round ( remainingbuses)
  [
  set speed 0
  set bus-wait-time 0
  set size 1.3
  put-on-empty-oppositeroad
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set down-vehicle? true ]
    [ set down-vehicle? false ]
  ]
  [
     ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc + 1)) mod grid-x-inc) = 0  )
    [ set down-vehicle? true ]
    [ set down-vehicle? false ]
    
     ifelse ((floor((pycor + max-pycor - 2) mod grid-y-inc ) = 0))
    [ set down-vehicle? false ]
    [ set down-vehicle? true ]
  ]
  
  ifelse down-vehicle?
  [ set heading 0 ]
  [ 
    set shape "horizontalbus1"
    set speed 0
    set heading 90 
    ]
  
  set-oppositebus-color
  record-busdata
  ;record-slowed-busdata
  ]
end

;; Find a road patch without any turtles on it and place the turtle there.
to put-on-empty-road  ;; turtle procedure  
  move-to one-of roads with [not any? turtles-on self and pcolor = white]   
end

;; Find a opposite-road patch without any turtles on it and place the turtle there.
to put-on-empty-oppositeroad  ;; turtle procedure
  move-to one-of oppositeroads with [not any? turtles-on self and pcolor = 9.9]
end



;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Run the simulation
to go

  update-current
  ;update-busstops
  set-signals
  
  ;; create busstops at intersections
   ;set-busstops
   
  set num-cars-stopped 0
  set num-buses-stopped 0
  set num-cars-slowed 0
  set num-buses-slowed 0
  set num-cars-stopped-at-yellowstop 0
  ;; set the turtles speed for this time thru the procedure, move them forward their speed,
  ;; record data for plotting, and set the color of the turtles to an appropriate color
  ;; based on their speed
  ask newcars
  [
       set-car-speed 
      fd speed          
    record-data
    record-slowed-cardata
    set-car-color
  ]
   ask oppositecars
  [
           set-oppositecar-speed               
           ;set negativespeed  ( - speed)
          fd  (- speed)          
    record-data
    record-slowed-cardata
    set-oppositecar-color            
  ]
  ask newbuses
  [
         set-bus-speed 
          fd speed
         record-busdata
         ;record-slowed-busdata
    set-bus-color             
  ]
  ask oppositebuses
  [
          set-oppositebus-speed          
         ;set negativespeed (- speed)         
          fd (- speed)
         record-busdata
        ;record-slowed-busdata
    set-oppositebus-color             
  ]

  ;; update the phase and the global clock
  next-phase
  tick
end

;; end of go

to choose-current
  if mouse-down?
  [
    let x-mouse mouse-xcor
    let y-mouse mouse-ycor
    if [intersection?] of patch x-mouse y-mouse
    [
      update-current
      unlabel-current
      make-current patch x-mouse y-mouse
      label-current
      stop
    ]    
  ]
end

;proceedue to setup busstops
to setup-busstops
  set-busstops
end

;proceedure to remove busstops

to remove-busstops
  ask intersections with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at -3 0 [ set pcolor 9.9 ]
    ;ask patch-at 0 5 [ set pcolor 45 ]
  ]
  ask intersections-west with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at 3 0 [ set pcolor 9.9 ]
    ;ask patch-at 0 -5 [ set pcolor 45 ]
  ] 
  ask intersections-south with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ;ask patch-at 5 0 [ set pcolor pink ]
    ask patch-at 0 -5 [ set pcolor 9.9 ]
  ] 
  ask intersections-north with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ;ask patch-at 5 0 [ set pcolor pink ]
    ask patch-at 0 5 [ set pcolor 9.9 ]
  ] 
  
  ;removes the busstops away from signal
  ask intersections with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at -5 -1 [ set pcolor 38 ]
    
  ]
  ask intersections-west with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at 5 1 [ set pcolor 38 ]
    
  ] 
  ask intersections-south with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at -1 -7 [ set pcolor 38 ]
    
  ] 
  ask intersections-north with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at 1 7 [ set pcolor 38 ]    
  ]
end

to move-busstops
remove-busstops
  
  let x-place 0
  let y-place 0
  
  ;if grid
  
  ask intersections with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at -5 -1 [ set pcolor 24 ]
    
  ]
  ask intersections-west with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at 5 1 [ set pcolor 24 ]
    
  ] 
  ask intersections-south with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    ask patch-at -1 -7 [ set pcolor 24 ]
    
  ] 
  ask intersections-north with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at 1 7 [ set pcolor 24 ]    
  ] 
  
end

to choose-busstop
  if mouse-down?
  [
    let x-mouse round mouse-xcor
    let y-mouse round mouse-ycor
    ;;if [roads] of patch x-mouse y-mouse
    ;;[
     ; update-busstops
      ;unlabel-busstop
      make-busstop patch x-mouse y-mouse
      label-busstop
      stop
    ;;]
  ]
end

to remove-busstop
   if mouse-down?
  [
    let x-mouse round mouse-xcor
    let y-mouse round mouse-ycor        
    make-busstop patch x-mouse y-mouse 
      unlabel-busstop
      stop
  ]
end

;; Set up the current light and the interface to change it.
to make-current [light]
  set current-light light
  set current-phase [my-phase] of current-light
  set current-auto? [auto?] of current-light
end

;; set up the current bus stop
to make-busstop[light]   
  set current-busstop light
 
end

;; update the variables for the current light
to update-current
  ask current-light [
    set my-phase current-phase
    set auto? current-auto?
  ]
end

;; update the variables of current busstop
to update-busstops
  ask current-busstop[
    set my-phase current-phase        
  ]
end
;; label the current light
to label-current
  ask current-light
  [
    ask patch-at -1 1
    [
      set plabel-color black
      set plabel "current"
    ]
  ]
end

;; label the current busstop
to label-busstop
  
  ifelse [pcolor] of patch round mouse-xcor round mouse-ycor = 38
  [
  if [ pcolor ] of patch (round (mouse-xcor) + 1) round mouse-ycor = white 
  [      
    ;user-message(word "here")stop
  ;ask current-busstop
  ;[
    ;ask patch-at 0 0
    ask patch round mouse-xcor round mouse-ycor
    [
      ;set shape "house ranch"   
      set pcolor 24     
    ]
   
    ;ask patch-at 1 0    
    ask patch round mouse-xcor round mouse-ycor
    [ 
      set plabel-color 21
      set plabel "current-busstop"
    ] 
  ;]
  ];; end of if

  
  if  [pcolor]  of patch round mouse-xcor (round( mouse-ycor) - 1) = white 
  [               
  ;ask current-busstop
  ;[
    ;ask patch-at 0 0
    ask patch round mouse-xcor round mouse-ycor
    [
      set pcolor 24     
    ]
    ;ask patch-at 1 0
    ask patch round mouse-xcor round mouse-ycor
    [ 
      set plabel-color 21
      set plabel "current-busstop"
    ] 
  ;]
  ];; end of if
  
  
  
  if [ pcolor ] of patch (round ( mouse-xcor) - 1)  round mouse-ycor = white 
  [  
  ;ask current-busstop
  ;[
    ;ask patch-at 0 0   
    ask patch round mouse-xcor round mouse-ycor
    [
      set pcolor 24     
    ]
    ;ask patch-at 1 0
    ask patch round mouse-xcor round mouse-ycor
    [ 
      set plabel-color 21
      set plabel "current-busstop"
   ; ] 
  ]
  ];; end of if

  
  if [ pcolor ] of patch round  mouse-xcor  (round (mouse-ycor) + 1) = white 
  [  
              
  ;ask current-busstop
  ;[
    ;ask patch-at 0 0
    ask patch round mouse-xcor round mouse-ycor
    [
      set pcolor 24     
    ]
    ;ask patch-at 1 0
    ask patch round mouse-xcor round mouse-ycor
    [ 
      set plabel-color 21
      set plabel "current-busstop"
    ] 
  ;]
  ];; end of if
  ];; end of if for checking patch color =38
 
  [
    user-message (word "a bus-stop can't be placed on road or road-divider or  very far from road")stop
  ]; 
  
  
  ;; give a alert if a bus stop is being placed beside existing busstop
  if [ pcolor ] of patch round  mouse-xcor  (round (mouse-ycor) + 1) = 45 or [ pcolor ] of patch (round ( mouse-xcor) - 1)  round mouse-ycor = 45 or [pcolor]  of patch round mouse-xcor (round( mouse-ycor) - 1) = 45 or [ pcolor ] of patch (round (mouse-xcor) + 1) round mouse-ycor = 45 
  [
    user-message (word "a bus-stop can't be placed beside another bus-stop")stop
  ]
  
  ;;give a alert if a bus stop is being placed besides a traffic signal
  ifelse [ pcolor ] of patch round  mouse-xcor  (round (mouse-ycor) + 1) = 15 or [ pcolor ] of patch (round ( mouse-xcor) - 1)  round mouse-ycor = 15 or [pcolor]  of patch round mouse-xcor (round( mouse-ycor) - 1) = 15 or [ pcolor ] of patch (round (mouse-xcor) + 1) round mouse-ycor = 15 
  [
    user-message (word "a bus-stop can't be placed beside a traffic signal")stop
  ]
  [
    if [ pcolor ] of patch round  mouse-xcor  (round (mouse-ycor) + 1) = 55 or [ pcolor ] of patch (round ( mouse-xcor) - 1)  round mouse-ycor = 55 or [pcolor]  of patch round mouse-xcor (round( mouse-ycor) - 1) = 55 or [ pcolor ] of patch (round (mouse-xcor) + 1) round mouse-ycor = 55 
  [
    user-message (word "a bus-stop can't be placed beside a traffic signal")stop
  ]
  ];end of else

end
;end of labeling busstop

;; unlabel the current light (because we've chosen a new one)
to unlabel-current
  ask current-light
  [
    ask patch-at -1 1
    [
      set plabel ""
    ]
  ]
end

;; unlabel the current busstop (because we've chosen a new one)
to unlabel-busstop  
  if[pcolor] of patch round mouse-xcor round mouse-ycor = 24
  [
  ;ask current-busstop
  ;[
    ;ask patch-at 0 0
    ask patch round mouse-xcor round mouse-ycor
    [
      set pcolor 38
    ]
    ;ask patch-at 1 0
    ask patch round mouse-xcor round mouse-ycor
    [
       set plabel ""
    ]
    set pcolor 38
  ;]
  ];end of if
  ;[
   ; user-message(word "there is no busstop")stop
  ;]


  
  
 
end

;; have the traffic lights change color if phase equals each intersections' my-phase
to set-signals
  ask intersections with [auto? and phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    set green-light-up? (not green-light-up?)
    set-signal-colors
  ]  
end

;;have the busstops 
to set-busstops
  ask intersections with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at -3 0 [ set pcolor 45 ]
    ;ask patch-at 0 5 [ set pcolor 45 ]
    
  ]
  ask intersections-west with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ask patch-at 3 0 [ set pcolor 45 ]
    ;ask patch-at 0 -5 [ set pcolor 45 ]
    
  ] 
  ask intersections-south with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ;ask patch-at 5 0 [ set pcolor pink ]
    ask patch-at 0 -5 [ set pcolor 45 ]
    
  ] 
  ask intersections-north with [phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [

    ;ask patch-at 5 0 [ set pcolor pink ]
    ask patch-at 0 5 [ set pcolor 45 ]
    
  ] 
end


;; This procedure checks the variable green-light-up? at each intersection and sets the
;; traffic lights to have the green light up or the green light to the left.
to set-signal-colors  ;; intersection (patch) procedure
  ifelse power?
  [
    ifelse green-light-up?
    [
      ask patch-at -1 0 [ set pcolor red 
        set intersection? true
        ]
      ask patch-at 0 -1 [ set pcolor green 
        set intersection? true
        ]
      ask patch-at 2 3 [ set pcolor green
        set intersection? true
        ]
      ask patch-at 3 2 [ set pcolor red 
        set intersection? true
        ]      
      
    ]
    [
      ask patch-at -1 0 [ set pcolor green 
        set intersection? true
        ]
      ask patch-at 0 -1 [ set pcolor red 
        set intersection? true
        ]
      ask patch-at 2 3 [ set pcolor red
        set intersection? true
        ]
      ask patch-at 3 2 [ set pcolor green 
        set intersection? true
        ]
    ]
  ]
  [
    ask patch-at -1 0 [ set pcolor white 
      set intersection? true
      ]
    ask patch-at 0 -1 [ set pcolor white 
      set intersection? true
      ]
    ask patch-at 2 3 [ set pcolor white
      set intersection? true
       ]
    ask patch-at 3 2 [ set pcolor white 
      set intersection? true
      ]
  ]
  ask patch-at 1 0 [ set pcolor white ]
  ask patch-at 0 1 [ set pcolor white ]
  ask patch-at 1 2 [ set pcolor white ]
  ask patch-at 2 1 [ set pcolor white ]
end



;; set the turtles' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-car-speed  ;; turtle procedure

  ifelse pcolor = red 
  [     set speed 0  ];end of if
  [
    ifelse up-vehicle? 
    [ 
      ;slow down the cars if there is a bus stop on side of road and if there is a bus in the bus stop
      ifelse [pcolor] of patch-at -1 1 = 24 and any? (newbuses-on patch-ahead 1 ) ;with [shape = "bus"]
      [
        set speed 0.3        
        ;record-slowed-cardata        
      ]
      [
        set-speed 0 1 
      ]
    ]
    [               
      ifelse [pcolor] of patch-at 1 -1 = 24 and any? (newbuses-on patch-ahead 1 ) ;with [shape = "horizontalbus"]
      [
        set speed 0.3
        ;record-slowed-cardata           
      ]
      [set-speed 1 0 ]       
    ]
  ];end of else
end

;; set the turtles' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-oppositecar-speed  ;; turtle procedure
     ifelse pcolor = red
     [set speed 0 ];end of if  
     [     
    ifelse down-vehicle? 
    [
            ;slow down the cars if there is a bus stop on side of road and if there is a bus in the bus stop
      ifelse [pcolor] of patch-at 1 -1 = 24 and any? (oppositebuses-on patch-ahead -1 ) ;with [shape = "other-bus"])  
      [
        set speed 0.3
        ;record-slowed-cardata    
      ]
      [
        set-oppositecarspeed 0 -1 
      ]       
    ]
    [      
       ifelse [pcolor] of patch-at -1 1 = 24 and any? (oppositebuses-on patch-ahead -1 ); with [shape = "other-bus"])  
      [                          
        set speed 0.3      
        ;record-slowed-cardata 
      ]
       [
       set-oppositecarspeed -1 0 
       ]
     ]

  ];end of else
end

;; set the buses' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-bus-speed  ;; turtle procedure
   
  ifelse pcolor = 45
  [ 
    set speed 0    
      count-vehicles-stopped-back    
  ];; end of pcolor 45
  [
    ifelse up-vehicle? 
    [ 
      ifelse [pcolor] of patch-at -1 0 = 24
      [
        set speed 0.3  
        record-slowed-busdata                 
      ]
      [
        set-busspeed 0 1 
      ]
    ]
    [
      ifelse [pcolor] of patch-at 0 -1 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
      [set-busspeed 1 0 ]
       
    ]
  ]
        
  ifelse pcolor = red 
  [ 
    set speed 0 
    ]
  [
    ifelse up-vehicle? 
    [ 
      ifelse [pcolor] of patch-at -1 0 = 24
      [
        set speed 0.3  
        record-slowed-busdata        
      ]
      [
        set-busspeed 0 1 
      ]
    ]
    [
      ifelse [pcolor] of patch-at 0 -1 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
      [set-busspeed 1 0 ]
       
    ]
  ]
  
end

;; set the buses' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-oppositebus-speed  ;; turtle procedure
  
 
   ifelse pcolor = 45
  [ 
    set speed 0 
   count-vehicles-stopped-ahead
  ]
  [
    ifelse down-vehicle?     
    [
      ifelse [pcolor] of patch-at 1 0 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
      [
        set-oppositebusspeed 0 -1 
      ]       
    ]
    [
       ifelse [pcolor] of patch-at 0 1 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
       [
       set-oppositebusspeed -1 0 
       ]
     ]
  ]
  
  ifelse pcolor = red 
  [ set speed 0 ]
  [
    ifelse down-vehicle?     
    [
      ifelse [pcolor] of patch-at 1 0 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
      [
        set-oppositebusspeed 0 -1 
      ]       
    ]
    [
       ifelse [pcolor] of patch-at 0 1 = 24
      [
        set speed 0.3
        record-slowed-busdata        
      ]
       [
       set-oppositebusspeed -1 0 
       ]
     ]
  ]
  
end



;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-speed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse (any? (turtles-ahead with [ up-vehicle? != [up-vehicle?] of myself]))
    [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead      
      slow-down
    ]
  ]
  [ speed-up ]
end

;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-oppositecarspeed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse any? (turtles-ahead with [ down-vehicle? != [down-vehicle?] of myself])
    [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead
      slow-down
    ]
  ]
    [ speed-up ]
end  
  
;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-busspeed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse any? (turtles-ahead with [ up-vehicle? != [up-vehicle?] of myself])
    [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead
      slow-down
    ]
  ]
  [ speed-up ]
end

;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-oppositebusspeed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse any? (turtles-ahead with [ down-vehicle? != [down-vehicle?] of myself])
    [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead
      slow-down
    ]
  ]
  [speed-up ]
end



;; decrease the speed of the turtle
to slow-down  ;; turtle procedure
  ifelse speed <= 0  ;;if speed < 0
  [ set speed 0 ]
  [ set speed speed - acceleration   ]
end

;; increase the speed of the turtle
to speed-up  ;; turtle procedure
  ifelse speed > speed-limit
  [ set speed speed-limit ]
  [ set speed speed + acceleration ]
   
end

;; decrease the speed of the turtle
to opposite-slow-down  ;; turtle procedure
  ifelse speed <= 0  ;;if speed < 0
  [ set speed 0 ]
  [ set speed speed - acceleration ]
end

;; increase the speed of the turtle
to opposite-speed-up  ;; turtle procedure
  ifelse speed > speed-limit
  [ set speed speed-limit ]
  [ set speed speed + acceleration]
end


;; set the color of the turtle to a different color based on how fast the turtle is moving
to set-car-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
  [ ask newcars [ set color blue ] ]
  [ ask newcars [set color blue - 2] ]
end

;; set the color of the turtle to a different color based on how fast the turtle is moving
to set-oppositecar-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
  [ ask oppositecars [ set color red ] ]
  [ ask oppositecars [set color red + 3 ] ]
end

;; set the color of the bus to a different color based on how fast the turtle is moving
to set-bus-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
  [ ask newbuses [ set color magenta ]]
  [ ask newbuses [ set color 95]]
end

;; set the color of the bus to a different color based on how fast the turtle is moving
to set-oppositebus-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
  [ ask oppositebuses [ set color  55]]
  [ ask oppositebuses [ set color 25 ]]
end

;;to count vehicles stopping behind a bus
to count-vehicles-stopped-back
  let x-range 0
let y-range 0
  if grid-size-x = 1 and grid-size-y = 1
      [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]     
      
      if grid-size-x = 1 and grid-size-y = 2
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 12]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1
          ]
        ]
        [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]       
      ]
      
      if grid-size-x = 1 and grid-size-y = 3
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 6]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
         ]
        [
          set x-range 1
          while [x-range <= 30]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]
        
      ]     
      if grid-size-x = 1 and grid-size-y = 4
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 3]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ] 
          
        ]
        [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]
        
      ]        
      if grid-size-x = 2 and grid-size-y = 1
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 30]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]

        ]
        [
               set x-range 1
          while [x-range <= 12]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
         ];end of while
         ]
        
      ]     
      if grid-size-x = 2 and grid-size-y = 2
      [  
          set x-range 1
          while [x-range <= 12]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while]
        
      ]
      
      if grid-size-x = 2 and grid-size-y = 3
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 6]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [
              set x-range 1
          while [x-range <= 12]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]
        
      ] 
          
      if grid-size-x = 2 and grid-size-y = 4
      [
        ifelse up-vehicle?
        [
                  set y-range 1
          while [y-range <= 3]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [ 
          set x-range 1
          while [x-range <= 12]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while]
        
      ]
      ]
      if grid-size-x = 3 and grid-size-y = 1
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 30]
          [
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [         
          set x-range 1
          while [x-range <= 6]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while 
        ]
        
      ]    
       
      if grid-size-x = 3 and grid-size-y = 2
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 12]
          [
          if any? (oppositecars-on patch-ahead (-  y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [          
          set x-range 1
          while [x-range <= 6]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ] 
        
      ]
      
      if grid-size-x = 3 and grid-size-y = 3
      [
        
          set x-range 1
          while [x-range <= 6]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]
           
      if grid-size-x = 3 and grid-size-y = 4
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [y-range <= 3]
          [
          if any? (oppositecars-on patch-ahead ( - y-range)) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [          
          set x-range 1
          while [x-range <= 6]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]         
      ]        
      if grid-size-x = 4 and grid-size-y = 1
      [                
        ifelse up-vehicle?
        [         
          set y-range 1
          while [ y-range <= 30]
          [
          ;set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + count oppositecars with [speed = 0 ]at-points[[0 30]]]
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ] 
          [
            ;user-message(word "h1")stop
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]          
        ]; end of if
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while        
        ]
      ]
        
         
      if grid-size-x = 4 and grid-size-y = 2
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [ y-range <= 12]
          [          
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ] 
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]          
        ]
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]  
        
      ]
      
      if grid-size-x = 4 and grid-size-y = 3
      [
        ifelse up-vehicle?
        [
          set y-range 1
          while [ y-range <= 6]
          [          
          if any? (newcars-on patch-ahead (- y-range)) with [speed = 0 ] 
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]
        ]
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]

        
      ]
           
      if grid-size-x = 4 and grid-size-y = 4
      [        
          set x-range 1
          while [x-range <= 3]
          [
           if any? (newcars-on patch-ahead (- x-range)) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]                         
            

end

;;to count vehicles stopping behind a bus
to count-vehicles-stopped-ahead
let x-range 0
let y-range 0
  if grid-size-x = 1 and grid-size-y = 1
      [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]     
      
      if grid-size-x = 1 and grid-size-y = 2
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 12]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1
          ]
        ]
        [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]       
      ]
      
      if grid-size-x = 1 and grid-size-y = 3
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 6]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
         ]
        [
          set x-range 1
          while [x-range <= 30]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]
        
      ]     
      if grid-size-x = 1 and grid-size-y = 4
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 3]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ] 
          
        ]
        [
        set x-range 1
          while [x-range <= 30]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]
        
      ]        
      if grid-size-x = 2 and grid-size-y = 1
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 30]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]

        ]
        [
               set x-range 1
          while [x-range <= 12]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
         ];end of while
         ]
        
      ]     
      if grid-size-x = 2 and grid-size-y = 2
      [  
          set x-range 1
          while [x-range <= 12]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while]
        
      ]
      
      if grid-size-x = 2 and grid-size-y = 3
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 6]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [
              set x-range 1
          while [x-range <= 12]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]
        
      ] 
          
      if grid-size-x = 2 and grid-size-y = 4
      [
        ifelse down-vehicle?
        [
                  set y-range 1
          while [y-range <= 3]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [ 
          set x-range 1
          while [x-range <= 12]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while]
        
      ]
      ]
      if grid-size-x = 3 and grid-size-y = 1
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 30]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [         
          set x-range 1
          while [x-range <= 6]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while 
        ]
        
      ]    
       
      if grid-size-x = 3 and grid-size-y = 2
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 12]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [          
          set x-range 1
          while [x-range <= 6]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ] 
        
      ]
      
      if grid-size-x = 3 and grid-size-y = 3
      [
        
          set x-range 1
          while [x-range <= 6]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]
           
      if grid-size-x = 3 and grid-size-y = 4
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [y-range <= 3]
          [
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ]   
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set y-range y-range + 1          
          ]
        ]
        [          
          set x-range 1
          while [x-range <= 6]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
        ]         
      ]        
      if grid-size-x = 4 and grid-size-y = 1
      [                
        ifelse down-vehicle?
        [         
          set y-range 1
          while [ y-range <= 30]
          [
          ;set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + count oppositecars with [speed = 0 ]at-points[[0 30]]]
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ] 
          [
            ;user-message(word "h3")stop            
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]          
        ]; end of if
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
           ; user-message(word "h4")stop            
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while        
        ]
      ]
        
         
      if grid-size-x = 4 and grid-size-y = 2
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [ y-range <= 12]
          [          
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ] 
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]          
        ]
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]  
        
      ]
      
      if grid-size-x = 4 and grid-size-y = 3
      [
        ifelse down-vehicle?
        [
          set y-range 1
          while [ y-range <= 6]
          [          
          if any? (oppositecars-on patch-ahead y-range) with [speed = 0 ] 
          [
            set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
           set y-range y-range + 1
          ]
        ]
        [
          set x-range 1
          while [x-range <= 3]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while          
        ]

        
      ]
           
      if grid-size-x = 4 and grid-size-y = 4
      [        
          set x-range 1
          while [x-range <= 3]
          [
           if any? (oppositecars-on patch-ahead x-range) with [speed = 0 ] 
          [  
          set num-cars-stopped-at-yellowstop num-cars-stopped-at-yellowstop + 1
          ]
          set x-range x-range + 1
        ];end of while
      ]                         
            
end

;; keep track of the number of stopped turtles and the amount of time a turtle has been stopped
;; if its speed is 0
to record-data  ;; turtle procedure
  ifelse speed = 0
  [
    set num-cars-stopped num-cars-stopped + 1
    set wait-time wait-time + 1
  ]
  [ set wait-time 0 ]
end


;; keep track of the number of stopped bus and the amount of time a turtle has been stopped
;; if its speed is 0
to record-busdata  ;; turtle procedure
  ifelse speed = 0
  [
    set num-buses-stopped num-buses-stopped + 1
    set bus-wait-time bus-wait-time + 1
  ]
  [ set bus-wait-time 0 ]
end

;; keep track of the number of stopped turtles and the amount of time a turtle has been stopped
to record-slowed-cardata  ;; turtle procedure 
    if speed = 0.3
    [
    set num-cars-slowed num-cars-slowed + 1
;    user-message(num-cars-slowed) stop
    set wait-time wait-time + 0.3
    ]
end

;; keep track of the number of stopped bus and the amount of time a turtle has been stopped
to record-slowed-busdata  ;; turtle procedure
    set num-buses-slowed num-buses-slowed + 1
    set bus-wait-time bus-wait-time + 0.3  
end


to change-current
  ask current-light
  [
    ifelse green-light-up? = true
    [
    set green-light-up? (not green-light-up?)
    ;set-signal-colors
    ask patch-at 0 0
    [
      set pcolor red
    ]
    ];end of if
    [
          set green-light-up? true    
    ask patch-at 0 0
    [
      set pcolor green
    ]
    ]  
  ]  
end

;; cycles phase to the next appropriate value
to next-phase
  ;; The phase cycles from 0 to ticks-per-cycle, then starts over.
  set phase phase + 1
  if phase mod ticks-per-cycle = 0
    [ set phase 0 ]
end


; Copyright 2003 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
325
10
742
448
18
18
11.0
1
12
1
1
1
0
1
1
1
-18
18
-18
18
1
1
1
ticks
30.0

PLOT
774
457
1146
623
Average Wait Time of Cars & buses
Time
Average Wait
0.0
100.0
0.0
5.0
true
true
"" ""
PENS
"cars-wait-time" 1.0 0 -16777216 true "" "plot mean [wait-time] of turtles with [ shape = \"car\" or shape = \"othercar\"]"
"bus-wait-time" 1.0 0 -13345367 true "" "plot mean [bus-wait-time] of turtles with [ shape = \"bus\" or shape = \"other-bus\" or shape = \"horizontalbus\" or shape =\"horizontalbus1\"]"

PLOT
387
458
767
620
Avg Speed of Cars & buses
Time
Average Speed
0.0
100.0
0.0
1.0
true
true
"set-plot-y-range 0 speed-limit" ""
PENS
"car-speed" 1.0 0 -16777216 true "" "plot mean [speed] of turtles with [ shape = \"car\" or shape = \"othercar\"]"
"bus-speed" 1.0 0 -13345367 true "" "plot mean [speed] of turtles with [ shape = \"bus\" or shape = \"other-bus\" or shape = \"horizontalbus\" or shape = \"horizontalbus1\"]"

SLIDER
108
35
205
68
grid-size-y
grid-size-y
1
4
2
1
1
NIL
HORIZONTAL

SLIDER
12
35
106
68
grid-size-x
grid-size-x
1
4
2
1
1
NIL
HORIZONTAL

SWITCH
12
107
107
140
power?
power?
0
1
-1000

SLIDER
12
71
293
104
num-cars
num-cars
1
400
90
1
1
NIL
HORIZONTAL

PLOT
1
455
377
621
Total Stopped Cars & buses
Time
Stopped Cars,buses
0.0
100.0
0.0
100.0
true
true
"set-plot-y-range 0 num-cars + num-buses" ""
PENS
"cars-stopped" 1.0 0 -16777216 true "" "plot num-cars-stopped"
"bus-stopped" 1.0 0 -13791810 true "" "plot num-buses-stopped"

BUTTON
217
203
281
236
Go
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
208
35
292
68
Setup
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
11
177
165
210
speed-limit
speed-limit
0
1
1
0.1
1
NIL
HORIZONTAL

MONITOR
201
151
306
196
Current Phase
phase
3
1
11

SLIDER
11
143
165
176
ticks-per-cycle
ticks-per-cycle
1
100
20
1
1
NIL
HORIZONTAL

SLIDER
146
256
302
289
current-phase
current-phase
0
99
0
1
1
%
HORIZONTAL

BUTTON
9
292
143
325
Change light
change-current
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
9
256
144
289
current-auto?
current-auto?
0
1
-1000

BUTTON
145
292
300
325
Select intersection
choose-current
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
778
258
958
295
add busstop on side
choose-busstop\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
127
107
299
140
num-buses
num-buses
1
200
30
1
1
NIL
HORIZONTAL

BUTTON
776
213
924
246
remove busstop
remove-busstop
T
1
T
PATCH
NIL
NIL
NIL
NIL
0

BUTTON
772
164
969
197
set-busstops-at-signal 
setup-busstops
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
768
119
1008
152
remove-busstops
remove-busstops
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
11
339
259
384
cars stopped due to yellow busstop
num-cars-stopped-at-yellowstop
17
1
11

MONITOR
14
392
255
437
cars slowed due to brown busstop
num-cars-slowed
17
1
11

BUTTON
789
79
1047
112
place busstop away from signal
move-busstops
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
778
312
1247
452
Cars stopped at different stops
Time
Stopped cars
0.0
100.0
0.0
100.0
true
true
"set-plot-y-range 0 25" ""
PENS
"cars stopped at yellow stop" 1.0 0 -10146808 true "" "plot num-cars-stopped-at-yellowstop"
"cars slowed at brown stop" 1.0 0 -14439633 true "" "plot num-cars-slowed"

@#$#@#$#@
## WHAT IS IT?

You control traffic lights and overall variables, such as the speed limit and the number of cars, in a real-time traffic simulation.  This allows you to explore traffic dynamics, which can lead into many areas of study, from calculus to social studies.

Try to develop strategies to improve traffic and to understand the different ways to measure the quality of traffic.

## HOW IT WORKS

Each time step, the cars attempt to move forward at their current speed.  If their current speed is less than the speed limit and there is no car directly in front of them, they accelerate.  If there is a slower car in front of them, they match the speed of the slower car and decelerate.  If there is a red light or a stopped car in front of them, they stop.

There are two different ways the lights can change.  First, the user can change any light at any time by making the light current, and then clicking CHANGE LIGHT.  Second, lights can change automatically, once per cycle.  Initially, all lights will automatically change at the beginning of each cycle.

## HOW TO USE IT

Change the traffic grid (using the sliders GRID-SIZE-X and GRID-SIZE-Y) to make the desired number of lights.  Change any other of the settings that you would like to change.  Press the SETUP button.

At this time, you may configure the lights however you like, with any combination of auto/manual and any phase. Changes to the state of the current light are made using the CURRENT-AUTO?, CURRENT-PHASE and CHANGE LIGHT controls.  You may select the current intersection using the SELECT INTERSECTION control.  See below for details.

Start the simulation by pressing the GO button.  You may continue to make changes to the lights while the simulation is running.

### Buttons

SETUP - generates a new traffic grid based on the current GRID-SIZE-X and GRID-SIZE-Y and NUM-CARS number of cars.  This also clears all the plots. All lights are set to auto, and all phases are set to 0.
GO - runs the simulation indefinitely
CHANGE LIGHT - changes the direction traffic may flow through the current light. A light can be changed manually even if it is operating in auto mode.
SELECT INTERSECTION - allows you to select a new "current" light. When this button is depressed, click in the intersection which you would like to make current. When you've selected an intersection, the "current" label will move to the new intersection and this button will automatically pop up.

### Sliders

SPEED-LIMIT - sets the maximum speed for the cars
NUM-CARS - the number of cars in the simulation (you must press the SETUP button to see the change)
TICKS-PER-CYCLE - sets the number of ticks that will elapse for each cycle.  This has no effect on manual lights.  This allows you to increase or decrease the granularity with which lights can automatically change.
GRID-SIZE-X - sets the number of vertical roads there are (you must press the SETUP button to see the change)
GRID-SIZE-Y - sets the number of horizontal roads there are (you must press the SETUP button to see the change)
CURRENT-PHASE - controls when the current light changes, if it is in auto mode. The slider value represents the percentage of the way through each cycle at which the light should change. So, if the TICKS-PER-CYCLE is 20 and CURRENT-PHASE is 75%, the current light will switch at tick 15 of each cycle.

### Switches

POWER? - toggles the presence of traffic lights
CURRENT-AUTO? - toggles the current light between automatic mode, where it changes once per cycle (according to CURRENT-PHASE), and manual, in which you directly control it with CHANGE LIGHT.

### Plots

STOPPED CARS - displays the number of stopped cars over time
AVERAGE SPEED OF CARS - displays the average speed of cars over time
AVERAGE WAIT TIME OF CARS - displays the average time cars are stopped over time

## THINGS TO NOTICE

When cars have stopped at a traffic light, and then they start moving again, the traffic jam will move backwards even though the cars are moving forwards.  Why is this?

When POWER? is turned off and there are quite a few cars on the roads, "gridlock" usually occurs after a while.  In fact, gridlock can be so severe that traffic stops completely.  Why is it that no car can move forward and break the gridlock?  Could this happen in the real world?

Gridlock can occur when the power is turned on, as well.  What kinds of situations can lead to gridlock?

## THINGS TO TRY

Try changing the speed limit for the cars.  How does this affect the overall efficiency of the traffic flow?  Are fewer cars stopping for a shorter amount of time?  Is the average speed of the cars higher or lower than before?

Try changing the number of cars on the roads.  Does this affect the efficiency of the traffic flow?

How about changing the speed of the simulation?  Does this affect the efficiency of the traffic flow?

Try running this simulation with all lights automatic.  Is it harder to make the traffic move well using this scheme than controlling one light manually?  Why?

Try running this simulation with all lights automatic.  Try to find a way of setting the phases of the traffic lights so that the average speed of the cars is the highest.  Now try to minimize the number of stopped cars.  Now try to decrease the average wait time of the cars.  Is there any correlation between these different metrics?

## EXTENDING THE MODEL

Currently, the maximum speed limit (found in the SPEED-LIMIT slider) for the cars is 1.0.  This is due to the fact that the cars must look ahead the speed that they are traveling to see if there are cars ahead of them.  If there aren't, they speed up.  If there are, they slow down.  Looking ahead for a value greater than 1 is a little bit tricky.  Try implementing the correct behavior for speeds greater than 1.

When a car reaches the edge of the world, it reappears on the other side.  What if it disappeared, and if new cars entered the city at random locations and intervals?

## NETLOGO FEATURES

This model uses two forever buttons which may be active simultaneously, to allow the user to select a new current intersection while the model is running.

It also uses a chooser to allow the user to choose between several different possible plots, or to display all of them at once.

## RELATED MODELS

Traffic Basic simulates the flow of a single lane of traffic in one direction
Traffic 2 Lanes adds a second lane of traffic
Traffic Intersection simulates a single intersection

The HubNet activity Gridlock has very similar functionality but allows a group of users to control the cars in a participatory fashion.


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Wilensky, U. (2003).  NetLogo Traffic Grid model.  http://ccl.northwestern.edu/netlogo/models/TrafficGrid.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  

## COPYRIGHT AND LICENSE

Copyright 2003 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
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

bus
false
0
Polygon -7500403 true true 206 285 150 285 120 285 105 270 105 30 120 15 135 15 206 15 210 30 210 270
Rectangle -16777216 true false 126 69 159 264
Line -7500403 true 135 240 165 240
Line -7500403 true 120 240 165 240
Line -7500403 true 120 210 165 210
Line -7500403 true 120 180 165 180
Line -7500403 true 120 150 165 150
Line -7500403 true 120 120 165 120
Line -7500403 true 120 90 165 90
Line -7500403 true 135 60 165 60
Rectangle -16777216 true false 174 15 182 285
Circle -16777216 true false 187 210 42
Rectangle -16777216 true false 127 24 205 60
Circle -16777216 true false 187 63 42
Line -7500403 true 120 43 207 43

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
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

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

horizontalbus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 true 60 135 60 165
Line -7500403 true 60 120 60 165
Line -7500403 true 90 120 90 165
Line -7500403 true 120 120 120 165
Line -7500403 true 150 120 150 165
Line -7500403 true 180 120 180 165
Line -7500403 true 210 120 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 true 257 120 257 207

horizontalbus1
false
0
Polygon -7500403 true true 285 206 285 150 285 120 270 105 30 105 15 120 15 135 15 206 30 210 270 210
Rectangle -16777216 true false 69 126 264 159
Line -7500403 true 240 135 240 165
Line -7500403 true 240 120 240 165
Line -7500403 true 210 120 210 165
Line -7500403 true 180 120 180 165
Line -7500403 true 150 120 150 165
Line -7500403 true 120 120 120 165
Line -7500403 true 90 120 90 165
Line -7500403 true 60 135 60 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 210 187 42
Rectangle -16777216 true false 24 127 60 205
Circle -16777216 true false 63 187 42
Line -7500403 true 43 120 43 207

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

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

other-bus
false
0
Polygon -7500403 true true 206 15 150 15 120 15 105 30 105 270 120 285 135 285 206 285 210 270 210 30
Rectangle -16777216 true false 126 36 159 231
Line -7500403 true 135 60 165 60
Line -7500403 true 120 60 165 60
Line -7500403 true 120 90 165 90
Line -7500403 true 120 120 165 120
Line -7500403 true 120 150 165 150
Line -7500403 true 120 180 165 180
Line -7500403 true 120 210 165 210
Line -7500403 true 135 240 165 240
Rectangle -16777216 true false 174 15 182 285
Circle -16777216 true false 187 48 42
Rectangle -16777216 true false 127 240 205 276
Circle -16777216 true false 187 195 42
Line -7500403 true 120 257 207 257

othercar
true
0
Polygon -7500403 true true 180 285 164 279 144 261 135 240 132 226 106 213 84 203 63 185 50 159 50 135 60 75 150 15 165 15 225 15 225 285 180 285
Circle -16777216 true false 180 180 90
Circle -16777216 true false 180 30 90
Polygon -16777216 true false 80 162 78 132 135 134 135 209 105 194 96 189 89 180
Circle -7500403 true true 195 47 58
Circle -7500403 true true 195 195 58

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.1
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
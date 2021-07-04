
create target 24 ,                        \ the target number
create inputs 4 floats allot              \ the starting set of numbers
create hstate 4 cells allot               \ working space for permuting

create op-xts ' f+ , ' f- , ' f* , ' f/ , \ the xts of all operations we do
create op-chr '+  c, '-  c, '*  c, '/  c, \ ASCII representation of ops

create curr-ops 0 , 0 , 0 ,               \ the indexes of the current ops

create linear 1 ,                         \ precedence control

: set-target target f! ;

\ sugar for input number access
: input-addr floats inputs + ;
: input@ input-addr f@ ;
: input! input-addr f! ;
: set-inputs 4 0 do i input-addr f! loop ;

\ sugar for heap-algo state access
: hstate@  cells hstate + @  ;
: hstate!  cells hstate + !  ;
: hstate1+! cells hstate + 1 swap +! ;

: op-do    cells curr-ops + @ cells op-xts + @ execute ;
: op-c@    cells curr-ops + @ op-chr + c@ ;
: curr-op! cells curr-ops + ! ;

: .input  input@ fe. ;
: .inputs 4 0 do i .input loop cr ;
: .state  ." hstate = " 4 0 do i hstate@ . loop cr ;
: .op  op-c@ emit bl emit ;
: .ops 3 0 do i .op loop ;

: swap-inputs ( a b -- ) \ gives two input positions (a b) swaps them
  2dup
  input@ input@
  input! input!  ;

: init-state 4 0 do 0 i hstate! loop ;

: do-ith-swap ( u -- )
  dup 2 mod 0=
    if   0 swap-inputs
    else dup hstate@ swap-inputs
    then ;

: zero-i r> rdrop 0 >r >r ;
: inc-i  r> r> 1+ >r >r ;

: each-permutation ( xt -- )
  init-state

  dup execute

  0 >r
  begin
    4 i <= if rdrop drop exit then

    i i hstate@ > if
      i do-ith-swap
      dup execute
      i hstate1+!
      zero-i
    else
      0 hstate i cells + !
      inc-i
    then
  again
  drop
  ;

: this-solution
  4 0 do i input@ loop

  linear @ if
    2 op-do 1 op-do 0 op-do
  else
    2 op-do
    frot frot
    0 op-do
    fswap
    1 op-do
  then
  ;

: (( ." ( " ;
: )) ." ) " ;

: .equation
  linear @
  if
    0 .input 0 .op
    ((
      1 .input 1 .op
      (( 2 .input 2 .op 3 .input ))
    ))
  else
    (( 0 .input 0 .op 1 .input ))
    1 .op
    (( 2 .input 2 .op 3 .input ))
  then
  ." = " target f@ fe. cr ;

: each-opset ( xt -- )
  4 0 do i 0 curr-op!
    4 0 do i 1 curr-op!
      4 0 do i 2 curr-op!
        dup each-permutation
        loop loop loop drop ;

: each-equation
  2 0 do
    i 0= linear !
    dup each-opset
    loop drop ;

: dump-state
  linear @ . cr
  .inputs .ops cr
  this-solution fe. cr
  ." -------- " cr ;

: check-solved
  this-solution target f@ 0.001e f~rel
  if .equation then ;

41e set-target
2e 3e 5e 7e set-inputs


." Inputs are: " .inputs
." Target is : " target f@ fe. cr
' check-solved each-equation

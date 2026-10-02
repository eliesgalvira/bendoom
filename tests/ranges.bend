# The wall ranges of E1M1's start frame: the BSP walked from the player
# 1 start's eye, each seg clipped to the view and against the solid
# columns, and each range left printed in the order Doom stores its
# drawsegs, with the columns it spans and its scale at the first with
# the step a column. Then the solid columns, which in a closed map end
# as the whole width. Pinned to Freedoom.
import Base
import ../src/fixed.bend as F
import ../src/clip.bend as C
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/draw.bend as D
import ../src/bsp.bend as R
import ../src/render.bend as N

def wall(w: D.Draw.Wall) -> String:
  D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil, texcols, tops, bottoms} = w
  "seg " ++ U32.show(seg) ++ " columns " ++ U32.show(x1) ++ " " ++ U32.show(x2) ++ " scale "
    ++ F.Fixed.show(scale1) ++ " step " ++ F.Fixed.show(step)

def walls(ws: List<&2, D.Draw.Wall>) -> IO(Unit):
  match ws:
    case []:
      IO.pure(Unit, Unit{})
    case w <> rest:
      do IO<Unit>:
        IO.print(wall(w))
        walls(rest)

def ranges(rs: List<&2, C.Clip.Range>) -> String:
  match rs:
    case []:
      ""
    case C.Range{first, last} <> rest:
      " " ++ Nat.show(first) ++ " " ++ Nat.show(last) ++ ranges(rest)

def report(st: D.Draw) -> IO(Unit):
  D.Draw{mem, solid, ws, tasks, planes, seen} = st
  do IO<Unit>:
    walls(List.reverse(&2, D.Draw.Wall, ws))
    IO.print("solid" ++ ranges(solid))

def start.go(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  report(R.Bsp.walk(N.Render.eye(P.Project.tables(level), S.Player.start(level)), level, gfx, mem))

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  start.go(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    start(world)

#|seg 431 columns 0 0 scale 1.666976 step 0.000000
#|seg 424 columns 267 319 scale 1.114791 step 0.010391
#|seg 425 columns 1 53 scale 1.657730 step -0.010406
#|seg 428 columns 10 53 scale 1.111099 step 0.000000
#|seg 429 columns 0 9 scale 1.155471 step -0.004852
#|seg 417 columns 0 9 scale 1.111984 step 0.000000
#|seg 435 columns 267 310 scale 1.111099 step 0.000000
#|seg 436 columns 311 319 scale 1.111099 step 0.004714
#|seg 437 columns 311 319 scale 1.111099 step 0.000000
#|seg 460 columns 33 287 scale 1.000000 step 0.000000
#|seg 463 columns 288 310 scale 1.000000 step 0.004791
#|seg 464 columns 10 32 scale 1.106353 step -0.004791
#|seg 456 columns 0 32 scale 1.000457 step 0.000000
#|seg 465 columns 288 319 scale 1.000000 step 0.000000
#|seg 448 columns 252 287 scale 0.719360 step 0.007797
#|seg 449 columns 212 251 scale 0.714279 step 0.000000
#|seg 450 columns 33 68 scale 0.993698 step -0.007797
#|seg 452 columns 115 205 scale 0.714279 step 0.000000
#|seg 453 columns 69 108 scale 0.714279 step 0.000000
#|seg 454 columns 206 211 scale 0.714279 step 0.000000
#|seg 455 columns 109 114 scale 0.714279 step 0.000000
#|seg 559 columns 115 115 scale 0.705963 step 0.000000
#|seg 560 columns 205 205 scale 0.704132 step 0.000000
#|seg 561 columns 116 204 scale 0.689651 step 0.000000
#|seg 556 columns 125 195 scale 0.555541 step 0.000000
#|seg 567 columns 121 124 scale 0.555541 step 0.000000
#|seg 566 columns 69 108 scale 0.555541 step 0.000000
#|seg 566 columns 116 120 scale 0.555541 step 0.000000
#|seg 542 columns 69 86 scale 0.475128 step -0.005233
#|seg 543 columns 87 108 scale 0.384613 step 0.000000
#|seg 543 columns 116 184 scale 0.384613 step 0.000000
#|seg 546 columns 138 181 scale 0.356704 step -0.000534
#|seg 548 columns 182 184 scale 0.343109 step 0.015670
#|seg 550 columns 69 108 scale 0.369689 step -0.000183
#|seg 550 columns 116 137 scale 0.360977 step -0.000183
#|seg 551 columns 69 74 scale 0.356246 step -0.003997
#|seg 554 columns 75 96 scale 0.333328 step 0.000000
#|seg 555 columns 139 181 scale 0.333328 step 0.000000
#|seg 537 columns 196 199 scale 0.555541 step 0.000000
#|seg 534 columns 200 204 scale 0.555541 step 0.000000
#|seg 534 columns 212 231 scale 0.555541 step 0.000000
#|seg 526 columns 219 231 scale 0.461059 step 0.007812
#|seg 529 columns 219 247 scale 0.454544 step 0.000000
#|seg 530 columns 224 247 scale 0.333328 step 0.005233
#|seg 659 columns 215 223 scale 0.286758 step 0.005172
#|seg 660 columns 182 204 scale 0.332382 step -0.001510
#|seg 660 columns 212 214 scale 0.286712 step -0.001556
#|seg 632 columns 139 143 scale 0.329406 step -0.015579
#|seg 633 columns 144 176 scale 0.263153 step 0.000000
#|seg 634 columns 177 181 scale 0.265090 step 0.015579
#|seg 631 columns 144 176 scale 0.256408 step 0.000000
#|seg 621 columns 173 176 scale 0.203964 step 0.015548
#|seg 623 columns 144 147 scale 0.250610 step -0.015426
#|seg 625 columns 170 172 scale 0.154388 step 0.016357
#|seg 626 columns 152 169 scale 0.128295 step 0.000839
#|seg 627 columns 148 150 scale 0.190368 step -0.016479
#|seg 652 columns 139 143 scale 0.263153 step 0.000000
#|seg 646 columns 149 150 scale 0.149993 step 0.001113
#|seg 649 columns 139 147 scale 0.263153 step -0.012405
#|seg 639 columns 97 108 scale 0.328872 step -0.005187
#|seg 639 columns 116 118 scale 0.229873 step -0.005142
#|seg 640 columns 119 129 scale 0.213973 step -0.005172
#|seg 641 columns 134 147 scale 0.137237 step 0.001007
#|seg 643 columns 137 148 scale 0.137954 step 0.000991
#|seg 645 columns 135 136 scale 0.136016 step 0.001007
#|seg 637 columns 149 151 scale 0.125717 step 0.000885
#|seg 654 columns 149 150 scale 0.125061 step 0.000106
#|seg 656 columns 151 169 scale 0.125701 step 0.000823
#|seg 617 columns 212 214 scale 0.270904 step 0.005325
#|seg 619 columns 177 181 scale 0.263153 step 0.000000
#|seg 613 columns 170 171 scale 0.141555 step 0.000930
#|seg 615 columns 172 181 scale 0.150619 step 0.012466
#|seg 609 columns 169 170 scale 0.126892 step 0.000335
#|seg 606 columns 171 185 scale 0.127609 step 0.000335
#|seg 607 columns 186 204 scale 0.135070 step 0.005203
#|seg 658 columns 185 185 scale 0.130172 step 0.000000
#|seg 671 columns 145 148 scale 0.122360 step 0.000823
#|seg 672 columns 137 144 scale 0.121948 step 0.000000
#|seg 675 columns 147 150 scale 0.122360 step 0.000854
#|seg 678 columns 145 146 scale 0.120788 step 0.000823
#|seg 679 columns 137 144 scale 0.120468 step 0.000000
#|seg 669 columns 137 137 scale 0.119827 step 0.000000
#|seg 662 columns 151 168 scale 0.125244 step 0.000076
#|seg 666 columns 138 138 scale 0.114929 step 0.000000
#|seg 667 columns 139 159 scale 0.111099 step 0.000000
#|seg 668 columns 160 184 scale 0.111022 step 0.000686
#|seg 701 columns 160 160 scale 0.108093 step 0.000000
#|seg 693 columns 140 153 scale 0.107513 step 0.000000
#|seg 695 columns 154 159 scale 0.107513 step 0.000000
#|seg 690 columns 161 165 scale 0.107513 step 0.000000
#|seg 691 columns 166 167 scale 0.107513 step 0.000000
#|seg 692 columns 168 172 scale 0.107513 step 0.000000
#|seg 685 columns 173 173 scale 0.108093 step 0.000000
#|seg 687 columns 174 180 scale 0.107513 step 0.000000
#|seg 588 columns 130 133 scale 0.136978 step 0.000000
#|seg 583 columns 132 134 scale 0.135131 step 0.000000
#|seg 589 columns 130 131 scale 0.135131 step 0.000000
#|seg 593 columns 130 132 scale 0.134567 step -0.004531
#|seg 595 columns 130 132 scale 0.121948 step 0.000000
#|seg 569 columns 133 136 scale 0.121948 step 0.000000
#|seg 581 columns 134 136 scale 0.120468 step 0.000000
#|seg 576 columns 133 133 scale 0.120391 step 0.000000
#|seg 570 columns 133 139 scale 0.107513 step 0.000000
#|seg 737 columns 180 180 scale 0.103744 step 0.000000
#|seg 738 columns 154 159 scale 0.103088 step 0.000000
#|seg 738 columns 161 172 scale 0.103088 step 0.000000
#|seg 738 columns 174 179 scale 0.103088 step 0.000000
#|seg 1375 columns 161 164 scale 0.097076 step 0.000000
#|seg 1379 columns 161 164 scale 0.091735 step 0.000000
#|seg 1365 columns 169 169 scale 0.093017 step 0.000000
#|seg 1367 columns 165 168 scale 0.091735 step 0.000000
#|seg 1368 columns 170 172 scale 0.097076 step 0.000000
#|seg 1372 columns 169 172 scale 0.091735 step 0.000000
#|seg 1362 columns 178 178 scale 0.093688 step 0.000000
#|seg 1364 columns 174 177 scale 0.091735 step 0.000000
#|seg 1283 columns 156 159 scale 0.091735 step 0.000000
#|seg 1286 columns 154 155 scale 0.097076 step 0.000000
#|seg 1290 columns 154 155 scale 0.091735 step 0.000000
#|seg 1669 columns 228 251 scale 0.265411 step 0.003921
#|seg 1672 columns 215 227 scale 0.281845 step -0.001525
#|seg 1667 columns 186 194 scale 0.132720 step 0.000457
#|seg 1673 columns 188 188 scale 0.109497 step 0.000000
#|seg 1676 columns 181 187 scale 0.107513 step 0.000000
#|seg 1677 columns 192 194 scale 0.125442 step 0.003753
#|seg 1683 columns 179 179 scale 0.097076 step 0.000000
#|seg 1687 columns 178 179 scale 0.091735 step 0.000000
#|seg 1695 columns 212 227 scale 0.162567 step 0.003112
#|seg 1696 columns 195 204 scale 0.136978 step 0.000701
#|seg 1700 columns 189 191 scale 0.111099 step 0.000000
#|solid 0 319

# Expectations from Chocolate Doom p_user.c, p_inter.c and st_stuff.c.
import Base
import ../src/inventory.bend as I
import ../src/bar.bend as Y
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ./fixtures/closed.bend as Fx

def words(xs: List<&2, U32>) -> String:
  List.show(~&2, ~U32, ~U32.show, xs)

def visor(+inv: I.Inventory) -> String:
  words([I.Inventory.power.of(I.Inventory.pw_infrared(), inv), I.Inventory.fixedcolormap(inv)])

def picked(g: Fx.Closed.Got) -> String:
  Fx.Got{alive, inv} = g
  visor(inv)

def counted(tics: U32) -> String:
  visor(I.Inventory.tic(I.Inventory.power(I.Inventory.pw_infrared(), tics, I.Inventory.start())))

def killed(+s: S.State) -> S.State:
  Tic.Sim.damage(H.Things.you(S.State.things(s)), 100, H.Thing.you(), H.Thing.you(), s)

def frozen() -> String:
  visor(S.Player.inv(S.State.player(Fx.Closed.idled(3n, killed(Fx.Closed.among(
    I.Inventory.tic(I.Inventory.power(I.Inventory.pw_infrared(), 128, I.Inventory.start())), 2097152, 0, 0, []))))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("suit palettes " ++ words([Y.Bar.palette(0, 0, 0, 2100), Y.Bar.palette(0, 0, 0, 129),
      Y.Bar.palette(0, 0, 0, 128), Y.Bar.palette(0, 0, 0, 127), Y.Bar.palette(0, 0, 0, 119),
      Y.Bar.palette(0, 0, 0, 8), Y.Bar.palette(0, 0, 0, 7), Y.Bar.palette(0, 0, 0, 0)]))
    IO.print("suit priority " ++ words([Y.Bar.palette(1, 0, 0, 2100), Y.Bar.palette(0, 1, 0, 2100),
      Y.Bar.palette(0, 0, 1, 2100)]))
    IO.print("visor pickup " ++ picked(Fx.Closed.offer(I.Inventory.start(), 2045)))
    IO.print("visor tic3 " ++ picked(Fx.Closed.walk(3n, 524288, I.Inventory.start(), 2045)))
    IO.print("visor renew " ++ picked(Fx.Closed.offer(I.Inventory.power(I.Inventory.pw_infrared(), 9,
      I.Inventory.start()), 2045)))
    IO.print("visor129 " ++ counted(130))
    IO.print("visor128 " ++ counted(129))
    IO.print("visor127 " ++ counted(128))
    IO.print("visor119 " ++ counted(120))
    IO.print("visor zero " ++ counted(1))
    IO.print("dead visor " ++ frozen())
    IO.print("level visor " ++ visor(I.Inventory.finished(I.Inventory.tic(I.Inventory.power(
      I.Inventory.pw_infrared(), 4200, I.Inventory.start())))))

#|suit palettes [13, 13, 0, 13, 0, 13, 0, 0]
#|suit priority [2, 3, 10]
#|visor pickup [4200, 0]
#|visor tic3 [4198, 1]
#|visor renew [4200, 1]
#|visor129 [129, 1]
#|visor128 [128, 0]
#|visor127 [127, 1]
#|visor119 [119, 0]
#|visor zero [0, 0]
#|dead visor [127, 1]
#|level visor [0, 0]

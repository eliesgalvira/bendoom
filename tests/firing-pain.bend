# P_FireWeapon enters S_PLAY_ATK1 before the delayed shot; A_FirePistol,
# A_FireShotgun and a loaded A_FireCGun enter S_PLAY_ATK2. Both cancel
# S_PLAY_PAIN before its pending A_Pain. An empty A_FireCGun returns
# before that transition. These are p_pspr.c's ordering, also observed
# in Chocolate at DEMO1/114, DEMO2/624-625 and E1M8/1832-1833.
import Base
import ./fixtures/closed.bend as Fx
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/things.bend as H
import ../src/vec.bend as V
import ../src/sound.bend as Sn

def pain(events: List<&2, Sn.Sound.Event>) -> U32:
  match events:
    case []:
      0
    case Sn.Start{sfx, source, vol, sep} <> rest:
      (Bool.to_u32(U32.is_eq(sfx, Sn.Sound.plpain())) + pain(rest) : U32)
    case Sn.Stop{source} <> rest:
      pain(rest)

def run(+weapon: U32, row: U32, +ammo: U32) -> U32:
  +p = S.Player.holding(Fx.Closed.player(0, 0, 0, 8388608),
    Fx.Closed.inv([Fx.Selection{weapon, 255}, Fx.Ammo{[ammo, ammo, 0, ammo]}]))
  +hurt = V.Vec.set(V.Vec.set(S.Player.hurt(p), S.Sim.hurt.state(), 71), S.Sim.hurt.tics(), 1)
  +ready = S.Player.showing(S.Player.hurting(p, hurt),
    S.Psprites{S.Psprite{Some{row}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}})
  pain(S.State.sounds(Tic.Sim.tic(K.Cmd{0, 0, 0, 1},
    S.State.attacking(False{}, Fx.Closed.state(ready, L.Level.room(0, 128), 0)))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("ready pistol " ++ U32.show(run(1, H.Thing.Weapon.ready(H.Thing.pistol()), 50)))
    IO.print("ready shotgun " ++ U32.show(run(2, H.Thing.Weapon.ready(H.Thing.shotgun()), 50)))
    IO.print("ready launcher " ++ U32.show(run(4, H.Thing.Weapon.ready(H.Thing.launcher()), 50)))
    IO.print("pistol shot " ++ U32.show(run(1, 79, 50)))
    IO.print("shotgun shot " ++ U32.show(run(2, 204, 50)))
    IO.print("chaingun second shot " ++ U32.show(run(3, 233, 50)))
    IO.print("empty chaingun second shot " ++ U32.show(run(3, 233, 0)))
#|ready pistol 0
#|ready shotgun 0
#|ready launcher 0
#|pistol shot 0
#|shotgun shot 0
#|chaingun second shot 0
#|empty chaingun second shot 1

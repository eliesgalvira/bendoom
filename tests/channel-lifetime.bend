# Chocolate's eight-channel saturation capture: pistol22516, baron44012,
# saw29996 frames. Callback18 ends the pistols; S_GetChannel rejects
# the saw at19 before S_UpdateSounds frees them. Callback completion
# retains bounded cursors even through further mixes without an update.
import Base
import ../src/channel.bend as C
import ../src/stream.bend as A
import ../src/sound.bend as Sn

def Test.params(ctx: Unit, source: Sn.Sound.Source) -> U32 & U32:
  (64, 129)

def Test.pistols(ids: List<&2, U32>, chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  match ids:
    case []:
      C.Channel.start(C.Sound{67, 0, 44012}, Sn.Thing{9}, 62, 65, chans)
    case id <> rest:
      Test.pistols(rest, C.Channel.start(C.Sound{1, 0, 22516}, Sn.Thing{id}, 62, 65, chans))

def Test.slot(c: Maybe<&2, C.Channel>) -> String:
  match c:
    case None{}:
      "empty"
    case Some{C.Chan{at, sfx, source, left, right, end}}:
      U32.show(sfx) ++ " " ++ U32.show(at) ++ " " ++ U32.show(end)

def Test.second(chans: List<&2, Maybe<&2, C.Channel>>) -> String:
  Test.slot(Maybe.default(&2, Maybe<&2, C.Channel>, List.get(&2, Maybe<&2, C.Channel>, chans, 1n), None{}))

def Test.saw(chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  C.Channel.start(C.Sound{11, 0, 29996}, Sn.Thing{10}, 62, 65, C.Channel.hush(Sn.Thing{10}, chans))

def Test.update(chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  C.Channel.update(~Unit, ~Test.params, Unit{}, chans)

def main() -> IO(Unit):
  +expired = A.Stream.played(22680, Test.pistols([1, 2, 3, 4, 5, 6, 7, 8], C.Channel.none()))
  +accepted = Test.saw(Test.update(expired))
  +repeated = A.Stream.played(1260, A.Stream.played(113400, accepted))
  do IO<Unit>:
    IO.print("expired " ++ Test.second(expired))
    IO.print("reject19 " ++ Test.second(Test.saw(expired)))
    IO.print("update19 " ++ Test.second(Test.update(expired)))
    IO.print("accept20 " ++ Test.second(accepted))
    IO.print("repeated " ++ Test.second(repeated))
    IO.print("cleanup " ++ Test.second(Test.update(repeated)))
#|expired 1 22516 22516
#|reject19 1 22516 22516
#|update19 empty
#|accept20 11 0 29996
#|repeated 11 29996 29996
#|cleanup empty

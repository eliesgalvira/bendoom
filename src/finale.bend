# Doom's shareware E1 finale, from f_finale.c and d_englsh.h.
import Base
import ./bytes.bend as B
import ./gfx.bend as G
import ./draw.bend as D
import ./message.bend as M

type Finale is Data:
  Finale{count: U32, art: Bool}

def Finale.text() -> String:
  "Once you beat the big badasses and\n" ++
    "clean out the moon base you're supposed\n" ++
    "to win, aren't you? Aren't you? Where's\n" ++
    "your fat reward and ticket home? What\n" ++
    "the hell is this? It's not supposed to\n" ++
    "end this way!\n" ++
    "\n" ++
    "It stinks like rotten meat, but looks\n" ++
    "like the lost Deimos base.  Looks like\n" ++
    "you're stuck on The Shores of Hell.\n" ++
    "The only way out is through.\n" ++
    "\n" ++
    "To continue the DOOM experience, play\n" ++
    "The Shores of Hell and its amazing\n" ++
    "sequel, Inferno!\n"

def Finale.start() -> Finale:
  Finale{0, False{}}

def Finale.ticked(over: Bool, count: U32) -> Finale:
  match over:
    case True{}:
      Finale{0, True{}}
    case False{}:
      Finale{count, False{}}

def Finale.textend() -> U32:
  (440 * 3 + 250 : U32)

def Finale.tic(f: Finale) -> Finale:
  match f:
    case Finale{count, True{}}:
      Finale{(count + 1 : U32), True{}}
    case Finale{+count, False{}}:
      Finale.ticked(U32.is_gt((count + 1 : U32), Finale.textend()), (count + 1 : U32))

def Finale.outro(f: Finale) -> Nat:
  match f:
    case Finale{+count, False{}}:
      U32.to_nat((Finale.textend() + 1 - count + 105 : U32))
    case Finale{count, True{}}:
      105n

def Finale.budget(+count: U32) -> U32:
  Bool.pick(U32, U32.is_le(count, 10), 0, ((count - 10) / 3 : U32))

def Finale.tile.put(+i: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, colour) = p
  Array.set(U32, mem, (G.Gfx.frame() + i : U32), colour)

def Finale.tile(n: Nat, +i: U32, +flat: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Finale.tile(m, (i + 1 : U32), flat,
        Finale.tile.put(i, B.Bytes.at(mem, (flat + ((i / 320 : U32) .&. 63 : U32) * 64 + (i .&. 63 : U32) : U32))))

type Finale.Pen is Type:
  Pen{mem: Array<U32>, x: U32, y: U32, done: Bool}

def Finale.fit(fits: Bool, +x: U32, +y: U32, w: U32, patch: U32, mem: Array<U32>) -> Finale.Pen:
  match fits:
    case False{}:
      Pen{mem, x, y, True{}}
    case True{}:
      Pen{D.Draw.patch(mem, patch, x, y), (x + w : U32), y, False{}}

def Finale.wide(+x: U32, y: U32, patch: U32, p: Array<U32> & U32) -> Finale.Pen:
  (mem, +w) = p
  Finale.fit(U32.is_le((x + w : U32), 320), x, y, w, patch, mem)

def Finale.glyph(g: Maybe<&2, U32>, +gfx: G.Gfx, +x: U32, y: U32, mem: Array<U32>) -> Finale.Pen:
  match g:
    case None{}:
      Pen{mem, (x + 4 : U32), y, False{}}
    case Some{i}:
      +patch = G.Gfx.font(gfx, i)
      Finale.wide(x, y, patch, B.Bytes.u16(mem, patch))

def Finale.char(newline: Bool, c: Char, gfx: G.Gfx, x: U32, +y: U32, mem: Array<U32>) -> Finale.Pen:
  match newline:
    case True{}:
      Pen{mem, 10, (y + 11 : U32), False{}}
    case False{}:
      Finale.glyph(M.Message.glyph(c), gfx, x, y, mem)

def Finale.write(text: String, budget: Nat, +gfx: G.Gfx, pen: Finale.Pen) -> Array<U32>:
  match text budget pen:
    case SCon{+c, rest} 1n+n Pen{mem, x, y, False{}}:
      Finale.write(rest, n, gfx, Finale.char(U32.is_eq(Char.to_u32(c), 10), c, gfx, x, y, mem))
    case _ _ Pen{mem, x, y, done}:
      mem

def Finale.frame(+gfx: G.Gfx, f: Finale, mem: Array<U32>) -> Array<U32>:
  match f:
    case Finale{count, True{}}:
      D.Draw.patch(mem, G.Gfx.patch(gfx, "HELP2"), 0, 0)
    case Finale{count, False{}}:
      Finale.write(Finale.text(), U32.to_nat(Finale.budget(count)), gfx,
        Pen{Finale.tile(64000n, 0, G.Gfx.flat(gfx, 0), mem), 10, 10, False{}})

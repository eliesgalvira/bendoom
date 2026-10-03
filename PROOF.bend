# The proofs: every law in LAWS.bend, filled. `bend PROOF.bend` is the
# gate; it fails while any law is open or false.
import Base
import ./tests/fixtures/closed.bend as Fx
import ./src/wad.bend as W
import ./src/vec.bend as V
import ./src/fixed.bend as F
import ./src/angle.bend as A
import ./src/level.bend as L
import ./src/keys.bend as K
import ./src/sound.bend as Sn
import ./src/sim.bend as S
import ./src/special.bend as Sp
import ./src/tic.bend as Tic
import ./src/things.bend as H
import ./src/inventory.bend as I
import ./src/clip.bend as C
import ./src/draw.bend as D
import ./src/channel.bend as Ch
import ./LAWS.bend as Laws

def channel_clear_size(slots: List<&2, Maybe<&2, Ch.Channel.Voice>>) ->
  {Ch.Channel.model.size(slots) == Ch.Channel.model.size(Ch.Channel.model.clear.all(slots)) : Nat}:
  match slots:
    case []:
      {==}
    case c <> rest:
      %channel_clear_size(rest) : {1n+Ch.Channel.model.size(rest) == 1n+_ : Nat}
      {==}

def channel_replace_size(slots: List<&2, Maybe<&2, Ch.Channel.Voice>>, n: Nat, priority: Nat) ->
  {Ch.Channel.model.size(slots) == Ch.Channel.model.size(Ch.Channel.model.replace(slots, n, priority)) : Nat}:
  match slots n:
    case [] _:
      {==}
    case c <> rest 0n:
      %channel_clear_size(rest) : {1n+Ch.Channel.model.size(rest) == 1n+_ : Nat}
      {==}
    case c <> rest 1n+m:
      %channel_replace_size(rest, m, priority) : {1n+Ch.Channel.model.size(rest) == 1n+_ : Nat}
      {==}

def channel_clear_one(slots: List<&2, Maybe<&2, Ch.Channel.Voice>>, seen: Bool) ->
  {True{} == Ch.Channel.model.one(Ch.Channel.model.clear.all(slots), seen) : Bool}:
  match slots:
    case []:
      {==}
    case None{} <> +rest:
      channel_clear_one(rest, seen)
    case Some{Ch.Voice{mine, priority}} <> rest:
      match seen:
        case True{}:
          channel_clear_one(rest, True{})
        case False{}:
          channel_clear_one(rest, False{})

def channel_replace_one(slots: List<&2, Maybe<&2, Ch.Channel.Voice>>, n: Nat, priority: Nat) ->
  {True{} == Ch.Channel.model.one(Ch.Channel.model.replace(slots, n, priority), False{}) : Bool}:
  match slots n:
    case [] _:
      {==}
    case c <> rest 0n:
      channel_clear_one(rest, True{})
    case None{} <> rest 1n+m:
      channel_replace_one(rest, m, priority)
    case Some{Ch.Voice{mine, old}} <> rest 1n+m:
      channel_replace_one(rest, m, priority)

def channel_keys_none_table(p: List<&2, Maybe<&2, Ch.Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  {None{} <> Ch.Channel.model.table(p) == Ch.Channel.model.table(Ch.Channel.model.keys.none(p))
    : List<&2, Maybe<&2, Ch.Channel.Voice>>}:
  match p:
    case (slots, keys):
      {==}

def channel_keys_some_table(mine: Bool, priority: Nat,
  p: List<&2, Maybe<&2, Ch.Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  {Some{Ch.Voice{mine, priority}} <> Ch.Channel.model.table(p)
    == Ch.Channel.model.table(Ch.Channel.model.keys.some(mine, priority, p))
    : List<&2, Maybe<&2, Ch.Channel.Voice>>}:
  match p:
    case (slots, keys):
      {==}

def channel_keys_keep(slots: List<&2, Maybe<&2, Ch.Channel.Voice>>) ->
  {slots == Ch.Channel.model.table(Ch.Channel.model.keys(slots))
    : List<&2, Maybe<&2, Ch.Channel.Voice>>}:
  match slots:
    case []:
      {==}
    case None{} <> +rest:
      %channel_keys_none_table(Ch.Channel.model.keys(rest))
        : {None{} <> rest == _ : List<&2, Maybe<&2, Ch.Channel.Voice>>}
      %channel_keys_keep(rest)
        : {None{} <> rest == None{} <> _ : List<&2, Maybe<&2, Ch.Channel.Voice>>}
      {==}
    case Some{Ch.Voice{+mine, +priority}} <> +rest:
      %channel_keys_some_table(mine, priority, Ch.Channel.model.keys(rest))
        : {Some{Ch.Voice{mine, priority}} <> rest == _ : List<&2, Maybe<&2, Ch.Channel.Voice>>}
      %channel_keys_keep(rest)
        : {Some{Ch.Voice{mine, priority}} <> rest == Some{Ch.Voice{mine, priority}} <> _
          : List<&2, Maybe<&2, Ch.Channel.Voice>>}
      {==}

def channel_start_size(+priority: Nat,
  p: List<&2, Maybe<&2, Ch.Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  {Ch.Channel.model.size(Ch.Channel.model.table(p))
    == Ch.Channel.model.size(Ch.Channel.model.start.hushed(priority, p)) : Nat}:
  match p:
    case (slots, keys):
      channel_replace_size(slots, Ch.Channel.choice(priority, keys), priority)

def channel_start_one(+priority: Nat,
  p: List<&2, Maybe<&2, Ch.Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  {True{} == Ch.Channel.model.one(Ch.Channel.model.start.hushed(priority, p), False{}) : Bool}:
  match p:
    case (slots, keys):
      channel_replace_one(slots, Ch.Channel.choice(priority, keys), priority)

def channel_capacity(priority: Nat, +slots: List<&2, Maybe<&2, Ch.Channel.Voice>>) ->
  {(Ch.Channel.model.size(Ch.Channel.model.start(priority, slots)),
    Ch.Channel.model.size(Ch.Channel.model.none()))
    == (Ch.Channel.model.size(slots), 8n) : Nat & Nat}:
  %channel_start_size(priority, Ch.Channel.model.keys(slots))
    : {(_, Ch.Channel.model.size(Ch.Channel.model.none()))
      == (Ch.Channel.model.size(slots), 8n) : Nat & Nat}
  %channel_keys_keep(slots)
    : {(Ch.Channel.model.size(_), Ch.Channel.model.size(Ch.Channel.model.none()))
      == (Ch.Channel.model.size(slots), 8n) : Nat & Nat}
  {==}

def Laws.channels_capacity(priority, slots):
  channel_capacity(priority, slots)

def Laws.channels_unique_source(priority, slots):
  channel_start_one(priority, Ch.Channel.model.keys(slots))

def Laws.text_nul_ends(rest):
  {==}

def Laws.text_byte_kept(rest):
  {==}

# A comparison of a value with itself answers EQ, from a bit up to a
# string; stated value first so a rewrite replaces the comparison in a
# goal by its answer.

def bool_cmp_refl(b: Bool) -> {EQ{} == Bool.cmp(b, b) : Cmp}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def word_cmp_refl(n: Nat, w: Word(n)) -> {EQ{} == Word.cmp(n, w, w) : Cmp}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{hb, ht}:
          %word_cmp_refl(p, ht) : {EQ{} == Word.cmp.fin(hb, hb, _) : Cmp}
          %bool_cmp_refl(hb) : {EQ{} == _ : Cmp}
          {==}

def u32_cmp_refl(x: U32) -> {EQ{} == U32.cmp(x, x) : Cmp}:
  match x:
    case U32{w}:
      word_cmp_refl(32n, w)

def char_cmp_refl(c: Char) ->
  {((c, c), EQ{}) == Char.cmp(c, c) : (Char & Char) & Cmp}:
  match c:
    case Chr{x}:
      %u32_cmp_refl(x)
        : {((Chr{x}, Chr{x}), EQ{}) == ((Chr{x}, Chr{x}), _) : (Char & Char) & Cmp}
      {==}

def string_cmp_refl(s: String) ->
  {((s, s), EQ{}) == String.cmp(s, s) : (String & String) & Cmp}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      %char_cmp_refl(h)
        : {((SCon{h, t}, SCon{h, t}), EQ{}) == String.cmp.fin(t, t, _) : (String & String) & Cmp}
      %string_cmp_refl(t)
        : {((SCon{h, t}, SCon{h, t}), EQ{}) == String.cmp.rec(h, h, _) : (String & String) & Cmp}
      {==}

def string_eq_refl(s: String) -> {True{} == String.eq(s, s) : Bool}:
  %string_cmp_refl(s) : {True{} == String.eq.fin(_) : Bool}
  {==}

def Laws.index_head(name, pos, size, rest):
  %string_eq_refl(name)
    : {W.Wad.index.pick(_, W.Wad.index(name, rest)) == Some{0n} : Maybe<Nat>}
  {==}

# Keys: a key's flag set twice keeps the second setting, and so does
# a number key, by the place the code names; the nine flags and the
# number keys are rewritten one by one, abstracted from the key code.

def set_twice(b: Bool, +d1: Bool, +d2: Bool, +old: Bool) ->
  {K.Keys.set(b, d2, old) == K.Keys.set(b, d2, K.Keys.set(b, d1, old)) : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def numbers_twice(ns: List<&2, Bool>, place: Nat, +d1: Bool, +d2: Bool) ->
  {K.Keys.numbers(ns, place, d2) == K.Keys.numbers(K.Keys.numbers(ns, place, d1), place, d2)
    : List<&2, Bool>}:
  match ns:
    case []:
      {==}
    case held <> rest:
      match place:
        case 0n:
          {==}
        case 1n+p:
          %numbers_twice(rest, p, d1, d2)
            : {held <> K.Keys.numbers(rest, p, d2) == held <> _ : List<&2, Bool>}
          {==}

def press9(b1: Bool, b2: Bool, b3: Bool, b4: Bool, b5: Bool, b6: Bool, b7: Bool, b8: Bool, b9: Bool,
  place: Nat, +d1: Bool, +d2: Bool, +up: Bool, +dn: Bool, +left: Bool, +right: Bool, +sleft: Bool,
  +sright: Bool, +run: Bool, +use: Bool, +fire: Bool, +numbers: List<&2, Bool>) ->
  {K.Keys{K.Keys.set(b1, d2, K.Keys.set(b1, d1, up)), K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)),
    K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
    K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
    K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
    K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(K.Keys.numbers(numbers, place, d1), place, d2)}
    == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
      K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}:
  %numbers_twice(numbers, place, d1, d2)
    : {K.Keys{K.Keys.set(b1, d2, K.Keys.set(b1, d1, up)), K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)),
      K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), _}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b1, d1, d2, up)
    : {K.Keys{_, K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)),
      K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b2, d1, d2, dn)
    : {K.Keys{K.Keys.set(b1, d2, up), _,
      K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b3, d1, d2, left)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      _, K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b4, d1, d2, right)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), _,
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b5, d1, d2, sleft)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      _, K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b6, d1, d2, sright)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      K.Keys.set(b5, d2, sleft), _,
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b7, d1, d2, run)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      _, K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b8, d1, d2, use)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), _,
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  %set_twice(b9, d1, d2, fire)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
      K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
      K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
      _, K.Keys.numbers(numbers, place, d2)}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn),
        K.Keys.set(b3, d2, left), K.Keys.set(b4, d2, right),
        K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use),
        K.Keys.set(b9, d2, fire), K.Keys.numbers(numbers, place, d2)} : K.Keys}
  {==}

def Laws.last_press(code, d1, d2, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use, fire, numbers}:
      press9(U32.is_eq(code, 63232) || U32.is_eq(code, 119),
        U32.is_eq(code, 63233) || U32.is_eq(code, 115), U32.is_eq(code, 63234),
        U32.is_eq(code, 63235), U32.is_eq(code, 97), U32.is_eq(code, 100),
        U32.is_eq(code, 65592) || U32.is_eq(code, 65596), U32.is_eq(code, 32),
        U32.is_eq(code, 65595) || U32.is_eq(code, 65598), K.Keys.number(code), d1, d2, up, dn, left, right, sleft,
        sright, run, use, fire, numbers)

def Laws.arrows_wasd(down, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use, fire, numbers}:
      {==}

def Laws.lowest_number_wins(rest):
  {==}

# The player of tic_rest's law, at rest at a place with the inventory
# G_PlayerReborn gives, the state a tic begins with, and the state its
# move and eye leave, which the sector's special is handed.
def rest_player(+x: U32, +y: U32) -> S.Player:
  S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}

def rest_before(+geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +heard: V.Vec, +x: U32, +y: U32) -> S.State:
  Fx.Closed.state(rest_player(x, y), L.Level{geo, sectors, specials, heard}, 0)

def rest_walked(+geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +heard: V.Vec, +x: U32, +y: U32) -> S.State:
  S.State.player.put(rest_before(geo, sectors, specials, heard, x, y),
    S.Sim.eye(L.Level{geo, sectors, specials, heard}, 0,
      S.Sim.move(L.Level{geo, sectors, specials, heard}, K.Cmd.idle(), rest_player(x, y))))

# The think a tic from rest makes, once the nukage's flag is known: a
# level the law says nothing about leaves that flag stuck, and the blow
# it may deal writes the health, the wound and the momentum, never the
# place.
def rest_think(+due: Bool, +geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +heard: V.Vec, +x: U32, +y: U32) -> S.State:
  Sp.Sim.use(Bool.and(Bool.not(S.Player.dead(rest_player(x, y))), Tic.Sim.pressed(K.Cmd.idle(), False{})),
    Tic.Sim.player.thinks(K.Cmd.idle(), Sp.Sim.sector.hurt(due, rest_walked(geo, sectors, specials, heard, x, y))))

def rest_due(due: Bool, +geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +heard: V.Vec, +x: U32, +y: U32) ->
  {(S.Player.x(S.State.player(Tic.Sim.tic.done(K.Cmd.idle(), geo, 0, x, y,
      rest_think(due, geo, sectors, specials, heard, x, y)))),
    S.Player.y(S.State.player(Tic.Sim.tic.done(K.Cmd.idle(), geo, 0, x, y,
      rest_think(due, geo, sectors, specials, heard, x, y)))))
    == (x, y) : U32 & U32}:
  match due:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.tic_rest(level, x, y):
  match level:
    case L.Level{geo, sectors, specials, heard}:
      rest_due(Bool.and(U32.is_eq(L.Level.sector.special(L.Level{geo, sectors, specials, heard},
          L.Level.sector_at(L.Level{geo, sectors, specials, heard},
            S.Player.x(S.State.player(rest_walked(geo, sectors, specials, heard, x, y))),
            S.Player.y(S.State.player(rest_walked(geo, sectors, specials, heard, x, y))))), 7),
        Bool.and(U32.is_zero((0 .&. 31 : U32)),
          U32.is_eq(S.Player.z(S.State.player(rest_walked(geo, sectors, specials, heard, x, y))),
            L.Level.floor(L.Level{geo, sectors, specials, heard},
              L.Level.sector_at(L.Level{geo, sectors, specials, heard},
                S.Player.x(S.State.player(rest_walked(geo, sectors, specials, heard, x, y))),
                S.Player.y(S.State.player(rest_walked(geo, sectors, specials, heard, x, y)))))))),
        geo, sectors, specials, heard, x, y)

def Laws.tic_counts(cmd, p, level, clock, secret):
  match level secret:
    case L.Level{geo, sectors, specials, heard} True{}:
      {==}
    case L.Level{geo, sectors, specials, heard} False{}:
      {==}

def Laws.eye_rest(x, y):
  {==}

def Laws.use_fires_once(forward, side, turn, buttons, next, player, level, things, sidetex, thinkers, rnd, clock, usedown,
  sounds, mrnd, reborn, secrets, held):
  match level:
    case L.Level{geo, sectors, specials, heard}:
      %held : {Tic.Sim.pressed(next, _) == False{} : Bool}
      {==}

# A tree read where it was just written answers what was written: both
# walk the same path, by the same bits of the index.
def vec_get_set(v: V.Vec, odd: Bool, +i: U32, +x: U32) ->
  {x == V.Vec.get.go(V.Vec.set.go(v, odd, i, x), odd, i) : U32}:
  match v odd:
    case V.Leaf{y} True{}:
      {==}
    case V.Leaf{y} False{}:
      {==}
    case V.Node{l, r} False{}:
      vec_get_set(l, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), x)
    case V.Node{l, r} True{}:
      vec_get_set(r, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), x)

def Laws.once_clears(line, s):
  match s:
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      Equal.sym(U32, 0, V.Vec.get.go(V.Vec.set.go(specials, V.Vec.odd(L.Level.at(line, 2, 0)),
        L.Level.at(line, 2, 0), 0), V.Vec.odd(L.Level.at(line, 2, 0)), L.Level.at(line, 2, 0)),
        vec_get_set(specials, V.Vec.odd(L.Level.at(line, 2, 0)), L.Level.at(line, 2, 0), 0))

def Laws.exit_ends(cmd):
  {==}

def Laws.replay_append(a, b, s):
  match a:
    case []:
      {==}
    case cmd <> rest:
      Laws.replay_append(rest, b, Tic.Sim.tic(cmd, s))

# Free pins the lines
# -------------------

# A type picked by a Bool or a Maybe: a rewrite through it refutes
# True == False and Some == None.
def BD(b: Bool, t: Type, f: Type) -> Type:
  match b:
    case True{}:
      t
    case False{}:
      f

def MD(m: Maybe<&2, U32>, s: Type, n: Type) -> Type:
  match m:
    case None{}:
      n
    case Some{x}:
      s

def and_true_left(a: Bool, -b: Bool, e: {True{} == Bool.and(a, b) : Bool}) ->
  {True{} == a : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      e

def and_true_right(a: Bool, -b: Bool, e: {True{} == Bool.and(a, b) : Bool}) ->
  {True{} == b : Bool}:
  match a:
    case True{}:
      e
    case False{}:
      %e : BD(_, Unit, {True{} == b : Bool})
      Unit{}

# The thing check's verdict is carried by a line's pass only while it
# holds, and a line that stops the box ends it: a True verdict after a
# line means the verdict before and the line's condition both held.
def cross_true(ok: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +line: L.Level.Line, fl: U32, cl: U32, dl: U32,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.cross(ok, level, x, y, r, line, fl, cl, dl)) : Bool}) -> {True{} == ok : Bool}:
  match ok:
    case False{}:
      e

    case True{}:
      {==}

def channel_protected_pick.go(go: Bool, +priority: Nat, +old: Nat,
  rest: List<&2, Maybe<&2, Nat>>,
  same: {go == Nat.is_le(priority, old) : Bool},
  protected: {True{} == Bool.and(Bool.not(go), Ch.Channel.model.protected(priority, rest)) : Bool},
  next: {Ch.Pick{Ch.Channel.model.size.keys(rest), Ch.Channel.model.size.keys(rest),
    Ch.Channel.model.size.keys(rest)} == Ch.Channel.pick(priority, rest) : Ch.Channel.Pick}) ->
  {Ch.Pick{Ch.Channel.model.size.keys(Some{old} <> rest),
      Ch.Channel.model.size.keys(Some{old} <> rest), Ch.Channel.model.size.keys(Some{old} <> rest)}
    == Ch.Channel.pick(priority, Some{old} <> rest) : Ch.Channel.Pick}:
  match go:
    case True{}:
      %protected : BD(_, Unit, {Ch.Pick{1n+Ch.Channel.model.size.keys(rest),
        1n+Ch.Channel.model.size.keys(rest), 1n+Ch.Channel.model.size.keys(rest)}
        == Ch.Channel.pick.slot(priority, Some{old}, Ch.Channel.pick(priority, rest)) : Ch.Channel.Pick})
      Unit{}
    case False{}:
      %next
        : {Ch.Pick{1n+Ch.Channel.model.size.keys(rest), 1n+Ch.Channel.model.size.keys(rest),
          1n+Ch.Channel.model.size.keys(rest)}
          == Ch.Channel.pick.slot(priority, Some{old}, _) : Ch.Channel.Pick}
      %same
        : {Ch.Pick{1n+Ch.Channel.model.size.keys(rest), 1n+Ch.Channel.model.size.keys(rest),
          1n+Ch.Channel.model.size.keys(rest)}
          == Ch.Pick{1n+Ch.Channel.model.size.keys(rest), Bool.pick(Nat, _, 0n,
            1n+Ch.Channel.model.size.keys(rest)), 1n+Ch.Channel.model.size.keys(rest)} : Ch.Channel.Pick}
      {==}

def channel_nat_lt_refl(n: Nat) -> {False{} == Nat.is_lt(n, n) : Bool}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      channel_nat_lt_refl(p)

def channel_protected_pick(+priority: Nat, slots: List<&2, Maybe<&2, Nat>>,
  +protected: {True{} == Ch.Channel.model.protected(priority, slots) : Bool}) ->
  {Ch.Pick{Ch.Channel.model.size.keys(slots), Ch.Channel.model.size.keys(slots),
      Ch.Channel.model.size.keys(slots)} == Ch.Channel.pick(priority, slots) : Ch.Channel.Pick}:
  match slots:
    case []:
      {==}
    case None{} <> +rest:
      %protected : BD(_, Unit, {Ch.Pick{1n+Ch.Channel.model.size.keys(rest),
        1n+Ch.Channel.model.size.keys(rest), 1n+Ch.Channel.model.size.keys(rest)}
        == Ch.Channel.pick.slot(priority, None{}, Ch.Channel.pick(priority, rest)) : Ch.Channel.Pick})
      Unit{}
    case Some{+old} <> +rest:
      channel_protected_pick.go(Nat.is_le(priority, old), priority, old, rest, {==}, protected,
        channel_protected_pick(priority, rest,
          and_true_right(Bool.not(Nat.is_le(priority, old)),
            Ch.Channel.model.protected(priority, rest), protected)))

def channel_priority_law(priority: Nat, +slots: List<&2, Maybe<&2, Nat>>,
  protected: {True{} == Ch.Channel.model.protected(priority, slots) : Bool}) ->
  {Ch.Channel.model.size.keys(slots) == Ch.Channel.choice(priority, slots) : Nat}:
  %channel_protected_pick(priority, slots, protected)
    : {Ch.Channel.model.size.keys(slots) == Ch.Channel.choice.free(_) : Nat}
  %channel_nat_lt_refl(Ch.Channel.model.size.keys(slots))
    : {Ch.Channel.model.size.keys(slots) == Bool.pick(Nat, _,
      Ch.Channel.model.size.keys(slots), Ch.Channel.model.size.keys(slots)) : Nat}
  {==}

def Laws.channels_priority(priority, slots, protected):
  channel_priority_law(priority, slots, protected)

def line_ok_of(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +i: U32, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, r, mask, i, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool}:
  match f:
    case S.Fit{False{}, fl, cl, dl}:
      %e : BD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool})
      Unit{}
    case S.Fit{True{}, fl, cl, dl}:
      cross_true(S.Sim.line_ok(level, x, y, r, mask, i), level, x, y, r, L.Level.line(level, i), fl, cl, dl, e)

def fit_of(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +i: U32, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, r, mask, i, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match f:
    case S.Fit{False{}, fl, cl, dl}:
      e
    case S.Fit{True{}, fl, cl, dl}:
      {==}

# The fold only ands: a True verdict at the end means one at the start.
def go_keeps(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, r, mask, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match lines:
    case []:
      e
    case +i <> rest:
      fit_of(level, x, y, r, mask, i, f,
        go_keeps(rest, level, x, y, r, mask, S.Sim.fit.line(level, x, y, r, mask, i, f), e))

def some_eq(+i: U32, +h: U32, e: {Some{i} == Some{h} : Maybe<&2, U32>}) -> {h == i : U32}:
  Equal.cong(Maybe<&2, U32>, U32, m => Maybe.default(&2, U32, m, 0), Some{h}, Some{i},
    Equal.sym(Maybe<&2, U32>, Some{i}, Some{h}, e))

# A True verdict over a list means the condition holds for each line in
# it, by its position.
def go_pins(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +f: S.Sim.Fit,
  k: Nat, +i: U32, listed: {Some{i} == List.get(&2, U32, lines, k) : Maybe<&2, U32>},
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, r, mask, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool}:
  match lines k:
    case [] _:
      %listed : MD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool})
      Unit{}
    case +h <> rest 0n:
      %some_eq(i, h, listed) : {True{} == S.Sim.line_ok(level, x, y, r, mask, _) : Bool}
      line_ok_of(level, x, y, r, mask, h, f, go_keeps(rest, level, x, y, r, mask,
        S.Sim.fit.line(level, x, y, r, mask, h, f), e))
    case +h <> rest 1n+j:
      go_pins(rest, level, x, y, r, mask, S.Sim.fit.line(level, x, y, r, mask, h, f), j, i, listed, e)

def Laws.free_pins_lines(level, x, y, k, i, listed, free):
  go_pins(S.Sim.lines(level, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32),
    (y + S.Sim.radius() : U32)), level, x, y, S.Sim.radius(), 1, S.Sim.fit.start(True{}, level, x, y), k, i, listed,
    free)

# Clear pins the mobjs
# --------------------

# A box that met no mobj that stops it is stopped by none of the list,
# by its position: the first that stops it would be what it hit.
def met_none(stops: Bool, id: U32, later: S.Sim.Met,
  e: {None{} == S.Sim.Met.hit(S.Sim.met.if(stops, id, later)) : Maybe<&2, U32>}) -> {False{} == stops : Bool}:
  match stops:
    case True{}:
      %e : MD(_, {False{} == True{} : Bool}, Unit)
      Unit{}
    case False{}:
      {==}

def met_later(stops: Bool, id: U32, later: S.Sim.Met,
  e: {None{} == S.Sim.Met.hit(S.Sim.met.if(stops, id, later)) : Maybe<&2, U32>}) ->
  {None{} == S.Sim.Met.hit(later) : Maybe<&2, U32>}:
  match stops later:
    case True{} S.Met{before, hit}:
      %e : MD(_, {None{} == hit : Maybe<&2, U32>}, Unit)
      Unit{}
    case False{} S.Met{before, hit}:
      e

def clear_pins(ids: List<&2, U32>, +things: H.Things, +p: S.Player, +m: S.Sim.Body, k: Nat, +id: U32,
  listed: {Some{id} == List.get(&2, U32, ids, k) : Maybe<&2, U32>},
  e: {None{} == S.Sim.Met.hit(S.Sim.met.go(ids, things, p, m)) : Maybe<&2, U32>}) ->
  {False{} == S.Sim.stops.at(things, p, m, id) : Bool}:
  match ids k:
    case [] _:
      %listed : MD(_, Unit, {False{} == S.Sim.stops.at(things, p, m, id) : Bool})
      Unit{}
    case +h <> +rest 0n:
      %some_eq(id, h, listed) : {False{} == S.Sim.stops.at(things, p, m, _) : Bool}
      met_none(S.Sim.stops.at(things, p, m, h), h, S.Sim.met.go(rest, things, p, m), e)
    case +h <> +rest 1n+j:
      clear_pins(rest, things, p, m, j, id, listed,
        met_later(S.Sim.stops.at(things, p, m, h), h, S.Sim.met.go(rest, things, p, m), e))

def Laws.clear_pins_things(level, things, p, m, k, id, listed, clear):
  clear_pins(S.Sim.nearby(level, things, m), things, p, m, k, id, listed, clear)

# The wall law
# ------------

# Free: no line stops the player's box. Every move the sim takes has
# passed Sim.check, whose lines are those, so each function from the tic
# down keeps it: a lemma a function, on the flag it decides by and the
# record it opens.
def Free(level: L.Level, +p: S.Player) -> Type:
  {True{} == S.Sim.free(level, S.Player.x(p), S.Player.y(p)) : Bool}

def Xy.player(s: S.Sim.Xy) -> S.Player:
  S.Xy{done, t, xm, ym} = s
  S.Sim.Try.player(t)

# Holding another inventory keeps the place.
def holding_free(+level: L.Level, p: S.Player, held: I.Inventory, hp: Free(level, p)) ->
  Free(level, S.Player.holding(p, held)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

# A place that passed the check with its things' verdict passes the
# lines alone.
def at_clear(c: Bool, +level: L.Level, +x: U32, +y: U32,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1)) : Bool}) ->
  {True{} == S.Sim.free(level, x, y) : Bool}:
  match c:
    case False{}:
      %e : BD(_, Unit, {True{} == S.Sim.free(level, x, y) : Bool})
      Unit{}
    case True{}:
      e

def fit_ok(c: Bool, +level: L.Level, +x: U32, +y: U32, +ok: Bool, fl: U32, cl: U32, dl: U32, +h: Bool,
  e: {True{} == Bool.and(ok, h) : Bool},
  hf: {S.Fit{ok, fl, cl, dl} == S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1) : S.Sim.Fit}) ->
  {True{} == S.Sim.Fit.ok(S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1)) : Bool}:
  %hf : {True{} == S.Sim.Fit.ok(_) : Bool}
  and_true_left(ok, h, e)

def fin_free(+level: L.Level, go: Bool, p: S.Player, things: H.Things, +x: U32, +y: U32, floor: U32,
  ceil: U32, over: List<&2, U32>, +c: Bool, +ok: Bool, fl: U32, cl: U32, dl: U32, +h: Bool,
  e: {go == Bool.and(ok, h) : Bool},
  hf: {S.Fit{ok, fl, cl, dl} == S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fin(go, level, p, things, x, y, floor, ceil, over))):
  match go p:
    case False{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      at_clear(c, level, x, y, fit_ok(c, level, x, y, ok, fl, cl, dl, h, e, hf))

def fit_free(+level: L.Level, +p: S.Player, +x: U32, +y: U32, touched: I.Inventory & H.Things,
  f: S.Sim.Fit, over: List<&2, U32>, +c: Bool,
  hf: {f == S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fit(level, p, x, y, touched, f, over))):
  match touched f:
    case (+inv, +things) S.Fit{+ok, +floor, +ceil, +drop}:
      fin_free(level, S.Sim.passes(S.Fit{ok, floor, ceil, drop}, S.Player.z(p), S.Sim.height()),
        S.Player.holding(p, inv), things, x, y, floor, ceil, over, c, ok, floor, ceil, drop,
        Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
          Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
            F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up()))), {==}, hf, holding_free(level, p, inv, hp))

def try_free(+level: L.Level, +things: H.Things, +p: S.Player, +x: U32, +y: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move(level, things, p, x, y))):
  +m = S.Sim.Body.at(S.Player.body(p, H.Things.you(things)), x, y)
  fit_free(level, p, x, y, S.Sim.touch(level, things, p, x, y, S.Sim.met(level, things, p, m)),
    S.Sim.check(level, things, p, m, 1), S.Sim.crossings(level, S.Player.x(p), S.Player.y(p), x, y, S.Sim.radius()),
    Maybe.is_none(&2, U32, S.Sim.blocked(level, things, p, m)), {==}, hp)

def done_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.Try.done(t))):
  match t:
    case S.Try{ok, p, things}:
      ht

def stairstep_fin_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.stairstep.fin(level, t))):
  match t:
    case S.Try{True{}, p, things}:
      ht
    case S.Try{False{}, +p, +things}:
      done_free(level, S.Sim.try_move(level, things, p, (S.Player.x(p) + S.Player.momx(p) : U32), S.Player.y(p)),
        try_free(level, things, p, (S.Player.x(p) + S.Player.momx(p) : U32), S.Player.y(p), ht))

def stairstep_free(+level: L.Level, +things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.stairstep(level, things, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      stairstep_fin_free(level, S.Sim.try_move(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, x, (y + momy : U32)),
        try_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, x, (y + momy : U32), hp))

def wall_go_free(+level: L.Level, things: H.Things, p: S.Player, m: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.wall.go(level, things, p, m))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      (+mx, +my) = m
      try_free(level, things, S.Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz,
        crossed, inv, psprites, hurt}, (x + mx : U32), (y + my : U32), hp)

def wall_free(left: Bool, +level: L.Level, things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.wall(left, level, things, p, frac, i))):
  match left p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      wall_go_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, S.Sim.along(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, i, F.Fixed.mul(momx, frac), F.Fixed.mul(momy, frac)), hp)

def rest_free(+level: L.Level, things: H.Things, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.rest(level, things, p, frac, i))):
  wall_free(F.Fixed.gt(F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), 0),
    level, things, p, F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), i, hp)

def upto_fin_free(+level: L.Level, +frac: U32, i: U32, t: S.Sim.Try,
  ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.upto.fin(level, frac, i, t))):
  match t:
    case S.Try{True{}, p, things}:
      rest_free(level, things, p, frac, i, ht)
    case S.Try{False{}, p, things}:
      stairstep_free(level, things, p, ht)

def upto_free(some: Bool, +level: L.Level, +things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.upto(some, level, things, p, frac, i))):
  match some p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      rest_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, frac, i, hp)
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      upto_fin_free(level, frac, i, S.Sim.try_move(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32)),
        try_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32), hp))

def found_free(hit: Bool, +level: L.Level, +things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.found(hit, level, things, p, frac, i))):
  match hit:
    case False{}:
      stairstep_free(level, things, p, hp)
    case True{}:
      upto_free(F.Fixed.gt(frac, 0), level, things, p, frac, i, hp)

def hit_free(+level: L.Level, +things: H.Things, p: S.Player, best: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.hit(level, things, p, best))):
  (+frac, i) = best
  found_free(U32.is_le(frac, F.Fixed.unit()), level, things, p, (frac - 2048 : U32), i, hp)

def once_free(+level: L.Level, +things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.once(level, things, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hit_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        S.Sim.trace(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
          S.Sim.lead(x, momx), S.Sim.trail(y, momy), (S.Sim.lead(x, momx) + momx : U32),
          (S.Sim.trail(y, momy) + momy : U32),
          S.Sim.trace(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
            S.Sim.trail(x, momx), S.Sim.lead(y, momy), (S.Sim.trail(x, momx) + momx : U32),
            (S.Sim.lead(y, momy) + momy : U32),
            S.Sim.trace(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
              S.Sim.lead(x, momx), S.Sim.lead(y, momy), (S.Sim.lead(x, momx) + momx : U32),
              (S.Sim.lead(y, momy) + momy : U32), ((F.Fixed.unit() + 1 : U32), 0)))), hp)

def slide_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Try, hs: Free(level, S.Sim.Try.player(st))) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.go(fuel, level, st))):
  match fuel st:
    case 0n S.Try{True{}, p, things}:
      hs
    case 1n+f S.Try{True{}, p, things}:
      hs
    case 0n S.Try{False{}, p, things}:
      stairstep_free(level, things, p, hs)
    case 1n+f S.Try{False{}, +p, +things}:
      slide_go_free(f, level, S.Sim.slide.once(level, things, p), once_free(level, things, p, hs))

def slide_free(+level: L.Level, things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide(level, things, p))):
  slide_go_free(2n, level, S.Try{False{}, p, things}, hp)

def tried_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.tried(level, t))):
  match t:
    case S.Try{True{}, p, things}:
      ht
    case S.Try{False{}, p, things}:
      slide_free(level, things, p, ht)

def xy_fin_free(+level: L.Level, +things: H.Things, +p: S.Player, +tx: U32, +ty: U32, xm: U32, ym: U32,
  hp: Free(level, p)) -> Free(level, Xy.player(S.Sim.xy.fin(level, things, p, tx, ty, xm, ym))):
  tried_free(level, S.Sim.try_move(level, things, p, tx, ty), try_free(level, things, p, tx, ty, hp))

def step_free(big: Bool, +level: L.Level, t: S.Sim.Try, +xm: U32, +ym: U32, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, Xy.player(S.Sim.xy.step(big, level, t, xm, ym))):
  match big t:
    case True{} S.Try{ok, +p, +things}:
      xy_fin_free(level, things, p, (S.Player.x(p) + F.Fixed.half(xm) : U32),
        (S.Player.y(p) + F.Fixed.half(ym) : U32), F.Fixed.sar(xm), F.Fixed.sar(ym), ht)
    case False{} S.Try{ok, +p, +things}:
      xy_fin_free(level, things, p, (S.Player.x(p) + xm : U32), (S.Player.y(p) + ym : U32), 0, 0, ht)

def xy_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Xy, hs: Free(level, Xy.player(st))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.go(fuel, level, st))):
  match fuel st:
    case 0n S.Xy{True{}, t, xm, ym}:
      hs
    case 1n+f S.Xy{True{}, t, xm, ym}:
      hs
    case 0n S.Xy{False{}, t, xm, ym}:
      hs
    case 1n+f S.Xy{False{}, +t, +xm, +ym}:
      xy_go_free(f, level, S.Sim.xy.step(S.Sim.big(xm, ym), level, t, xm, ym),
        step_free(S.Sim.big(xm, ym), level, t, xm, ym, hs))

def slow_free(stop: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.slow(stop, p)):
  match stop p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def ground_free(+level: L.Level, cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.friction.ground(cmd, p)):
  match cmd p:
    case K.Cmd{+forward, +side, +turn, +buttons} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      slow_free(Bool.and(S.Sim.crawling(momx), Bool.and(S.Sim.crawling(momy),
        Bool.and(U32.is_zero(forward), U32.is_zero(side)))), level,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

def friction_if_free(ground: Bool, +level: L.Level, +cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, Bool.pick(S.Player, ground, S.Sim.friction.ground(cmd, p), p)):
  match ground:
    case True{}:
      ground_free(level, cmd, p, hp)
    case False{}:
      hp

def friction_free(+level: L.Level, +cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.friction(cmd, p)):
  friction_if_free(S.Player.onground(p), level, cmd, p, hp)

def slowed_free(+level: L.Level, +cmd: K.Cmd, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.slowed(cmd, t))):
  match t:
    case S.Try{ok, +p, things}:
      friction_free(level, cmd, p, ht)

def moving_free(moving: Bool, +level: L.Level, +things: H.Things, +cmd: K.Cmd, p: S.Player,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.xy.moving(moving, level, things, cmd, p))):
  match moving p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      slowed_free(level, cmd, S.Sim.xy.go(2n, level, S.Xy{False{}, S.Try{False{},
        S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz, viewheight,
          deltaview, viewz, crossed, inv, psprites, hurt}, things}, S.Sim.clamp(momx), S.Sim.clamp(momy)}),
        xy_go_free(2n, level, S.Xy{False{}, S.Try{False{},
          S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz,
            viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, things}, S.Sim.clamp(momx), S.Sim.clamp(momy)}, hp))

def xy_free(+level: L.Level, +things: H.Things, +cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.xy(level, things, cmd, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      moving_free(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, things, cmd, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

# Thrust, turning, the eye and the vertical move keep the position.
def thrust_free(+level: L.Level, p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.thrust(level, p, angle, move)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def push_if_free(skip: Bool, +level: L.Level, +p: S.Player, +angle: U32, +move: U32,
  hp: Free(level, p)) ->
  Free(level, Bool.pick(S.Player, skip, p, S.Sim.thrust(level, p, angle, (move * 2048 : U32)))):
  match skip:
    case True{}:
      hp
    case False{}:
      thrust_free(level, p, angle, (move * 2048 : U32), hp)

def push_free(+level: L.Level, +p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.push(level, p, angle, move)):
  push_if_free(Bool.or(U32.is_zero(move), Bool.not(S.Player.onground(p))), level, p, angle, move, hp)

def move_cmd_free(+level: L.Level, cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.move.cmd(level, cmd, p)):
  match cmd p:
    case K.Cmd{+forward, +side, +turn, +buttons} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      push_free(level, S.Sim.push(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        (angle + (turn << 16n) : U32), forward),
        ((angle + (turn << 16n) : U32) - A.Angle.ang90() : U32), side,
        push_free(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
          (angle + (turn << 16n) : U32), forward, hp))

def pulled_free(+level: L.Level, p: S.Player, pulled: Bool, hp: Free(level, p)) ->
  Free(level, S.Player.pulled(p, pulled)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def move_go_free(pulled: Bool, +level: L.Level, cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.move.go(pulled, level, cmd, p)):
  match pulled:
    case True{}:
      move_cmd_free(level, K.Cmd.demo(100, 0, 0, 0), S.Player.pulled(p, False{}),
        pulled_free(level, p, False{}, hp))
    case False{}:
      move_cmd_free(level, cmd, p, hp)

def move_free(+level: L.Level, cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.move(level, cmd, p)):
  move_go_free(Bool.not(U32.is_zero(V.Vec.get(S.Player.hurt(p), S.Sim.hurt.justattacked()))), level, cmd, p, hp)

def eye_if_free(ground: Bool, live: Bool, +level: L.Level, p: S.Player, swing: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.eye.if(ground, live, p, swing)):
  match ground live p:
    case True{} True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def eye_free(+level: L.Level, clock: U32, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.eye(level, clock, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      eye_if_free(S.Player.onground(S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}),
        Bool.not(S.Player.dead(S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt})),
        level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        F.Fixed.mul((S.Sim.bob(momx, momy) >> 1n : U32),
          A.Angle.sin(L.Level.sine(level), ((409 * clock : U32) .&. 8191 : U32))), hp)

def z_if_free(still: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z.if(still, p)):
  match still p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def z_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      z_if_free(Bool.and(U32.is_eq(z, floorz), U32.is_zero(momz)), level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

# The counters and the vertical move keep the place too.
def counters_free(+level: L.Level, p: S.Player, hp: Free(level, p)) -> Free(level, Tic.Sim.counters(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def mobj_z_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(Tic.Sim.mobj.z(t))):
  match t:
    case S.Try{ok, +p, things}:
      z_free(level, p, ht)

# Free reads the geometry alone
# -----------------------------

# A line's pass narrows the floor and ceiling and changes nothing else of
# the verdict, stated value first.
def narrow_ok(hit: Bool, +level: L.Level, +line: L.Level.Line, f: S.Sim.Fit) ->
  {S.Sim.Fit.ok(f) == S.Sim.Fit.ok(S.Sim.fit.narrow(hit, level, line, f)) : Bool}:
  match hit f:
    case True{} S.Fit{ok, floor, ceil, drop}:
      {==}
    case False{} S.Fit{ok, floor, ceil, drop}:
      {==}

def heights_ok(+level: L.Level, +x: U32, +y: U32, +r: U32, line: L.Level.Line, f: S.Sim.Fit) ->
  {S.Sim.Fit.ok(f) == S.Sim.Fit.ok(S.Sim.fit.heights(level, x, y, r, line, f)) : Bool}:
  match line:
    case L.Line{+x1, +y1, +x2, +y2, +flags, +front, +back}:
      narrow_ok(Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
        Bool.and(S.Sim.box_touches(x, y, r, L.Line{x1, y1, x2, y2, flags, front, back}),
          S.Sim.box_crosses(x, y, r, L.Line{x1, y1, x2, y2, flags, front, back}))),
        level, L.Line{x1, y1, x2, y2, flags, front, back}, f)

# A line's condition reads its ends, flags and sides, which two levels
# of one geometry share whatever their sectors and specials hold.
def cond_same(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, +sb: V.Vec, +pb: V.Vec, +hb: V.Vec, +x: U32, +y: U32, +r: U32, +mask: U32,
  +i: U32) ->
  {S.Sim.line_ok(L.Level{geo, sa, pa, ha}, x, y, r, mask, i) == S.Sim.line_ok(L.Level{geo, sb, pb, hb}, x, y, r, mask, i)
    : Bool}:
  match geo:
    case L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}:
      {==}

# Past a line the box does not stop, the verdict is True in any level.
def cross_same(ok: Bool, +la: L.Level, +lb: L.Level, +x: U32, +y: U32, +r: U32, +linea: L.Level.Line,
  +lineb: L.Level.Line, +fl: U32, +cl: U32, +dl: U32, +gl: U32, +hl: U32, +il: U32) ->
  {S.Sim.Fit.ok(S.Sim.fit.cross(ok, la, x, y, r, linea, fl, cl, dl))
    == S.Sim.Fit.ok(S.Sim.fit.cross(ok, lb, x, y, r, lineb, gl, hl, il)) : Bool}:
  match ok:
    case False{}:
      {==}
    case True{}:
      %heights_ok(la, x, y, r, linea, S.Fit{True{}, fl, cl, dl})
        : {_ == S.Sim.Fit.ok(S.Sim.fit.heights(lb, x, y, r, lineb, S.Fit{True{}, gl, hl, il})) : Bool}
      heights_ok(lb, x, y, r, lineb, S.Fit{True{}, gl, hl, il})

def line_same(+geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, +sb: V.Vec, +pb: V.Vec, +hb: V.Vec, +x: U32, +y: U32, +r: U32,
  +mask: U32, +i: U32, fa: S.Sim.Fit, fb: S.Sim.Fit, e: {S.Sim.Fit.ok(fa) == S.Sim.Fit.ok(fb) : Bool}) ->
  {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa, ha}, x, y, r, mask, i, fa))
    == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb, hb}, x, y, r, mask, i, fb)) : Bool}:
  match fa fb:
    case S.Fit{False{}, fl, cl, dl} S.Fit{False{}, gl, hl, il}:
      {==}
    case S.Fit{True{}, +fl, +cl, +dl} S.Fit{True{}, +gl, +hl, +il}:
      %cond_same(geo, sa, pa, ha, sb, pb, hb, x, y, r, mask, i)
        : {S.Sim.Fit.ok(S.Sim.fit.cross(S.Sim.line_ok(L.Level{geo, sa, pa, ha}, x, y, r, mask, i), L.Level{geo, sa, pa, ha},
          x, y, r, L.Level.line(L.Level{geo, sa, pa, ha}, i), fl, cl, dl))
          == S.Sim.Fit.ok(S.Sim.fit.cross(_, L.Level{geo, sb, pb, hb}, x, y, r, L.Level.line(L.Level{geo, sb, pb, hb}, i), gl,
            hl, il)) : Bool}
      cross_same(S.Sim.line_ok(L.Level{geo, sa, pa, ha}, x, y, r, mask, i), L.Level{geo, sa, pa, ha}, L.Level{geo, sb, pb, hb}, x,
        y, r, L.Level.line(L.Level{geo, sa, pa, ha}, i), L.Level.line(L.Level{geo, sb, pb, hb}, i), fl, cl, dl, gl, hl, il)
    case S.Fit{True{}, fl, cl, dl} S.Fit{False{}, gl, hl, il}:
      %e : BD(_, Unit, {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa, ha}, x, y, r, mask, i, S.Fit{True{}, fl, cl, dl}))
        == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb, hb}, x, y, r, mask, i, S.Fit{False{}, gl, hl, il})) : Bool})
      Unit{}
    case S.Fit{False{}, fl, cl, dl} S.Fit{True{}, gl, hl, il}:
      %e : BD(_, {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa, ha}, x, y, r, mask, i, S.Fit{False{}, fl, cl, dl}))
        == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb, hb}, x, y, r, mask, i, S.Fit{True{}, gl, hl, il})) : Bool}, Unit)
      Unit{}

def go_same(lines: List<&2, U32>, +geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, +sb: V.Vec, +pb: V.Vec, +hb: V.Vec,
  +x: U32, +y: U32, +r: U32, +mask: U32, +fa: S.Sim.Fit, +fb: S.Sim.Fit,
  e: {S.Sim.Fit.ok(fa) == S.Sim.Fit.ok(fb) : Bool}) ->
  {S.Sim.Fit.ok(S.Sim.fit.go(lines, L.Level{geo, sa, pa, ha}, x, y, r, mask, fa))
    == S.Sim.Fit.ok(S.Sim.fit.go(lines, L.Level{geo, sb, pb, hb}, x, y, r, mask, fb)) : Bool}:
  match lines:
    case []:
      e
    case +i <> rest:
      go_same(rest, geo, sa, pa, ha, sb, pb, hb, x, y, r, mask, S.Sim.fit.line(L.Level{geo, sa, pa, ha}, x, y, r, mask, i, fa),
        S.Sim.fit.line(L.Level{geo, sb, pb, hb}, x, y, r, mask, i, fb),
        line_same(geo, sa, pa, ha, sb, pb, hb, x, y, r, mask, i, fa, fb, e))

# The lines gathered for a box are the blockmap's, which two levels of
# one geometry share.
def lines_same(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, +sb: V.Vec, +pb: V.Vec, +hb: V.Vec, +x0: U32, +y0: U32, +x1: U32,
  +y1: U32) ->
  {S.Sim.lines(L.Level{geo, sa, pa, ha}, x0, y0, x1, y1) == S.Sim.lines(L.Level{geo, sb, pb, hb}, x0, y0, x1, y1)
    : List<&2, U32>}:
  match geo:
    case L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}:
      {==}

# Free is the same in two levels of one geometry: the lines gathered are
# its blockmap's, and each one's condition is the geometry's.
def free_geo(+geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, +sb: V.Vec, +pb: V.Vec, +hb: V.Vec, +x: U32, +y: U32) ->
  {S.Sim.free(L.Level{geo, sa, pa, ha}, x, y) == S.Sim.free(L.Level{geo, sb, pb, hb}, x, y) : Bool}:
  %lines_same(geo, sa, pa, ha, sb, pb, hb, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
    (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32))
    : {S.Sim.Fit.ok(S.Sim.fit.go(S.Sim.lines(L.Level{geo, sa, pa, ha}, (x - S.Sim.radius() : U32),
      (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), L.Level{geo, sa, pa, ha},
      x, y,
      S.Sim.radius(), 1, S.Sim.fit.start(True{}, L.Level{geo, sa, pa, ha}, x, y)))
      == S.Sim.Fit.ok(S.Sim.fit.go(_, L.Level{geo, sb, pb, hb}, x, y, S.Sim.radius(), 1,
        S.Sim.fit.start(True{}, L.Level{geo, sb, pb, hb}, x, y))) : Bool}
  go_same(S.Sim.lines(L.Level{geo, sa, pa, ha}, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
    (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), geo, sa, pa, ha, sb, pb, hb, x, y, S.Sim.radius(), 1,
    S.Sim.fit.start(True{}, L.Level{geo, sa, pa, ha}, x, y), S.Sim.fit.start(True{}, L.Level{geo, sb, pb, hb}, x, y), {==})

# Held: free in a geometry, whatever the state's sectors and specials
# have become. Each thinker's turn keeps it: the turn is held to the
# geometry and the player's place, or is the player's own move.
def Held(geo: L.Level.Geo, +s: S.State) -> Type:
  {True{} == S.Sim.free(L.Level{geo, L.Level.sectors(S.State.level(s)), L.Level.specials(S.State.level(s)), L.Level.alerted(S.State.level(s))},
    S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s))) : Bool}

def held_x(x: U32, y: U32, after: S.Player) ->
  {x == S.Player.x(Tic.Player.held(x, y, after)) : U32}:
  match after:
    case S.Player{ax, ay, az, aangle, amomx, amomy, amomz, afloorz, aceilz, aviewheight, adeltaview, aviewz, acrossed, ainv, apsprites, ahurt}:
      {==}

def held_y(x: U32, y: U32, after: S.Player) ->
  {y == S.Player.y(Tic.Player.held(x, y, after)) : U32}:
  match after:
    case S.Player{ax, ay, az, aangle, amomx, amomy, amomz, afloorz, aceilz, aviewheight, adeltaview, aviewz, acrossed, ainv, apsprites, ahurt}:
      {==}

# What a turn holds is free where the state before it was: the level it
# packs has the geometry, and the player it packs the place. The hold
# takes that place as two words, so the lemma spells it out.
def held_free(+geo: L.Level.Geo, before: S.State, after: S.State, h: Held(geo, before)) ->
  Held(geo, Tic.State.held(geo, S.Player.x(S.State.player(before)), S.Player.y(S.State.player(before)), after)):
  match before after:
    case S.State{+was, +wlevel, wthings, wsidetex, wthinkers, wrnd, wclock, wended, wusedown, wsounds, wmrnd, wreborn, wsecrets} S.State{+player, L.Level{g, +sectors, +specials, +heard}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      %held_x(S.Player.x(was), S.Player.y(was), player)
        : {True{} == S.Sim.free(L.Level{geo, sectors, specials, heard}, _,
          S.Player.y(Tic.Player.held(S.Player.x(was), S.Player.y(was), player))) : Bool}
      %held_y(S.Player.x(was), S.Player.y(was), player)
        : {True{} == S.Sim.free(L.Level{geo, sectors, specials, heard}, S.Player.x(was), _) : Bool}
      %free_geo(geo, L.Level.sectors(wlevel), L.Level.specials(wlevel), L.Level.alerted(wlevel), sectors, specials, heard, S.Player.x(was),
        S.Player.y(was))
        : {True{} == _ : Bool}
      h

def kept_held(geo: L.Level.Geo, s: S.State, t: S.Thinker, h: Held(geo, s)) -> Held(geo, S.State.kept(s, t)):
  match s:
    case S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h

def moved_held(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +ha: V.Vec, t: S.Sim.Try, s: S.State,
  ht: Free(L.Level{geo, sa, pa, ha}, S.Sim.Try.player(t))) -> Held(geo, S.State.moved(t, L.Level{geo, sa, pa, ha}, s)):
  match t s:
    case S.Try{ok, p, got} S.State{player, old, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      ht

# The player's own turn: its move is checked against the geometry, and
# the lines it fires are held.
def mobj_held(+cmd: K.Cmd, +geo: L.Level.Geo, +s: S.State, h: Held(geo, s)) -> Held(geo, Tic.Sim.mobj(cmd, geo, s)):
  +level = {L.Level{geo, L.Level.sectors(S.State.level(s)), L.Level.specials(S.State.level(s)), L.Level.alerted(S.State.level(s))} : L.Level}
  +went = S.State.moved(Tic.Sim.mobj.z(S.Sim.xy(level, S.State.things(s), cmd, S.State.player(s))), level, s)
  kept_held(geo, Tic.State.held(geo, S.Player.x(S.State.player(went)), S.Player.y(S.State.player(went)),
      S.Sim.mobj.tics(Sp.Sim.cross(S.Player.crossed(S.State.player(went)), went))),
    S.Mobj{H.Things.you(S.State.things(s))},
    held_free(geo, went, S.Sim.mobj.tics(Sp.Sim.cross(S.Player.crossed(S.State.player(went)), went)),
      moved_held(geo, L.Level.sectors(S.State.level(s)), L.Level.specials(S.State.level(s)), L.Level.alerted(S.State.level(s)),
        Tic.Sim.mobj.z(S.Sim.xy(level, S.State.things(s), cmd, S.State.player(s))), s,
        mobj_z_free(level, S.Sim.xy(level, S.State.things(s), cmd, S.State.player(s)),
          xy_free(level, S.State.things(s), cmd, S.State.player(s), h)))))

def turn_held(mine: Bool, t: S.Thinker, +cmd: K.Cmd, +geo: L.Level.Geo, +s: S.State, h: Held(geo, s)) ->
  Held(geo, Tic.Sim.turn(mine, t, cmd, geo, s)):
  match mine:
    case True{}:
      mobj_held(cmd, geo, s, h)
    case False{}:
      held_free(geo, s, Sp.Sim.think(~Tic.Sim.thing, t, s), h)

def run_held(fuel: List<&2, S.Thinker>, +cmd: K.Cmd, +geo: L.Level.Geo, s: S.State, h: Held(geo, s)) ->
  Held(geo, Tic.Sim.thinkers.go(fuel, cmd, geo, s)):
  match fuel s:
    case [] S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h
    case x <> rest S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h
    case x <> rest S.State{+player, +level, +things, +sidetex, S.Thinkers{+ran, +t <> +due}, +rnd, +clock, +ended, +usedown, +sounds, +mrnd, +reborn, +secrets}:
      run_held(rest, cmd, geo, Tic.Sim.turn(Tic.Sim.mine(t, H.Things.you(things)), t, cmd, geo,
          S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}),
        turn_held(Tic.Sim.mine(t, H.Things.you(things)), t, cmd, geo,
          S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}, h))

def all_held(fuel: Nat, +cmd: K.Cmd, +geo: L.Level.Geo, s: S.State, h: Held(geo, s)) ->
  Held(geo, Tic.Sim.thinkers.all(fuel, cmd, geo, s)):
  match fuel s:
    case 0n S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h
    case 1n+f S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h
    case 1n+f S.State{+player, +level, +things, +sidetex, S.Thinkers{+ran, +t <> +due}, +rnd, +clock, +ended, +usedown, +sounds, +mrnd, +reborn, +secrets}:
      all_held(f, cmd, geo, Tic.Sim.thinkers.go(t <> due, cmd, geo,
          S.State{player, level, things, sidetex, S.Thinkers{ran, t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}),
        run_held(t <> due, cmd, geo,
          S.State{player, level, things, sidetex, S.Thinkers{ran, t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}, h))

def rested_held(geo: L.Level.Geo, s: S.State, h: Held(geo, s)) -> Held(geo, Tic.State.rested(s)):
  match s:
    case S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h

# Reporting a sound keeps the place: it writes the sounds and the index
# and nothing the place is read from.
def heard_held(geo: L.Level.Geo, e: Sn.Sound.Event, s: S.State, h: Held(geo, s)) ->
  Held(geo, S.State.heard(e, s)):
  match s:
    case S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      h

def told_go_held(+geo: L.Level.Geo, events: List<&2, Sn.Sound.Event>, +s: S.State, h: Held(geo, s)) ->
  Held(geo, S.State.told.go(events, s)):
  match events:
    case []:
      h
    case +e <> rest:
      told_go_held(geo, rest, S.State.heard(e, s), heard_held(geo, e, s, h))

def told_held(geo: L.Level.Geo, s: S.State, h: Held(geo, s)) -> Held(geo, S.State.told(s)):
  match s:
    case S.State{player, level, H.Things{tree, count, you, cells, sectors, heard}, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, +secrets}:
      told_go_held(geo, heard,
        S.State{player, level, H.Things{tree, count, you, cells, sectors, []}, sidetex, thinkers, rnd, clock, ended,
          usedown, sounds, mrnd, reborn, secrets}, h)

def Laws.tic_keeps_geometry(cmd, s):
  match s:
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, S.Normal{}, usedown, sounds, mrnd, reborn, +secrets}:
      {==}
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, S.Secret{}, usedown, sounds, mrnd, reborn, +secrets}:
      {==}
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, S.Unended{}, usedown, sounds, mrnd, reborn, +secrets}:
      {==}

# The rest of a live tic: the think, the use and the thinkers all run
# inside the hold, which puts the geometry and the player's place back,
# and the place a think leaves is the place it began with, since the
# player's own turn is the only mover. Whatever the think left is a
# parameter, since a symbolic level leaves it stuck.
def tic_done_free(+cmd: K.Cmd, +geo: L.Level.Geo, +clock: U32, +before: S.State, +after: S.State,
  h: Held(geo, before)) -> Laws.Free(Tic.Sim.tic.done(cmd, geo, clock, S.Player.x(S.State.player(before)),
    S.Player.y(S.State.player(before)), after)):
  +place = {Tic.State.held(geo, S.Player.x(S.State.player(before)), S.Player.y(S.State.player(before)),
    after) : S.State}
  told_held(geo, Tic.Sim.thinkers(cmd, geo, place),
    rested_held(geo, Tic.Sim.thinkers.all(8n, cmd, geo, place),
      all_held(8n, cmd, geo, place,
        held_free(geo, before, after, h))))

def Laws.tic_keeps_free(cmd, s, free):
  match s:
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, S.Normal{}, usedown, sounds, mrnd, reborn, +secrets}:
      free
    case S.State{player, L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, S.Secret{}, usedown, sounds, mrnd, reborn, +secrets}:
      free
    case S.State{+player, L.Level{+geo, +sectors, +specials, +heard}, +things, +sidetex, +thinkers, +rnd, +clock, S.Unended{}, +usedown, sounds, +mrnd, +reborn, +secrets}:
      +level = {L.Level{geo, sectors, specials, heard} : L.Level}
      +before = {S.State{player, level, things, sidetex, thinkers, rnd, clock, S.Unended{}, usedown, [], mrnd,
        reborn, secrets} : S.State}
      tic_done_free(cmd, geo, clock, before,
        Sp.Sim.use(Bool.and(Bool.not(S.Player.dead(player)), Tic.Sim.pressed(cmd, usedown)),
          Tic.Sim.player(S.Player.dead(player), cmd, level, clock, before)), free)

def Laws.replay_keeps_free(script, s, free):
  match script:
    case []:
      free
    case +cmd <> rest:
      Laws.replay_keeps_free(rest, Tic.Sim.tic(cmd, s), Laws.tic_keeps_free(cmd, s, free))

# The freedom law
# ---------------

def at_true(c: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.at(c, level, x, y, r, mask)) : Bool}) -> {True{} == c : Bool}:
  match c:
    case False{}:
      e
    case True{}:
      {==}

def none_is(b: Maybe<&2, U32>, e: {True{} == Maybe.is_none(&2, U32, b) : Bool}) -> {None{} == b : Maybe<&2, U32>}:
  match b:
    case None{}:
      {==}
    case Some{v}:
      %e : BD(_, Unit, {None{} == Some{v} : Maybe<&2, U32>})
      Unit{}

def Laws.check_is_clear(level, things, p, m, mask, passed):
  match m:
    case S.Body{+id, +x, +y, +z, +radius, +height, +flags}:
      none_is(S.Sim.blocked(level, things, p, S.Body{id, x, y, z, radius, height, flags}),
        at_true(Maybe.is_none(&2, U32, S.Sim.blocked(level, things, p, S.Body{id, x, y, z, radius, height, flags})),
          level, x, y, radius, mask, passed))

def fin_taken(go: Bool, +level: L.Level, p: S.Player, things: H.Things, +x: U32, +y: U32, floor: U32, ceil: U32,
  over: List<&2, U32>,
  taken: {True{} == S.Sim.Try.ok(S.Sim.try_move.fin(go, level, p, things, x, y, floor, ceil, over)) : Bool}) ->
  {True{} == go : Bool}:
  match go:
    case False{}:
      taken
    case True{}:
      {==}

def fit_taken(+level: L.Level, +p: S.Player, +x: U32, +y: U32, touched: I.Inventory & H.Things, f: S.Sim.Fit,
  over: List<&2, U32>,
  taken: {True{} == S.Sim.Try.ok(S.Sim.try_move.fit(level, p, x, y, touched, f, over)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match touched f:
    case (+inv, +things) S.Fit{+ok, +floor, +ceil, +drop}:
      and_true_left(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
          Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
            F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up()))),
        fin_taken(S.Sim.passes(S.Fit{ok, floor, ceil, drop}, S.Player.z(p), S.Sim.height()), level,
          S.Player.holding(p, inv), things, x, y, floor, ceil, over, taken))

def thing_fin_taken(go: Bool, th: H.Thing, +id: U32, +level: L.Level, +ox: U32, +oy: U32, +x: U32, +y: U32,
  +r: U32, +floor: U32, +ceil: U32, s: S.State,
  taken: {True{} == S.Sim.Walk.ok(Tic.Sim.chase.step.fin(go, th, id, level, ox, oy, x, y, r, floor, ceil,
    s)) : Bool}) -> {True{} == go : Bool}:
  match go:
    case False{}:
      taken
    case True{}:
      {==}

# Sim.walks ands the shared rules with the ledge, and Sim.passes ands
# the verdict with the heights, so a thing that walked stood where the
# check passed.
def walks_taken(f: S.Sim.Fit, +z: U32, +height: U32, e: {True{} == S.Sim.walks(f, z, height) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match f:
    case S.Fit{+ok, +floor, +ceil, +drop}:
      and_true_left(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), height),
          Bool.and(F.Fixed.ge((ceil - z : U32), height),
            F.Fixed.le((floor - z : U32), S.Sim.step_up()))),
        and_true_left(S.Sim.passes(S.Fit{ok, floor, ceil, drop}, z, height),
          F.Fixed.le((floor - drop : U32), S.Sim.step_up()), e))

def thing_fit_taken(+z: U32, +height: U32, th: H.Thing, +id: U32, +level: L.Level, +ox: U32, +oy: U32,
  +x: U32, +y: U32, +r: U32, f: S.Sim.Fit, s: S.State,
  taken: {True{} == S.Sim.Walk.ok(Tic.Sim.chase.step.fit(z, height, th, id, level, ox, oy, x, y, r, f,
    s)) : Bool}) -> {True{} == S.Sim.Fit.ok(f) : Bool}:
  match f:
    case S.Fit{+ok, +floor, +ceil, +drop}:
      walks_taken(S.Fit{ok, floor, ceil, drop}, z, height,
        thing_fin_taken(S.Sim.walks(S.Fit{ok, floor, ceil, drop}, z, height), th, id, level, ox, oy, x, y, r,
          floor, ceil, s, taken))

def Laws.thing_move_is_checked(m, th, id, level, x, y, ts, p, s, taken):
  match m:
    case S.Body{i, ox, oy, +z, +radius, +height, flags}:
      thing_fit_taken(z, height, th, id, level, ox, oy, x, y, radius,
        S.Sim.check(level, ts, p, S.Body{i, x, y, z, radius, height, flags}, 3), s, taken)

def Laws.move_is_checked(level, things, p, x, y, taken):
  +m = S.Sim.Body.at(S.Player.body(p, H.Things.you(things)), x, y)
  fit_taken(level, p, x, y, S.Sim.touch(level, things, p, x, y, S.Sim.met(level, things, p, m)),
    S.Sim.check(level, things, p, m, 1), S.Sim.crossings(level, S.Player.x(p), S.Player.y(p), x, y, S.Sim.radius()), taken)

# Things compute.

def Laws.lasting_stays(id, kind, x, y, z, s):
  {==}

def Laws.rejected_never_sees(level, m, t):
  {==}

# The solid columns stay sorted
# -----------------------------

# The order on Nat, through Base's comparison: each fact by induction on
# the numbers, the impossible cases refuted through BD.
def LE(a: Nat, b: Nat) -> Type:
  {True{} == Nat.is_le(a, b) : Bool}

def LT(a: Nat, b: Nat) -> Type:
  {True{} == Nat.is_lt(a, b) : Bool}

def zero_le(n: Nat) -> LE(0n, n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def le_max(lo: Nat, hi: Nat, other: Nat, h: LE(lo, hi)) -> LE(lo, Nat.max(hi, other)):
  match lo hi other:
    case 0n _ _:
      zero_le(Nat.max(hi, other))
    case 1n+p 0n _:
      %h : BD(_, Unit, LE(1n+p, Nat.max(0n, other)))
      Unit{}
    case 1n+p 1n+q 0n:
      h
    case 1n+p 1n+q 1n+r:
      le_max(p, q, r, h)

def min_le(a: Nat, b: Nat, hi: Nat, h: LE(a, hi)) -> LE(Nat.min(a, b), hi):
  match a b hi:
    case 0n _ _:
      h
    case 1n+p 0n 0n:
      {==}
    case 1n+p 0n 1n+r:
      {==}
    case 1n+p 1n+q 0n:
      %h : BD(_, Unit, LE(Nat.min(1n+p, 1n+q), 0n))
      Unit{}
    case 1n+p 1n+q 1n+r:
      min_le(p, q, r, h)

# The smaller of first and rf is no more than the larger of last and rl
# when first is no more than last.
def min_le_max(+first: Nat, +last: Nat, +rf: Nat, rl: Nat, h: LE(first, last)) ->
  LE(Nat.min(first, rf), Nat.max(last, rl)):
  le_max(Nat.min(first, rf), last, rl, min_le(first, rf, last, h))

def lt_min(x: Nat, b: Nat, c: Nat, hb: LT(x, b), hc: LT(x, c)) -> LT(x, Nat.min(b, c)):
  match x b c:
    case 0n 0n _:
      %hb : BD(_, Unit, LT(0n, Nat.min(0n, c)))
      Unit{}
    case 0n 1n+q 0n:
      %hc : BD(_, Unit, LT(0n, Nat.min(1n+q, 0n)))
      Unit{}
    case 0n 1n+q 1n+r:
      {==}
    case 1n+p 0n _:
      %hb : BD(_, Unit, LT(1n+p, Nat.min(0n, c)))
      Unit{}
    case 1n+p 1n+q 0n:
      %hc : BD(_, Unit, LT(1n+p, Nat.min(1n+q, 0n)))
      Unit{}
    case 1n+p 1n+q 1n+r:
      lt_min(p, q, r, hb, hc)

# Three true conjuncts make the sorted conjunction of a head range.
def and3(a: Bool, b: Bool, c: Bool, ha: {True{} == a : Bool}, hb: {True{} == b : Bool},
  hc: {True{} == c : Bool}) -> {True{} == Bool.and(a, Bool.and(b, c)) : Bool}:
  %ha : {True{} == Bool.and(_, Bool.and(b, c)) : Bool}
  %hb : {True{} == Bool.and(_, c) : Bool}
  hc

# absorb's head starts at lo, whatever it swallows, so a column two
# before lo stays apart from it.
def absorb_head(rs: List<&2, C.Clip.Range>, ahead: Bool, +lo: Nat, +hi: Nat, +x: Nat,
  h: LT(1n+x, lo)) -> {True{} == C.Clip.apart(C.Clip.absorb(rs, ahead, lo, hi), x) : Bool}:
  match rs ahead:
    case [] True{}:
      h
    case [] False{}:
      h
    case C.Range{rf, rl} <> rest True{}:
      h
    case C.Range{+rf, +rl} <> +rest False{}:
      absorb_head(rest, C.Clip.ahead(rest, Nat.max(hi, rl)), lo, Nat.max(hi, rl), x, h)

def absorb_sorted(rs: List<&2, C.Clip.Range>, ahead: Bool, +lo: Nat, +hi: Nat,
  e: {ahead == C.Clip.ahead(rs, hi) : Bool}, ho: LE(lo, hi),
  hs: {True{} == C.Clip.sorted(rs) : Bool}) ->
  {True{} == C.Clip.sorted(C.Clip.absorb(rs, ahead, lo, hi)) : Bool}:
  match rs ahead:
    case [] True{}:
      and3(Nat.is_le(lo, hi), True{}, True{}, ho, {==}, {==})
    case [] False{}:
      and3(Nat.is_le(lo, hi), True{}, True{}, ho, {==}, {==})
    case C.Range{+rf, +rl} <> +rest True{}:
      and3(Nat.is_le(lo, hi), Nat.is_lt(1n+hi, rf), C.Clip.sorted(C.Range{rf, rl} <> rest), ho, e, hs)
    case C.Range{+rf, +rl} <> +rest False{}:
      absorb_sorted(rest, C.Clip.ahead(rest, Nat.max(hi, rl)), lo, Nat.max(hi, rl), {==},
        le_max(lo, hi, rl, ho),
        and_true_right(C.Clip.apart(rest, rl), C.Clip.sorted(rest),
          and_true_right(Nat.is_le(rf, rl), Bool.and(C.Clip.apart(rest, rl), C.Clip.sorted(rest)), hs)))

# add's head is a range of the list, the new range, or absorb's: a
# column apart from the list's head and two before first stays apart.
def add_head(rs: List<&2, C.Clip.Range>, behind: Bool, ahead: Bool, +first: Nat, +last: Nat, +x: Nat,
  hf: LT(1n+x, first), hr: {True{} == C.Clip.apart(rs, x) : Bool}) ->
  {True{} == C.Clip.apart(C.Clip.add.go(rs, behind, ahead, first, last), x) : Bool}:
  match rs behind ahead:
    case [] True{} True{}:
      hf
    case [] True{} False{}:
      hf
    case [] False{} True{}:
      hf
    case [] False{} False{}:
      hf
    case C.Range{+rf, +rl} <> +rest True{} True{}:
      hr
    case C.Range{+rf, +rl} <> +rest True{} False{}:
      hr
    case C.Range{+rf, +rl} <> +rest False{} True{}:
      hf
    case C.Range{+rf, +rl} <> +rest False{} False{}:
      absorb_head(rest, C.Clip.ahead(rest, Nat.max(last, rl)), Nat.min(first, rf), Nat.max(last, rl), x,
        lt_min(1n+x, first, rf, hf, hr))

# A proof is used once, so the three conjuncts of a sorted list come
# out of its one hypothesis together.
def and3_split(a: Bool, b: Bool, c: Bool, e: {True{} == Bool.and(a, Bool.and(b, c)) : Bool}) ->
  {True{} == a : Bool} & {True{} == b : Bool} & {True{} == c : Bool}:
  match a b c:
    case True{} True{} True{}:
      ({==}, {==}, {==})
    case True{} True{} False{}:
      %e : BD(_, Unit, {True{} == True{} : Bool} & {True{} == True{} : Bool} & {True{} == False{} : Bool})
      Unit{}
    case True{} False{} _:
      %e : BD(_, Unit, {True{} == True{} : Bool} & {True{} == False{} : Bool} & {True{} == c : Bool})
      Unit{}
    case False{} _ _:
      %e : BD(_, Unit, {True{} == False{} : Bool} & {True{} == b : Bool} & {True{} == c : Bool})
      Unit{}

# A range behind the new one stays the head: it is a range, the rest's
# head stays apart from it, and the rest stays sorted, which the caller
# proves by its own induction, handed in as next.
def behind_sorted(+rf: Nat, +rl: Nat, +rest: List<&2, C.Clip.Range>, +first: Nat, +last: Nat,
  parts: {True{} == Nat.is_le(rf, rl) : Bool} & {True{} == C.Clip.apart(rest, rl) : Bool}
    & {True{} == C.Clip.sorted(rest) : Bool},
  eb: LT(1n+rl, first),
  next: {True{} == C.Clip.sorted(rest) : Bool} -> {True{} == C.Clip.sorted(C.Clip.add.go(rest,
    C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last)) : Bool}) ->
  {True{} == C.Clip.sorted(C.Range{rf, rl} <> C.Clip.add.go(rest, C.Clip.behind(rest, first),
    C.Clip.ahead(rest, last), first, last)) : Bool}:
  (p1, p2, p3) = parts
  and3(Nat.is_le(rf, rl),
    C.Clip.apart(C.Clip.add.go(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last), rl),
    C.Clip.sorted(C.Clip.add.go(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last)),
    p1, add_head(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last, rl, eb, p2),
    next(p3))

def add_sorted(rs: List<&2, C.Clip.Range>, behind: Bool, ahead: Bool, +first: Nat, +last: Nat,
  eb: {behind == C.Clip.behind(rs, first) : Bool}, ea: {ahead == C.Clip.ahead(rs, last) : Bool},
  ho: LE(first, last), hs: {True{} == C.Clip.sorted(rs) : Bool}) ->
  {True{} == C.Clip.sorted(C.Clip.add.go(rs, behind, ahead, first, last)) : Bool}:
  match rs behind ahead:
    case [] True{} True{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] True{} False{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] False{} True{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] False{} False{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case C.Range{+rf, +rl} <> +rest True{} _:
      behind_sorted(rf, rl, rest, first, last,
        and3_split(Nat.is_le(rf, rl), C.Clip.apart(rest, rl), C.Clip.sorted(rest), hs), eb,
        h => add_sorted(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last, {==}, {==},
          ho, h))
    case C.Range{+rf, +rl} <> +rest False{} True{}:
      and3(Nat.is_le(first, last), Nat.is_lt(1n+last, rf), C.Clip.sorted(C.Range{rf, rl} <> rest), ho, ea, hs)
    case C.Range{+rf, +rl} <> +rest False{} False{}:
      absorb_sorted(rest, C.Clip.ahead(rest, Nat.max(last, rl)), Nat.min(first, rf), Nat.max(last, rl),
        {==}, min_le_max(first, last, rf, rl, ho),
        and_true_right(C.Clip.apart(rest, rl), C.Clip.sorted(rest),
          and_true_right(Nat.is_le(rf, rl), Bool.and(C.Clip.apart(rest, rl), C.Clip.sorted(rest)), hs)))

def Laws.solid_sorted(first, last, rs, ordered, sorted):
  add_sorted(rs, C.Clip.behind(rs, first), C.Clip.ahead(rs, last), first, last, {==}, {==}, ordered, sorted)

# The draw's loop reaches its indices in order
# --------------------------------------------

def nat_eq_refl(i: Nat) -> {True{} == Nat.is_eq(i, i) : Bool}:
  match i:
    case 0n:
      {==}
    case 1n+p:
      nat_eq_refl(p)

def add_succ(m: Nat, +i: Nat) -> {Nat.add(m, 1n+i) == 1n+Nat.add(m, i) : Nat}:
  match m:
    case 0n:
      {==}
    case 1n++p:
      %add_succ(p, i) : {1n+Nat.add(p, 1n+i) == 1n+_ : Nat}
      {==}

def Laws.each_in_order(n, i):
  match n:
    case 0n:
      {==}
    case 1n++m:
      %nat_eq_refl(i)
        : {D.Draw.each(~Laws.Seq, ~Laws.Seq.see, m, 1n+i, Laws.Seq{_, 1n+i}) == Laws.Seq{True{}, 1n+Nat.add(m, i)} : Laws.Seq}
      %add_succ(m, i)
        : {D.Draw.each(~Laws.Seq, ~Laws.Seq.see, m, 1n+i, Laws.Seq{True{}, 1n+i}) == Laws.Seq{True{}, _} : Laws.Seq}
      Laws.each_in_order(m, 1n+i)

# Music: the reader's laws split on what follows, since Midi.drop
# matches the list even when its count is 0.

def Laws.sysex_skipped(rest):
  match rest:
    case []:
      {==}
    case h <> t:
      {==}

def Laws.end_of_track_ends(rest):
  match rest:
    case []:
      {==}
    case h <> t:
      {==}

def Laws.heap_one(e):
  {==}

def Laws.quiet_offs(t, raw, key, vel):
  {==}

def Laws.sfx_rates_unserved(count, bytes):
  {==}


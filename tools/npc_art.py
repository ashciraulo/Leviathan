"""Saltmarrow's villagers: overworld sprites and dialogue portraits.

Sprites are 16x24 with feet on row 22, like Wren and Old Hessa. Portraits
are 32x32 head-and-shoulders busts shown in the dialogue box. Both are
material silhouettes that build_art.lit() lights and outlines.

Each villager sheet is one row: idle, breathe, talk, then (for those who
walk about) walk_a and walk_b.
"""

# --------------------------------------------------------------------------
# Materials for this file (registered by build_art). Capital letters only,
# so they stay clear of the other art files' letters.
# --------------------------------------------------------------------------
RAMPS = {
    "F": ["#FFF2A0", "#F7D35A", "#E0A93A", "#A8702E", "#4E3022"],   # oilskin yellow
    "V": ["#DCA47C", "#BC8058", "#9A6244", "#6A4036", "#2E1A22"],   # deep brown skin
    "A": ["#F2C49A", "#DCA07A", "#C08060", "#8A5648", "#46283A"],   # tan skin
    "M": ["#A87A5A", "#86583E", "#64402E", "#40282A", "#20141E"],   # brown hair
    "P": ["#D88AB0", "#B4628E", "#8A4470", "#5E2C54", "#2E1630"],   # plum headscarf
    "Y": ["#B8D88A", "#8AB86A", "#5E9050", "#3E6444", "#1E3430"],   # green knit
    "Z": ["#E8E0D0", "#C8BCA8", "#A09080", "#6E6064", "#36283A"],   # grizzled beard
    "R": ["#FFB0A0", "#F2806A", "#D85A50", "#9E3446", "#4E1830"],   # coral knit cap
}
FLAT = {}


def paint(rows, marks):
    """Overwrite runs of pixels: (row, col, text)."""
    out = [list(r) for r in rows]
    for (row, col, text) in marks:
        for i, ch in enumerate(text):
            out[row][col + i] = ch
    return ["".join(r) for r in out]


def settle(rows, from_row):
    """Breathing: everything above from_row drops one pixel."""
    blank = "." * len(rows[0])
    return [blank] + rows[0:from_row] + rows[from_row + 1:]


# --------------------------------------------------------------------------
# Corrin, the fisher. Sou'wester hat and oilskin coat, both bright yellow so
# he reads from across the beach. Talks with a raised hand.
# --------------------------------------------------------------------------
CORRIN = [
    "..............d.",
    "......FFFF....d.",
    ".....FFFFFF...d.",
    "....FFFFFFFF..d.",
    "..FFFFFFFFFFFFd.",
    ".FFVVVVVVVVVVFd.",
    "...VVVVVVVVVV.d.",
    "...VVeVVVVeVV.d.",
    "...VVeVVVVeVV.d.",
    "...VVVVVVVVVV.d.",
    "....VZZZZZZV..d.",
    ".....ZZZZZZ...d.",
    "...FFFFFFFFFF.d.",
    "..FFFFFFFFFFFFd.",
    "..FFFFFbbFFFFFd.",
    ".VFFFFFFFFFFFFV.",
    ".VFFFFFbbFFFFFV.",
    "..FFFFFFFFFFFF..",
    "..FFFFFFFFFFFF..",
    "...FFFFFFFFFF...",
    "....dddddddd....",
    "....bbb..bbb....",
    "....bbb..bbb....",
    "................",
]


def corrin_frames():
    idle = CORRIN
    breathe = settle(idle, 15)
    # Talking: his free hand (viewer's left) comes up to shoulder height.
    talk = paint(idle, [(15, 1, "."), (16, 1, "."), (13, 1, "F"), (12, 1, "F"), (11, 1, "V"), (10, 1, "V")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Pell, a village kid. Shorter than the grown-ups, messy hair, a buoy-red
# scarf just like the keepers wear. Pell runs about between the huts.
# --------------------------------------------------------------------------
PELL = [
    "................",
    "................",
    "................",
    "................",
    "................",
    ".....MMMMMM.....",
    "....MMMMMMMM....",
    "...MMMMMMMMMM...",
    "...MMwwwwwwMM...",
    "...MwewwwwewM...",
    "...MwewwwwewM...",
    "....w%wwww%w....",
    ".....wwwwww.....",
    "....rrrrrrrr....",
    "...ttttttrrtt...",
    "...tttttttrtt...",
    "..wtttttttttttw.",
    "...tttttttttt...",
    "...bbbbbbbbbb...",
    "....pppppppp....",
    "....ww....ww....",
    "....ww....ww....",
    "....bb....bb....",
    "................",
]


def pell_frames():
    idle = PELL
    breathe = settle(idle, 16)
    # Talking: bounces on tiptoe with both arms up.
    talk = paint(idle, [(16, 2, "."), (16, 14, "."), (15, 2, "t"), (15, 13, "t"), (14, 2, "w"), (14, 13, "w"), (13, 2, "w"), (13, 13, "w")])
    talk = talk[1:] + ["." * 16]
    walk_a = paint(idle, [(21, 4, "ww....bb"), (22, 4, "bb......")])
    walk_b = paint(idle, [(21, 4, "bb....ww"), (22, 4, "......bb")])
    return [idle, breathe, talk, walk_a, walk_b]


# --------------------------------------------------------------------------
# Marga, who runs the smokehouse. Plum headscarf, white apron over a dusk
# dress. Hands on hips when she talks.
# --------------------------------------------------------------------------
MARGA = [
    "................",
    "................",
    ".....PPPPPP.....",
    "....PPPPPPPP....",
    "...PPPPPPPPPP...",
    "...PPMMMMMMPP...",
    "...PAAAAAAAAP...",
    "...PAeAAAAeAP...",
    "...PAeAAAAeAP...",
    "...PA%AAAA%AP...",
    "....PAAAAAAP....",
    ".....AAAAAA.....",
    "....pppppppp....",
    "...ppqqqqqqpp...",
    "..pppqqqqqqppp..",
    ".ppppqqqqqqpppp.",
    ".Apbbbbbbbbbbpa.",
    "..ppqqqqqqqqpp..",
    "..ppqqqqqqqqpp..",
    "..ppqqqqqqqqpp..",
    "...pqqqqqqqqp...",
    "...pppppppppp...",
    "....bb....bb....",
    "................",
]


def marga_frames():
    idle = paint(MARGA, [(16, 14, "A")])
    breathe = settle(idle, 16)
    # Hands on hips: elbows out, hands tucked in at the waist.
    talk = paint(idle, [(15, 0, "p"), (15, 15, "p"), (16, 0, "pA"), (16, 14, "Ap")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Dunstan, a big dockhand: coral knit cap, grizzled beard, green jumper,
# rope over his shoulder. Nods slowly when he talks.
# --------------------------------------------------------------------------
DUNSTAN = [
    "................",
    "......RRRR......",
    ".....RRRRRR.....",
    "....RRRRRRRR....",
    "...RRRRRRRRRR...",
    "...jjjjjjjjjj...",
    "..wwwwwwwwwwww..",
    "..wwewwwwwwewww.",
    "..wwewwwwwwewww.",
    "..wZwwwwwwwwZw..",
    "..ZZZZZZZZZZZZ..",
    "...ZZZZZZZZZZ...",
    ".YYYYZZZZZZYYYY.",
    "YYYYYYZZZZYYYjYY",
    "YYYYYYYYYYYjjYYY",
    "wYYYYYYYYYjjYYYw",
    "wYYYYYYYYjjYYYYw",
    ".YYYYYYYjjYYYYY.",
    ".YYYYYYjjYYYYYY.",
    "..pppppppppppp..",
    "..pppppp.ppppp..",
    "...bbbb...bbbb..",
    "...bbbb...bbbb..",
    "................",
]


def dunstan_frames():
    idle = paint(DUNSTAN, [(7, 13, "."), (8, 13, ".")])
    breathe = settle(idle, 13)
    # A slow nod: the head dips a pixel, the cap with it.
    talk = settle(idle, 12)
    talk = paint(talk, [(8, 4, "w"), (8, 11, "w"), (9, 4, "e"), (9, 11, "e")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Nettle, about nine, who wants to be a keeper too. A keeper's cap far too
# big for them, a red-striped jumper (Wren's is navy), and a paper lantern. Holds the
# lantern up when they talk.
# --------------------------------------------------------------------------
NETTLE = [
    "................",
    "................",
    "................",
    "................",
    "......CCCC......",
    "....CCCCCCCC....",
    "...CCCCJCCCCC...",
    "..CCCCCCCCCCCCC.",
    "...MVVVVVVVVM...",
    "...MVeVVVVeVM...",
    "...MVeVVVVeVM...",
    "....V%VVVV%V....",
    ".....VVVVVV.....",
    "....rrrrrrrr....",
    "...qqqqqqqqqq...",
    "..VrrrrrrrrrrV..",
    "...qqqqqqqqqq.Q.",
    "...rrrrrrrrrrQQQ",
    "....pppppppp.QJQ",
    "....pp....pp.QQQ",
    "....VV....VV....",
    "....VV....VV....",
    "....bb....bb....",
    "................",
]


NETTLE_TALK = [
    "................",
    "................",
    "................",
    "................",
    "......CCCC......",
    "....CCCCCCCC....",
    "...CCCCJCCCCC.Q.",
    "..CCCCCCCCCCCQQQ",
    "...MVVVVVVVVMQJQ",
    "...MVeVVVVeVMQQQ",
    "...MVeVVVVeVM.V.",
    "....V%VVVV%V..V.",
    ".....VVVVVV...r.",
    "....rrrrrrrr.r..",
    "...qqqqqqqqqqq..",
    "..Vrrrrrrrrrr...",
    "...qqqqqqqqqq...",
    "...rrrrrrrrrr...",
    "....pppppppp....",
    "....pp....pp....",
    "....VV....VV....",
    "....VV....VV....",
    "....bb....bb....",
    "................",
]


def nettle_frames():
    idle = NETTLE
    breathe = settle(idle, 15)
    # Talking: the lantern comes up beside the cap, held high.
    return [idle, breathe, NETTLE_TALK]


# --------------------------------------------------------------------------
# Agna Holt, the last bell-founder of Cinderreach. Grey hair in a bun,
# founder's goggles pushed up on her brow, a long leather apron over rolled
# sleeves and strong arms. Points with one arm when she talks.
# --------------------------------------------------------------------------
AGNA = [
    "................",
    "......ZZZZ......",
    ".....ZZZZZZ.....",
    "....ZZZZZZZZ....",
    "...ZQeQQQQeQZ...",
    "...ZAAAAAAAAZ...",
    "...AAeAAAAeAA...",
    "...AAeAAAAeAA...",
    "...AA%AAAA%AA...",
    "....AAAAAAAA....",
    ".....AAAAAA.....",
    "...qqqqqqqqqq...",
    "..qqbbbbbbbbqq..",
    ".AqqbbbbbbbbqqA.",
    ".AAqbbbbbbbbqAA.",
    ".AA.bbbbbbbb.AA.",
    ".AA.bbbbbbbb.AA.",
    "..A.bbbbbbbb.A..",
    "....bbbbbbbb....",
    "....bbbbbbbb....",
    "....pppppppp....",
    "....ppp..ppp....",
    "....bbb..bbb....",
    "................",
]


def agna_frames():
    idle = AGNA
    breathe = settle(idle, 11)
    # Talking: her right arm comes up, pointing the way to the Kiln.
    talk = paint(idle, [(15, 13, ".."), (16, 13, ".."), (17, 13, "."), (14, 13, "q."),
                        (12, 14, "AA"), (11, 14, "AA"), (10, 15, "A")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# The Choir, in grey robes (the Hull's iron grey, "S"). Sister Lowe wears
# her hood down: black hair scraped back, a hard brow, a brass tuning fork
# on a cord. Her singers keep their hoods up and pry with iron bars.
# --------------------------------------------------------------------------
LOWE = [
    "................",
    "......vvvv......",
    ".....vvvvvv.....",
    "....vvvvvvvv....",
    "....vAAAAAAv....",
    "....veeAAeev....",
    "....AAeAAeAA....",
    "....AAAAAAAA....",
    ".....AA--AA.....",
    "......AAAA......",
    "...SSSSSSSSSS...",
    "..SSSSSSSSSSSS..",
    "..SSSSJSJSSSSS..",
    ".ASSSSJSJSSSSSA.",
    ".ASSSSJJJSSSSSA.",
    ".ASSSUUJUUUSSSA.",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "...SSSSSSSSSS...",
    "....vv....vv....",
    "................",
]


def lowe_frames():
    idle = LOWE
    breathe = settle(idle, 10)
    # Talking: one arm thrown out, giving orders.
    talk = paint(idle, [(13, 14, "S."), (14, 14, "S."), (12, 14, "SA"), (11, 14, "SA"), (10, 15, "A")])
    return [idle, breathe, talk]


SINGER = [
    "................",
    "................",
    "......SSSS......",
    ".....SSSSSS.....",
    "....SSSSSSSS....",
    "....SS1111SS....",
    "....SVeVVeVS....",
    "....SVVVVVVS....",
    "....SSVVVVSS....",
    "...SSSSSSSSSS...",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    ".VSSSSSSSSSSSSV.",
    ".VSSSSSSSSSSSSV.",
    "..SSSUUUUUUSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "...SSSSSSSSSS...",
    "...SSSSSSSSSS...",
    "....vv....vv....",
    "................",
]


def singer_frames():
    idle = SINGER
    breathe = settle(idle, 9)
    # Prying: both hands on an iron bar driven down under the Matriarch,
    # leaning on it, then heaving.
    pry_a = paint(idle, [(12, 0, ".."), (13, 0, ".."), (12, 14, ".."), (13, 14, "..")]
                  + [(11, 3, "VV"), (11, 11, "VV")]
                  + [(11 + i, 11 - (i * 7) // 11, "U") for i in range(12)])
    pry_b = settle(pry_a, 12)
    pry_b = paint(pry_b, [(12 + i, 11 - (i * 7) // 10, "U") for i in range(11)])
    return [idle, breathe, pry_a, pry_b]


# --------------------------------------------------------------------------
# Murmur, the Choir's wisp-tender in Gloamfen. Grey robe with the hood down,
# long pale hair, a small lantern with a wisp in it held close. Lifts the
# lantern to the face when speaking.
# --------------------------------------------------------------------------
MURMUR = [
    "................",
    "......HHHH......",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "....HAAAAAAH....",
    "....HAeAAeAH....",
    "....HAAAAAAH....",
    "....HHAAAAHH....",
    "....HHHAAHHH....",
    "...SHHSSSSHHS...",
    "..SSHHSSSSHHSS..",
    "..SSSHSSSSHSSS..",
    ".ASSSSSSSSSSSSA.",
    ".ASSSSSSSSSSSQQQ",
    "..SSSUUUUUUSSQNQ",
    "..SSSSSSSSSSSQQQ",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "...SSSSSSSSSS...",
    "...SSSSSSSSSS...",
    "....vv....vv....",
    "................",
]


def murmur_frames():
    idle = MURMUR
    breathe = settle(idle, 9)
    # Talking: the lantern comes up under the chin, lighting the face.
    talk = paint(idle, [(13, 13, "SA."), (14, 13, "S.."), (15, 13, "S.."),
                        (9, 13, "QQQ"), (10, 13, "QNQ"), (11, 13, "QQQ"), (12, 14, "A")])
    return [idle, breathe, talk]


SPRITES = {
    "murmur": murmur_frames,
    "lowe": lowe_frames,
    "singer": singer_frames,
    "agna": agna_frames,
    "nettle": nettle_frames,
    "corrin": corrin_frames,
    "pell": pell_frames,
    "marga": marga_frames,
    "dunstan": dunstan_frames,
}


# --------------------------------------------------------------------------
# Dialogue portraits, 32x32 busts. Built from simple shapes (ellipses and
# boxes of material) so every face shares the same proportions.
# --------------------------------------------------------------------------
P = 32


def _canvas():
    return [["."] * P for _ in range(P)]


def _ellipse(c, cx, cy, rx, ry, m):
    for y in range(P):
        for x in range(P):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                c[y][x] = m


def _box(c, x, y, w, h, m):
    for yy in range(max(y, 0), min(y + h, P)):
        for xx in range(max(x, 0), min(x + w, P)):
            c[yy][xx] = m


def _dots(c, points, m):
    for (x, y) in points:
        if 0 <= x < P and 0 <= y < P:
            c[y][x] = m


def _face(c, skin, eye_row=15, cheeks=True, mouth=True, cy=15, rx=7, ry=8):
    _box(c, 13, cy + ry - 3, 6, 6, skin)              # neck
    _ellipse(c, 16, cy, rx, ry, skin)
    for x in (12, 19):
        _dots(c, [(x, eye_row), (x, eye_row + 1)], "e")
    if cheeks:
        _dots(c, [(10, eye_row + 3), (11, eye_row + 3), (20, eye_row + 3), (21, eye_row + 3)], "%")
    if mouth:
        _box(c, 15, eye_row + 5, 2, 1, "-")


def _rows(c):
    return ["".join(r) for r in c]


def portrait_hessa():
    c = _canvas()
    _ellipse(c, 16, 30, 15, 8, "E")                    # the big coat
    _ellipse(c, 16, 14, 10, 10, "H")                   # grey hair, loose
    _face(c, "w")
    _dots(c, [(11, 13), (12, 13), (19, 13), (20, 13)], "H")   # bushy brows
    _box(c, 9, 17, 1, 1, "w")
    # Turned-up collar standing either side of her chin.
    for i in range(6):
        _box(c, 6 + i // 2, 18 + i, 4, 1, "E")
        _box(c, 22 - i // 2, 18 + i, 4, 1, "E")
    _box(c, 12, 25, 8, 2, "j")                         # scarf knot
    _ellipse(c, 17, 6, 11, 5, "E")                     # tilted cap
    _box(c, 6, 8, 22, 2, "E")
    _box(c, 16, 4, 2, 2, "J")                          # the keeper's lamp badge
    # Brass ear trumpet, bell turned out at the right.
    _box(c, 26, 14, 2, 4, "Q")
    _box(c, 28, 12, 3, 8, "Q")
    _dots(c, [(24, 15), (25, 15)], "Q")
    return _rows(c)


def portrait_corrin():
    c = _canvas()
    _ellipse(c, 16, 31, 15, 8, "F")                    # oilskin
    _box(c, 15, 25, 2, 7, "b")
    _dots(c, [(15, 27), (16, 29)], "d")                # wooden toggles
    _face(c, "V", mouth=False, cheeks=False)
    _ellipse(c, 16, 22, 6, 3, "Z")                     # short grey beard
    _box(c, 14, 20, 4, 1, "Z")
    _ellipse(c, 16, 7, 8, 5, "F")                      # sou'wester crown
    _box(c, 4, 9, 24, 2, "F")                          # brim
    _box(c, 4, 11, 3, 5, "F")                          # flaps over the ears
    _box(c, 25, 11, 3, 5, "F")
    return _rows(c)


def portrait_pell():
    c = _canvas()
    _ellipse(c, 16, 32, 13, 8, "t")
    _box(c, 10, 24, 12, 3, "r")                        # scarf
    _box(c, 18, 26, 3, 4, "r")
    _ellipse(c, 16, 12, 10, 8, "M")                    # mop of hair
    _face(c, "w", eye_row=16, cy=17, rx=7, ry=7)
    # A ragged fringe.
    _box(c, 9, 10, 14, 3, "M")
    _dots(c, [(10, 13), (13, 13), (14, 13), (18, 13), (21, 13), (22, 13), (9, 14)], "M")
    _dots(c, [(16, 4), (17, 3), (12, 5)], "M")         # tufts
    return _rows(c)


def portrait_marga():
    c = _canvas()
    _ellipse(c, 16, 31, 14, 8, "p")
    _box(c, 11, 25, 10, 7, "q")                        # apron bib
    _dots(c, [(10, 24), (21, 24)], "q")
    _ellipse(c, 16, 13, 10, 11, "P")                   # headscarf
    _face(c, "A")
    _box(c, 10, 9, 12, 3, "M")                         # dark fringe under the scarf
    _box(c, 8, 7, 16, 2, "P")
    _dots(c, [(24, 19), (25, 20), (25, 21), (26, 22)], "P")   # scarf knot tail
    return _rows(c)


def portrait_dunstan():
    c = _canvas()
    _ellipse(c, 16, 32, 16, 9, "Y")                    # broad shoulders
    for i in range(8):
        _box(c, 20 - i, 24 + i, 2, 1, "j")             # rope over the shoulder
    _face(c, "w", mouth=False, rx=8)
    _ellipse(c, 16, 23, 9, 5, "Z")                     # big beard
    _box(c, 12, 19, 8, 1, "Z")
    _dots(c, [(15, 22), (16, 22)], "-")                # mouth in the beard
    _ellipse(c, 16, 7, 9, 6, "R")                      # knit cap
    _box(c, 7, 9, 18, 3, "j")                          # turned-up band
    _dots(c, [(16, 0), (15, 1), (17, 1)], "R")         # bobble
    return _rows(c)


def portrait_nettle():
    c = _canvas()
    # Striped jumper, red and white, after Wren's.
    _ellipse(c, 16, 32, 13, 8, "r")
    for y in (26, 29):
        _box(c, 0, y, P, 1, "q")
    for y in range(24, 32):
        for x in range(P):
            if c[y][x] == "q" and ((x + 0.5 - 16) / 13) ** 2 + ((y + 0.5 - 32) / 8) ** 2 > 1.0:
                c[y][x] = "."
    _face(c, "V", eye_row=17, cy=18, rx=7, ry=7)
    _dots(c, [(8, 15), (8, 16), (9, 17), (23, 15), (23, 16), (22, 17), (8, 18), (23, 18)], "M")  # curls
    # The cap, much too big, slipping down to the eyebrows.
    _ellipse(c, 16, 9, 12, 7, "C")
    _box(c, 3, 12, 26, 3, "C")
    _box(c, 15, 7, 3, 3, "J")                          # the lamp badge, home-made
    return _rows(c)


def portrait_agna():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "q")                    # rolled-up shirt
    _box(c, 10, 25, 12, 7, "b")                        # leather apron bib
    _dots(c, [(9, 24), (22, 24)], "b")                 # straps
    _ellipse(c, 16, 14, 10, 8, "Z")                    # grey hair
    _ellipse(c, 16, 5, 5, 3, "Z")                      # the bun
    _face(c, "A", eye_row=16, cy=17, rx=7, ry=8)
    # Founder's goggles pushed up on her brow.
    _box(c, 8, 11, 16, 2, "Q")
    _box(c, 10, 10, 3, 3, "e")
    _box(c, 19, 10, 3, 3, "e")
    _dots(c, [(21, 20), (22, 21)], "-")                # a smudge of soot
    return _rows(c)


def portrait_lowe():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "S")                    # grey robe
    _ellipse(c, 16, 26, 13, 4, "S")                    # the hood, down
    _dots(c, [(16, 26), (16, 27), (15, 28), (16, 28), (17, 28), (16, 29)], "J")  # tuning fork
    _ellipse(c, 16, 13, 10, 8, "v")                    # black hair, scraped back
    _face(c, "A", eye_row=16, cy=17, rx=7, ry=8, cheeks=False)
    _box(c, 10, 14, 4, 1, "v")                         # hard brows
    _box(c, 18, 14, 4, 1, "v")
    return _rows(c)


def portrait_murmur():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "S")                    # grey robe
    _ellipse(c, 16, 26, 13, 4, "S")                    # the hood, down
    _ellipse(c, 16, 16, 12, 12, "H")                   # long pale hair
    _box(c, 4, 16, 24, 12, "H")
    _face(c, "A", eye_row=16, cy=17, rx=7, ry=8, mouth=False)
    _box(c, 15, 22, 2, 1, "-")                         # a small, sad mouth
    # The lantern held close, a wisp glowing in it.
    _box(c, 22, 25, 7, 7, "Q")
    _box(c, 24, 27, 3, 3, "N")
    return _rows(c)


PORTRAITS = {
    "murmur": portrait_murmur(),
    "lowe": portrait_lowe(),
    "agna": portrait_agna(),
    "nettle": portrait_nettle(),
    "hessa": portrait_hessa(),
    "corrin": portrait_corrin(),
    "pell": portrait_pell(),
    "marga": portrait_marga(),
    "dunstan": portrait_dunstan(),
}

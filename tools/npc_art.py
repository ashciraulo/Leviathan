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


# --------------------------------------------------------------------------
# Ide the ferrywoman, at Causeway End: a red headscarf, a long grey braid
# over one shoulder, a sea-green coat and her oar stood upright beside her.
# Beckons Wren aboard with her free hand when she talks.
# --------------------------------------------------------------------------
IDE = [
    "................",
    ".d..............",
    ".d....rrrr......",
    ".d...rrrrrr.....",
    ".d..rrrrrrrr....",
    ".d..rVVVVVVr....",
    ".d..VVeVVeVV....",
    ".d..VVeVVeVV....",
    ".d..VVVVVVVV....",
    ".d...VVVVVVZ....",
    ".d....VVVVZZ....",
    ".d.tttttttttZ...",
    ".VttttttttttZt..",
    ".dtttttttttttZ..",
    ".dtttttttttttV..",
    ".dttttjjjttttt..",
    ".dtttttttttttt..",
    ".dtttttttttttt..",
    ".d.tttttttttt...",
    ".d.tttttttttt...",
    ".d..pppppppp....",
    ".d..ppp..ppp....",
    "....bbb..bbb....",
    "................",
]


def ide_frames():
    # The oar's blade, broad at the foot.
    idle = paint(IDE, [(17, 0, "dd"), (18, 0, "ddd"), (19, 0, "ddd"), (20, 0, "ddd"), (21, 0, "dd"), (22, 1, "d")])
    breathe = settle(idle, 11)
    # Talking: her free hand comes up, beckoning.
    talk = paint(idle, [(14, 13, "t"), (13, 14, "V"), (12, 14, "V"), (11, 14, "V")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Liesl, of the Sunken Verge: a plum headscarf, a green knit shawl over a
# dusk-coloured dress, a canvas apron, and her broom. Every low tide she
# walks out to her great-grandmother's drowned door and sweeps the step.
# --------------------------------------------------------------------------
LIESL = [
    "................",
    "................",
    "......PPPP......",
    ".....PPPPPP.....",
    "....PPPPPPPP....",
    "....PAAAAAAP....",
    "....AAeAAeAA....",
    "....AAeAAeAA....",
    "....AAAAAAAA....",
    ".....AAAAAA.....",
    "....YYYAAYYY....",
    "...YYYYYYYYYY.d.",
    "..YYYYYYYYYYYYd.",
    "..YYYYYYYYYYYAd.",
    "..AppjjjjjjppYd.",
    "...ppjjjjjjpp.d.",
    "...ppjjjjjjpp.d.",
    "...ppjjjjjjpp.d.",
    "...pppppppppp.d.",
    "...pppppppppp.d.",
    "....pppppppp.xdx",
    "....ppppppppxxxx",
    ".....bb..bbxxxxx",
    "................",
]


def liesl_frames():
    idle = LIESL
    # Sweeping: the broom swung out to her side, bristles across the step.
    sweep = paint(LIESL, [(r, 14, ".") for r in range(11, 20)] + [(20, 13, "..."), (21, 12, "...."), (22, 11, ".....")])
    sweep = paint(sweep, [(14, 14, "d"), (15, 14, "d"), (16, 14, "d"), (17, 15, "d"), (18, 15, "d"), (19, 15, "d"), (20, 12, "xxxx"), (21, 11, "xxxxx"), (22, 11, "xxxxx")])
    # Talking: leaning on the broom, her free hand up to her scarf.
    talk = paint(LIESL, [(14, 2, "."), (13, 2, "."), (12, 2, "Y"), (11, 3, "A"), (10, 3, "A"), (9, 4, "A")])
    return [idle, sweep, talk]


# --------------------------------------------------------------------------
# Wick, Gloamfen's lamplighter child, about ten: a moss-green hooded cape,
# a brown fringe, and a lighting pole twice their height with a little
# brass lamp on its hook. Counts the fen's lanterns every night.
# --------------------------------------------------------------------------
WICK = [
    "............QQQ.",
    "............QJQ.",
    "............QQQ.",
    ".............d..",
    ".............d..",
    ".....mmmmmm..d..",
    "....mmmmmmmm.d..",
    "...mmMMMMMMmmd..",
    "...mMAAAAAAMmd..",
    "...mAAeAAeAAmd..",
    "...mAAeAAeAAmd..",
    "....AAAAAAAA.d..",
    ".....AAAAAA..d..",
    "...mmmmmmmmmmd..",
    "..mmmmmmmmmmAd..",
    "..mmmmmmmmmmmd..",
    "..mmmmmmmmmmmd..",
    "...mmmmmmmmm.d..",
    "....pppppppp.d..",
    "....pp....pp.d..",
    "....pp....pp.d..",
    "....AA....AA.d..",
    "....bb....bb.d..",
    "................",
]


def wick_frames():
    idle = WICK
    breathe = settle(idle, 13)
    # The lamp's flame flickers while they breathe.
    breathe = paint(breathe, [(0, 12, "QQQ"), (1, 12, "QJQ"), (2, 12, "QQQ")])
    # Talking: a hand up, counting on their fingers.
    talk = paint(idle, [(14, 2, "m"), (13, 1, "A"), (12, 1, "A"), (11, 1, "A")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Ottilie, Frostspine's old ice-fisher, who trained with Hessa and Vael in
# the keepers' cave: a white fur-hooded parka, red mittens, a short ice rod
# with its line hanging. Idle she watches her float; talk, the rod tips up.
# --------------------------------------------------------------------------
OTTILIE = [
    "................",
    "................",
    "......qqqq......",
    "....qqqqqqqq....",
    "...qqqqqqqqqq...",
    "...qqVVVVVVqq...",
    "...qVVeVVeVVq...",
    "...qVVeVVeVVq...",
    "...qVVVVVVVVq...",
    "...qqVVVVVVqq...",
    "....qqqqqqqq....",
    "...ssssssssss...",
    "..ssssssssssss..",
    "..ssssqqssssss..",
    "..rsssssssssrd..",
    "..rssssqsssrrd..",
    "...ssssssssss.d.",
    "...ssssssssss.d.",
    "...qqqqqqqqqq..j",
    "....bb....bb...j",
    "....bb....bb...j",
    "....bb....bb...r",
    "...bbb....bbb...",
    "................",
]


def ottilie_frames():
    idle = OTTILIE
    breathe = settle(idle, 11)
    # Talking: the rod tips up as she turns to Wren.
    talk = paint(idle, [(14, 13, "."), (15, 13, "."), (16, 14, "."), (17, 14, "."), (18, 15, "."),
                        (19, 15, "."), (20, 15, "."), (21, 15, "."),
                        (13, 13, "d"), (12, 13, "d"), (11, 14, "d"), (10, 14, "d"), (9, 15, "j")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Coralie, Saltmarrow's beachcomber, who strings sea-glass into wind chimes:
# a wide straw hat with a coral band, loose dark hair, a teal shawl over a
# coral skirt, bare feet, and a string of glass beads in her hand. Talking,
# she holds the string up to the light.
# --------------------------------------------------------------------------
CORALIE = [
    "................",
    "................",
    "......dddd......",
    ".....dccccd.....",
    "..dddddddddddd..",
    "....vVVVVVVv....",
    "....VVeVVeVV....",
    "....VVVVVVVV....",
    "....vVVVVVVv....",
    "....vvVVVVvv....",
    "....vttVVttv....",
    "...tttttttttt...",
    "..tttttttttttt..",
    "..tttt0ttttttt..",
    "..VccccccccccVj.",
    "...cccccccccc.0.",
    "...cccccccccc.j.",
    "...cccccccccc.?.",
    "...cccccccccc...",
    "...cccccccccc...",
    "....cccccccc....",
    ".....VV..VV.....",
    "....VVV..VVV....",
    "................",
]


def coralie_frames():
    idle = CORALIE
    breathe = settle(idle, 10)
    # Talking: the string held up to the light, the beads swinging below.
    talk = paint(idle, [(14, 13, "c.."), (15, 14, "."), (16, 14, "."), (17, 14, "."),
                        (11, 13, "t"), (11, 14, "t"), (10, 14, "V"), (9, 14, "V"),
                        (10, 15, "j"), (11, 15, "0"), (12, 15, "j"), (13, 15, "?")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Captain Sorrel, the retired Gullwatch kite-post captain: a leather flying
# cap with brass goggles pushed up, a grey braid, a long blue coat and a red
# scarf the wind never stops tugging. Talks with her whistle in her hand.
# --------------------------------------------------------------------------
SORREL = [
    "................",
    "................",
    ".....bbbbbb.....",
    "....bbbbbbbb....",
    "...bQQeQQeQQb...",
    "...bQQQQQQQQb...",
    "...bwwwwwwwwb...",
    "...Zwwewwewwb...",
    "...Zwwewwewwb...",
    "...Zwwwwwwww....",
    "...Z.wwwwww.....",
    "...ZrrrrrrrrRrr.",
    "..CCrrrrrrrCCrrr",
    "..CCCCCCCCCCCC.r",
    "..CCCCQCCCCCCC..",
    "..CCCCCCCCCCCC..",
    "..wCCCQCCCCCCw..",
    "...CCCCCCCCCC...",
    "...CCCCCCCCCC...",
    "...CCCC..CCCC...",
    "....pp....pp....",
    "....pp....pp....",
    "....bb....bb....",
    "................",
]


def sorrel_frames():
    idle = SORREL
    breathe = settle(idle, 12)
    # The scarf's tail lifts in the wind as she breathes.
    breathe = paint(breathe, [(11, 13, "rrr"), (12, 14, "rr"), (13, 15, ".")])
    # Talking: the whistle up in her hand.
    talk = paint(idle, [(16, 13, "C"), (15, 14, "w"), (14, 14, "Q"), (13, 14, "Q")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Gully, Brinewood's salvager: a coral knit cap pulled low, a grizzled
# beard, a patched leather coat. Sleeps sat in the crook of a beached
# figurehead's arm. Idle and breathe are dozing (chin down, eyes shut);
# talk is awake, a hand up.
# --------------------------------------------------------------------------
GULLY = [
    "................",
    "................",
    "................",
    "................",
    "......RRRR......",
    "....RRRRRRRR....",
    "....RRRRRRRR....",
    "....RwwwwwwR....",
    "....ww-ww-ww....",
    "....wwwwwwww....",
    "....wZZZZZZw....",
    ".....ZZZZZZ.....",
    "...bbbZZZZbbb...",
    "..bbbbbZZbbbbb..",
    "..bbbjbbbbbbbb..",
    "..wbbjbbbbbjbw..",
    "..bbbbbbbbbjbb..",
    "...bbbbbbbbbb...",
    "...pppppppppp...",
    "...pppppppppp...",
    "...pp......pp...",
    "...bb......bb...",
    "..bbb......bbb..",
    "................",
]


def gully_frames():
    idle = GULLY
    breathe = settle(idle, 12)
    # Awake: eyes open, chin up, one hand raised.
    talk = paint(idle, [(8, 6, "e"), (8, 9, "e"), (14, 2, "."), (15, 2, "."), (13, 1, "b"), (12, 1, "w"), (11, 1, "w")])
    return [idle, breathe, talk]


def figurehead():
    """The Lantern Wake's figurehead, 24x40, washed up and planted upright in
    the sand at a lean: a keeper carved holding her lamp high, eyes shut,
    her dress the last of its red paint, standing on the curled scroll of
    the ship's stem. Gully dozes against her."""
    w, h = 24, 40
    c = [["."] * w for _ in range(h)]

    def ell(cx, cy, rx, ry, ch):
        for y in range(h):
            for x in range(w):
                dx = (x + 0.5 - cx) / rx
                dy = (y + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    c[y][x] = ch

    def line(x0, y0, x1, y1, ch, thick=2):
        steps = max(abs(x1 - x0), abs(y1 - y0)) * 2
        for i in range(steps + 1):
            t = i / steps
            x = round(x0 + (x1 - x0) * t)
            y = round(y0 + (y1 - y0) * t)
            for dx in range(thick):
                if 0 <= x + dx < w and 0 <= y < h:
                    c[y][x + dx] = ch

    # The curled scroll of the stem she stands on, half sunk in the sand.
    ell(11.0, 34.0, 6.0, 5.0, "d")
    ell(11.5, 34.0, 3.0, 2.5, "b")
    ell(12.5, 34.0, 1.2, 1.2, "d")
    # Her body, tapering down into the stem, leaning a little.
    for y in range(14, 31):
        half = 5.0 - (y - 14) * 0.17
        cx = 11.5 + (30 - y) * 0.06
        for x in range(w):
            d = abs(x + 0.5 - cx)
            if d <= half:
                c[y][x] = "d"
            if d <= half - 1.0 and y >= 17:
                c[y][x] = "r"
    for y in range(18, 30):                 # carved folds in her dress
        for x in (10, 13):
            if c[y][x] == "r":
                c[y][x] = "-"
    # The other arm across her breast.
    line(8, 16, 13, 19, "d")
    # Her head: carved hair, her face still painted pale, eyes shut.
    ell(11.5, 10.0, 4.5, 5.0, "d")
    ell(11.8, 10.6, 3.0, 3.4, "q")
    c[10][10] = "-"
    c[10][13] = "-"
    c[12][11] = "-"
    c[12][12] = "-"
    # The arm raised over her head, and the lamp held high in her hand.
    line(15, 16, 18, 6, "d")
    for y in range(1, 6):
        for x in range(16, 22):
            c[y][x] = "Q"
    for y in range(2, 5):
        c[y][18] = "J"
        c[y][19] = "J"
    c[0][18] = "Q"
    c[0][19] = "Q"
    return ["".join(r) for r in c]


# --------------------------------------------------------------------------
# Tobin, Dunstan's son, about seventeen: the Choir's newest singer. A grey
# robe too big for him, hood shoved down, a rope belt, his father's mop of
# brown hair grown out. Rubs the back of his neck when he talks.
# --------------------------------------------------------------------------
TOBIN = [
    "................",
    "................",
    "......MMMM......",
    "....MMMMMMMM....",
    "...MMMMMMMMMM...",
    "...MMwMMMwMMM...",
    "....wwwwwwww....",
    "....wewwwwew....",
    "....wewwwwew....",
    "....w%wwww%w....",
    ".....wwwwww.....",
    "....SSSwwSSS....",
    "...SSSSSSSSSS...",
    "...SSSSSSSSSS...",
    "..wSSSSSSSSSSw..",
    "..wSSSSSSSSSSw..",
    "...jjjjjjjjjj...",
    "...SSSSSjSSSS...",
    "...SSSSSjSSSS...",
    "...SSSSSSSSSS...",
    "....SSSSSSSS....",
    "....pp....pp....",
    "....bb....bb....",
    "................",
]


def tobin_frames():
    idle = TOBIN
    breathe = settle(idle, 11)
    # Talking: one hand up rubbing the back of his neck.
    talk = paint(idle, [(14, 13, "."), (15, 13, "."), (13, 13, "S"), (12, 13, "S"), (11, 12, "w"), (10, 12, "w")])
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


# --------------------------------------------------------------------------
# The last singers: four of the Choir who never went home after the ending
# (StoryDirector, Sister Lowe's errand). Grey robes, hoods pushed down.
# --------------------------------------------------------------------------
def _straggler(head, robe_from=9):
    """A Choir robe under a bare head: `head` gives rows 0..robe_from-1."""
    body = [
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
    return head + body[len(head) + len(body) - 24:]


def _skin(rows, skin):
    return [r.replace("V", skin) for r in rows]


# Bram, a big Cinderreach lad who helped stoke the Kiln: cropped hair and
# a short beard.
BRAM = _skin(_straggler([
    "................",
    "......MMMM......",
    ".....MMMMMM.....",
    "....MMVVVVMM....",
    "....MVeVVeVM....",
    "....MVVVVVVM....",
    "....MMVVVVMM....",
    ".....MMMMMM.....",
    "......MMMM......",
]), "V")

# Sela, from the Frostspine mills: a long dark braid over one shoulder.
SELA = _skin(_straggler([
    "................",
    "......MMMM......",
    ".....MMMMMM.....",
    "....MMVVVVMM....",
    "....MVeVVeVM....",
    "....MVVVVVVM....",
    ".....VVVVVVM....",
    "......VVVV.MM...",
    "...........MM...",
]), "A")

# Pim, the youngest: a fair, untidy mop, and a robe that's too long.
PIM = _skin(_straggler([
    "................",
    "................",
    "................",
    ".....FFFFFF.....",
    "....FFFFFFFF....",
    "....FVeVVeVF....",
    "....FVVVVVVF....",
    ".....VVVVVV.....",
    "......VVVV......",
]), "A")

# Ansel, the oldest: bald on top, a grey fringe and a long grey beard.
ANSEL = _skin(_straggler([
    "................",
    "......VVVV......",
    ".....VVVVVV.....",
    "....ZVVVVVVZ....",
    "....ZVeVVeVZ....",
    "....ZVVVVVVZ....",
    ".....ZZZZZZ.....",
    ".....ZZZZZZ.....",
    "......ZZZZ......",
]), "A")


def straggler_frames(rows):
    idle = rows
    breathe = settle(idle, 9)
    # Talking: one hand comes up to the chest.
    talk = paint(idle, [(12, 1, "."), (13, 1, "."), (11, 3, "SV")])
    return [idle, breathe, talk]


# After the ending Murmur sets the Choir's grey robe aside: a fen-green
# knit and a plain brown skirt, the same pale hair, the same lantern.
MURMUR_PLAIN = [
    "................",
    "......HHHH......",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "....HAAAAAAH....",
    "....HAeAAeAH....",
    "....HAAAAAAH....",
    "....HHAAAAHH....",
    "....HHHAAHHH....",
    "...YHHYYYYHHY...",
    "..YYHHYYYYHHYY..",
    "..YYYHYYYYHYYY..",
    ".AYYYYYYYYYYYYA.",
    ".AYYYYYYYYYYYQQQ",
    "..YYYUUUUUUYYQNQ",
    "...MMMMMMMMMMQQQ",
    "...MMMMMMMMMM...",
    "...MMMMMMMMMM...",
    "...MMMMMMMMMM...",
    "...MMMMMMMMMM...",
    "....MMMMMMMM....",
    ".....AA..AA.....",
    "....vv....vv....",
    "................",
]


def murmur_plain_frames():
    idle = MURMUR_PLAIN
    breathe = settle(idle, 9)
    talk = paint(idle, [(13, 13, "YA."), (14, 13, "Y.."), (15, 13, "M.."), (9, 13, "QQQ"), (10, 13, "QNQ"), (11, 13, "QQQ"), (12, 14, "A")])
    return [idle, breathe, talk]


def murmur_frames():
    idle = MURMUR
    breathe = settle(idle, 9)
    # Talking: the lantern comes up under the chin, lighting the face.
    talk = paint(idle, [(13, 13, "SA."), (14, 13, "S.."), (15, 13, "S.."),
                        (9, 13, "QQQ"), (10, 13, "QNQ"), (11, 13, "QQQ"), (12, 14, "A")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Vael, who leads the Choir: Hessa's first apprentice, about 55. Grey robes
# like his singers, close-cropped grey hair and beard, and the keepers' lamp
# badge he still wears, gone dull. Opens a hand when he speaks.
# --------------------------------------------------------------------------
VAEL = [
    "................",
    "......ZZZZ......",
    ".....ZZZZZZ.....",
    "....ZZZZZZZZ....",
    "....ZVVVVVVZ....",
    "....VVeVVeVV....",
    "....VVVVVVVV....",
    "....ZVVVVVVZ....",
    ".....ZZ--ZZ.....",
    "......ZZZZ......",
    "...SSSSSSSSSS...",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSTTSSS..",
    ".VSSSSSSSTTSSSV.",
    ".VSSSSSSSSSSSSV.",
    ".VSSSUUUUUUSSSV.",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "..SSSSSSSSSSSS..",
    "...SSSSSSSSSS...",
    "....vv....vv....",
]


def vael_frames():
    idle = VAEL
    breathe = settle(idle, 10)
    # Talking: one hand opens, palm up, towards Wren.
    talk = paint(idle, [(13, 14, "S."), (14, 14, "S."), (15, 14, "S."), (13, 14, "SV"), (12, 15, "V")])
    return [idle, breathe, talk]


# --------------------------------------------------------------------------
# Mother Dace, who walks the Ossuary Dunes: very old, small and bent, in
# sand-coloured wraps with a dusk-purple scarf over grey hair, leaning on a
# long staff of pale bone. Lifts the staff to point when she speaks.
# --------------------------------------------------------------------------
DACE = [
    "................",
    "................",
    "................",
    "......pppp......",
    ".....pppppp...s.",
    "....ppZZZZpp..s.",
    "....pVVVVVVp..s.",
    "....pVeVVeVp..s.",
    "....pVVVVVVp..s.",
    ".....pV--Vp...s.",
    "......pppp....s.",
    "....jjjjjjjj.Vs.",
    "...jjjjjjjjjjVs.",
    "...jjjjjjjjjjjs.",
    "...jjjjjjjjjjjs.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "...jjjjjjjjjj.s.",
    "....jjjjjjjj..s.",
    ".....VV..VV...s.",
]


def dace_frames():
    # A purple sash, its end hanging, and a string of small bones at the neck.
    idle = paint(DACE, [(15, 3, "pppppppppp"), (16, 9, "p"), (17, 9, "p"),
                        (11, 6, "s.s.s")])
    breathe = settle(idle, 11)
    # Talking: the staff comes up off the sand to point.
    talk = [r[:13] + "..." for r in idle]
    talk = paint(talk, [(r, 14, "s") for r in range(1, 21)] + [(11, 13, "V"), (12, 13, "V")])
    return [idle, breathe, talk]



# Vael at the end, with the grey robe dropped: under it all along, the
# keepers' navy coat he trained in, its lamp badge polished again.
def vael_keeper_frames():
    coat = [r.replace("S", "D") for r in VAEL]
    # Brass buttons down the front, and the badge bright on the chest.
    coat = paint(coat, [(12, 9, "QQ"), (13, 9, "QQ"), (15, 7, "Q"), (17, 7, "Q"), (19, 7, "Q")])
    breathe = settle(coat, 10)
    talk = paint(coat, [(13, 14, "D."), (14, 14, "D."), (15, 14, "D."), (13, 14, "DV"), (12, 15, "V")])
    return [coat, breathe, talk]

# --------------------------------------------------------------------------
# Marlo Pike, Saltmarrow's trader. Bald as an egg, with ginger mutton chops
# and a moustache to match, a sea-green waistcoat with brass buttons over a
# round belly. Talks with a glint held up between finger and thumb. Stands
# behind the market stall (market_stall below).
# --------------------------------------------------------------------------
def _mirror(halves):
    return [h + h[::-1] for h in halves]


MARLO = paint(_mirror([
    "........", "........",
    "......ww", ".....www", "....wwww", "...^wwww",
    "...^wwew", "...^wwew", "...^^www", "...^^^^^", "....^^ww",
    "....qq00", "...qqq00", "..qqq000", "..qq0000", ".wqq0000", ".w.00000",
    "...00000", "...bbbbb", "....8888", "....8888", "....888.", "....vvv.", "........",
]), [(13, 7, "Q"), (15, 7, "Q"), (17, 7, "Q"), (18, 7, "GG"), (9, 7, "ww"), (5, 5, "^^"), (5, 9, "^^")])


def marlo_frames():
    idle = MARLO
    breathe = settle(idle, 11)
    talk = paint(idle, [(15, 14, "."), (16, 14, "."), (14, 14, "q."), (13, 14, "qq"), (12, 14, "qw"),
                        (11, 14, "w"), (10, 14, "wG"), (9, 15, "G")])
    return [idle, breathe, talk]


def market_stall():
    """Marlo's stall, 48x46 with its foot on row 44: a striped awning on two
    posts, wares on the counter, and a puffer painted on the front."""
    W, H = 48, 46
    c = [["."] * W for _ in range(H)]

    def box(x, y, w, h, m):
        for yy in range(max(y, 0), min(y + h, H)):
            for xx in range(max(x, 0), min(x + w, W)):
                c[yy][xx] = m

    def dots(pts, m):
        for x, y in pts:
            if 0 <= x < W and 0 <= y < H:
                c[y][x] = m

    box(3, 8, 2, 36, "[")                                   # posts
    box(43, 8, 2, 36, "[")
    # The striped canvas awning, sloping out, with a scalloped hem.
    for y in range(1, 10):
        inset = max(0, 3 - y)
        for x in range(inset, W - inset):
            c[y][x] = "r" if (x // 4) % 2 == 0 else "]"
    for x in range(W):
        if (x % 6) in (1, 2, 3, 4):
            c[10][x] = "r" if (x // 4) % 2 == 0 else "]"
        if (x % 6) in (2, 3):
            c[11][x] = c[10][x]
    # Dried fish strung under the left of the awning.
    for x in (7, 10, 13):
        box(x, 12, 1, 2, "B")
        box(x, 14, 2, 4, "T")
        dots([(x - 1, 18), (x + 2, 18), (x, 17), (x + 1, 17)], "T")
    # A little lantern on the right.
    box(39, 12, 1, 2, "B")
    box(38, 14, 3, 4, "Q")
    dots([(39, 15), (39, 16)], "*")
    # The counter: a top board and a planked front.
    box(0, 27, W, 3, "b")
    box(1, 30, W - 2, 14, "[")
    for y in (34, 39):
        box(1, y, W - 2, 1, "b")
    for x in (12, 24, 36):
        box(x, 30, 1, 14, "b")
    # A puffer painted on the front: the stall's sign.
    for y in range(31, 43):
        for x in range(17, 31):
            if ((x + 0.5 - 24) / 5.5) ** 2 + ((y + 0.5 - 37) / 4.5) ** 2 <= 1.0:
                c[y][x] = ";"
    dots([(21, 35), (21, 36)], "e")
    for i in range(5):                                      # its tail
        box(30 + i // 2, 37 - i // 2 - 1, 1, 2 + i, ";")
    dots([(18, 31), (21, 30), (24, 30), (27, 30), (30, 31), (17, 42), (30, 42)], ";")
    # Wares: two puffer bombs on the left, bottles of lamp oil and a jar of
    # kelp tonic on the right.
    for cx in (6, 13):
        for y in range(20, 27):
            for x in range(cx - 4, cx + 4):
                if ((x + 0.5 - cx) / 3.5) ** 2 + ((y + 0.5 - 23.5) / 3.5) ** 2 <= 1.0:
                    c[y][x] = ";"
        dots([(cx - 4, 22), (cx + 3, 22), (cx - 1, 19), (cx + 1, 19), (cx, 26)], ";")
        dots([(cx - 2, 22), (cx - 2, 23)], "e")
        box(cx + 1, 18, 1, 2, "B")                          # the fuse
    for bx in (32, 36):
        box(bx, 20, 3, 7, "x")
        box(bx + 1, 18, 1, 2, "x")
        box(bx + 1, 17, 1, 1, "b")                          # cork
    box(40, 21, 5, 6, "L")
    box(41, 20, 3, 1, "b")
    return ["".join(r) for r in c]


# --------------------------------------------------------------------------
# Young Hessa and young Vael, as they were when they trained together in the
# Hollow Glacier: new keepers in navy caps and jackets with the buoy-red
# scarf. Hessa wears her chestnut hair in a braid and carries the lamp.
# They only appear in the frozen journal's vision (cutscene 13).
# --------------------------------------------------------------------------
YOUNG_HESSA = paint([
    "................",
    "......EEEE......",
    ".....EEEEEE.....",
    "....EEEJJEEE....",
    "...EEEEEEEEEE...",
    "...MMwwwwwwMM...",
    "...MwwwwwwwwM...",
    "...MwewwwwewM...",
    "...Mwewwwwew M..".replace(" ", "M")[:16],
    "....w%wwww%wM...",
    ".....wwwwwwM....",
    ".....rrrrrrM....",
    "....EEErrEEEM...",
    "...EEEEEEEEEM...",
    "..wEEEEEEEEEEw..",
    "..wEEEEEEEEEEw..",
    "...EEEEEEEEEE...",
    "...EEEEEEEEEE...",
    "....88888888....",
    "....888..888....",
    "....888..888....",
    "....bbb..bbb....",
    "....bbb..bbb....",
    "................",
], [(15, 1, "Q"), (16, 0, "QJQ"), (17, 0, "QJQ"), (18, 0, "QQQ")])
YOUNG_VAEL = [
    "................",
    "......EEEE......",
    ".....EEEEEE.....",
    "....EEEJJEEE....",
    "...EEEEEEEEEE...",
    "...++VVVVVV++...",
    "...+VVVVVVVV+...",
    "...VVeVVVVeVV...",
    "...VVeVVVVeVV...",
    "....VVVVVVVV....",
    ".....VV--VV.....",
    ".....rrrrrr.....",
    "...EEErrrrEEE...",
    "..EEEEErrEEEEE..",
    ".VEEEEEEEEEEEEV.",
    ".VEEEEEEEEEEEEV.",
    "..EEEEEEEEEEEE..",
    "..EEEEEEEEEEEE..",
    "...8888888888...",
    "....888..888....",
    "....888..888....",
    "....888..888....",
    "....vvv..vvv....",
    "................",
]


def young_hessa_frames():
    idle = YOUNG_HESSA
    # Talking: the lamp comes up to shoulder height, as if to signal.
    talk = paint(idle, [(15, 0, "..."), (16, 0, "..."), (17, 0, "..."), (18, 0, "..."),
                        (14, 2, "w"), (11, 0, "QJQ"), (12, 0, "QJQ"), (13, 1, "Qw")])
    return [idle, settle(idle, 10), talk]


def young_vael_frames():
    idle = YOUNG_VAEL
    # Talking: he kneels, head bowed, listening down through the ice.
    talk = ["." * 16] * 4 + idle[:13] + idle[13:17] + idle[21:23] + ["." * 16]
    return [idle, settle(idle, 11), talk]


def journal_ice():
    """A page of the keepers' journal frozen in a block of ice, 16x20."""
    c = [["."] * 16 for _ in range(20)]
    def box(x, y, w, h, m):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                c[yy][xx] = m
    box(2, 4, 12, 15, "`")
    box(3, 2, 9, 2, "`")
    box(1, 7, 1, 10, "`")
    box(14, 6, 1, 11, "`")
    # The page, tilted a little, with lines of ink.
    for y in range(6, 16):
        x0 = 4 + (y - 6) // 5
        box(x0, y, 7, 1, "]")
    for y in (8, 10, 12, 14):
        x0 = 5 + (y - 6) // 5
        box(x0, y, 4 if y != 14 else 2, 1, "-")
    # Light catching the ice.
    for x, y in ((4, 3), (3, 5), (12, 5), (13, 7), (12, 16)):
        c[y][x] = "'"
    return ["".join(r) for r in c]


def rowboat():
    """Hessa's rowboat seen from above and a little south, 36x16: red-painted
    planks, a thwart, oars shipped out either side."""
    w, h = 36, 16
    c = [["."] * w for _ in range(h)]
    cx, cy, rx, ry = 18.0, 8.5, 15.5, 5.0
    for y in range(h):
        for x in range(w):
            # A hull pointed at both ends (bow left, stern right, rounder).
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy * (1.0 + 0.6 * max(0.0, -dx)) <= 1.0:
                c[y][x] = "r"
    # The inside, planked, inset from the painted hull.
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / (rx - 2.5)
            dy = (y + 0.5 - (cy - 0.8)) / (ry - 1.6)
            if c[y][x] == "r" and dx * dx + dy * dy * (1.0 + 0.6 * max(0.0, -dx)) <= 1.0:
                c[y][x] = "d"
    for x in range(6, 31):
        if c[7][x] == "d":
            c[7][x] = "-"
    # Two thwarts across.
    for y in range(4, 11):
        for x in (13, 14, 23, 24):
            if c[y][x] == "d" or c[y][x] == "-":
                c[y][x] = "b"
    # Oars out over the water from the oarlocks, blades down at the ends.
    for i in range(6):
        c[3 - i // 2][16 - i] = "j"
        c[13 + i // 2][16 - i] = "j"
    for x, y in ((9, 0), (10, 0), (9, 15), (10, 15)):
        c[y][x] = "j"
    return ["".join(r) for r in c]


SPRITES = {
    "young_hessa": young_hessa_frames,
    "young_vael": young_vael_frames,
    "marlo": marlo_frames,
    "dace": dace_frames,
    "vael_keeper": vael_keeper_frames,
    "vael": vael_frames,
    "murmur": murmur_frames,
    "murmur_plain": murmur_plain_frames,
    "bram": lambda: straggler_frames(BRAM),
    "sela": lambda: straggler_frames(SELA),
    "pim": lambda: straggler_frames(PIM),
    "ansel": lambda: straggler_frames(ANSEL),
    "lowe": lowe_frames,
    "tobin": tobin_frames,
    "ide": ide_frames,
    "liesl": liesl_frames,
    "wick": wick_frames,
    "gully": gully_frames,
    "sorrel": sorrel_frames,
    "ottilie": ottilie_frames,
    "coralie": coralie_frames,
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


def portrait_ide():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "t")                    # sea-green coat
    _box(c, 13, 25, 6, 1, "j")                         # coat ties
    _face(c, "V", eye_row=16, cy=17, rx=7, ry=8)
    _ellipse(c, 16, 9, 10, 5, "r")                     # headscarf
    _box(c, 6, 11, 20, 2, "r")
    _dots(c, [(25, 15), (26, 16)], "r")                # its knot
    for y in range(18, 30):
        _box(c, 21 + (y % 2), y, 3, 1, "Z")            # the braid, over her shoulder
        if y % 3 == 0:
            _box(c, 21 + (y % 2), y, 3, 1, "H")
    _box(c, 3, 0, 2, 22, "d")                          # the oar's loom
    _box(c, 2, 22, 4, 10, "d")                         # and its blade
    return _rows(c)


def portrait_liesl():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "Y")                    # green knit shawl
    _box(c, 9, 27, 14, 5, "j")                         # apron bib
    _face(c, "A", eye_row=16, cy=17, rx=7, ry=8)
    _dots(c, [(9, 13), (9, 14), (10, 15), (23, 13), (23, 14), (22, 15)], "M")  # brown hair at her temples
    _ellipse(c, 16, 8, 11, 5, "P")                     # plum headscarf, over the crown
    _box(c, 6, 9, 20, 3, "P")
    _dots(c, [(8, 12), (24, 12)], "P")
    _box(c, 24, 12, 3, 3, "P")                         # knotted at the side
    _box(c, 25, 15, 2, 6, "P")                         # and its ends down past her ear
    _box(c, 27, 16, 1, 4, "P")
    _box(c, 28, 2, 2, 30, "d")                         # the broom's handle, held close
    return _rows(c)


def portrait_wick():
    c = _canvas()
    _ellipse(c, 16, 32, 14, 8, "m")                    # moss-green cape
    _ellipse(c, 16, 15, 13, 13, "m")                   # its hood, up
    _face(c, "A", eye_row=17, cy=18, rx=7, ry=8)
    _box(c, 9, 10, 14, 3, "M")                         # brown fringe under the hood
    _dots(c, [(10, 13), (13, 13), (19, 13), (22, 13)], "M")
    _box(c, 28, 4, 2, 28, "d")                         # the lighting pole
    _box(c, 26, 0, 6, 5, "Q")                          # and its little lamp
    _box(c, 28, 1, 2, 3, "J")
    return _rows(c)


def portrait_ottilie():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "s")                    # pale grey parka
    _ellipse(c, 16, 16, 14, 15, "q")                   # white fur hood, up
    _face(c, "V", eye_row=17, cy=18, rx=7, ry=8)
    _box(c, 9, 10, 14, 3, "q")                         # the fur's edge over her brow
    _box(c, 10, 13, 12, 1, "Z")                        # white hair under it
    _dots(c, [(10, 14), (21, 14)], "Z")
    _dots(c, [(10, 17), (21, 17), (11, 22), (20, 22)], "-")  # lines of a long life
    _box(c, 3, 26, 4, 4, "r")                          # a red mitten
    _box(c, 4, 8, 1, 18, "d")                          # on her ice rod
    _dots(c, [(5, 8), (6, 9)], "j")
    return _rows(c)


def portrait_coralie():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "t")                    # teal shawl
    _dots(c, [(11, 27), (13, 28), (16, 28), (19, 28), (21, 27)], "0")  # glass beads
    _dots(c, [(14, 28), (18, 28)], "?")
    _ellipse(c, 16, 20, 10, 10, "v")                   # dark hair, loose
    _face(c, "V", eye_row=17, cy=18, rx=7, ry=8)
    _ellipse(c, 16, 8, 8, 5, "d")                      # straw hat
    _box(c, 2, 10, 28, 3, "d")                         # its wide brim
    _box(c, 8, 9, 16, 1, "c")                          # coral band
    _dots(c, [(8, 22), (23, 22)], "0")                 # sea-glass earrings
    _dots(c, [(8, 23), (23, 23)], "?")
    return _rows(c)


def portrait_sorrel():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "C")                    # long blue coat
    _box(c, 8, 26, 16, 3, "r")                         # red scarf
    _box(c, 22, 24, 8, 3, "r")                         # its tail, out in the wind
    _box(c, 27, 21, 5, 3, "r")
    _face(c, "w", eye_row=16, cy=17, rx=7, ry=8)
    _box(c, 8, 13, 2, 6, "Z")                          # grey hair under the cap
    _box(c, 22, 13, 2, 5, "Z")
    _box(c, 5, 14, 3, 14, "Z")                         # her grey braid
    _dots(c, [(5, 28), (6, 29), (6, 30)], "Z")
    _dots(c, [(10, 17), (21, 17), (11, 18), (20, 18)], "-")  # weathered, crow's feet
    _ellipse(c, 16, 9, 10, 6, "b")                     # leather flying cap
    _box(c, 6, 10, 20, 3, "b")
    _box(c, 9, 9, 14, 4, "Q")                          # brass goggles, pushed up
    _box(c, 10, 10, 4, 2, "e")
    _box(c, 18, 10, 4, 2, "e")
    _dots(c, [(11, 10), (19, 10)], "W")
    return _rows(c)


def portrait_gully():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "b")                    # patched leather coat
    _box(c, 9, 28, 3, 3, "j")                          # a canvas patch
    _face(c, "w", eye_row=16, cy=17, rx=7, ry=8, mouth=False)
    _ellipse(c, 16, 23, 8, 5, "Z")                     # grizzled beard
    _box(c, 14, 21, 4, 1, "-")
    _ellipse(c, 16, 9, 10, 6, "R")                     # coral knit cap, pulled low
    _box(c, 6, 11, 20, 3, "R")
    _dots(c, [(16, 2), (15, 2), (16, 1)], "R")         # its bobble
    return _rows(c)


def portrait_tobin():
    c = _canvas()
    _ellipse(c, 16, 32, 14, 8, "S")                    # grey robe, too big
    _ellipse(c, 16, 26, 12, 4, "S")                    # the hood, shoved down
    for i in range(6):
        _box(c, 13 + (i % 2), 26 + i, 1, 1, "j")       # rope belt's knot, up the front
    _face(c, "w", eye_row=16, cy=17, rx=7, ry=8)
    _dots(c, [(10, 19), (12, 20), (20, 19), (21, 20), (14, 18), (18, 18)], "T")  # freckles
    _ellipse(c, 16, 9, 10, 5, "M")                     # mop of brown hair
    _dots(c, [(7, 12), (7, 13), (8, 14), (24, 12), (24, 13), (23, 14), (11, 14), (14, 14), (18, 14)], "M")  # grown out, over his ears
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


def _portrait_straggler(skin, hair):
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "S")                    # grey robe
    _ellipse(c, 16, 26, 13, 4, "S")                    # the hood, pushed down
    hair(c)
    _face(c, skin, eye_row=16, cy=17, rx=7, ry=8, mouth=False)
    _box(c, 15, 22, 2, 1, "-")
    return c


def portrait_bram():
    def hair(c):
        _ellipse(c, 16, 11, 9, 5, "M")
    c = _portrait_straggler("V", hair)
    _ellipse(c, 16, 23, 6, 3, "M")                     # short beard
    _box(c, 15, 22, 2, 1, "-")
    return _rows(c)


def portrait_sela():
    def hair(c):
        _ellipse(c, 16, 13, 10, 8, "M")
        _box(c, 22, 18, 3, 12, "M")                    # the braid
    return _rows(_portrait_straggler("A", hair))


def portrait_pim():
    def hair(c):
        _ellipse(c, 16, 11, 10, 6, "F")
        _dots(c, [(8, 13), (24, 13), (12, 5), (19, 5)], "F")
    return _rows(_portrait_straggler("A", hair))


def portrait_ansel():
    def hair(c):
        _box(c, 7, 12, 3, 6, "Z")
        _box(c, 22, 12, 3, 6, "Z")
    c = _portrait_straggler("A", hair)
    _ellipse(c, 16, 24, 6, 5, "Z")                     # long grey beard
    _box(c, 14, 21, 4, 1, "-")
    return _rows(c)


def portrait_murmur_plain():
    """Murmur after the ending: the robe set aside for a fen-green knit."""
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "Y")                    # green knit
    _box(c, 10, 26, 12, 2, "Y")                        # its rolled collar
    _ellipse(c, 16, 16, 12, 12, "H")                   # long pale hair
    _box(c, 4, 16, 24, 12, "H")
    _face(c, "A", eye_row=16, cy=17, rx=7, ry=8, mouth=False)
    _box(c, 14, 22, 4, 1, "-")                         # nearly a smile
    _dots(c, [(13, 21), (18, 21)], "-")
    _box(c, 22, 25, 7, 7, "Q")                         # the same lantern
    _box(c, 24, 27, 3, 3, "N")
    return _rows(c)


def portrait_vael():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "S")                    # grey robe
    _ellipse(c, 16, 26, 13, 4, "S")                    # the hood, down
    _box(c, 19, 28, 3, 3, "T")                         # the old lamp badge
    _ellipse(c, 16, 12, 9, 6, "Z")                     # cropped grey hair
    _face(c, "V", eye_row=16, cy=17, rx=7, ry=8, cheeks=False, mouth=False)
    _ellipse(c, 16, 22, 6, 4, "Z")                     # beard
    _box(c, 14, 21, 4, 1, "-")                         # a gentle mouth
    return _rows(c)


def portrait_dace():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "j")                    # sand wraps
    _ellipse(c, 16, 15, 12, 11, "p")                   # dusk-purple scarf
    _box(c, 4, 15, 24, 13, "p")
    _ellipse(c, 16, 12, 8, 3, "Z")                     # grey hair under it
    _face(c, "V", eye_row=17, cy=18, rx=7, ry=8, cheeks=False)
    _box(c, 10, 21, 2, 1, "-")                         # deep lines by the mouth
    _box(c, 20, 21, 2, 1, "-")
    _box(c, 27, 4, 2, 28, "s")                         # the bone staff
    return _rows(c)


def portrait_vael_keeper():
    # The same face over the keepers' navy coat, the badge bright again.
    c = [list(r) for r in portrait_vael()]
    c = [["D" if ch == "S" else ("Q" if ch == "T" else ch) for ch in r] for r in c]
    return ["".join(r) for r in c]


def portrait_marlo():
    c = _canvas()
    _ellipse(c, 16, 32, 16, 9, "q")                    # shirt, sleeves rolled
    _ellipse(c, 16, 33, 11, 9, "0")                    # sea-green waistcoat
    for i in range(6):                                 # its V opening
        _box(c, 16 - (6 - i) // 2, 24 + i, (6 - i) // 2 * 2, 1, "q")
    _dots(c, [(11, 27), (11, 30), (20, 27), (20, 30)], "Q")   # brass buttons
    _box(c, 15, 24, 2, 1, "R")                         # a red neckerchief knot
    _face(c, "w", mouth=False, cheeks=False, rx=8, ry=9, cy=14)
    # Bald crown, shining.
    _dots(c, [(13, 7), (14, 6), (15, 6)], "q")
    # Ginger mutton chops down to the jaw, and a big moustache.
    for side in (8, 22):
        _box(c, side, 12, 2, 8, "^")
        _box(c, side + (1 if side == 8 else -1), 17, 3, 4, "^")
    _box(c, 12, 19, 8, 2, "^")
    _dots(c, [(11, 20), (20, 20), (11, 21), (20, 21)], "^")
    _dots(c, [(15, 22), (16, 22)], "-")
    # Little round spectacles on the end of the nose.
    for x in (11, 18):
        _box(c, x, 14, 3, 1, "Q")
        _box(c, x, 17, 3, 1, "Q")
        _dots(c, [(x - 1, 15), (x - 1, 16), (x + 3, 15), (x + 3, 16)], "Q")
    _dots(c, [(15, 15)], "Q")
    _box(c, 11, 12, 3, 1, "^")                         # bushy ginger brows
    _box(c, 18, 12, 3, 1, "^")
    _dots(c, [(15, 17), (16, 17), (15, 18), (16, 18)], "%")   # a round nose
    # A pencil behind one ear.
    for i in range(5):
        _dots(c, [(24 + i // 2, 9 + i)], "F")
    _dots(c, [(26, 14)], "-")
    return _rows(c)


def _keeper_cap(c):
    _ellipse(c, 16, 7, 10, 5, "E")
    _box(c, 5, 9, 22, 3, "E")
    _box(c, 15, 5, 3, 3, "J")                          # the lamp badge, new
def portrait_young_hessa():
    c = _canvas()
    _ellipse(c, 16, 32, 14, 8, "E")                    # keeper's jacket
    _box(c, 10, 24, 12, 3, "r")                        # red scarf
    _box(c, 18, 26, 3, 4, "r")
    _ellipse(c, 16, 15, 10, 9, "M")                    # chestnut hair
    _face(c, "w", eye_row=16, cy=17, rx=7, ry=8)
    for i in range(9):                                 # the braid, over one shoulder
        _box(c, 24 - i // 4, 18 + i, 3, 1, "M")
    _keeper_cap(c)
    return _rows(c)
def portrait_young_vael():
    c = _canvas()
    _ellipse(c, 16, 32, 15, 8, "E")
    _box(c, 10, 24, 12, 3, "r")
    _ellipse(c, 16, 14, 9, 7, "+")                     # close-cropped dark hair
    _face(c, "V", eye_row=16, cy=17, rx=7, ry=8, cheeks=False)
    _keeper_cap(c)
    return _rows(c)


PORTRAITS = {
    "young_hessa": portrait_young_hessa(),
    "young_vael": portrait_young_vael(),
    "marlo": portrait_marlo(),
    "dace": portrait_dace(),
    "vael_keeper": portrait_vael_keeper(),
    "vael": portrait_vael(),
    "murmur": portrait_murmur(),
    "murmur_plain": portrait_murmur_plain(),
    "bram": portrait_bram(),
    "sela": portrait_sela(),
    "pim": portrait_pim(),
    "ansel": portrait_ansel(),
    "lowe": portrait_lowe(),
    "tobin": portrait_tobin(),
    "ide": portrait_ide(),
    "liesl": portrait_liesl(),
    "wick": portrait_wick(),
    "gully": portrait_gully(),
    "sorrel": portrait_sorrel(),
    "ottilie": portrait_ottilie(),
    "coralie": portrait_coralie(),
    "agna": portrait_agna(),
    "nettle": portrait_nettle(),
    "hessa": portrait_hessa(),
    "corrin": portrait_corrin(),
    "pell": portrait_pell(),
    "marga": portrait_marga(),
    "dunstan": portrait_dunstan(),
}

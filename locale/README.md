# Text and translations

Languages so far: English, Spanish (`es`), Brazilian Portuguese (`pt_BR`),
German (`de`), French (`fr`) and Russian (`ru`). The translations were
written by Claude and still want a native speaker's read before launch.
Planned next: Simplified Chinese, Japanese and Korean (CJK needs a second
font first).

Every piece of on-screen text lives in `strings.csv`: one row per key, one
column per language. Code only ever uses keys (`"MENU_CONTINUE"`), never the
English words. Godot turns each column into a `strings.<code>.translation`
file on import.

## Adding a language

The easy way is `tools/l10n.py`: `export DIR` writes English as
`DIR/en_NN.tsv` chunks of `KEY<tab>text` lines; translate each into
`DIR/<code>_NN.tsv`, then `import <code> DIR` adds the column (it refuses
missing, unknown or doubled keys) and `check <code>` compares placeholders
with English and lists dialogue lines likely to need a third line.

Keep a glossary per language for place names, item names and the terms of
address. Wren is never gendered: in Spanish Wren is "guarda", in
Portuguese "vigia", in German "Lampenwache" (or "Wache"); grown-ups call
Wren "criatura" / "criança" / "Kind". Avoid gendered adjectives about Wren.
French: "vigie", elders say "mon enfant", and nothing agrees with Wren
(no prêt/prête, allé/allée). Russian: "Рен" (never declined), elders say
"дитя"; no past-tense verbs or short adjectives with Wren as the subject
(use the present, the passive or "У Рен теперь..."). Nettle and Murmur are
ungendered too.

1. Add a column to `strings.csv` headed with the language code (`fr`, `de`,
   `es`, `pt_BR`, `ja`...). Fill in every row. Leave nothing empty: an empty
   cell shows the raw key in game.
2. Add a row for the language's own name in its own language, e.g.
   `OPT_LANG_FR` = `Français` in every column (players look for their
   language by the name they know).
3. Open the project in Godot once so it imports the new column, then add
   `res://locale/strings.<code>.translation` under
   **Project Settings > Localization > Translations** (this edits
   `project.godot`). The Options > Language setting picks it up by itself.
4. Run `python3 tools/check_strings.py`: it fails on any letter the Tide
   font can't draw. The font covers English plus the accented letters of
   French, German, Spanish, Italian, Portuguese, Dutch, Danish, Norwegian,
   Swedish, Finnish and Icelandic (with ß, æ, ø, œ, ç, ð, þ, ¡, ¿, « »,
   „ ‚ “ ” ‘ ’, …, dashes and no-break spaces) and the Russian alphabet
   with Ё, Й and №.
   Other letters go in `tools/font_glyphs.py` (`ACCENTED` for a base
   letter plus a mark, `EXTRA` for hand-drawn ones); then run
   `python3 tools/build_art.py`.

## Checks

- `python3 tools/l10n.py check-all` (run by `tools/check.sh`) fails on
  placeholders that differ from English and on text wider than a fixed menu
  cell (the progress page's columns and region names).
- The smoke test's villager checks lay out every conversation page and every
  dialogue row in every language and fail on any that needs a third line.
- `LEVIATHAN_LOCALE=de xvfb-run -a godot --rendering-driver opengl3 --path .
  res://tests/menu_screenshots.tscn` saves the menus as `screenshots/de_*.png`
  and prints `CUT (de): ...` for every label it had to cut short.
- `python3 tools/check_strings.py` (also run by CI) fails if code uses a key
  that has no English text, a key is listed twice, or a row is empty.
  `-v` lists keys that no script names directly (most are built at runtime,
  like `"ITEM_" + id`).
- Long-text check: run the menu screenshots with every string stretched by
  40% and bracketed, then look for text spilling out of its box:

      LEVIATHAN_PSEUDO=1 xvfb-run -a godot --rendering-driver opengl3 \
          --path . res://tests/menu_screenshots.tscn

  Run `res://tests/screenshots.tscn` the same way for the HUD, the
  dialogue box (normal and large text) and a cutscene.
  The shots are saved as `screenshots/pseudo_*.png`. CI captures them too.
  Single-line labels drawn with `MenuKit.draw_text(..., max_width)` and
  wrapped text from `MenuKit.draw_wrapped` cut themselves short with ".."
  rather than overflow, so the check is about text that got cut too much.

## Writing strings

- Keep the dialogue box's two-line limit in mind: write for the box, not
  around it.
- No on-screen text that explains what is happening (sound captions are an
  opt-in accessibility option only). Story narration and dialogue are fine.
- Use `%s` / `%d` placeholders for numbers and names, never string joins, so
  translators can move them.

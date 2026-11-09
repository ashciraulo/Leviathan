# Text and translations

Every piece of on-screen text lives in `strings.csv`: one row per key, one
column per language. Code only ever uses keys (`"MENU_CONTINUE"`), never the
English words. Godot turns each column into a `strings.<code>.translation`
file on import.

## Adding a language

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
   French, German, Spanish, Italian, Portuguese, Dutch and the Nordic
   languages (with ß, æ, ø, œ, ç, ¡, ¿, « », „ “ ” ‘ ’, … and dashes).
   Other letters go in `tools/font_glyphs.py` (`ACCENTED` for a base
   letter plus a mark, `EXTRA` for hand-drawn ones); then run
   `python3 tools/build_art.py`.

## Checks

- `python3 tools/check_strings.py` (also run by CI) fails if code uses a key
  that has no English text, a key is listed twice, or a row is empty.
  `-v` lists keys that no script names directly (most are built at runtime,
  like `"ITEM_" + id`).
- Long-text check: run the menu screenshots with every string stretched by
  40% and bracketed, then look for text spilling out of its box:

      LEVIATHAN_PSEUDO=1 xvfb-run -a godot --rendering-driver opengl3 \
          --path . res://tests/menu_screenshots.tscn

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

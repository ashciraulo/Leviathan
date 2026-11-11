#!/usr/bin/env python3
"""Writes the web build's extra page code into export_presets.cfg.

The browser page gets three things in its <head> (html/head_include of the
"Web" and "Web perf" presets), kept as plain files in web/ so they're easy to
edit:
  web/file_notice.html  a notice when the page is opened from a folder
                        (file://), pointing at the hosted game
  web/loading.html      the loading bar under the boot splash
  web/touch.html        on-screen controls for phones and tablets

    python3 tools/web_head.py           # update export_presets.cfg
    python3 tools/web_head.py --check   # fail if it's out of date
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARTS = ["web/file_notice.html", "web/loading.html", "web/touch.html"]
PRESETS = ["Web", "Web perf"]


def head() -> str:
    text = ""
    for part in PARTS:
        with open(os.path.join(ROOT, part), encoding="utf-8") as f:
            text += f.read().strip() + "\n"
    return text


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def main() -> int:
    path = os.path.join(ROOT, "export_presets.cfg")
    with open(path, encoding="utf-8") as f:
        cfg = f.read()
    value = 'html/head_include="%s"' % escape(head())
    # Each [preset.N] block with its [preset.N.options] block after it.
    blocks = re.split(r"(?m)^(?=\[preset\.\d+\]$)", cfg)
    out = []
    done = []
    for block in blocks:
        name = re.search(r'(?m)^name="([^"]*)"$', block)
        if name and name.group(1) in PRESETS:
            block, n = re.subn(r'(?m)^html/head_include=".*"$', lambda m: value, block)
            if n != 1:
                print("No head_include line in preset %s" % name.group(1))
                return 1
            done.append(name.group(1))
        out.append(block)
    new = "".join(out)
    if sorted(done) != sorted(PRESETS):
        print("Presets not found: %s" % (set(PRESETS) - set(done)))
        return 1
    if "--check" in sys.argv:
        if new != cfg:
            print("export_presets.cfg is out of date with web/ (run python3 tools/web_head.py)")
            return 1
        print("Web page head up to date.")
        return 0
    with open(path, "w", encoding="utf-8") as f:
        f.write(new)
    print("Wrote the web page head into %s" % ", ".join(done))
    return 0


if __name__ == "__main__":
    sys.exit(main())

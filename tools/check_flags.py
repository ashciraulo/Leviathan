#!/usr/bin/env python3
"""Catches story flags that are checked but never set (usually a typo).

A flag is *read* in GDScript by has_flag("x") / flags.get("x"), and in the
conversation tables (scripts/dialogue/conversations.gd) by "if" and
"unless" lists. It is *set* by set_flag("x"), a conversation's "set" list,
a constant (const SOMETHING_FLAG := "x") passed to set_flag, or a name
built at run time from a prefix ("entered_" + id, "tidebell_" + id).

Every flag read has to be set somewhere, or the line it guards can never
show. Exits 1 and lists them otherwise. Standard library only:
    python3 tools/check_flags.py
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> int:
    sources = {}
    for path in glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True):
        with open(path, encoding="utf-8") as f:
            sources[os.path.relpath(path, ROOT)] = f.read()

    consts = {}
    for text in sources.values():
        # const X := "a_b", or "a_" + "b" spelled out in pieces.
        for m in re.finditer(r'^\s*const\s+(\w+)\s*:?=\s*("[a-z0-9_]+"(?:\s*\+\s*"[a-z0-9_]+")*)\s*(?:#.*)?$', text, re.M):
            consts[m.group(1)] = "".join(re.findall(r'"([a-z0-9_]+)"', m.group(2)))

    reads = {}
    written = set()
    patterns = set()
    for path, text in sources.items():
        for m in re.finditer(r'(?:has_flag|flags\.get)\(\s*"([a-z0-9_]+)"\s*[,)]', text):
            reads.setdefault(m.group(1), path)
        for m in re.finditer(r'(?:has_flag|flags\.get)\(\s*(?:\w+\.)?([A-Z][A-Z0-9_]*)\b', text):
            if m.group(1) in consts:
                reads.setdefault(consts[m.group(1)], path)
        for m in re.finditer(r'(?:set_flag|clear_flag)\(\s*"([a-z0-9_]+)"\s*[,)]', text):
            written.add(m.group(1))
        for m in re.finditer(r'(?:set_flag|clear_flag)\(\s*(?:\w+\.)?([A-Z][A-Z0-9_]*)\b', text):
            if m.group(1) in consts:
                written.add(consts[m.group(1)])
        # Names built at run time ("entered_" + id): a prefix counts when it
        # is built on a line about flags or in a function named for one.
        # "x_" + id matches any x_..., "x_%d_%d" only numbers in those places.
        for m in re.finditer(r'"([a-z0-9_]+_)"\s*\+|"([a-z0-9_]*%[sd][a-z0-9_%]*)"', text):
            start = text.rfind("\n", 0, m.start()) + 1
            end = text.find("\n", m.end())
            line = text[start:end if end >= 0 else None]
            funcs = re.findall(r'^(?:static\s+)?func\s+(\w+)', text[:m.start()], re.M)
            if "flag" in line.lower() or (funcs and "flag" in funcs[-1].lower()):
                if m.group(1):
                    patterns.add(re.escape(m.group(1)) + ".+")
                else:
                    parts = re.split(r"(%[sd])", m.group(2))
                    patterns.add("".join("-?[0-9]+" if p == "%d" else ".+" if p == "%s" else re.escape(p) for p in parts))
        # Conversation tables and other flag lists.
        for m in re.finditer(r'"(if|unless|set)"\s*:\s*\[([^\]]*)\]', text):
            names = re.findall(r'"([a-z0-9_]+)"', m.group(2))
            for name in names:
                if m.group(1) == "set":
                    written.add(name)
                else:
                    reads.setdefault(name, path)

    missing = sorted(
        (name, path) for name, path in reads.items()
        if name not in written and not any(re.fullmatch(p, name) for p in patterns)
    )
    if missing:
        for name, path in missing:
            print(f"Flag '{name}' is checked in {path} but nothing ever sets it")
        return 1
    print(f"Story flags OK: {len(reads)} checked, every one is set somewhere.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Catches story flags that are checked but never set (usually a typo).

A flag is *read* in GDScript by has_flag("x") / flags.get("x"), and in the
conversation tables (scripts/dialogue/conversations.gd) by "if" and
"unless" lists. It is *set* by set_flag("x"), a conversation's "set" list,
flags[...] = true, a constant (const SOMETHING_FLAG := "x", looked up in
its own file or by Class.CONST) passed to either, or a name built at run
time from a prefix ("entered_" + id) where a flag is written or in a
function that names flags. Rooms read flags too (alt_flag = "x").

Every flag read has to be set somewhere, or the line it guards can never
show. Exits 1 and lists them otherwise. Standard library only:
    python3 tools/check_flags.py
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


CONST_RE = re.compile(r'^\s*const\s+(\w+)\s*:?=\s*("[a-z0-9_]+"(?:\s*\+\s*"[a-z0-9_]+")*)\s*(?:#.*)?$', re.M)
# A constant named in a flag call: CONST or Class.CONST.
NAME = r'(?:(\w+)\.)?([A-Z][A-Z0-9_]*)\b'


def main() -> int:
    sources = {}
    for path in glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True):
        with open(path, encoding="utf-8") as f:
            sources[os.path.relpath(path, ROOT)] = f.read()

    # Constants belong to their own file (several scripts have their own
    # DEFEATED_FLAG), and to its class_name for Class.CONST.
    file_consts = {}
    class_consts = {}
    for path, text in sources.items():
        consts = {m.group(1): "".join(re.findall(r'"([a-z0-9_]+)"', m.group(2))) for m in CONST_RE.finditer(text)}
        file_consts[path] = consts
        cls = re.search(r'^class_name\s+(\w+)', text, re.M)
        if cls:
            class_consts[cls.group(1)] = consts

    def const(path, m):
        owner, name = m.group(1), m.group(2)
        table = class_consts.get(owner, {}) if owner and owner != "self" else file_consts[path]
        return table.get(name)

    reads = {}
    written = set()
    patterns = set()
    for path, text in sources.items():
        for m in re.finditer(r'(?:has_flag|flags\.get)\(\s*"([a-z0-9_]+)"\s*[,)]', text):
            reads.setdefault(m.group(1), path)
        for m in re.finditer(r'(?:has_flag|flags\.get)\(\s*' + NAME, text):
            if const(path, m):
                reads.setdefault(const(path, m), path)
        for m in re.finditer(r'(?:set_flag|clear_flag)\(\s*"([a-z0-9_]+)"\s*[,)]|flags\[\s*"([a-z0-9_]+)"\s*\]\s*=[^=]', text):
            written.add(m.group(1) or m.group(2))
        for m in re.finditer(r'(?:set_flag|clear_flag)\(\s*' + NAME + r'|flags\[\s*' + NAME + r'\s*\]\s*=[^=]', text):
            if m.group(2) and const(path, m):
                written.add(const(path, m))
            elif m.group(4):
                owner, name = m.group(3), m.group(4)
                table = class_consts.get(owner, {}) if owner and owner != "self" else file_consts[path]
                if name in table:
                    written.add(table[name])
        # Names built at run time ("entered_" + id): a prefix counts only
        # where a flag is written with it (a set_flag or flags[...] = line),
        # or in a function that names flags (seen_flag, flag_key, flag_for);
        # never where one is only read. "x_" + id matches any x_...,
        # "x_%d_%d" only numbers in those places.
        for m in re.finditer(r'"([a-z0-9_]+_)"\s*\+|"([a-z0-9_]*%[sd][a-z0-9_%]*)"', text):
            start = text.rfind("\n", 0, m.start()) + 1
            end = text.find("\n", m.end())
            line = text[start:end if end >= 0 else None]
            funcs = re.findall(r'^(?:static\s+)?func\s+(\w+)', text[:m.start()], re.M)
            func = funcs[-1].lower() if funcs else ""
            writes = re.search(r'set_flag\(|clear_flag\(|flags\[[^\]]*\]\s*=[^=]', line)
            names = "flag" in func and not func.startswith(("has_", "is_", "_has", "_is"))
            if writes or names:
                if m.group(1):
                    patterns.add(re.escape(m.group(1)) + ".+")
                else:
                    parts = re.split(r"(%[sd])", m.group(2))
                    patterns.add("".join("-?[0-9]+" if p == "%d" else ".+" if p == "%s" else re.escape(p) for p in parts))
        # Conversation tables and other flag lists: "if": ["a", "b"] or
        # "if": "a".
        for m in re.finditer(r'"(if|unless|set)"\s*:\s*(?:\[([^\]]*)\]|("[a-z0-9_]+"))', text):
            for name in re.findall(r'"([a-z0-9_]+)"', m.group(2) or m.group(3)):
                if m.group(1) == "set":
                    written.add(name)
                else:
                    reads.setdefault(name, path)

    # Rooms that change once a flag is set (alt_flag = "...").
    for path in glob.glob(os.path.join(ROOT, "rooms", "**", "*.tscn"), recursive=True):
        with open(path, encoding="utf-8") as f:
            for m in re.finditer(r'^\w*_flag\s*=\s*"([a-z0-9_]+)"', f.read(), re.M):
                reads.setdefault(m.group(1), os.path.relpath(path, ROOT))

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

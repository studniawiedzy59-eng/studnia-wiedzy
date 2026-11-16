#!/usr/bin/env python3
"""Checks that lessons build on each other.

1. A learner is never asked to PRODUCE (build, translate, fill in) an English
   word that no earlier lesson and no part of the current lesson has shown.
2. Reports words taught as "new" twice, so repeats are deliberate.

Usage: python3 tools/check_progression.py [first_unit]
Exit code 1 if rule 1 is broken in the units checked.
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "assets" / "content" / "en"
TOKEN = re.compile(r"[A-Za-z][A-Za-z'’-]*")
NAMES = {"anna", "tom", "max", "kate", "maria", "koval", "green", "siobhan", "mark", "olena", "ben", "emma", "sam", "lisa"}


def tokens(text):
    return {t.lower().replace("’", "'") for t in TOKEN.findall(text or "")}


def derivable(token, known):
    """True for a shown word or a regular form of one: plural, 's, compound number."""
    if token in known:
        return True
    if "-" in token:
        return all(derivable(part, known) for part in token.split("-"))
    for ending in ("'s", "s'", "es", "s"):
        if token.endswith(ending) and token[: -len(ending)] in known:
            return True
    return False


def english_options(ex):
    options = ex.get("options")
    return options if isinstance(options, list) else []


def main():
    first = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    course = json.loads((ROOT / "course.json").read_text())
    seen, taught, problems, repeats = set(), {}, [], []
    for unit in course["units"]:
        number = int(unit["id"][1:])
        for lesson_id in unit["lessons"]:
            lesson = json.loads((ROOT / "lessons" / f"{lesson_id}.json").read_text())
            here = set()
            for word in lesson["words"]:
                here |= tokens(word["text"]) | tokens(word["example"])
                key = word["text"].lower()
                if key in taught and number >= first:
                    repeats.append(f"{lesson_id}: '{word['text']}' was already taught in {taught[key]}")
                taught.setdefault(key, lesson_id)
            here |= tokens(lesson["rule"].get("uk", ""))
            for ex in lesson["exercises"]:
                here |= tokens(ex.get("audioText")) | tokens(ex.get("sentence"))
                for option in english_options(ex):
                    here |= tokens(option)
                for pair in ex.get("pairs", []):
                    here |= tokens(pair["left"])
            known = seen | here
            if number >= first:
                for ex in lesson["exercises"]:
                    produced = set()
                    if ex["type"] == "build_sentence":
                        produced = tokens(" ".join(ex["answer"]))
                    elif ex["type"] == "translate":
                        produced = tokens(ex["answers"][0])
                    missing = {t for t in produced if not derivable(t, known) and t not in NAMES}
                    if missing:
                        problems.append(f"{lesson_id}/{ex['id']}: never shown before: {sorted(missing)}")
            for ex in lesson["exercises"]:
                for answer in ex.get("answers", []) + ex.get("answer", []) if isinstance(ex.get("answer"), list) else ex.get("answers", []):
                    here |= tokens(answer)
            seen |= here
    for line in repeats:
        print("REPEAT ", line)
    for line in problems:
        print("PROBLEM", line)
    print(f"{len(problems)} problem(s), {len(repeats)} repeated word(s) from unit {first} on")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()

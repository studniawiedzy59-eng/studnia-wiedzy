#!/usr/bin/env python3
"""Checks that every course and lesson file is well formed.

Run from the repository root: python3 tools/validate_content.py
Exits with status 1 and prints every problem if anything is wrong.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "content"
TYPES = {"multiple_choice", "listening", "fill_blank", "matching", "build_sentence", "translate"}
errors = []


def err(where, message):
    errors.append(f"{where}: {message}")


def l10n(where, value, langs):
    if not isinstance(value, dict) or not value:
        err(where, "must be an object keyed by language")
        return
    for lang in langs:
        if not str(value.get(lang, "")).strip():
            err(where, f"missing text for language '{lang}'")


def options_of(ex, langs, where):
    opts = ex.get("options")
    if isinstance(opts, list):
        return [opts]
    if isinstance(opts, dict):
        for lang in langs:
            if lang not in opts:
                err(where, f"options missing language '{lang}'")
        return list(opts.values())
    err(where, "options must be a list or an object keyed by language")
    return []


def check_exercise(ex, langs, where):
    kind = ex.get("type")
    if kind not in TYPES:
        err(where, f"unknown type '{kind}'")
        return
    l10n(f"{where}.explanation", ex.get("explanation"), langs)
    l10n(f"{where}.prompt", ex.get("prompt"), langs)
    if kind in {"multiple_choice", "listening", "fill_blank"}:
        for opts in options_of(ex, langs, where):
            if len(opts) < 2:
                err(where, "needs at least two options")
            if len(set(opts)) != len(opts):
                err(where, "options must be unique")
            answer = ex.get("answer")
            if not isinstance(answer, int) or not 0 <= answer < len(opts):
                err(where, "answer index out of range")
    if kind == "listening" and not str(ex.get("audioText", "")).strip():
        err(where, "listening needs audioText")
    if kind == "fill_blank" and "___" not in str(ex.get("sentence", "")):
        err(where, "sentence must contain ___")
    if kind == "matching":
        pairs = ex.get("pairs") or []
        if len(pairs) < 2:
            err(where, "needs at least two pairs")
        lefts = [p.get("left") for p in pairs]
        if len(set(lefts)) != len(lefts):
            err(where, "left sides must be unique")
        for i, pair in enumerate(pairs):
            l10n(f"{where}.pairs[{i}].right", pair.get("right"), langs)
        for lang in langs:
            rights = [(p.get("right") or {}).get(lang) for p in pairs]
            if len(set(rights)) != len(rights):
                err(where, f"right sides must be unique for language '{lang}'")
    if kind == "build_sentence":
        words, answer = list(ex.get("words") or []), ex.get("answer") or []
        if not answer:
            err(where, "answer must not be empty")
        for word in answer:
            if word in words:
                words.remove(word)
            else:
                err(where, f"answer word '{word}' is not in the word bank")
    if kind == "translate":
        answers = ex.get("answers") or []
        if not answers or any(not str(a).strip() for a in answers):
            err(where, "needs at least one non-empty answer")


def check_lesson(path, unit_id, langs):
    where = path.name
    try:
        lesson = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        err(where, f"cannot read: {exc}")
        return
    if lesson.get("id") != path.stem:
        err(where, "id must equal the file name")
    if lesson.get("unit") != unit_id:
        err(where, f"unit must be '{unit_id}'")
    for key in ("title", "goal", "rule"):
        l10n(f"{where}.{key}", lesson.get(key), langs)
    word_ids = set()
    for word in lesson.get("words") or []:
        wid = word.get("id")
        if wid in word_ids:
            err(where, f"duplicate word id '{wid}'")
        word_ids.add(wid)
        for key in ("text", "ipa", "pos", "example"):
            if not str(word.get(key, "")).strip():
                err(f"{where}.words[{wid}]", f"missing {key}")
        l10n(f"{where}.words[{wid}].translation", word.get("translation"), langs)
        l10n(f"{where}.words[{wid}].exampleTranslation", word.get("exampleTranslation"), langs)
    if not word_ids and not lesson.get("review"):
        err(where, "lesson has no words and is not marked as review")
    if word_ids and lesson.get("review"):
        err(where, "a review lesson must not introduce new words")
    if len(word_ids) > 10:
        err(where, "more than 10 new words in one lesson")
    exercise_ids = set()
    exercises = lesson.get("exercises") or []
    if len(exercises) < 8:
        err(where, "lesson needs at least 8 exercises")
    for ex in exercises:
        eid = ex.get("id")
        if eid in exercise_ids:
            err(where, f"duplicate exercise id '{eid}'")
        exercise_ids.add(eid)
        check_exercise(ex, langs, f"{where}.{eid}")


def main():
    courses = sorted(ROOT.glob("*/course.json"))
    if not courses:
        err("content", "no course.json found")
    lesson_count = 0
    for course_path in courses:
        course = json.loads(course_path.read_text(encoding="utf-8"))
        langs = course.get("explanationLanguages") or []
        if not langs:
            err(course_path.name, "explanationLanguages must not be empty")
        seen = set()
        for unit in course.get("units") or []:
            l10n(f"{course_path.parent.name}/{unit.get('id')}.title", unit.get("title"), langs)
            for lesson_id in unit.get("lessons") or []:
                if lesson_id in seen:
                    err(course_path.name, f"lesson '{lesson_id}' listed twice")
                seen.add(lesson_id)
                lesson_path = course_path.parent / "lessons" / f"{lesson_id}.json"
                if not lesson_path.exists():
                    err(course_path.name, f"lesson file missing: {lesson_id}.json")
                    continue
                lesson_count += 1
                check_lesson(lesson_path, unit.get("id"), langs)
        on_disk = {p.stem for p in (course_path.parent / "lessons").glob("*.json")}
        for orphan in sorted(on_disk - seen):
            err(course_path.name, f"lesson file not listed in course.json: {orphan}.json")
    if errors:
        print("\n".join(errors))
        print(f"\n{len(errors)} problem(s) found")
        return 1
    print(f"OK: {len(courses)} course(s), {lesson_count} lesson(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

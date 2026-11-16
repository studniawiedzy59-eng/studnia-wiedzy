import json, pathlib
OUT = pathlib.Path('/home/claude/studnia-wiedzy/assets/content/en/lessons')
uk = lambda s: {"uk": s}
def W(text, ipa, pos, tr, ex, extr):
    return {"id": text.lower().replace(" ", "_").replace("'", ""), "text": text, "ipa": ipa, "pos": pos,
            "translation": uk(tr), "example": ex, "exampleTranslation": uk(extr)}
def mc(p, opts, e): return {"type": "multiple_choice", "prompt": uk(p), "options": opts, "answer": 0, "explanation": uk(e)}
def mcu(p, opts, e): return {"type": "multiple_choice", "prompt": uk(p), "options": uk(opts), "answer": 0, "explanation": uk(e)}
def li(a, p, opts, e): return {"type": "listening", "audioText": a, "prompt": uk(p), "options": opts, "answer": 0, "explanation": uk(e)}
def liu(a, p, opts, e): return {"type": "listening", "audioText": a, "prompt": uk(p), "options": uk(opts), "answer": 0, "explanation": uk(e)}
def fb(s, opts, e, p="Оберіть слово, якого бракує"): return {"type": "fill_blank", "prompt": uk(p), "sentence": s, "options": opts, "answer": 0, "explanation": uk(e)}
def mt(pairs, e, p="З'єднайте слова з перекладом"): return {"type": "matching", "prompt": uk(p), "pairs": [{"left": l, "right": uk(r)} for l, r in pairs], "explanation": uk(e)}
def bs(p, ans, extra, e): return {"type": "build_sentence", "prompt": uk(p), "words": ans + extra, "answer": ans, "explanation": uk(e)}
def tr(p, answers, e): return {"type": "translate", "prompt": uk(p), "answers": answers, "explanation": uk(e)}
def lesson(u, cefr, n, title, goal, rule, words, exs, review=False):
    exs = [dict(id=f"e{i}", **e) for i, e in enumerate(exs, 1)]
    d = {"id": f"u{u:02d}_l0{n}", "unit": f"u{u:02d}", "cefr": cefr}
    if review: d["review"] = True
    d.update(title=uk(title), goal=uk(goal), rule=uk(rule), words=words, exercises=exs)
    (OUT / f"u{u:02d}_l0{n}.json").write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")

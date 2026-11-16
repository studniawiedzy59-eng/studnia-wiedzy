from lib import *
def T(unit, n, title, goal, rule, words, li0, listens, fbs, mc_, bs_, tr_, li1, review=False):
    pairs = [(w["text"], w["translation"]["uk"]) for w in words]
    ex = [li(*li0)] + ([mt(pairs, "Слова цього уроку.")] if pairs else [])
    ex += [liu(*s) for s in listens]
    ex += [fb(*f) for f in fbs]
    ex.append(mcu(*mc_))
    ex += [bs(*bs_), tr(*tr_), li(*li1)]
    lesson(unit, "A1", n, title, goal, rule, words, ex, review)

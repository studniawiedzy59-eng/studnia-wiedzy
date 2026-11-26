#!/usr/bin/env python3
"""Draws the original flat illustrations used in the app (topic cards and the tutor).

Everything is vector code written for this project; no outside artwork is used.
Run from the repository root: python3 tools/make_images.py   (needs rsvg-convert)
"""
import pathlib, subprocess, tempfile

OUT = pathlib.Path("assets/images")
OUT.mkdir(parents=True, exist_ok=True)

CREAM, TERRA, DARK, NAVY, SKY = "#FFF6EC", "#BF3F0A", "#8A2C06", "#1F3A5F", "#E1ECF8"
PEACH, SAND, INK = "#FFE3D1", "#E9CDB9", "#2A1B12"


def person(x, y, shirt, hair, skin="#F2C6A0", s=1.0, long_hair=True):
    """A simple friendly flat character; (x, y) is the centre of the body base."""
    h = f'<ellipse cx="{x}" cy="{y-118*s}" rx="{36*s}" ry="{40*s}" fill="{hair}"/>' if long_hair else ""
    return f'''
    <g>
      {h}
      <rect x="{x-38*s}" y="{y-70*s}" width="{76*s}" height="{90*s}" rx="{30*s}" fill="{shirt}"/>
      <rect x="{x-9*s}" y="{y-84*s}" width="{18*s}" height="{20*s}" fill="{skin}"/>
      <circle cx="{x}" cy="{y-108*s}" r="{30*s}" fill="{skin}"/>
      <path d="M{x-31*s} {y-112*s} Q{x} {y-150*s} {x+31*s} {y-112*s} Q{x+10*s} {y-128*s} {x-31*s} {y-112*s}Z" fill="{hair}"/>
      <circle cx="{x-10*s}" cy="{y-106*s}" r="{3*s}" fill="{INK}"/>
      <circle cx="{x+10*s}" cy="{y-106*s}" r="{3*s}" fill="{INK}"/>
      <path d="M{x-8*s} {y-93*s} Q{x} {y-86*s} {x+8*s} {y-93*s}" stroke="{INK}" stroke-width="{2.5*s}" fill="none" stroke-linecap="round"/>
    </g>'''


def wrap(body, w=600, h=340, bg1=PEACH, bg2=CREAM):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">
  <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{bg1}"/><stop offset="1" stop-color="{bg2}"/></linearGradient></defs>
  <rect width="{w}" height="{h}" fill="url(#g)"/>
  {body}
</svg>'''


def table(x, y, w):
    return f'<rect x="{x}" y="{y}" width="{w}" height="14" rx="7" fill="{DARK}"/><rect x="{x+w/2-6}" y="{y+14}" width="12" height="70" fill="{DARK}"/>'


SCENES = {}

SCENES["cafe"] = wrap(f'''
  <rect y="270" width="600" height="70" fill="{SAND}"/>
  <rect x="40" y="50" width="130" height="90" rx="12" fill="{SKY}"/><path d="M105 50V140M40 95H170" stroke="#fff" stroke-width="6"/>
  {person(180, 262, NAVY, INK)}
  {table(250, 232, 250)}
  <rect x="300" y="190" width="60" height="42" rx="8" fill="#fff"/><path d="M360 200q24 0 24 16t-24 16" stroke="#fff" stroke-width="8" fill="none"/>
  <path d="M318 180q-8-14 0-26M338 180q-8-14 0-26" stroke="{TERRA}" stroke-width="5" fill="none" stroke-linecap="round"/>
  <ellipse cx="430" cy="224" rx="46" ry="12" fill="#fff"/><path d="M400 222q30-34 62 0z" fill="#E8A55B"/>
''')

SCENES["shop"] = wrap(f'''
  <rect y="280" width="600" height="60" fill="{SAND}"/>
  {person(150, 272, TERRA, "#5A3418")}
  <path d="M290 150h170l-18 130H308z" fill="{NAVY}"/><path d="M325 150q0-50 50-50t50 50" stroke="{NAVY}" stroke-width="12" fill="none"/>
  <circle cx="330" cy="210" r="16" fill="{CREAM}"/><rect x="365" y="196" width="40" height="30" rx="6" fill="{PEACH}"/>
  <rect x="470" y="190" width="90" height="90" rx="10" fill="#E8A55B"/><path d="M470 220h90" stroke="#fff" stroke-width="6"/>
''', bg1=SKY, bg2=CREAM)

SCENES["travel"] = wrap(f'''
  <circle cx="470" cy="90" r="46" fill="#F7C873"/>
  <ellipse cx="130" cy="80" rx="60" ry="22" fill="#fff"/><ellipse cx="190" cy="94" rx="46" ry="18" fill="#fff"/>
  <path d="M120 190l250-40 90-60 24 8-56 70 80 10-12 22-100-8-90 50-22-8 40-48-130 20z" fill="{NAVY}"/>
  <rect y="290" width="600" height="50" fill="{SAND}"/>
  <rect x="80" y="236" width="90" height="64" rx="12" fill="{TERRA}"/><rect x="108" y="222" width="34" height="16" rx="6" fill="none" stroke="{DARK}" stroke-width="6"/>
  <rect x="190" y="250" width="70" height="50" rx="10" fill="#E8A55B"/>
''', bg1="#BFD8F2", bg2=CREAM)

SCENES["health"] = wrap(f'''
  <rect y="285" width="600" height="55" fill="{SAND}"/>
  <rect x="380" y="70" width="150" height="150" rx="26" fill="#fff"/><path d="M455 100v90M410 145h90" stroke="{TERRA}" stroke-width="26" stroke-linecap="round"/>
  {person(160, 280, "#FFFFFF", INK)}
  <path d="M135 230q-12 36 25 40q37-4 25-40" stroke="{NAVY}" stroke-width="7" fill="none"/>
  <circle cx="160" cy="276" r="11" fill="{NAVY}"/>
  <rect x="300" y="250" width="30" height="34" rx="6" fill="#7FB7A4"/><rect x="304" y="238" width="22" height="14" rx="4" fill="{NAVY}"/>
''', bg1="#DFF0EA", bg2=CREAM)

SCENES["work"] = wrap(f'''
  <rect y="285" width="600" height="55" fill="{SAND}"/>
  <rect x="60" y="50" width="120" height="100" rx="10" fill="{SKY}"/><path d="M80 130l24-36 22 20 18-30 22 46" stroke="{NAVY}" stroke-width="6" fill="none"/>
  {person(170, 280, NAVY, "#5A3418", long_hair=False)}
  {table(250, 232, 280)}
  <rect x="310" y="168" width="130" height="64" rx="8" fill="{INK}"/><rect x="318" y="176" width="114" height="48" rx="4" fill="#9CC3EE"/><rect x="290" y="232" width="170" height="8" rx="4" fill="{NAVY}"/>
  <rect x="480" y="196" width="26" height="36" rx="6" fill="{TERRA}"/><path d="M493 196q-22-30 0-48q22 18 0 48" fill="#6AA384"/>
''')

SCENES["people"] = wrap(f'''
  <rect y="285" width="600" height="55" fill="{SAND}"/>
  {person(180, 280, TERRA, INK)}
  {person(400, 280, NAVY, "#C97B2B", long_hair=False)}
  <g transform="translate(0,-34)"><path d="M120 70h120a16 16 0 0 1 16 16v44a16 16 0 0 1-16 16h-70l-26 24v-24h-24a16 16 0 0 1-16-16V86a16 16 0 0 1 16-16z" fill="#fff"/>
  <circle cx="150" cy="108" r="6" fill="{TERRA}"/><circle cx="178" cy="108" r="6" fill="{TERRA}"/><circle cx="206" cy="108" r="6" fill="{TERRA}"/></g>
  <path d="M450 56h96a14 14 0 0 1 14 14v34a14 14 0 0 1-14 14h-14v22l-24-22h-58a14 14 0 0 1-14-14V70a14 14 0 0 1 14-14z" fill="{NAVY}"/>
  <path d="M468 88h70" stroke="#fff" stroke-width="7" stroke-linecap="round"/>
''', bg1=PEACH, bg2=CREAM)

SCENES["city"] = wrap(f'''
  <rect y="270" width="600" height="70" fill="#5C5048"/><path d="M0 305h600" stroke="#F7E7B0" stroke-width="6" stroke-dasharray="36 28"/>
  <rect x="40" y="110" width="90" height="160" fill="{NAVY}"/><rect x="150" y="60" width="100" height="210" fill="{TERRA}"/>
  <rect x="270" y="130" width="80" height="140" fill="#E8A55B"/><rect x="370" y="90" width="110" height="180" fill="{DARK}"/>
  <g fill="#FFF6EC" opacity=".85"><rect x="62" y="130" width="18" height="18"/><rect x="92" y="130" width="18" height="18"/><rect x="62" y="170" width="18" height="18"/><rect x="92" y="170" width="18" height="18"/>
  <rect x="172" y="84" width="20" height="20"/><rect x="206" y="84" width="20" height="20"/><rect x="172" y="130" width="20" height="20"/><rect x="206" y="130" width="20" height="20"/>
  <rect x="392" y="114" width="22" height="22"/><rect x="430" y="114" width="22" height="22"/><rect x="392" y="162" width="22" height="22"/><rect x="430" y="162" width="22" height="22"/></g>
  <circle cx="530" cy="70" r="30" fill="#F7C873"/>
''', bg1="#BFD8F2", bg2=CREAM)

SCENES["home"] = wrap(f'''
  <rect y="280" width="600" height="60" fill="{SAND}"/>
  <rect x="70" y="60" width="140" height="110" rx="10" fill="{SKY}"/><path d="M140 60V170M70 115H210" stroke="#fff" stroke-width="8"/>
  <rect x="250" y="190" width="260" height="90" rx="26" fill="{TERRA}"/><rect x="230" y="170" width="60" height="110" rx="26" fill="{DARK}"/><rect x="470" y="170" width="60" height="110" rx="26" fill="{DARK}"/>
  <rect x="300" y="168" width="70" height="46" rx="14" fill="#E8A55B"/>
  <rect x="540" y="130" width="20" height="150" fill="{DARK}"/><path d="M500 130h100l-18 -44h-64z" fill="{NAVY}"/>
''')

SCENES["holiday"] = wrap(f'''
  <rect y="290" width="600" height="50" fill="{SAND}"/>
  <path d="M150 120q-30-40 0-70q30 30 0 70" fill="{TERRA}"/><path d="M150 120v100" stroke="{DARK}" stroke-width="3"/>
  <path d="M230 100q-30-40 0-70q30 30 0 70" fill="#E8A55B"/><path d="M230 100v120" stroke="{DARK}" stroke-width="3"/>
  <path d="M310 130q-30-40 0-70q30 30 0 70" fill="{NAVY}"/><path d="M310 130v110" stroke="{DARK}" stroke-width="3"/>
  <rect x="380" y="206" width="130" height="84" rx="10" fill="{TERRA}"/><rect x="438" y="206" width="14" height="84" fill="#F7C873"/><rect x="380" y="236" width="130" height="14" fill="#F7C873"/>
  <path d="M445 206q-34-30-8-40t8 40q34-30 8-40t-8 40" fill="#F7C873"/>
  <circle cx="90" cy="70" r="6" fill="#F7C873"/><circle cx="540" cy="80" r="7" fill="{TERRA}"/><circle cx="560" cy="150" r="5" fill="{NAVY}"/><circle cx="60" cy="170" r="5" fill="{TERRA}"/>
''', bg1="#F9D9C2", bg2=CREAM)


def render(name, svg, w, h):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg)
        path = f.name
    subprocess.run(["rsvg-convert", "-w", str(w), "-h", str(h), path, "-o", str(OUT / f"{name}.png")], check=True)


for name, svg in SCENES.items():
    render(f"topic_{name}", svg, 600, 340)

# The tutor: an original character called Anna (square portrait).
anna = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" width="300" height="300">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{PEACH}"/><stop offset="1" stop-color="#F9C9AA"/></linearGradient></defs>
  <rect width="300" height="300" rx="46" fill="url(#g)"/>
  {person(150, 292, TERRA, "#4A2A12", s=1.7)}
</svg>'''
render("tutor_anna", anna, 300, 300)
print("images:", sorted(p.name for p in OUT.glob("*.png")))

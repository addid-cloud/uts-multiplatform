from pathlib import Path
from html import escape

assets = Path(__file__).resolve().parents[1] / 'docs' / 'assets'
assets.mkdir(parents=True, exist_ok=True)

banner = '''<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="430" viewBox="0 0 1200 430" role="img" aria-labelledby="title desc">
<title id="title">Catatan Harian — Ruang kecil untuk ide besar</title>
<desc id="desc">Banner hijau sage dengan ilustrasi kartu catatan, kategori, dan sematan.</desc>
<defs><pattern id="dots" width="24" height="24" patternUnits="userSpaceOnUse"><circle cx="2" cy="2" r="1" fill="#315e4b" opacity=".09"/></pattern></defs>
<rect width="1200" height="430" rx="30" fill="#f3f6ed"/>
<rect x="700" width="500" height="430" fill="url(#dots)"/>
<circle cx="1050" cy="112" r="145" fill="#e1ebd8"/>
<circle cx="850" cy="390" r="155" fill="#e4eddf"/>
<rect x="52" y="44" width="52" height="52" rx="16" fill="#315e4b"/>
<path d="M63 60 Q70 56 78 61 Q86 56 93 60 V82 Q86 78 78 84 Q70 78 63 82 Z M78 62 V82" fill="none" stroke="#fffefa" stroke-width="3" stroke-linejoin="round"/>
<text x="120" y="77" font-family="Segoe UI,Arial,sans-serif" font-size="15" font-weight="600" letter-spacing="2" fill="#315e4b">UTS · MULTIPLATFORM</text>
<text x="52" y="173" font-family="Segoe UI,Arial,sans-serif" font-size="62" font-weight="700" letter-spacing="-2" fill="#233d30">Catatan Harian</text>
<text x="55" y="222" font-family="Segoe UI,Arial,sans-serif" font-size="26" fill="#315e4b">Ruang kecil untuk ide besar.</text>
<text x="55" y="267" font-family="Segoe UI,Arial,sans-serif" font-size="18" fill="#59665e">Tulis, temukan, dan susun ceritamu dalam satu tempat.</text>
<rect x="54" y="308" width="127" height="38" rx="19" fill="#315e4b"/>
<text x="117" y="332" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" font-size="14" font-weight="600" fill="white">Flutter + SQLite</text>
<rect x="193" y="308" width="140" height="38" rx="19" fill="#e1eadd"/>
<text x="263" y="332" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" font-size="14" fill="#315e4b">Lokal &amp; tanpa akun</text>
<g transform="translate(782 82) rotate(-9 150 130)">
<rect x="12" y="14" width="275" height="266" rx="22" fill="#315e4b" opacity=".07"/>
<rect width="275" height="266" rx="22" fill="#faedd9"/>
<rect x="24" y="23" width="62" height="23" rx="10" fill="#f2dfbc"/>
<text x="55" y="39" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#725d36">IDE</text>
<text x="25" y="84" font-family="Segoe UI,Arial,sans-serif" font-size="21" font-weight="600" fill="#3e4637">Mulai dari satu kata.</text>
<path d="M26 110 H242 M26 132 H219 M26 154 H235 M26 176 H177" stroke="#d8c5a3" stroke-width="5" stroke-linecap="round"/>
<circle cx="242" cy="230" r="16" fill="#f2dfbc"/>
<path d="M237 235 L247 225 M237 225 H247 V235" fill="none" stroke="#725d36" stroke-width="2"/>
</g>
<g transform="translate(916 172) rotate(9 105 90)">
<rect x="5" y="9" width="208" height="168" rx="20" fill="#315e4b" opacity=".08"/>
<rect width="208" height="168" rx="20" fill="#e8edf6"/>
<path d="M27 29 H41 L38 38 L42 44 H26 L30 38 Z M34 44 V53" fill="none" stroke="#52657e" stroke-width="2"/>
<text x="23" y="83" font-family="Segoe UI,Arial,sans-serif" font-size="19" font-weight="600" fill="#3a4c63">Simpan yang penting.</text>
<path d="M26 108 H179 M26 129 H152" stroke="#bccbdd" stroke-width="5" stroke-linecap="round"/>
</g>
<text x="55" y="393" font-family="Segoe UI,Arial,sans-serif" font-size="12" fill="#6b7d6e">CATATAN · KATEGORI · SEMATAN · WARNA · MODE GELAP</text>
</svg>'''
(assets / 'banner.svg').write_text(banner, encoding='utf-8')

for name, label, value, color, lw, rw in [
    ('flutter', 'Flutter', '3.35.5', '#286d98', 64, 70),
    ('dart', 'Dart', '3.9.2', '#176e80', 48, 63),
    ('sqlite', 'SQLite', 'lokal', '#315e4b', 62, 58),
    ('tests', 'Tes', '14 lulus', '#315e4b', 44, 77),
    ('version', 'Versi', '1.0.0+1', '#725d36', 54, 83),
]:
    width = lw + rw
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="28" viewBox="0 0 {width} 28" role="img" aria-label="{escape(label)}: {escape(value)}">
<clipPath id="r"><rect width="{width}" height="28" rx="7"/></clipPath>
<g clip-path="url(#r)"><rect width="{lw}" height="28" fill="#34463d"/><rect x="{lw}" width="{rw}" height="28" fill="{color}"/></g>
<g font-family="Segoe UI,Arial,sans-serif" font-size="12" fill="white" text-anchor="middle"><text x="{lw/2}" y="18">{escape(label)}</text><text x="{lw+rw/2}" y="18" font-weight="600">{escape(value)}</text></g></svg>'''
    (assets / f'badge-{name}.svg').write_text(svg, encoding='utf-8')

colors = [('Sage', '#EAF0E3', '#263C30'), ('Pasir', '#FAEDD9', '#403727'), ('Langit', '#E8EDF6', '#293547'), ('Rose', '#F3E5E2', '#422E2D')]
parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="230" viewBox="0 0 1000 230" role="img" aria-label="Palet warna kartu: Sage, Pasir, Langit, dan Rose; tema terang dan gelap"><rect width="1000" height="230" rx="20" fill="#f7f8f2"/>']
for i, (name, light, dark) in enumerate(colors):
    x = 24 + i * 244
    parts.append(f'<rect x="{x}" y="24" width="220" height="80" rx="15" fill="{light}"/><rect x="{x}" y="114" width="220" height="52" rx="12" fill="{dark}"/><text x="{x+110}" y="199" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" font-size="17" font-weight="600" fill="#315e4b">{name}</text>')
parts.append('</svg>')
(assets / 'palet-warna.svg').write_text(''.join(parts), encoding='utf-8')
print('Aset README dibuat:', len(list(assets.glob('*.svg'))))

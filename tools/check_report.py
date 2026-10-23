from pathlib import Path
import sys, json
root=Path.cwd()
sys.path.insert(0,str(root/'build'/'report_tools'))
import pymupdf
from PIL import Image, ImageDraw
pdf=pymupdf.open(root/'laporan'/'Laporan_Catatan_Harian_Muhammad_Alif_Mujaddid.pdf')
thumbs=[]
info=[]
for i,page in enumerate(pdf):
    pix=page.get_pixmap(matrix=pymupdf.Matrix(.65,.65),alpha=False)
    im=Image.frombytes('RGB',[pix.width,pix.height],pix.samples)
    tile=Image.new('RGB',(420,595),'#e7ebe7')
    im.thumbnail((400,562))
    tile.paste(im,((420-im.width)//2,10))
    ImageDraw.Draw(tile).text((15,575),f'Halaman {i+1}',fill='black')
    thumbs.append(tile)
    text=page.get_text()
    info.append({'page':i+1,'chars':len(text),'start':text[:110].replace('\n',' | '),'images':len(page.get_images())})
montage=Image.new('RGB',(420*3,595*4),'white')
for i,im in enumerate(thumbs):montage.paste(im,((i%3)*420,(i//3)*595))
preview=root/'build'/'report-layout-preview.png'
montage.save(preview)
for n in [0,6,7,10]:
    pdf[n].get_pixmap(matrix=pymupdf.Matrix(1.2,1.2),alpha=False).save(root/'build'/f'report-page-{n+1}.png')
print(json.dumps(info,ensure_ascii=False,indent=2))
print('total_pages:',len(pdf))

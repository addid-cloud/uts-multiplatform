from pathlib import Path
import json
import win32com.client
root = Path(__file__).resolve().parents[1]
source = root / 'laporan' / 'Laporan_Catatan_Harian_Muhammad_Alif_Mujaddid.docx'
pdf = source.with_suffix('.pdf')
app = win32com.client.DispatchEx('Word.Application')
app.Visible = False
app.DisplayAlerts = 0
app.AutomationSecurity = 3
document = None
try:
    document = app.Documents.Open(str(source), ReadOnly=False, AddToRecentFiles=False)
    document.Fields.Update()
    document.Repaginate()
    pages = document.ComputeStatistics(2)
    document.Save()
    document.ExportAsFixedFormat(str(pdf), 17, OpenAfterExport=False, CreateBookmarks=1)
    print(json.dumps({'pages': pages, 'pdf': str(pdf)}, ensure_ascii=False))
finally:
    if document is not None:
        document.Close(False)
    app.Quit()

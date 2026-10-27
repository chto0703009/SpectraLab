#!/usr/bin/env python3
"""Rebuild current PDF documentation; retain the unmodified historical foundation."""
from pathlib import Path
import io
import re
from xml.sax.saxutils import escape
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.pdfgen import canvas
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT/'VERSION').read_text().strip()
DATE = '2026-10-27'
INK = colors.HexColor('#183448')
STYLES = {
    'h1': ParagraphStyle('title', fontName='Helvetica-Bold', fontSize=21, leading=26, textColor=INK, spaceAfter=18),
    'h2': ParagraphStyle('heading', fontName='Helvetica-Bold', fontSize=12, leading=16, textColor=INK, spaceBefore=10, spaceAfter=7, keepWithNext=True),
    'body': ParagraphStyle('body', fontName='Helvetica', fontSize=10, leading=14.2, textColor=INK, spaceAfter=9),
}


def footer(c, doc):
    c.saveState()
    c.setFont('Helvetica', 8)
    c.setFillColor(INK)
    c.drawString(46, 30, f'SpectraLab v{VERSION} | {DATE} | Current release documentation')
    c.drawRightString(A4[0]-46, 30, str(doc.page))
    c.restoreState()


def render(source):
    story = []
    for block in source.read_text().split('\n\n'):
        block = block.strip()
        if not block:
            continue
        if block == '---':
            story.append(PageBreak())
            continue
        style = 'h1' if block.startswith('# ') else 'h2' if block.startswith('## ') else 'body'
        text = re.sub(r'^#+ ', '', block).replace('\n', ' ')
        story.append(Paragraph(escape(text), STYLES[style]))
    buffer = io.BytesIO()
    SimpleDocTemplate(buffer, pagesize=A4, leftMargin=46, rightMargin=46,
                      topMargin=45, bottomMargin=53, title=f'SpectraLab v{VERSION}: '+source.stem,
                      author='Christer Törnkvist').build(story, onFirstPage=footer, onLaterPages=footer)
    buffer.seek(0)
    return buffer


def main():
    summary = ROOT/'docs/spectralab_summary_spectral_measurement.pdf'
    summary.write_bytes(render(ROOT/'docs/TECHNICAL_SUMMARY.md').getvalue())
    report = ROOT/'docs/scientific-reports/spectralab_spectral_measurement_analysis_and_provenance.pdf'
    writer = PdfWriter()
    writer.append(PdfReader(render(ROOT/'docs/RELEASE_GUIDE.md')))
    historical = PdfReader(ROOT/'docs/scientific-reports/foundation-v1.0.1-historical.pdf')
    for page in historical.pages:
        overlay = io.BytesIO()
        width, height = float(page.mediabox.width), float(page.mediabox.height)
        c = canvas.Canvas(overlay, pagesize=(width, height))
        c.setFillColor(colors.HexColor('#843d19'))
        c.setFont('Helvetica-Bold', 7)
        c.drawCentredString(width/2, 13, f'HISTORICAL v1.0.1 - Current v{VERSION} sections take precedence')
        c.save()
        overlay.seek(0)
        page.merge_page(PdfReader(overlay).pages[0])
        writer.add_page(page)
    writer.add_metadata({'/Title': f'SpectraLab v{VERSION}: spectral measurement, analysis and provenance',
                         '/Author': 'Christer Törnkvist',
                         '/Subject': 'Current release guide with explicitly marked historical foundation appendix'})
    with report.open('wb') as stream:
        writer.write(stream)
    print(summary)
    print(report)


if __name__ == '__main__':
    main()

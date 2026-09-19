import io
from typing import List, Dict, Any
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Image, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.services.qr_service import generate_qr_image_bytes

def generate_printable_card_grid_pdf(
    organization_name: str,
    members: List[Dict[str, Any]]
) -> bytes:
    """
    Generator Lembar Cetak Kartu ID QR dalam Layout Grid A4 (4 kolom per baris)
    Diadopsi langsung dari fitur Cetak Kartu Grid 4 Kolom pada absensi-sekolah-qr-code.
    Dilengkapi garis bantu potong, header institusi, nama anggota, dan barcode QR.
    """
    buffer = io.BytesIO()
    # A4 dimensions: 595.27 x 841.89 points
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=20,
        rightMargin=20,
        topMargin=25,
        bottomMargin=25
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'HeaderStyle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=6.5,
        alignment=1, # Center
        textColor=colors.HexColor('#1F497D'),
        leading=8
    )
    name_style = ParagraphStyle(
        'NameStyle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7,
        alignment=1,
        textColor=colors.black,
        leading=9
    )
    info_style = ParagraphStyle(
        'InfoStyle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=6,
        alignment=1,
        textColor=colors.HexColor('#4A5568'),
        leading=7.5
    )

    card_cells = []
    for m in members:
        qr_bytes = generate_qr_image_bytes(m.get("qr_token", "SAMPLE-TOKEN"))
        qr_img = Image(io.BytesIO(qr_bytes), width=65, height=65)

        card_content = [
            [Paragraph(organization_name[:24].upper(), title_style)],
            [Spacer(1, 2)],
            [qr_img],
            [Spacer(1, 2)],
            [Paragraph(m.get("name", "Nama")[:22], name_style)],
            [Paragraph(f"No: {m.get('registration_number', '-')}", info_style)],
            [Paragraph(m.get("group_name", "-")[:20], info_style)],
        ]

        single_card_table = Table(card_content, colWidths=[125])
        single_card_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BOX', (0, 0), (-1, -1), 0.8, colors.HexColor('#1F497D')), # Border luar kartu
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#EBF4FF')), # Header background
            ('INNERGRID', (0, 0), (-1, -1), 0, colors.transparent),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
            ('LEFTPADDING', (0, 0), (-1, -1), 3),
            ('RIGHTPADDING', (0, 0), (-1, -1), 3),
        ]))
        card_cells.append(single_card_table)

    # Susun ke dalam Grid 4 Kolom
    grid_rows = []
    current_row = []
    for card in card_cells:
        current_row.append(card)
        if len(current_row) == 4:
            grid_rows.append(current_row)
            current_row = []
    if current_row:
        # Pad sisa kolom kosong
        while len(current_row) < 4:
            current_row.append("")
        grid_rows.append(current_row)

    main_grid = Table(grid_rows, colWidths=[136, 136, 136, 136])
    main_grid.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 2),
        ('RIGHTPADDING', (0, 0), (-1, -1), 2),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))

    doc.build([main_grid])
    return buffer.getvalue()

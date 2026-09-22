import io
from datetime import datetime, timezone
from bson import ObjectId
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

from app.database.mongodb import db
from app.services.financial_service import FinancialService

financial_service = FinancialService()


class PDFService:
    def generate_financial_report_pdf(
        self,
        business_id: str | None,
        period: str,
        user_id: str,
        start_date=None,
        end_date=None,
    ) -> bytes:
        # 1. Fetch real report overview data from MongoDB
        data = financial_service.get_report_overview(
            business_id=business_id,
            period=period,
            user_id=user_id,
            start_date=start_date,
            end_date=end_date,
        )

        # 2. Fetch business details
        business_name = "My Business"
        if business_id:
            try:
                b_doc = db.businesses.find_one({"_id": ObjectId(business_id)})
                if b_doc and b_doc.get("name"):
                    business_name = b_doc["name"]
            except Exception:
                pass
        elif user_id:
            try:
                b_doc = db.businesses.find_one({"owner_id": user_id})
                if b_doc and b_doc.get("name"):
                    business_name = b_doc["name"]
            except Exception:
                pass

        total_income = float(data.get("total_income", 0.0))
        total_expenses = float(data.get("total_expenses", 0.0))
        net_profit = float(data.get("net_profit", 0.0))
        txn_count = int(data.get("transaction_count", 0))
        income_breakdown = data.get("income_breakdown", [])
        expense_breakdown = data.get("expense_breakdown", [])
        transactions = data.get("transactions", [])

        margin = (net_profit / total_income * 100) if total_income > 0 else 0.0

        # 3. Setup document and styles
        buf = io.BytesIO()
        doc = SimpleDocTemplate(
            buf,
            pagesize=letter,
            rightMargin=40,
            leftMargin=40,
            topMargin=40,
            bottomMargin=40,
        )

        styles = getSampleStyleSheet()

        primary_color = colors.HexColor("#2563EB")
        secondary_color = colors.HexColor("#0F172A")
        text_muted = colors.HexColor("#64748B")
        income_green = colors.HexColor("#059669")
        expense_red = colors.HexColor("#DC2626")
        border_color = colors.HexColor("#E2E8F0")

        header_style = ParagraphStyle(
            "DocHeader",
            parent=styles["Normal"],
            fontSize=22,
            fontName="Helvetica-Bold",
            textColor=secondary_color,
            leading=26,
        )
        subtitle_style = ParagraphStyle(
            "DocSubtitle",
            parent=styles["Normal"],
            fontSize=11,
            fontName="Helvetica",
            textColor=text_muted,
            leading=15,
        )
        section_style = ParagraphStyle(
            "SectionHeader",
            parent=styles["Normal"],
            fontSize=14,
            fontName="Helvetica-Bold",
            textColor=primary_color,
            leading=18,
            spaceBefore=14,
            spaceAfter=6,
        )
        cell_style = ParagraphStyle(
            "TableCell",
            parent=styles["Normal"],
            fontSize=9,
            fontName="Helvetica",
            textColor=secondary_color,
            leading=12,
        )
        cell_bold = ParagraphStyle(
            "TableCellBold",
            parent=styles["Normal"],
            fontSize=9,
            fontName="Helvetica-Bold",
            textColor=secondary_color,
            leading=12,
        )

        story = []

        # Header Block
        story.append(Paragraph("VyaparAI Financial Report", header_style))
        gen_time = datetime.now(timezone.utc).strftime("%d %B %Y, %H:%M UTC")
        story.append(
            Paragraph(
                f"Business: <b>{business_name}</b> | Period: <b>{period.upper()}</b> | Generated: {gen_time}",
                subtitle_style,
            )
        )
        story.append(Spacer(1, 10))
        story.append(HRFlowable(width="100%", thickness=1.5, color=primary_color, spaceAfter=15))

        # Executive KPI Summary Table
        story.append(Paragraph("Executive Financial Summary", section_style))
        kpi_data = [
            [
                Paragraph("<b>Total Revenue (Income)</b>", cell_bold),
                Paragraph(f"<b>₹ {total_income:,.2f}</b>", ParagraphStyle("KPIInc", parent=cell_bold, textColor=income_green)),
            ],
            [
                Paragraph("<b>Total Operating Expenses</b>", cell_bold),
                Paragraph(f"<b>₹ {total_expenses:,.2f}</b>", ParagraphStyle("KPIExp", parent=cell_bold, textColor=expense_red)),
            ],
            [
                Paragraph("<b>Net Operating Profit</b>", cell_bold),
                Paragraph(
                    f"<b>₹ {net_profit:,.2f}</b>",
                    ParagraphStyle("KPIProf", parent=cell_bold, textColor=income_green if net_profit >= 0 else expense_red),
                ),
            ],
            [
                Paragraph("<b>Profit Margin</b>", cell_bold),
                Paragraph(f"{margin:.1f}%", cell_style),
            ],
            [
                Paragraph("<b>Total Record Count</b>", cell_bold),
                Paragraph(f"{txn_count} transactions", cell_style),
            ],
        ]
        kpi_table = Table(kpi_data, colWidths=[240, 290])
        kpi_table.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
                ("INNERGRID", (0, 0), (-1, -1), 0.5, border_color),
                ("BOX", (0, 0), (-1, -1), 1.0, border_color),
                ("PADDING", (0, 0), (-1, -1), 6),
            ])
        )
        story.append(kpi_table)
        story.append(Spacer(1, 12))

        # Income Breakdown Table
        if income_breakdown:
            story.append(Paragraph("Income by Category", section_style))
            inc_data = [[
                Paragraph("<b>Category</b>", cell_bold),
                Paragraph("<b>Amount (INR)</b>", cell_bold),
                Paragraph("<b>Share</b>", cell_bold),
                Paragraph("<b>Count</b>", cell_bold),
            ]]
            for item in income_breakdown:
                amt = float(item.get("amount", 0.0))
                pct = float(item.get("percentage", 0.0))
                cnt = int(item.get("count", 0))
                inc_data.append([
                    Paragraph(item.get("category", "General"), cell_style),
                    Paragraph(f"₹ {amt:,.2f}", cell_style),
                    Paragraph(f"{pct:.1f}%", cell_style),
                    Paragraph(str(cnt), cell_style),
                ])
            inc_table = Table(inc_data, colWidths=[180, 130, 110, 110])
            inc_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#ECFDF5")),
                    ("INNERGRID", (0, 0), (-1, -1), 0.5, border_color),
                    ("BOX", (0, 0), (-1, -1), 1.0, border_color),
                    ("PADDING", (0, 0), (-1, -1), 5),
                ])
            )
            story.append(inc_table)
            story.append(Spacer(1, 12))

        # Expense Breakdown Table
        if expense_breakdown:
            story.append(Paragraph("Expenses by Category", section_style))
            exp_data = [[
                Paragraph("<b>Category</b>", cell_bold),
                Paragraph("<b>Amount (INR)</b>", cell_bold),
                Paragraph("<b>Share</b>", cell_bold),
                Paragraph("<b>Count</b>", cell_bold),
            ]]
            for item in expense_breakdown:
                amt = float(item.get("amount", 0.0))
                pct = float(item.get("percentage", 0.0))
                cnt = int(item.get("count", 0))
                exp_data.append([
                    Paragraph(item.get("category", "General"), cell_style),
                    Paragraph(f"₹ {amt:,.2f}", cell_style),
                    Paragraph(f"{pct:.1f}%", cell_style),
                    Paragraph(str(cnt), cell_style),
                ])
            exp_table = Table(exp_data, colWidths=[180, 130, 110, 110])
            exp_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#FEF2F2")),
                    ("INNERGRID", (0, 0), (-1, -1), 0.5, border_color),
                    ("BOX", (0, 0), (-1, -1), 1.0, border_color),
                    ("PADDING", (0, 0), (-1, -1), 5),
                ])
            )
            story.append(exp_table)
            story.append(Spacer(1, 12))

        # Recent Transactions Table
        if transactions:
            story.append(Paragraph("Transactions in Period", section_style))
            tx_data = [[
                Paragraph("<b>Date</b>", cell_bold),
                Paragraph("<b>Type</b>", cell_bold),
                Paragraph("<b>Category</b>", cell_bold),
                Paragraph("<b>Description</b>", cell_bold),
                Paragraph("<b>Amount (INR)</b>", cell_bold),
            ]]
            for tx in transactions[:40]:  # Limit to 40 most recent
                dt = tx.get("date", "")
                if "T" in dt:
                    dt = dt.split("T")[0]
                ttype = str(tx.get("type", "income")).upper()
                amt = float(tx.get("amount", 0.0))
                type_color = income_green if ttype == "INCOME" else expense_red
                tx_data.append([
                    Paragraph(dt, cell_style),
                    Paragraph(ttype, ParagraphStyle("TT", parent=cell_bold, textColor=type_color)),
                    Paragraph(tx.get("category", "General"), cell_style),
                    Paragraph((tx.get("description") or "—")[:30], cell_style),
                    Paragraph(f"₹ {amt:,.2f}", cell_style),
                ])
            tx_table = Table(tx_data, colWidths=[80, 65, 110, 175, 100])
            tx_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
                    ("INNERGRID", (0, 0), (-1, -1), 0.5, border_color),
                    ("BOX", (0, 0), (-1, -1), 1.0, border_color),
                    ("PADDING", (0, 0), (-1, -1), 4),
                ])
            )
            story.append(tx_table)
            story.append(Spacer(1, 15))

        # Footer
        story.append(HRFlowable(width="100%", thickness=0.8, color=border_color, spaceBefore=10, spaceAfter=8))
        story.append(
            Paragraph(
                "Generated securely via VyaparAI Enterprise Financial Engine • All rights reserved.",
                ParagraphStyle("DocFooter", parent=styles["Normal"], fontSize=8, fontName="Helvetica", textColor=text_muted, alignment=1),
            )
        )

        doc.build(story)
        return buf.getvalue()


pdf_service = PDFService()

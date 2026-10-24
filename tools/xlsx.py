"""Makes a chit's spreadsheet from its saved document.

    python3 tools/xlsx.py OUT.xlsx  < kuri.json

Three sheets: Months (collected, fines, pot, who took it), Ledger (every
member, every month) and How it works. The server runs this whenever the
kuri has changed since the last copy was made.
"""
import json, sys
from datetime import date

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

MEN = ["January", "February", "March", "April", "May", "June",
       "July", "August", "September", "October", "November", "December"]
MSH = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
# The chit's currency: (symbol, Indian grouping, space after the symbol).
# Chits saved before currencies existed are in rupees.
CURRENCIES = {
    "INR": ("₹", True, False), "AED": ("AED", False, True), "SAR": ("SAR", False, True), "QAR": ("QAR", False, True),
    "KWD": ("KWD", False, True), "OMR": ("OMR", False, True), "BHD": ("BHD", False, True), "USD": ("$", False, False),
    "GBP": ("£", False, False), "EUR": ("€", False, False), "SGD": ("S$", False, False), "MYR": ("RM", False, True),
    "LKR": ("Rs", False, True),
}


def currency_of(code):
    return CURRENCIES.get(str(code or "INR").strip().upper(), CURRENCIES["INR"])


def indian(n):
    s = str(abs(int(round(n))))
    if len(s) > 3:
        last, rest, parts = s[-3:], s[:-3], []
        while len(rest) > 2:
            parts.insert(0, rest[-2:])
            rest = rest[:-2]
        if rest:
            parts.insert(0, rest)
        s = ",".join(parts) + "," + last
    return ("-" if n < 0 else "") + s


def money(n, code):
    sym, ind, spaced = currency_of(code)
    digits = indian(n) if ind else format(int(round(n)), ",")
    return ("%s %s" if spaced else "%s%s") % (sym, digits)


def number_format(code):
    sym, ind, spaced = currency_of(code)
    sym = sym.replace('"', "")
    return '"%s%s"#,##0' % (sym, " " if spaced else "")


def ordinal(n):
    if 11 <= n % 100 <= 13:
        return "%dth" % n
    return "%d%s" % (n, {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th"))


def style(ws, widths, freeze="A2"):
    head = Font(bold=True, color="FFFFFF")
    fill = PatternFill("solid", fgColor="116326")
    for c in ws[1]:
        c.font = head
        c.fill = fill
        c.alignment = Alignment(vertical="center")
    ws.row_dimensions[1].height = 22
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = freeze


def main(out, d):
    sm, sy = int(d.get("startMonth") or 1), int(d.get("startYear") or date.today().year)
    share, fine = int(d.get("share") or 0), int(d.get("fine") or 0)
    cur = d.get("currency") or "INR"
    fmt = number_format(cur)
    slots = int(d.get("slots") or 0)
    months = sorted(d.get("months") or [], key=lambda m: m.get("n", 0))
    people = {p.get("id"): p.get("name", "") for p in d.get("people") or []}
    payers = sorted(d.get("payers") or [], key=lambda p: (p.get("slot", 0), str(p.get("id"))))
    slot_names = {}
    for p in payers:
        slot_names.setdefault(p.get("slot"), []).append(people.get(p.get("person"), "Someone"))

    def label(n):
        i = (sm - 1) + n - 1
        return "%s %d" % (MSH[i % 12], sy + i // 12)

    wb = Workbook()
    ws = wb.active
    ws.title = "Months"
    ws.append(["Month", "Collected", "Late fines", "Pot", "Took the pot"])
    for i, m in enumerate(months, 1):
        paid = m.get("paid") or {}
        fines = m.get("fines") or {}
        got = sum(int(p.get("amt") or 0) for p in payers if paid.get(p.get("id")))
        nf = sum(1 for p in payers if fines.get(p.get("id")))
        won = m.get("winner")
        ws.append([label(i), got, fine * nf, share * slots,
                   (" / ".join(slot_names.get(won, [])) + " (slot %d)" % won) if won else ""])
    for row in ws.iter_rows(min_row=2, min_col=2, max_col=4):
        for c in row:
            c.number_format = fmt
    style(ws, [12, 13, 12, 12, 30])

    ws = wb.create_sheet("Ledger")
    ws.append(["Slot", "Member", "Share"] + [label(i) for i in range(1, len(months) + 1)])
    for p in payers:
        row = [p.get("slot"), people.get(p.get("person"), "Someone"), int(p.get("amt") or 0)]
        for m in months:
            pid = p.get("id")
            if not (m.get("paid") or {}).get(pid):
                cell = "Not paid"
            elif (m.get("fines") or {}).get(pid):
                cell = "Late"
            else:
                cell = "Paid"
            if m.get("winner") == p.get("slot"):
                cell += ", took the pot"
            row.append(cell)
        ws.append(row)
    for r in range(2, ws.max_row + 1):
        ws.cell(row=r, column=3).number_format = fmt
    style(ws, [7, 22, 10], freeze="D2")
    for i in range(len(months)):
        ws.column_dimensions[get_column_letter(4 + i)].width = 12

    ws = wb.create_sheet("How it works")
    title = ("%s %s" % (d.get("group") or "", d.get("name") or "Chit")).strip()
    ws.append([title])
    ws["A1"].font = Font(bold=True, size=13)
    cd, ld = int(d.get("collectDay") or 20), int(d.get("lastDay") or 25)
    lines = [
        "%d slots at %s a month." % (slots, money(share, cur)),
        "Collection on the %s. Last date is midnight on the %s%s." % (ordinal(cd), ordinal(ld), " of the next month" if ld < cd else ""),
    ]
    if fine:
        lines.append("A late payment costs %s, which goes into that month's pot." % money(fine, cur))
    lines += [
        "One slot takes the whole %s pot each month." % money(share * slots, cur),
        "A slot that has taken the pot keeps paying but is out of the draw.",
        "",
        "Figures as of %s." % (d.get("updated") or date.today().isoformat()),
    ]
    for line in lines:
        ws.append([line])
    ws.column_dimensions["A"].width = 78
    wb.save(out)


if __name__ == "__main__":
    main(sys.argv[1], json.load(sys.stdin))

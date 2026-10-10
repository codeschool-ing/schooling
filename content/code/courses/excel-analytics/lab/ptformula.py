"""An English Excel formula as a Brazilian Excel spells it.

Excel translates its function names and its argument separator per language:
the formula a student types in an Excel set to Portuguese is `=SOMASES(…; …)`,
and the English spelling is refused there. So every formula fence in this
course is `localised`, and its Portuguese side is produced here from the
English one rather than typed twice, which is the way a translated formula
goes wrong: one argument edited in one language.

What changes: the function names below, `,` between arguments to `;`, a
decimal point to a comma, TRUE and FALSE, and the error values. What does not:
cell addresses, sheet and table names (they are the student's own), text in
quotes, and anything that is not a function call. A name missing from the
table is a refusal, never a pass-through: an English name left in a
Portuguese formula is a formula the Portuguese Excel answers with #NOME?.
"""
import re

NAMES = {
    "ABS": "ABS", "AND": "E", "AVERAGE": "MÉDIA", "AVERAGEIF": "MÉDIASE",
    "AVERAGEIFS": "MÉDIASES", "CHOOSE": "ESCOLHER", "CLEAN": "TIRAR",
    "CONCAT": "CONCAT", "COUNT": "CONT.NÚM", "COUNTA": "CONT.VALORES",
    "COUNTBLANK": "CONTAR.VAZIO", "COUNTIF": "CONT.SE", "COUNTIFS": "CONT.SES",
    "DATE": "DATA", "DATEVALUE": "DATA.VALOR", "DAY": "DIA", "EDATE": "DATAM",
    "EOMONTH": "FIMMÊS", "EXACT": "EXATO", "FILTER": "FILTRO", "FIND": "PROCURAR",
    "GETPIVOTDATA": "INFODADOSTABELADINÂMICA", "HLOOKUP": "PROCH", "IF": "SE",
    "IFERROR": "SEERRO", "IFNA": "SENÃODISP", "IFS": "SES", "INDEX": "ÍNDICE",
    "INT": "INT", "ISBLANK": "ÉCÉL.VAZIA", "ISNUMBER": "ÉNÚM", "ISTEXT": "ÉTEXTO",
    "LEFT": "ESQUERDA", "LEN": "NÚM.CARACT", "LOWER": "MINÚSCULA", "MATCH": "CORRESP",
    "MAX": "MÁXIMO", "MAXIFS": "MÁXIMOSES", "MEDIAN": "MED", "MID": "EXT.TEXTO",
    "MIN": "MÍNIMO", "MINIFS": "MÍNIMOSES", "MONTH": "MÊS", "NOT": "NÃO",
    "NETWORKDAYS": "DIATRABALHOTOTAL", "NOW": "AGORA", "OR": "OU",
    "PROPER": "PRI.MAIÚSCULA", "RIGHT": "DIREITA", "ROUND": "ARRED",
    "ROWS": "LINS", "SEARCH": "LOCALIZAR", "SORT": "CLASSIFICAR",
    "SUBSTITUTE": "SUBSTITUIR", "SUBTOTAL": "SUBTOTAL", "SUM": "SOMA",
    "SUMIF": "SOMASE", "SUMIFS": "SOMASES", "SUMPRODUCT": "SOMARPRODUTO",
    "SWITCH": "PARÂMETRO", "TEXT": "TEXTO", "TEXTAFTER": "TEXTODEPOIS",
    "TEXTBEFORE": "TEXTOANTES", "TEXTJOIN": "UNIRTEXTO", "TODAY": "HOJE",
    "TRIM": "ARRUMAR", "UNIQUE": "ÚNICO", "UPPER": "MAIÚSCULA", "VALUE": "VALOR",
    "VLOOKUP": "PROCV", "WEEKDAY": "DIA.DA.SEMANA", "XLOOKUP": "PROCX",
    "XMATCH": "CORRESPX", "YEAR": "ANO", "ISNA": "É.NÃO.DISP", "NA": "NÃO.DISP",
    "ISERROR": "ÉERRO", "LET": "LET", "SEQUENCE": "SEQUÊNCIA",
}
WORDS = {"TRUE": "VERDADEIRO", "FALSE": "FALSO"}
ERRORS = {"#N/A": "#N/D", "#VALUE!": "#VALOR!", "#NAME?": "#NOME?",
          "#REF!": "#REF!", "#DIV/0!": "#DIV/0!", "#SPILL!": "#DESPEJAR!"}

TOKEN = re.compile(r'"[^"]*"|\'[^\']*\'!|\[[^\]]*\]|#N/A|#VALUE!|#NAME\?|#REF!|#DIV/0!|#SPILL!'
                   r'|[A-Za-z_][A-Za-z0-9_.]*(?=\()|\b(?:TRUE|FALSE)\b|\d+\.\d+|,|.', re.S)


def to_pt(formula):
    out = []
    for m in TOKEN.finditer(formula):
        t = m.group(0)
        if t.startswith('"') or t.startswith("'") or t.startswith("["):
            out.append(t)
        elif t in ERRORS:
            out.append(ERRORS[t])
        elif t == ",":
            out.append(";")
        elif re.fullmatch(r"\d+\.\d+", t):
            out.append(t.replace(".", ","))
        elif t in WORDS:
            out.append(WORDS[t])
        elif re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", t) and m.end() < len(formula) and formula[m.end()] == "(":
            up = t.upper()
            if up not in NAMES:
                raise SystemExit(f"no Portuguese name for {t} in {formula!r}")
            out.append(NAMES[up])
        else:
            out.append(t)
    return "".join(out)


def block_to_pt(body):
    """A whole `localised` fence: every line that is a formula is translated;
    a line that is not (a value, a cell's text) is kept."""
    return "\n".join(to_pt(l) if l.lstrip().startswith("=") else l for l in body.split("\n"))


if __name__ == "__main__":
    for f in ['=SUMIFS(F2:F109, G2:G109, "Online", B2:B109, ">="&DATE(2025,1,1))',
              '=IFERROR(XLOOKUP(D2, Products!A:A, Products!F:F), "missing")',
              '=IF(AND(E2>=10, G2="Wholesale"), TRUE, FALSE)', '=ROUND(F2*0.9, 0)']:
        print(f, "→", to_pt(f))

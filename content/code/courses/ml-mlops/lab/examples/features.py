FILE = __file__.replace('/examples/', '/programs/')
LANGUAGE = "python"
NAME = "features.py"
PARTS = [
 ('"""features.py', "The definitions this whole course runs on. **Active** means bought something in the 180 days up to the cutoff; **lapsed** means bought nothing in the 90 days after it.",
  "As definições sobre as quais o curso inteiro roda. **Ativo** quer dizer que comprou algo nos 180 dias até o corte; **afastado** (`lapsed`) quer dizer que não comprou nada nos 90 dias depois dele."),
 ("QUERY = ", "`recent` is every visit in the 180 days up to `:cutoff`, with what it cost. Only members with a row here appear in the result, which is what makes them active.",
  "`recent` é cada visita nos 180 dias até `:cutoff`, com quanto custou. Só membros com alguma linha aqui aparecem no resultado, e é isso que os torna ativos."),
 ("SELECT m.member_id", "The features: one number per member, each computed from days on or before the cutoff and never after it.",
  "Os atributos: um número por membro, cada um calculado com dias até o corte, nunca depois dele."),
 ("       NOT EXISTS", "The label, and the only line that reads the future: a purchase in the 90 days after the cutoff. **For a cutoff less than 90 days ago the future is not over yet**, and this line answers 1 for members who simply have not had time to come back. Lesson 3 is about that.",
  "O rótulo, e a única linha que lê o futuro: uma compra nos 90 dias depois do corte. **Para um corte de menos de 90 dias atrás o futuro ainda não acabou**, e esta linha responde 1 para membros que só não tiveram tempo de voltar. A lição 3 é sobre isso."),
 ("NUMERIC = ", "Two lists the later programs use to pick columns, and the one function they call. A cutoff is a date as text, `2025-09-30`.",
  "Duas listas que os programas seguintes usam para escolher colunas, e a única função que eles chamam. Um corte é uma data em texto, `2025-09-30`."),
]

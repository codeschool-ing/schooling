"""Lesson 24: Azure CLI, Azure PowerShell and Cloud Shell."""
from figures import Fig, T, figure


@figure('l24-pipeline', 24)
def pipeline():
    f = Fig('l24-pipeline', 720, 250, T(
        'What happens to an answer inside the Azure CLI, left to right. The answer arrives as JSON. '
        'The query, written in JMESPath, keeps the part asked for. The output format then prints it '
        'as json, table, tsv or yaml. Both steps run on your computer, after the answer has arrived.',
        'O que acontece com uma resposta dentro da CLI do Azure, da esquerda para a direita. A resposta '
        'chega como JSON. A consulta, escrita em JMESPath, fica com a parte pedida. O formato de saída '
        'então a imprime como json, table, tsv ou yaml. Os dois passos rodam no seu computador, depois '
        'que a resposta chegou.'))
    f.rect(20, 20, 680, 170, stroke='--paper-dim', fill='--ink', dash='5 4')
    f.text(36, 38, T('your computer', 'o seu computador'), size=9.5, anchor='start', fill='--paper-dim')
    boxes = [(50, T('the answer', 'a resposta'), 'JSON'),
             (280, T('the query', 'a consulta'), '--query'),
             (510, T('the view', 'a visão'), '--output')]
    for x, title, code in boxes:
        f.rect(x, 70, 160, 70, stroke='--wire', fill='--panel')
        f.text(x + 80, 92, title, size=10.5, weight='600')
        f.text(x + 80, 116, code, size=10.5, mono=True, fill='--amber')
    f.arrow([(211, 105), (279, 105)], stroke='--paper-dim', width=1.4)
    f.arrow([(441, 105), (509, 105)], stroke='--paper-dim', width=1.4)
    f.text(360, 162, "[?name=='AzureCloud'] .endpoints  | [0]", size=10, mono=True, fill='--paper-dim')
    f.text(130, 162, '[ {...}, {...}, ... ]', size=10, mono=True, fill='--paper-dim')
    f.text(590, 162, 'json  table  tsv  yaml', size=10, mono=True, fill='--paper-dim')
    f.text(360, 222, T('nothing in either step is sent to Azure: both cut what already came back',
                       'nada nos dois passos é mandado ao Azure: os dois recortam o que já voltou'),
           size=10, fill='--phosphor')
    return f, T('The query picks the part, the output chooses how to print it, both after the answer is in.',
                'A consulta escolhe a parte, a saída escolhe como imprimi-la, as duas depois que a resposta chegou.')

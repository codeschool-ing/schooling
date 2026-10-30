---
title: Quanto custaria sair, estimado antes de chegar
version: 1
---

"O quanto estamos presos?" não tem resposta. **"Quanto custaria sair, em pessoas-dia e em
dinheiro?" tem**, e pode ser estimado no primeiro dia, quando mudar é mais barato. A estimativa tem
quatro linhas, e cada uma vem de algo que dá para contar: os componentes que seriam reescritos, os
dados que seriam levados para fora, as pessoas que teriam de aprender outra plataforma e os meses
rodando as duas enquanto a mudança acontece.

**Todo número do exemplo desta seção é inventado**: as pessoas-dia, os gigabytes, a tarifa por
gigabyte e a fatura mensal. Eles estão aqui para deixar a aritmética concreta, e nenhum deles é
preço do Azure nem medição de ninguém. O método é a parte a guardar.

## A reescrita, componente por componente

Comece pelo código e pelos arquivos em volta dele. A pergunta não é o tamanho do sistema, e sim o
quanto dele toca o Azure, e a unidade honesta é um componente por vez. Para a loja depois da
decisão da aula 21, isso é a imagem, o Container App e seus dois jobs, a fila do Service Bus da
exportação financeira, a identidade que os conecta, o banco e o compartilhamento de arquivos, o
Bicep que declara tudo e aquilo com que a equipe observa o sistema.

Um programa curto guarda essa lista, dá a cada linha uma nota em pessoas-dia e as soma por tipo de
lock-in. Ele não usa nada além da biblioteca padrão do Python. Salve-o como `~/azure/exitcost.py`; o
botão de copiar leva o arquivo inteiro, sem as notas:

```schooling-example
{"language": "python", "file": "exitcost.py", "parts": [{"code": "# exitcost.py\n\"\"\"What leaving Azure would cost the shop. Every figure here is invented.\"\"\"\n\nDEPENDENCIES = [\n    # component, kind of lock-in, person-days to replace it elsewhere\n    ('shop:1.0, the image', 'API', 0),\n    ('Container Apps: the app and two jobs', 'API', 3),\n    ('Service Bus queue for the export', 'API', 2),\n    ('managed identity and role assignments', 'identity', 3),\n    ('orders database and report share', 'data', 2),\n    ('Bicep files', 'operations', 4),\n    ('Azure Monitor queries and alerts', 'operations', 3),\n    ('three developers on a new platform', 'operations', 12),\n    ('reservations and savings plans', 'contract', 0),\n]\n", "note": "As dependências da loja depois da decisão da aula 21, uma linha cada: o que é, que tipo de lock-in da seção 02 carrega e as pessoas-dia para substituí-la em outra plataforma. **Todo número aqui é inventado.** A imagem vale zero porque a seção 03 a executou sem mudança de três maneiras, e o contrato vale zero porque a loja não assinou nada."}, {"code": "GB = 300               # orders and report files to carry out\nUSD_PER_GB = 0.10      # illustrative, not Azure's price\nMONTHS_BOTH = 2        # both platforms running during the move\nUSD_PER_MONTH = 150    # illustrative: the shop's Azure bill today\n\n", "note": "As duas linhas que são dinheiro e não esforço: os gigabytes a levar para fora e os meses em que as duas plataformas rodam. As tarifas são redondas de propósito, para ninguém confundi-las com as do Azure."}, {"code": "width = max(len(name) for name, _, _ in DEPENDENCIES)\nprint(f\"{'component':<{width}}  {'kind':<10}  days\")\nfor name, kind, days in sorted(DEPENDENCIES, key=lambda d: d[2], reverse=True):\n    print(f'{name:<{width}}  {kind:<10}  {days:>4}')\n\n", "note": "A tabela, da maior para a menor. `sorted` com `reverse=True` mantém as linhas de mesmos dias na ordem em que foram escritas, então a saída é igual em toda execução."}, {"code": "totals = {}\nfor _, kind, days in DEPENDENCIES:\n    totals[kind] = totals.get(kind, 0) + days\neverything = sum(totals.values())\nprint()\nfor kind, days in sorted(totals.items(), key=lambda t: t[1], reverse=True):\n    print(f'{kind:<10}  {days:>4} person-days  {100 * days / everything:3.0f}%')\nprint(f\"{'total':<10}  {everything:>4} person-days\")\n\n", "note": "A nota por tipo: as pessoas-dia de cada tipo e a fatia dele no total. A fatia é o que o registro de decisão da próxima seção lê, porque diz para que tipo de lock-in valeria comprar uma costura."}, {"code": "print()\nprint(f'data out   {GB} GB x {USD_PER_GB:.2f} USD = {GB * USD_PER_GB:.2f} USD')\nprint(f'both run   {MONTHS_BOTH} months x {USD_PER_MONTH} USD = {MONTHS_BOTH * USD_PER_MONTH:.2f} USD')\n", "note": "O dinheiro, impresso à parte dos dias para que ninguém some dinheiro com pessoas-dia."}], "output": "component                              kind        days\nthree developers on a new platform     operations    12\nBicep files                            operations     4\nContainer Apps: the app and two jobs   API            3\nmanaged identity and role assignments  identity       3\nAzure Monitor queries and alerts       operations     3\nService Bus queue for the export       API            2\norders database and report share       data           2\nshop:1.0, the image                    API            0\nreservations and savings plans         contract       0\n\noperations    19 person-days   66%\nAPI            5 person-days   17%\nidentity       3 person-days   10%\ndata           2 person-days    7%\ncontract       0 person-days    0%\ntotal         29 person-days\n\ndata out   300 GB x 0.10 USD = 30.00 USD\nboth run   2 months x 150 USD = 300.00 USD\n"}
```

Execute-o com `python3 exitcost.py`. A saída é a primeira metade da estimativa, o esforço, seguida
do dinheiro.

Cada linha é um palpite que alguém pode contestar, e é para isso que ele é escrito: um número num
arquivo pode ser corrigido, e uma impressão numa reunião não pode.

Leia primeiro o topo da tabela. **A maior linha são as pessoas, não o código**: doze pessoas-dia
para três desenvolvedores aprenderem os contêineres, a identidade e o monitoramento de outra
plataforma, contra três para o Container App e duas para a fila. Isso é comum numa equipe pequena,
e é o tipo operacional da seção 02 aparecendo como número. O Bicep vem em seguida, porque todo
recurso da loja está declarado numa linguagem que só o Azure lê, e os quatro dias são a reescrita
para o que a próxima plataforma ler.

Depois leia o fim. **A imagem não custa nada para mudar**, porque a seção 03 a mostrou rodando sem
mudança no Docker, no Dapr e no Kubernetes: não ter reescrita é todo o valor de uma costura que já
estava paga. E a linha de contrato é zero porque a loja não assinou nada. Um savings plan de três
anos não somaria pessoa-dia nenhuma e poderia somar muito dinheiro, e é por isso que ele tem uma
linha própria.

Num sistema real, a lista da reescrita vem de uma busca, não da memória: todo arquivo que importa
uma biblioteca `azure`, toda função decorada com um gatilho ou um binding, toda definição de
workflow, todo módulo Bicep, toda atribuição de função. Um sistema em que essa busca devolve quatro
arquivos tem uma linha de reescrita pequena; um em que ela devolve duzentos tem uma grande, diga o
que disser o diagrama de arquitetura.

## Os dados, e o preço de levá-los para fora

Dados são o lock-in que cresce sozinho. Todo mês a loja guarda mais pedidos e mais arquivos de
relatório, e cada gigabyte é mais um a levar para fora. O Azure cobra por gigabyte os dados que saem
dele para a internet. O programa usa uma tarifa redonda, 0,10 USD por GB, que é **ilustrativa e não
é a do Azure**. A real está na calculadora de preços, em largura de banda, ou na Retail Prices API
que as aulas 1 e 21 mostraram, filtrada pelos medidores de largura de banda de `brazilsouth`; este
curso não cita número de nenhuma das duas. Na tarifa do exemplo, 300 GB dão 30,00 USD, a linha que
o programa imprimiu.

Para a loja o dinheiro é pouco e o tempo não: um banco de dados não é copiado uma vez e trocado
numa tarde de sexta-feira. Ele é copiado, mantido em sincronia enquanto os dois rodam e então
virado, que é a próxima linha. Se a Microsoft oferecer algum alívio na transferência para um
cliente que sai do Azure, isso é algo a perguntar quando o dia chegar; mantenha a tarifa cheia na
estimativa, porque é o número que vale sem a aprovação de ninguém.

## Pessoas e sobreposição

As duas últimas linhas são onde a maior parte do custo se esconde:

- **o retreinamento** é pessoas vezes dias, e já está na tabela como a maior linha dela. Ele
  pertence à estimativa mesmo quando ninguém recebe a mais, porque as semanas gastas aprendendo são
  semanas não gastas na loja;
- **a operação em paralelo** é meses vezes a fatura antiga. Durante a mudança as duas plataformas
  rodam, e o Azure custa o que custava antes. O exemplo põe a fatura da loja em ilustrativos 150 USD
  por mês, durante dois meses, 300,00 USD, como o programa imprimiu. A aula 21 é de onde vem o
  número mensal de verdade, quando as tarifas dela forem reais.

## A estimativa, por escrito

Juntando tudo, com todos os números do exemplo:

| linha | como se conta | a loja, como exemplo |
| --- | --- | --- |
| reescrita | pessoas-dia por componente que toca o Azure | 17 pessoas-dia, 3 delas de identidade |
| dados | GB a levar para fora × preço por GB | 300 GB × 0,10 = 30,00 USD |
| retreinamento | pessoas × dias para aprender | 3 pessoas × 4 dias = 12 pessoas-dia |
| sobreposição | meses × a fatura mensal antiga | 2 meses × 150 USD = 300,00 USD |

**O total não é o que importa; a maior linha é.** Para a loja são as pessoas, depois o Bicep, e o
dinheiro é pouco ao lado dos dois. Isso diz onde uma costura se pagaria e onde não: nenhum adaptador
faz três pessoas conhecerem uma plataforma nova, mas manter a imagem livre do Azure zerou a linha
dela. A próxima seção escreve tudo isso num arquivo que a loja guarda.

---
title: Por arquivo, a integração mais antiga ainda rodando
version: 1
---

Toda noite, por volta das 23:30, o Coleta grava um arquivo: um header, uma linha para cada um dos
cerca de 1.900 produtores coletados no dia, e um trailer. Ele empurra o arquivo por SFTP para um
diretório no servidor de aplicação do SAP, e às 02:00 um programa ABAP o lê e cria uma entrada de
mercadoria de leite para cada linha. O Sebastião escreveu a primeira versão em 1996, para outro ERP,
e o leiaute mudou duas vezes desde então. **É a integração mais antiga da empresa, e aquela de que
depende o pagamento dos produtores.**

É fácil olhar esse arquivo de cima. A Joana olhou, na primeira semana, porque na fintech nada se
movia por arquivo desde antes de ela chegar. Mas arquivos continuam em toda parte nas empresas
grandes, e por bons motivos. Os 1.900 pagamentos aos produtores saem da Serra Alta num arquivo CNAB
240 para o banco, e a resposta do banco volta em outro arquivo. As grandes redes de supermercado
mandam seus pedidos e recebem suas notas como mensagens EDI, por um provedor de EDI, num padrão como
o EANCOM, o subconjunto do EDIFACT para o varejo, ou numa variante da própria rede. **Um arquivo não
precisa de nada rodando do outro lado no momento em que é gravado**, qualquer sistema de qualquer
década consegue produzir um, e qualquer pessoa consegue abrir e ler. Esse último ponto vale mais
durante um incidente do que parece.

## O que um arquivo custa

O preço é latência e silêncio. Um arquivo traz o que era verdade quando foi gravado. Até a mudança
da aula 1, o Portal B2B sabia o estoque do SAP por um arquivo que o SAP gravava a cada hora, e umas
30 vezes por semana uma padaria pedia algo que tinha esgotado desde o último arquivo. **Um arquivo é
uma fotografia, e todo mundo depois dele está olhando a fotografia, não a sala.**

O silêncio é a metade pior. Uma integração por arquivo falha de jeitos que não se anunciam: o
arquivo não chega, chega duas vezes, chega gravado pela metade, ou chega com uma linha faltando.
Cada um tem uma defesa, e uma integração por arquivo segura tem todas.

## Header e trailer, com totais de controle

A primeira defesa é que **o arquivo diz o que contém, para que quem lê possa conferir que recebeu
tudo**. Um header dá nome ao arquivo: quem gravou, de que dia, com que número de sequência. Um
trailer o fecha com totais de controle: quantos registros vieram antes dele, e a soma do campo que
mais importa. Para o Coleta, são os litros. Uma carga que soma as linhas e compara com o trailer
sabe se o arquivo está inteiro antes de lançar uma única entrada de mercadoria.

O CNAB 240 tem a mesma forma numa escala maior. Toda linha tem 240 caracteres; o arquivo tem um
header e um trailer próprios, e dentro dele cada lote de pagamentos tem seu header e seu trailer,
com o número de registros e a soma dos valores. Um banco que recebe um arquivo cujos totais não
batem o rejeita antes de pagar qualquer pessoa, que é o que se espera de um banco.

## O nome, e o momento em que o arquivo aparece

A segunda defesa está no nome. **O nome traz a data e um número de sequência**, para que quem lê
distinga um arquivo novo de uma repetição e perceba uma lacuna. `coleta-20261022-0001.txt` é o primeiro arquivo de 22 de outubro, e se aparecer um segundo com o mesmo nome, alguma coisa está
sendo mandada de novo.

A terceira trata de quando o arquivo fica visível. Um arquivo gravado direto com o nome final existe
enquanto está sendo gravado, e um leitor que vigia o diretório pode pegá-lo pela metade: 1.200 de
1.900 linhas, um trailer que nunca vê. A correção é **gravar com um nome temporário e renomear o
arquivo quando estiver completo**. No mesmo sistema de arquivos, renomear é atômico: quem lê vê
nenhum arquivo ou o arquivo inteiro, nunca um pedaço. Um leitor que só procura nomes terminados em
`.txt` nunca encosta no `.tmp`.

## O programa

Este programa grava um pequeno arquivo do Coleta do jeito seguro e confere um do jeito que uma carga
deveria conferir. São seis produtores em vez de 1.900, e o leiaute é simplificado, mas o header, o
trailer e o renomear são de verdade. Salve-o como `coleta_file.py` num diretório vazio; ele precisa
de Python 3 e de mais nada.

```schooling-example
{
  "language": "python",
  "file": "coleta_file.py",
  "parts": [
    {
      "code": "# coleta_file.py: write Coleta's nightly file safely, and check one before it is loaded\nimport os\nimport pathlib\nimport sys",
      "note": "Três módulos da biblioteca padrão. `os.replace` é o renomear; `pathlib` lê e grava o arquivo."
    },
    {
      "code": "\nDAY, SEQ, WIDTH = \"20261022\", 1, 40\nFARMS = [  # farm code, name, litres, fat and protein in hundredths of a percent\n    (\"004417\", \"SITIO BOA VISTA\", 1840, 362, 318),\n    (\"010233\", \"FAZ SANTA LUZIA\", 312, 405, 331),\n    (\"002981\", \"FAZ TRES PONTES\", 5120, 348, 309),\n    (\"017605\", \"SITIO DO CORREGO\", 960, 391, 322),\n    (\"008112\", \"FAZ RIO DO PEIXE\", 2275, 357, 314),\n    (\"021340\", \"SITIO PEDRA ALTA\", 730, 376, 327),\n]",
      "note": "A coleta de um dia, fixa para que toda execução grave o mesmo arquivo. Todo registro tem 40 caracteres de largura. Gordura e proteína são números inteiros de centésimos, então 362 é 3,62%, porque um arquivo de largura fixa não tem lugar para a vírgula decimal, nem acordo sobre se ela é vírgula ou ponto. Os nomes não têm acento: em UTF-8 uma letra acentuada ocupa dois bytes, o que deslocaria todos os campos depois dela."
    },
    {
      "code": "\n\ndef write():\n    name = f\"coleta-{DAY}-{SEQ:04d}.txt\"\n    total = sum(farm[2] for farm in FARMS)\n    lines = [f\"HCOLETA{DAY}{SEQ:04d}SERRA ALTA LATICINIOS\"]\n    for code, farm, litres, fat, protein in FARMS:\n        lines.append(f\"D{code}{farm:<18}{litres:07d}{fat:04d}{protein:04d}\")\n    lines.append(f\"T{DAY}{SEQ:04d}{len(FARMS):09d}{total:018d}\")",
      "note": "O header diz que arquivo é este: o sistema, o dia e a sequência. Cada linha `D` completa o nome com espaços até 18 caracteres e os números com zeros, para que cada campo comece na mesma coluna em todas as linhas. O trailer repete o dia e a sequência, depois os dois totais de controle: quantas linhas de produtor, e quantos litros."
    },
    {
      "code": "    tmp = pathlib.Path(name + \".tmp\")\n    tmp.write_text(\"\\n\".join(lines) + \"\\n\", encoding=\"ascii\")\n    os.replace(tmp, name)\n    print(f\"wrote {name}: {len(FARMS)} farms, {total} litres\")\n    return 0",
      "note": "O arquivo é gravado com um nome que ninguém está procurando, e só é renomeado quando a última linha está escrita. Um leitor que procura arquivos `.txt` não vê nada, e depois vê o arquivo inteiro. `encoding=\"ascii\"` faz o Python recusar um caractere fora do ASCII em vez de gravar uma linha da largura errada."
    },
    {
      "code": "\n\ndef check(path):\n    lines = pathlib.Path(path).read_text(encoding=\"ascii\").splitlines()\n    problems = [f\"line {n} has {len(line)} characters, not {WIDTH}\"\n                for n, line in enumerate(lines, 1) if len(line) != WIDTH]\n    kinds = \"\".join(line[:1] for line in lines)\n    if not problems and (len(kinds) < 2 or kinds != \"H\" + \"D\" * (len(kinds) - 2) + \"T\"):\n        problems.append(\"the file must be one header, the farm lines and one trailer\")",
      "note": "Primeiro o formato. Toda linha precisa ter 40 caracteres, o que pega um arquivo cortado no meio de uma linha. Depois, as primeiras letras das linhas precisam formar um `H`, qualquer número de `D` e um `T`: um arquivo sem trailer para aqui, antes que alguém tente ler totais de uma linha de produtor."
    },
    {
      "code": "    if not problems:\n        head, farms, tail = lines[0], lines[1:-1], lines[-1]\n        count, litres = int(tail[13:22]), int(tail[22:40])\n        found = sum(int(line[25:32]) for line in farms)\n        if head[7:19] != tail[1:13]:\n            problems.append(\"the header and the trailer name different files\")\n        if (count, litres) != (len(farms), found):\n            problems.append(f\"trailer says {count} farms and {litres} litres; \"\n                            f\"the file has {len(farms)} farms and {found} litres\")",
      "note": "Os totais. Os recortes são o leiaute: os caracteres 13 a 21 do trailer são a contagem, 22 a 39 os litros, e os caracteres 25 a 31 de uma linha de produtor são seus litros. A carga soma as linhas de produtor por conta própria e compara com o que quem gravou prometeu."
    },
    {
      "code": "    if problems:\n        print(f\"REFUSED {path}\")\n        for problem in problems:\n            print(f\"  {problem}\")\n        return 1\n    print(f\"accepted {path}: {count} farms, {litres} litres\")\n    return 0",
      "note": "Um arquivo recusado é informado com todos os motivos encontrados, e o status de saída é 1, para que o que roda a carga possa parar e disparar um alarme. Nada foi carregado até aqui: a conferência vem antes da primeira entrada de mercadoria."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if sys.argv[1:] == [\"write\"]:\n        sys.exit(write())\n    if len(sys.argv) == 3 and sys.argv[1] == \"check\":\n        sys.exit(check(sys.argv[2]))\n    sys.exit(\"usage: python3 coleta_file.py write | check FILE\")",
      "note": "Dois comandos: `write` faz o arquivo do dia, `check FILE` julga um. No Windows o comando é `python`, e não `python3`."
    }
  ]
}
```

Grave o arquivo e liste o diretório para ver que só sobrou o nome final:

```
$ python3 coleta_file.py write
wrote coleta-20261022-0001.txt: 6 farms, 11237 litres
$ ls
coleta-20261022-0001.txt
coleta_file.py
```

Depois olhe o arquivo. Cada linha é um registro, e as colunas se alinham porque cada campo tem
largura fixa:

```
$ cat coleta-20261022-0001.txt
HCOLETA202610220001SERRA ALTA LATICINIOS
D004417SITIO BOA VISTA   000184003620318
D010233FAZ SANTA LUZIA   000031204050331
D002981FAZ TRES PONTES   000512003480309
D017605SITIO DO CORREGO  000096003910322
D008112FAZ RIO DO PEIXE  000227503570314
D021340SITIO PEDRA ALTA  000073003760327
T202610220001000000006000000000000011237
```

A primeira linha de produtor diz: tipo de registro `D`, produtor `004417`, o nome completado até 18
caracteres, `0001840` litros, gordura `0362` e proteína `0318`. O trailer diz: dia `20261022`,
sequência `0001`, `000000006` linhas de produtor e `000000000000011237` litros. **Nada no arquivo diz
onde um campo termina**; o leiaute é um acordo guardado fora dele, e os dois lados precisam guardar o
mesmo.

Agora confira-o como a carga faria:

```
$ python3 coleta_file.py check coleta-20261022-0001.txt
accepted coleta-20261022-0001.txt: 6 farms, 11237 litres
$ echo $?
0
```

## Um arquivo com uma linha a menos

Para ver uma recusa, faça uma cópia sem uma das linhas de produtor. No Linux ou no macOS, `sed '5d'`
mostra o arquivo sem a quinta linha, e `>` salva isso como `damaged.txt`. Em qualquer outro lugar,
copie o arquivo para `damaged.txt` e apague num editor de texto a linha do produtor `017605`.

```
$ sed '5d' coleta-20261022-0001.txt > damaged.txt
$ python3 coleta_file.py check damaged.txt
REFUSED damaged.txt
  trailer says 6 farms and 11237 litres; the file has 5 farms and 10277 litres
$ echo $?
1
```

**O trailer é como quem lê descobre que falta alguma coisa.** Sem ele, as cinco linhas que sobraram
formam um arquivo perfeitamente válido, a carga dá certo, e um produtor recebe 960 litros a menos no
fim do mês. Uma linha pode sumir de jeitos que ninguém escolheu: uma transferência interrompida e
retomada, uma conversão que parou num caractere de que não gostou, alguém editando o arquivo à mão
para corrigir outra linha.

## A resposta, a repetição e a ausência

Mais três defesas cobrem o que o trailer não vê.

**Quem lê responde.** Uma integração por arquivo segura devolve alguma coisa: um arquivo de
confirmação com o nome do arquivo carregado e os totais encontrados, ou um arquivo de rejeição com os
motivos. O CNAB funciona assim, porque o arquivo de retorno do banco diz, registro por registro, o
que aconteceu com cada pagamento. O arquivo do Coleta não tinha resposta. Se a carga recusasse um
arquivo, o Sebastião ficava sabendo quando alguém ligava para ele.

**Carregar o mesmo arquivo duas vezes não pode mudar nada.** Em 2019 um operador rodou de novo a
carga das 02:00 depois de ela estourar o tempo limite, sem saber que ela tinha terminado, e o leite
de um dia foi contado duas vezes para 1.870 produtores. Foi pego na prévia do pagamento, porque os
litros do mês deram 3% acima do que as fábricas tinham recebido. Uma carga que registra o dia e a
sequência de cada arquivo carregado, e recusa um que já viu, torna inofensiva uma segunda execução.
A aula 10 chama essa propriedade de idempotência e a aplica a mensagens.

**A ausência é a falha que uma integração por arquivo esconde.** Em março de 2025 venceu a senha da
conta que o Coleta usa no SFTP. Por quatro noites nenhum arquivo chegou; a carga das 02:00 não achou
nada para carregar e terminou sem erro, que é o que faz uma carga sem nada a fazer. Ninguém percebeu
até 7 de abril, quando a prévia do pagamento mostrou todos os produtores com quatro dias a menos.
**Uma integração por arquivo precisa de um alarme para o arquivo que não veio**, marcado para um
horário em que ele já deveria ter vindo. O da Serra Alta agora dispara às 01:30 se não houver arquivo
do Coleta no dia. Aos domingos o SAP fica parado para manutenção das 01:00 às 05:00 e a carga espera
até depois, o que o arquivo permite: ele fica no diretório, inteiro, até quem lê voltar.

## A integração por arquivo segura, em ordem

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-safe-file\" aria-label=\"A integração por arquivo segura, em ordem. No lado de quem grava, o Coleta: 1, gravar o arquivo com um nome temporário, com header e trailer trazendo a contagem e os litros; 2, renomear quando estiver completo. O arquivo então chega ao diretório de quem lê. No lado de quem lê, o SAP: 3, conferir o header, o formato e os totais do trailer; 4, recusar um arquivo cujo dia e sequência já foram carregados; 5, carregar; 6, mandar um arquivo de confirmação ou de rejeição de volta a quem gravou, desenhado como uma seta tracejada. Ao lado de quem lê, um alarme dispara às 01:30 se nenhum arquivo chegou no dia.\"><defs><marker id=\"l09-safe-file-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-safe-file-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"250.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem grava: Coleta</text><rect x=\"300.0\" y=\"20.0\" width=\"410.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem lê: SAP</text><rect x=\"25.0\" y=\"63.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"78.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  gravar com nome .tmp,</text><text x=\"135.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">com header e trailer</text><rect x=\"25.0\" y=\"125.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  renomear quando completo</text><path d=\"M135.0 107.0 L135.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"58.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  conferir formato e totais</text><rect x=\"315.0\" y=\"110.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  recusar dia já carregado</text><path d=\"M420.0 92.0 L420.0 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"162.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  carregar</text><path d=\"M420.0 144.0 L420.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"214.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6  devolver confirmação ou rejeição</text><path d=\"M420.0 196.0 L420.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><path d=\"M245.0 147.0 L280.0 147.0 L280.0 75.0 L313.0 75.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><path d=\"M315.0 231.0 L135.0 231.0 L135.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l09-safe-file-es-ah-paper-dim)\"></path><rect x=\"565.0\" y=\"98.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"121.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem arquivo às 01:30:</text><text x=\"630.0\" y=\"134.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o alarme dispara</text><text x=\"135.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a confirmação ou rejeição volta</text></svg>", "caption": "Seis passos e um alarme. Cada um existe porque um arquivo deu errado em algum lugar: gravado pela metade, com uma linha a menos, carregado duas vezes, recusado em silêncio, ou nunca enviado."}
```

Nenhum desses passos é caro, e cada um existe porque um arquivo deu errado em algum lugar. O mapa da
Joana tem 41 integrações por arquivo, e quando ela passou por elas com esta lista, **só 9 tinham um
trailer que alguém conferia**.

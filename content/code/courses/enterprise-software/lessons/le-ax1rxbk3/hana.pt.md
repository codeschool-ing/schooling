---
title: O HANA, e por que o S/4HANA não é uma atualização
version: 1
---

No terceiro dia com o time de SAP, Joana fez a pergunta que todo mundo faz: quando a Serra Alta
atualiza para o S/4HANA? A resposta de Edson foi que ela não atualiza. **O S/4HANA não é o ECC num
banco mais rápido; é a suíte reescrita em torno de um banco de dados que mudou o que o modelo de
dados precisava ser.** Migrar para ele é um projeto de anos, com decisões próprias sobre o histórico,
sobre o código próprio e sobre cada interface que toca o SAP. Para entender por quê,
comece pelo banco.

## Um banco que guarda as colunas juntas

O HANA é o banco de dados da própria SAP, e difere dos bancos em que o ECC costumava rodar em duas
coisas.

Ele é **em memória**: a cópia de trabalho dos dados fica na memória principal, e não em disco com um
cache na frente. Nem por isso é volátil. O HANA grava um log de cada mudança e salva a memória em
disco de tempos em tempos, então um reinício recarrega os dados e não perde nada que foi confirmado.

E ele é **orientado a colunas**. Um banco convencional guarda a tabela linha por linha: todos os
campos de uma linha de pedido ficam juntos no disco. Um armazenamento por coluna guarda cada coluna
junta: todas as quantidades num lugar, todos os centros em outro, todos os números de material num
terceiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-columns\" aria-label=\"As mesmas três linhas de pedido guardadas de dois jeitos. Cada linha tem quatro campos: pedido, material, centro e quantidade. Num armazenamento por linha os doze valores ficam uma linha depois da outra, então as três quantidades ficam espalhadas e somá-las exige ler cada linha inteira. Num armazenamento por coluna os valores ficam uma coluna depois da outra, então as três quantidades ficam num bloco só e a soma lê só esse bloco. A coluna de centro é guardada como um dicionário de três centros e um código de dois bits por linha.\"><text x=\"42.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">por linha: uma linha depois da outra</text><rect x=\"42.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"67.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4711</text><rect x=\"94.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"119.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"146.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"198.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1200</text><rect x=\"258.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4712</text><rect x=\"310.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"335.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BUT-200</text><rect x=\"362.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"387.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LV01</text><rect x=\"414.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"439.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300</text><rect x=\"474.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4713</text><rect x=\"526.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"551.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"578.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"603.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"630.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"655.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">950</text><text x=\"42.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">para somar as quantidades, cada linha é lida inteira</text><text x=\"42.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">por coluna: uma coluna depois da outra</text><rect x=\"42.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"67.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4711</text><rect x=\"94.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"119.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4712</text><rect x=\"146.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4713</text><rect x=\"206.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"231.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"258.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BUT-200</text><rect x=\"310.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"335.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"370.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"395.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"422.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"447.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LV01</text><rect x=\"474.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"534.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"559.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1200</text><rect x=\"586.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"611.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300</text><rect x=\"638.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"663.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">950</text><text x=\"42.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">para somar as quantidades, um bloco só é lido</text><text x=\"42.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a coluna de centro, comprimida:</text><text x=\"242.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01=0  BA01=1  LV01=2</text><text x=\"412.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e um código de 2 bits por linha:</text><text x=\"602.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0 2 0</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os campos, na ordem: pedido, material, centro, quantidade</text></svg>", "caption": "Uma tabela, dois arranjos. O armazenamento por linha mantém o registro junto; o por coluna mantém o campo junto, que é o que uma soma sobre milhões de linhas precisa."}
```

**O armazenamento por linha é rápido para mexer num registro; o por coluna é rápido para ler um campo
em milhões deles.** Criar uma ordem de venda, ou lê-la de volta, pede a linha inteira, e o
armazenamento por linha a entrega num lugar só. Uma pergunta como "quantos litros de leite UHT cada
centro vendeu no último trimestre" pede três campos de quarenta, em todas as linhas. O armazenamento
por linha precisa ler os quarenta para chegar aos três; o por coluna lê os três e ignora o resto.

As colunas também comprimem bem, porque uma coluna guarda um tipo só de valor e o repete. Pegue uma
tabela de linhas de ordem de venda na Serra Alta com 40 milhões de linhas. A coluna de centro guarda
um de três valores, já que só Juiz de Fora, Barbacena e Lavras rodam no SAP. Guardada como texto de
quatro caracteres, essa coluna ocupa 40.000.000 × 4 bytes, ou seja, 160 MB. Troque cada valor por um
número que aponta para um dicionário curto dos três centros, e dois bits bastam por linha:
40.000.000 × 2 bits são 80.000.000 bits, ou 10 MB. Os números são ilustrativos, não o formato exato
do HANA, mas o princípio, **um dicionário dos valores distintos e um código compacto por linha**, é
o que faz tabelas grandes caberem na memória de um banco colunar.

## O que o modelo de dados deixou de precisar

O ECC foi desenhado para bancos que não conseguiam somar milhões de itens de lançamento enquanto um
usuário esperava. Então cada lançamento fazia mais do que se registrar. Gravava o item, depois
atualizava uma tabela de *totais* com somas acumuladas por conta e período, depois gravava linhas em
tabelas de *índice* que existiam só para achar coisas rápido, como as partidas em aberto de um
cliente. Uma entrada de mercadoria ou uma fatura mexia em várias tabelas, todas mantidas em
sincronia pelo código da SAP.

Num banco colunar em memória, as somas podem ser calculadas a partir dos itens na hora em que são
pedidas. O S/4HANA foi construído sobre essa premissa, e a SAP a usou para tirar uma boa parte do
modelo de dados do ECC.

| área | no ECC | no S/4HANA |
|---|---|---|
| finanças e controladoria | itens de lançamento separados para o FI e para o CO, mais tabelas de totais como a `GLT0` e de índice como a `BSID` e a `BSAK` | uma tabela de itens só, a `ACDOCA`, o *Universal Journal*; totais e índices calculados na leitura |
| estoque | documentos de material numa tabela de cabeçalho e numa de itens, `MKPF` e `MSEG` | uma tabela só, a `MATDOC`, a que a aula 1 apresentou |
| documentos de venda | status em tabelas próprias, `VBUK` e `VBUP` | campos de status nas próprias tabelas da ordem |
| clientes e fornecedores | cadastros separados de cliente e de fornecedor | um *business partner*, obrigatório para os dois |
| número do material | até 18 caracteres | até 40 caracteres |
| banco de dados | vários suportados | só o HANA |

**O Universal Journal é a mudança que importa para quem é de finanças.** No ECC, a contabilidade
financeira e a controladoria guardavam registros separados dos mesmos eventos, e o fechamento
mensal da Serra Alta inclui uma conciliação entre os dois que o time de Marcos Teles faz à mão. Com
uma tabela de itens só para os dois, eles batem por construção.

Os nomes antigos de tabela não sumiram todos. Muitos sobrevivem como *views de compatibilidade*
calculadas a partir das tabelas novas, então o código ABAP que lê a `BSID` ainda recebe resposta. O
código que escreve nelas falha, e o mesmo acontece com o código que supõe que um número de material
cabe em 18 caracteres, ou que cria um cliente sem business partner. Cada um desses casos está em
algum lugar dos 1.800 objetos Z da Serra Alta, e alguns estão nas interfaces também: um mapeamento
de EDI que corta o número do material em 18 caracteres funciona até o primeiro número mais longo ser
criado.

## A data que define a pauta

A SAP publica por quanto tempo dá suporte a cada versão. Para o ECC 6.0 com enhancement package 6
ou posterior, que é onde a Serra Alta está, **a manutenção principal termina em 31 de dezembro de
2027**. A SAP oferece manutenção estendida opcional até o fim de 2030, por uma taxa adicional.
Depois disso, o ECC passa para o que a SAP chama de manutenção específica do cliente, que não entrega
mais mudanças legais novas.

Essa última parte é a que importa no Brasil. **Um ERP que para de receber mudanças legais para de
conseguir faturar.** A reforma tributária do consumo introduz tributos novos em etapas entre 2026 e
2033, e o leiaute da NF-e muda junto; uma Serra Alta que não conseguisse emitir uma NF-e válida não
conseguiria despachar um palete de manteiga. "Ficar no ECC" é, portanto, uma opção com data de
validade.

Joana fez a conta num quadro branco para Regina Fontes. A manutenção estendida compra três anos, de
1º de janeiro de 2028 a 31 de dezembro de 2030, e cada um deles custa mais do que custava um ano de
manutenção principal. Ela compra tempo para fazer o projeto; não deixa o projeto menor.

## Três caminhos para atravessar

A SAP e os parceiros descrevem três abordagens amplas, e cada uma é uma resposta diferente à pergunta
"o que a gente guarda?".

| abordagem | o que acontece | o que é mantido | o que custa |
|---|---|---|---|
| greenfield, uma implantação nova | o S/4HANA é implantado do zero e os processos de negócio são redesenhados | dados mestres, partidas em aberto e saldos, migrados para o sistema novo | o histórico fica para trás, no sistema antigo ou num arquivo, e cada objeto próprio é reescrito ou descartado |
| brownfield, uma conversão de sistema | o sistema existente é convertido no lugar: o banco vai para o HANA, os dados são convertidos para o modelo novo | tudo: histórico, customizing, código próprio | cada item da lista de mudanças da SAP para a versão de destino tem de ser tratado antes de a conversão rodar |
| transição seletiva de dados | um sistema novo é montado a partir da configuração do antigo, e depois os dados e o histórico escolhidos são levados para ele | o que você escolher, por exemplo uma empresa ou os últimos três anos | ferramentas especializadas e um parceiro que já tenha feito isso |

**Nenhuma das três é uma atualização**, e a diferença entre elas é sobretudo uma diferença sobre
dados: o que vai, com quanto do histórico e para qual modelo. A aula 14 é sobre mover dados entre
sistemas.

## O que acontece com os 1.800 objetos

A SAP publica uma *Simplification List* para cada versão do S/4HANA: cada ponto em que o modelo de
dados ou a funcionalidade nova difere do ECC. O ABAP Test Cockpit dela consegue conferir o código
próprio contra essa lista, e a primeira execução contra o sistema da Serra Alta listou achados na
casa dos milhares, cada um um lugar onde um objeto Z lê, escreve ou supõe algo que mudou.

É a conta de quinze anos sem o núcleo limpo que a aula 1 descreveu, chegando de uma vez. O achado
mais barato de resolver está no código que ninguém roda. O time de Edson ligou o registro de uso da
SAP em janeiro de 2026, e em outubro cerca de 650 dos 1.800 objetos não tinham rodado nenhuma vez.
**Código próprio que não rodou num ciclo de negócio inteiro é candidato a ser apagado, não a ser
convertido**, e apagá-lo antes de o projeto começar diminui toda estimativa feita depois. O ciclo
importa: um relatório usado só no fechamento anual parece morto por onze meses, e o registro precisa
cobrir um ano inteiro antes de alguém apagar alguma coisa com base nele.

O que sobra é triado. Alguns objetos existem porque faltava ao ECC algo que o S/4HANA agora tem no
padrão, e esses podem voltar ao padrão. Outros codificam como a Serra Alta trabalha e precisam ser
reescritos para o modelo novo. E alguns, como o programa que carrega o arquivo do Coleta, são
interfaces, que é onde começa a próxima seção.

O erro de Joana no terceiro dia foi útil. Tratar a mudança como atualização a teria colocado no
orçamento de TI do ano seguinte, ao lado das licenças de banco de dados. Tratada como o que é, ela
vira uma decisão de Regina, de Marcos e do conselho sobre qual abordagem seguir e quanto histórico
levar, e, seja qual for a escolha, toda interface com o SAP está na lista do que precisa mudar.

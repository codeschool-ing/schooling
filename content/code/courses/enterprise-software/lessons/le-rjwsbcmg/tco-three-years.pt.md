---
title: Custo total de propriedade, três anos à frente
version: 1
---

Preço é o que alguém pede para você pagar. **Custo total de propriedade (TCO) é tudo o que você vai
pagar, a quem quer que seja, para pôr um sistema para rodar, mantê-lo rodando, mudá-lo e sair dele,
num período declarado.** Os dois diferem por um fator de dois no exemplo abaixo, e a diferença não é
fraude nem descuido de ninguém. O fornecedor cotou o que o fornecedor vende. O resto é da Serra Alta
para contar, e ninguém mais vai contar.

Esta seção monta a planilha da opção A, o produto SaaS, linha a linha. A seção 06 desta aula põe B e C
ao lado dela com as mesmas linhas. Todo número é estimativa da própria Serra Alta, inventada para este
curso, e nenhum é preço de fornecedor real.

## As linhas

Uma planilha que deixa uma linha de fora compara as opções em bases diferentes sem dizer. Estas são as
doze linhas da planilha da Serra Alta, e **toda opção recebe todas as linhas, com um zero digitado
onde a linha não custa nada** — célula vazia diz que ninguém olhou, zero diz que alguém decidiu.

| linha | o que ela guarda |
|---|---|
| licença ou assinatura | o que se paga pelo direito de usar o software: assinatura, licença, taxa de plataforma |
| implantação | o trabalho único para chegar ao primeiro pagamento aos produtores: configurar ou construir, testar, entrar em produção |
| migração de dados | levar o cadastro e o histórico das fazendas para fora da Coleta, o assunto inteiro da aula 14 |
| integração | as interfaces com o SAP, os resultados de laboratório e o Rota, aulas 8 a 11 |
| customização | o que se escreve porque o produto não faz algo de fábrica |
| infraestrutura | servidores, contas de nuvem, ambientes, o runtime de que as interfaces precisam |
| operação e suporte | manter rodando: contratos de suporte, primeiro atendimento, monitoramento, plantão, patches |
| time interno | as pessoas da própria Serra Alta alocadas ao sistema: donos, analistas, desenvolvedores |
| treinamento | ensinar os 300 motoristas de caminhão e as 30 pessoas de escritório que o usam |
| atualizações | o custo de cada versão nova: testar, consertar o que ela quebra |
| Coleta mantida no ar | o sistema antigo, pago até o novo substituí-lo |
| saída | quanto custaria sair no fim do período; seção 05 desta aula |

Duas linhas dessa lista faltam na maioria das planilhas. **Coleta mantida no ar** é fácil de esquecer
porque ninguém está propondo gastar dinheiro com a Coleta, e mesmo assim, a cada mês em que o sistema
novo não está pronto, a Serra Alta paga R$ 15.000 para manter o IBM i sob contrato de manutenção. Ela
pertence à planilha porque as opções terminam em momentos diferentes, e portanto mantêm a Coleta por
tempos diferentes. **Saída** é o preço da porta, e a seção 05 desta aula explica por que ela entra
inteira.

## Quatro regras para a planilha

**O mesmo horizonte para toda opção.** O da Serra Alta são 36 meses de calendário, de janeiro de 2027
a dezembro de 2029. Três anos é tempo bastante para os custos de operação aparecerem e pouco o
bastante para os números serem estimativas e não esperanças. A área financeira costuma acrescentar
uma coluna chamada ano 0 para o dinheiro pago antes de qualquer coisa rodar. Isso funciona quando toda
opção começa a rodar no mesmo dia; aqui não começa, porque a construção gasta um ano inteiro antes de
pagar alguém, então esta planilha põe cada pagamento no ano de calendário em que ele é feito.

**A mesma unidade.** Reais, como pagos, sem inflação. O time de Marcos Teles também desconta os três
anos a valor presente. Nas taxas que eles usam, entre 10% e 15% ao ano, a ordem das três opções não
muda, então a planilha desta aula fica em reais simples, que você consegue somar.

**Todo número tem uma derivação.** "R$ 360.000" é uma afirmação; "R$ 40.000 por mês durante nove
meses" é uma alegação que alguém consegue conferir e contestar.

**Toda premissa fica escrita.** A planilha abaixo se apoia em quatro, e a seção 06 desta aula as
testa:

- a Serra Alta acrescenta 100 fazendas por ano, de 1.900 em 2027 a 2.100 em 2029;
- o contrato limita o reajuste na renovação a 4%;
- uma pessoa do time interno custa R$ 25.000 por mês, salário e encargos juntos;
- o primeiro pagamento aos produtores pelo sistema novo é em outubro de 2027, o mês 10.

## A opção A, linha a linha

O fornecedor do SaaS cobra por fazenda ativa por mês: R$ 25 nos dois primeiros anos, o prazo do
contrato, e no máximo 4% a mais na primeira renovação, portanto R$ 26 no ano 3. A implantação vai do
mês 1 ao mês 9, com três meses de execução em paralelo (aula 13) no fim. O primeiro pagamento pelo
produto é em 10 de outubro de 2027, e a Coleta é desligada depois do terceiro, em dezembro.

| linha | calculada como | ano 1 | ano 2 | ano 3 | 36 meses |
|---|---|---|---|---|---|
| assinatura | R$ 25 × 1.900 fazendas × 12; R$ 25 × 2.000 × 12; R$ 26 × 2.100 × 12 | 570.000 | 600.000 | 655.200 | 1.825.200 |
| implantação | o parceiro do fornecedor, R$ 40.000 por mês, meses 1–9 | 360.000 | 0 | 0 | 360.000 |
| migração de dados | R$ 25.000 por mês, meses 4–9 | 150.000 | 0 | 0 | 150.000 |
| integração | SAP, resultados de laboratório e Rota, R$ 30.000 por mês, meses 2–9 | 240.000 | 0 | 0 | 240.000 |
| customização | as cinco regras estendidas ao lado, R$ 25.000 por mês, meses 3–8 | 150.000 | 0 | 0 | 150.000 |
| infraestrutura | runtime e monitoramento das interfaces, R$ 2.500 por mês | 30.000 | 30.000 | 30.000 | 90.000 |
| operação e suporte | primeiro atendimento e vigilância das interfaces, R$ 4.000 por mês a partir do mês 10 | 12.000 | 48.000 | 48.000 | 108.000 |
| time interno | um product owner em tempo integral até o mês 9 (R$ 25.000 por mês), meio período depois | 262.500 | 150.000 | 150.000 | 562.500 |
| treinamento | motoristas e escritório, meses 7–9 | 80.000 | 0 | 0 | 80.000 |
| atualizações | R$ 10.000 para testar cada versão trimestral, a partir do mês 12 | 10.000 | 40.000 | 40.000 | 90.000 |
| Coleta mantida no ar | R$ 15.000 por mês, meses 1–12 | 180.000 | 0 | 0 | 180.000 |
| **gasto** | | **2.044.500** | **868.000** | **923.200** | **3.835.700** |
| saída | se a Serra Alta saísse no fim do mês 36; seção 05 desta aula | | | | 397.800 |
| **TCO** | | | | | **4.233.500** |

Confira duas células à mão antes de confiar no resto. O time interno do ano 1 são nove meses a
R$ 25.000 e três a R$ 12.500: R$ 225.000 + R$ 37.500 = R$ 262.500. A assinatura do ano 3 é
R$ 26 × 2.100 × 12 = R$ 655.200. Se essas duas batem com a tabela, a aritmética da planilha merece
confiança, e a discussão passa para as premissas, que é onde ela deve estar.

## Lendo por ano

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-a-by-year\" aria-label=\"A opção A, o produto SaaS, em quatro barras. O ano 1 é a mais alta, R$ 2.044.500: R$ 1.160.000 pagos uma vez (implantação, migração, integração, customização, treinamento e os últimos doze meses da Coleta) e R$ 884.500 que se repetem. O ano 2 é R$ 868.000 e o ano 3, R$ 923.200, tudo recorrente. Uma quarta barra, tracejada, é a saída, R$ 397.800, paga só se a Serra Alta sair.\"><rect x=\"120.0\" y=\"165.8\" width=\"90.0\" height=\"84.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"55.3\" width=\"90.0\" height=\"110.5\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"110.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1.160.000</text><text x=\"165.0\" y=\"207.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">884.500</text><text x=\"165.0\" y=\"43.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2.044.500</text><text x=\"165.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ano 1</text><rect x=\"260.0\" y=\"167.3\" width=\"90.0\" height=\"82.7\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"208.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">868.000</text><text x=\"305.0\" y=\"155.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">868.000</text><text x=\"305.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ano 2</text><rect x=\"400.0\" y=\"162.1\" width=\"90.0\" height=\"87.9\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">923.200</text><text x=\"445.0\" y=\"150.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">923.200</text><text x=\"445.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ano 3</text><rect x=\"540.0\" y=\"212.1\" width=\"90.0\" height=\"37.9\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"585.0\" y=\"200.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">397.800</text><text x=\"585.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">saída</text><path d=\"M100.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"120.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pago uma vez</text><rect x=\"270.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"288.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pago todo ano</text><rect x=\"430.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"448.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pago só ao sair</text></svg>", "caption": "A opção A, em reais, pelo ano em que o dinheiro é pago. O ano 1 carrega tudo o que se paga uma vez; os anos 2 e 3 mostram quanto custa ter o sistema."}
```

**O ano 1 carrega 53% do gasto dos três anos**: R$ 2.044.500 de R$ 3.835.700. Disso, R$ 1.160.000 se
paga uma vez e nunca mais — implantação, migração, integração, customização, treinamento e os últimos
doze meses da Coleta. Os anos 2 e 3 são o sistema como ele vai custar normalmente: R$ 868.000 e
R$ 923.200. Esse segundo número é o que vale guardar, porque é a conta que a Serra Alta recebe todo
ano enquanto ficar com o produto, e ela cresce sozinha conforme crescem as fazendas e o preço.

Mais três leituras que os totais escondem:

- **a assinatura é 43% do TCO**, R$ 1.825.200 de R$ 4.233.500. É a maior linha e ainda assim menos da
  metade do custo; uma decisão tomada só pelo preço é tomada com menos da metade dos fatos;
- **nove meses de assinatura são pagos antes de o produto pagar uma única fazenda**: meses 1 a 9 a
  R$ 25 × 1.900 fazendas = R$ 47.500 por mês, R$ 427.500 no total. Fornecedores ligam o relógio na
  assinatura do contrato, e uma implantação que atrasa um mês custa um mês de assinatura além do mês
  de todo o resto;
- **o time interno é a segunda maior linha**, R$ 562.500, maior que a implantação. Comprar um produto
  não compra a ausência de pessoas: alguém tem de ser dono da configuração, decidir o que a próxima
  versão muda e responder a Cláudia quando as tabelas mudam.

## O que a planilha não decide

Uma planilha completa de uma opção diz quanto A custa. Não diz se A é uma boa ideia, e não diz nada
sobre B e C. Ela também foi montada de dentro para fora — a partir do que a Serra Alta sabe que vai
fazer — e os erros mais caros de um TCO são linhas que ninguém do time pensou em acrescentar. A seção
04 desta aula é sobre elas, dos dois lados da discussão.

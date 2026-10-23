---
title: Como este curso funciona
version: 1
---

A maioria dos cursos desta trilha ensina a construir alguma coisa. Este é sobre os sistemas que uma
empresa grande **comprou** em vez de construir, e sobre o trabalho de ligar uns aos outros. **Numa
empresa de alguns milhares de pessoas, quase todo o software que roda o negócio foi escrito por um
fornecedor, configurado por uma consultoria e integrado por alguém que já saiu da empresa**, e
nenhum dele pode ser desligado por uma tarde enquanto você pensa. Ali o trabalho do arquiteto tem
menos a ver com desenhar um sistema novo do que com mudar um que está rodando, sem parar.

O curso tem duas metades, e elas não têm o mesmo tamanho de propósito.

| aulas | o que são | como são ensinadas |
|---|---|---|
| 1 | o que é um ERP, e por que ele molda tudo à sua volta | ideias, com uma empresa como exemplo |
| 2 a 6 | cinco produtos: SAP, Microsoft Dynamics, Salesforce, OpenText Documentum, IBM BPM | a partir da documentação dos fornecedores e de como uma empresa usa cada um |
| 7 a 15 | modelagem de processos, o barramento de serviços, os estilos e padrões de integração, filas, contratos e SLA, aposentar um sistema legado, migrar os dados dele, e comprar ou construir | sem fornecedor, com diagramas, números e três programas curtos |

**A segunda metade é a maior e a mais duradoura.** Os produtos das aulas 2 a 6 vão mudar de nome e
de preço em poucos anos; como mover dados entre dois sistemas que discordam sobre o que é um cliente
não vai mudar. A primeira metade está aqui porque ninguém desenha em volta de um produto que nunca
lhe foi explicado, e porque um arquiteto que entra numa empresa grande ouve esses nomes na primeira
semana.

## Os produtos que você não vai usar

**Você vai terminar este curso sem ter usado SAP, Dynamics, Salesforce, Documentum ou IBM BPM**, e
isso é o desenho do curso, não uma lacuna. Nenhum deles é vendido a uma pessoa. A licença é um
contrato corporativo, negociado por um time de vendas ao longo de meses e com preço de empresa, então
não existe uma conta que um indivíduo possa pagar para ter uma. As aulas 2 a 6 são ensinadas a partir
da documentação publicada pelos fornecedores e de como a empresa deste curso usa cada produto.

Dois fornecedores deixam qualquer pessoa dar uma olhada. A Salesforce oferece de graça uma org
Developer Edition, e a Microsoft tem avaliações por tempo limitado do Dynamics 365 e um plano de
desenvolvedor gratuito do Power Apps. As aulas citam essas opções onde elas ajudam. **Nada no curso
depende delas**, porque um curso que precisa da oferta gratuita de uma empresa para de funcionar no
dia em que a oferta muda.

Se você quiser ver um ERP por dentro, dois de código aberto podem ser instalados na sua própria
máquina: a edição Community do Odoo e o ERPNext. Nenhum dos dois é assunto de aula e nenhum é
necessário, mas qualquer um mostra uma ordem de venda virando remessa e nota fiscal, que é o que a
aula 1 descreve.

## Nada para instalar

**A prática neste curso é ler, decidir, desenhar e escrever.** Você precisa de quatro ferramentas
comuns, cada uma com uma opção gratuita:

| ferramenta | opções gratuitas | onde o curso usa |
|---|---|---|
| um editor de texto | o que você usa desde o começo da trilha | suas anotações em toda aula, o contrato de interface da aula 12, o registro de decisão da aula 15 |
| uma ferramenta de diagramas | diagrams.net, no navegador ou como aplicativo, salvando no seu disco; Excalidraw; papel e lápis | mapas de sistemas desde esta aula, modelos BPMN na aula 7, planos de migração nas aulas 13 e 14 |
| um lugar para registros de decisão | uma pasta de arquivos Markdown, um por decisão, num repositório git se quiser | as decisões que a Joana escreve, e as suas, da aula 1 à aula 15 |
| uma planilha | LibreOffice Calc; qualquer outra funciona do mesmo jeito | contas de disponibilidade na aula 12, três opções com preço em três anos na aula 15 |

**Para os diagramas, o papel não é a escolha menor.** Uma ferramenta tenta você a deixar o desenho
arrumado; o papel obriga a decidir o que são as caixas, e essa decisão é a habilidade.

## Três programas curtos, e onde rodá-los

As aulas 9, 10 e 14 mostram, cada uma, um programa curto em Python 3: um arquivo com total de
controle, um consumidor de mensagens que ignora duplicatas, e uma reconciliação de dois conjuntos de
dados. **Cada programa aparece inteiro na aula, usa só a biblioteca padrão do Python e não precisa de
mais nada.** Ler o programa e a saída impressa embaixo dele basta para acompanhar a aula. Rodar é
opcional, e vale a pena, porque mudar uma linha e ver o que quebra ensina mais do que o parágrafo.

Qualquer Python a partir do 3.10 roda os três. Há três lugares para conseguir um:

| | o que é | o que custa ao seu computador |
|---|---|---|
| **sua máquina Linux** (recomendada) | a máquina virtual que você montou na aula 1 de `linux-terminal`. O Ubuntu Server 24.04 já vem com `python3` instalado | nada novo: é a máquina que você já tem |
| **instalado** | o Python do python.org no Windows ou no macOS, ou o pacote `python3` da sua distribuição Linux | um pouco de disco, bem menos de um gigabyte |
| **online** | qualquer serviço que rode Python numa aba do navegador ou numa máquina alugada | nada no seu computador, e o que esse serviço decidir cobrar |

**A recomendada é a máquina que você já montou.** É onde o resto da trilha fez você trabalhar, e um
programa que escreve arquivos e um banco pequeno fica melhor num lugar que você pode jogar fora.

### Quando não funciona

Três coisas dão errado, e cada uma tem resposta curta:

- **`python3: command not found`.** No Windows o comando costuma ser `py` ou `python`, vindo do
  instalador do python.org; numa máquina Linux, instale o pacote `python3` com o gerenciador de
  pacotes da distribuição, como `linux-terminal` mostrou.
- **A versão é anterior à 3.10.** `python3 --version` diz qual você tem. Máquinas antigas trazem um
  Python antigo; instale um mais novo ao lado em vez de substituir o do sistema.
- **`No module named '_sqlite3'`** na aula 10. Algumas compilações mínimas do Python deixam o SQLite
  de fora. Os instaladores do python.org e o pacote do Ubuntu incluem; um Python compilado à mão pode
  não incluir.

Se nenhuma das três resolver, leia o programa da aula e a saída dele e siga em frente. O programa
existe para tornar a ideia concreta, e a ideia está no texto.

## A empresa que você vai acompanhar

Toda aula acompanha uma empresa. **A Serra Alta Laticínios é inventada**: um laticínio em Juiz de
Fora, Minas Gerais, fundado em 1968, com cerca de 3.200 funcionários. Tem quatro fábricas. Juiz de
Fora faz leite e iogurte, Barbacena leite em pó, Lavras manteiga e creme, e Alagoa queijo. A fábrica
de queijo veio com a compra da Queijaria Mantiqueira em 2021.

**A Serra Alta coleta cerca de 2,3 milhões de litros de leite por dia de cerca de 1.900 fazendas**,
365 dias por ano, e esse fato explica muito dos seus sistemas. O tanque de resfriamento de uma
fazenda guarda no máximo dois dias de leite, então um caminhão que não passa significa leite jogado
fora. As fazendas recebem no dia 10 de cada mês, pelos litros coletados e pela qualidade medida no
laboratório: gordura, proteína e as contagens que dizem quão limpo e saudável o leite está. A Serra
Alta vende para redes de supermercado, para distribuidores e para cerca de 4.000 padarias e
mercadinhos, e toda venda precisa de uma NF-e, a nota fiscal eletrônica que a secretaria da fazenda
do estado precisa autorizar antes de o caminhão sair.

Isto é o que roda a empresa. Cada sistema tem a sua aula ou aparece em várias.

| sistema | desde | o que faz |
|---|---|---|
| SAP ECC 6.0 | 2011 | o ERP: finanças, vendas, compras, estoque, produção, qualidade, armazém. Cerca de 520 usuários |
| SAP BW e BusinessObjects | 2013 | relatórios, cerca de 900 |
| Microsoft Dynamics 365 Business Central | 2019 | o ERP da Mantiqueira, mantido depois da compra |
| Microsoft 365 e Entra ID | 2017 | e-mail, Teams, documentos, e o login que todo mundo usa |
| Salesforce | 2018 | 140 representantes de vendas para os grandes clientes, e o atendimento |
| OpenText Documentum | 2010 | documentos da qualidade: procedimentos, certificados de laboratório, relatórios de auditoria |
| IBM BPM | 2014 | três processos de negócio, entre eles o cadastro de uma fazenda nova |
| Coleta | 1996 | a coleta de leite e a base do pagamento de cada fazenda, num IBM i (AS/400), escrito em RPG |
| IBM Integration Bus e IBM MQ | 2015 | o barramento de serviços, cerca de 70 fluxos de integração |
| Rota | 2022 | o planejamento de rotas dos caminhões de leite, feito em casa |
| Portal B2B | 2023 | o site de pedidos das padarias e mercadinhos, feito em casa |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" data-fig=\"l01-estate\" aria-label=\"Um mapa dos sistemas da Serra Alta. O SAP ECC 6.0 fica no meio. Acima dele, quatro sistemas se ligam a ele: Salesforce, OpenText Documentum, IBM BPM, e SAP BW com BusinessObjects. À esquerda, o Coleta num IBM i manda um arquivo toda noite; à direita, o Business Central da Mantiqueira. Abaixo dele corre o barramento de serviços, IBM Integration Bus com IBM MQ, que liga o SAP ao Rota, ao Portal B2B e ao mundo de fora: bancos, a autoridade fiscal e o EDI dos clientes. Microsoft 365 e Entra ID, embaixo à direita, dão o login de todo mundo.\"><defs><marker id=\"l01-estate-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-estate-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"17.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Salesforce</text><text x=\"95.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vendas e atendimento</text><path d=\"M95.0 72.0 L293.8 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Documentum</text><text x=\"270.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">documentos da qualidade</text><path d=\"M270.0 72.0 L337.5 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"372.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IBM BPM</text><text x=\"450.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três processos</text><path d=\"M450.0 72.0 L382.5 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"547.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">BW + BusinessObjects</text><text x=\"625.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900 relatórios</text><path d=\"M625.0 72.0 L426.2 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"146.0\" width=\"200.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC 6.0</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o ERP, desde 2011</text><rect x=\"17.0\" y=\"152.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Coleta</text><text x=\"95.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">IBM i, RPG, 1996</text><path d=\"M173.0 175.0 L258.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-amber)\"></path><text x=\"215.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivo noturno</text><rect x=\"547.0\" y=\"152.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Business Central</text><text x=\"625.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mantiqueira</text><path d=\"M547.0 175.0 L462.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"246.0\" width=\"420.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">barramento: IBM Integration Bus + IBM MQ, cerca de 70 fluxos</text><path d=\"M360.0 244.0 L360.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"17.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rota</text><text x=\"95.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rotas dos caminhões</text><path d=\"M95.0 325.0 L240.8 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"270.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.000 padarias</text><path d=\"M270.0 325.0 L319.5 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"372.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bancos · SEFAZ · EDI</text><text x=\"450.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora da empresa</text><path d=\"M450.0 325.0 L400.5 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"547.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"625.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft 365 + Entra ID</text><text x=\"625.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o login de todo mundo</text></svg>", "caption": "O parque da Serra Alta como a Joana o encontra. Tudo é desenhado em volta do SAP porque tudo se organiza em volta dele; a linha âmbar é a integração mais antiga da empresa.", "same": ["BW + BusinessObjects", "Business Central", "Coleta", "Documentum", "IBM BPM", "IBM i, RPG, 1996", "Mantiqueira", "Microsoft 365 + Entra ID", "Portal B2B", "Rota", "SAP ECC 6.0", "Salesforce"]}
```

## As pessoas

A protagonista é a **Joana Brandão**. Ela passou oito anos numa fintech de Belo Horizonte onde todo
sistema era construído em casa, como serviços, por times que ela conhecia pelo nome. Em 2026 a Serra
Alta a contrata como sua primeira arquiteta corporativa. Ela sabe construir software bem. O que está
para aprender é o que significa mudar uma empresa cujos sistemas foram comprados, e o curso a
acompanha nisso, inclusive nas partes em que ela erra.

| pessoa | papel |
|---|---|
| Joana Brandão | arquiteta corporativa, recém-chegada à Serra Alta |
| Regina Fontes | CIO, que a contratou |
| Marcos Teles | diretor financeiro; para ele, o ERP são os livros da empresa |
| Edson Prado | lidera o time de SAP, há quinze anos na Serra Alta |
| Rui Andrade | lidera integração: o barramento, as filas, as trocas com clientes |
| Talita Gomes | administra o Salesforce |
| Felipe Arruda | a TI da Mantiqueira, e o dono do Business Central |
| Cláudia Mendes | gerente da qualidade |
| Denise Okada | comanda o escritório de processos |
| Sebastião Lima | escreveu quase todo o Coleta, e se aposenta em 2028 |

Todo mundo nessa tabela é fictício, e os números da Serra Alta também. Os produtos, os padrões e as
ideias são reais, e cada um aparece com a fonte, para você poder ler o original.

## Como uma aula é organizada

Toda aula abre com um vídeo curto dizendo para que ela serve, segue com seções de leitura e termina
com uma seção de prática. **As questões de uma aula não valem nota.** Uma resposta errada mostra por
que está errada e você segue. Muitas pedem um julgamento — que estilo de integração cabe, que sistema
deveria ser dono de um campo — e nessas o curso se compromete com uma resposta e dá o raciocínio na
própria opção. Se você continuar discordando depois de ler, a questão cumpriu o papel. A prova do
curso, no fim, é o único lugar com nota.

## Um hábito que vale começar agora

Mantenha um arquivo de texto por aula. **Quando a aula fizer alguma coisa na Serra Alta, anote como a
mesma coisa é onde você trabalha**, ou no último sistema em que você trabalhou. Desenhe a versão da
sua empresa do mapa acima, mesmo que tenha quatro caixas. A Serra Alta é arrumada porque foi inventada
para ensinar. O seu parque não é, e a distância entre os dois é onde este curso é posto à prova.

---
title: O que o nome Dynamics cobre
version: 1
---

A primeira imagem que a Joana fez de "Dynamics" foi a de um produto só, do jeito que "SAP" na Serra
Alta quer dizer um sistema ECC. **Dynamics é uma marca sobre vários sistemas de negócio que a
Microsoft comprou ou construiu separadamente**, e cada um ainda carrega a própria história: o próprio
modelo de dados, a própria linguagem de programação e a própria comunidade de gente que o conhece.
Quando alguém diz que "conhece Dynamics", a pergunta útil seguinte é: qual deles?

Esta aula, como a aula 2, é dada a partir da documentação do fornecedor e da experiência da Serra
Alta, e você não vai mexer num sistema de negócio da Microsoft para acompanhá-la. Se quiser ver um,
a Microsoft oferece avaliações por tempo limitado dos produtos Dynamics 365 e um plano gratuito de
desenvolvedor para o Power Apps. Os dois são opcionais, e nenhum exercício depende deles.

## Comprados, depois renomeados

A Microsoft não cultivou suas aplicações de negócio; comprou. Em 2001 adquiriu a Great Plains, uma
fabricante americana de software contábil, e em 2002 a Navision, uma dinamarquesa. A Navision trouxe
dois ERPs: o produto dela, também chamado Navision, e o Axapta, que vinha da Damgaard, a empresa com
que a Navision tinha se fundido pouco antes.

Seguiram-se vinte anos de mudanças de nome, e os nomes antigos não sumiram. Consultores, anúncios de
vaga e fóruns usam todos eles, às vezes no mesmo parágrafo. A tabela é a parte que vale guardar.

| vendido hoje como | nomes anteriores | feito para | estendido com |
|---|---|---|---|
| Dynamics 365 Finance e Dynamics 365 Supply Chain Management | Dynamics AX, e antes disso Axapta | empresas grandes, com muitas pessoas jurídicas e países | X++ |
| Dynamics 365 Business Central | Dynamics NAV, e antes disso Navision | empresas pequenas e médias | extensões escritas em AL |
| Dynamics 365 Sales, Dynamics 365 Customer Service e seus irmãos | Dynamics CRM | times de vendas e de atendimento | configuração sobre o Dataverse, depois código |
| Dataverse | Common Data Service | os dados sob os apps de CRM e o Power Apps | tabelas, relacionamentos, regras de negócio |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l03-family\" aria-label=\"A família Dynamics como quatro linhas de descendência, lidas da esquerda para a direita. O Axapta virou Dynamics AX, depois Dynamics 365 for Operations em 2016, e hoje é vendido como Dynamics 365 Finance e Supply Chain Management. O Navision virou Dynamics NAV e, em 2018, Business Central, que a Mantiqueira roda desde 2019. Axapta e Navision foram comprados pela Microsoft em 2002. O Dynamics CRM virou Dynamics 365 Sales e Customer Service, construídos sobre o Dataverse. O Common Data Service foi renomeado Dataverse em 2020; ele guarda os dados dos apps de CRM e do Power Apps, e os dois ERPs mantêm bancos próprios fora dele.\"><defs><marker id=\"l03-family-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">origem</text><text x=\"235.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">era Dynamics</text><text x=\"605.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">vendido hoje</text><rect x=\"12.0\" y=\"40.0\" width=\"136.0\" height=\"168.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"80.0\" y=\"177.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">compradas pela</text><text x=\"80.0\" y=\"190.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Microsoft, 2002</text><rect x=\"15.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Axapta</text><rect x=\"170.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics AX</text><rect x=\"325.0\" y=\"50.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"63.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics 365</text><text x=\"400.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">for Operations, 2016</text><rect x=\"505.0\" y=\"50.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"63.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Finance</text><text x=\"605.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Supply Chain Management</text><path d=\"M147.0 70.0 L167.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M302.0 70.0 L322.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M477.0 70.0 L502.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><rect x=\"15.0\" y=\"125.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Navision</text><rect x=\"170.0\" y=\"125.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics NAV</text><rect x=\"505.0\" y=\"125.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central, 2018</text><path d=\"M147.0 145.0 L167.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M302.0 145.0 L502.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><text x=\"605.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Mantiqueira, desde 2019</text><rect x=\"170.0\" y=\"205.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics CRM</text><rect x=\"505.0\" y=\"205.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"218.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics 365 Sales,</text><text x=\"605.0\" y=\"231.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Customer Service</text><path d=\"M302.0 225.0 L502.0 225.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"295.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Common Data Service</text><rect x=\"505.0\" y=\"293.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"308.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dataverse, 2020</text><text x=\"605.0\" y=\"321.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">também sob o Power Apps</text><path d=\"M302.0 315.0 L502.0 315.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M605.0 246.0 L605.0 292.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><text x=\"613.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">construídos sobre</text><text x=\"400.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">os ERPs mantêm bancos próprios</text></svg>", "caption": "Quatro linhas de descendência sob uma marca. Os dois ERPs vieram de empresas diferentes e guardam os próprios dados; só os apps de CRM e o Power Apps moram no Dataverse.", "same": ["Axapta", "Business Central, 2018", "Common Data Service", "Customer Service", "Dataverse, 2020", "Dynamics 365", "Dynamics 365 Sales,", "Dynamics AX", "Dynamics CRM", "Dynamics NAV", "Finance", "Microsoft, 2002", "Navision", "Supply Chain Management", "for Operations, 2016"]}
```

## O ERP das empresas grandes

O Dynamics AX foi renomeado Dynamics 365 for Operations em 2016, quando a Microsoft lançou a marca
Dynamics 365, e depois foi dividido nos dois apps vendidos hoje. Quem trabalha com eles ainda chama
o par de "F&O", de Finance and Operations, e a própria documentação da Microsoft os chama de apps de
finanças e operações.

É o produto que concorre com o SAP nas empresas grandes. Ele lida com muitas pessoas jurídicas,
moedas e países numa instalação só, e é customizado em X++, uma linguagem própria. A Serra Alta não
o usa. Ele importa para a Joana por outro motivo: **o fim da manutenção do ECC em 2027 é o momento
em que uma empresa que roda SAP precisa perguntar se continua no SAP.** O conselho vai perguntar à
Regina Fontes se este produto foi considerado. A aula 15 trata de responder esse tipo de pergunta com
números, e não com lealdade.

## O ERP das empresas médias: Business Central

O Business Central é o que a Mantiqueira usa. Ele descende da Navision, passando pelo Dynamics NAV,
e foi lançado com o nome atual em 2018. Cobre finanças, vendas, compras, estoque, armazém e um tanto
de produção, o que basta para uma fábrica de queijo com cerca de 260 funcionários, 41 dos quais o
usam. A Mantiqueira o roda desde 2019 na versão online, que a Microsoft opera como serviço; o
Business Central também existe para instalação nos servidores da própria empresa.

A ideia do Business Central que vale levar para qualquer sistema que você projetar é o jeito como
ele é customizado. No NAV, os parceiros mudavam o código da aplicação base diretamente, numa
linguagem chamada C/AL. O sistema de cada cliente era, portanto, um fork do da Microsoft, e cada
atualização era um merge dos dois. Por isso as atualizações do NAV tinham fama de projeto à parte, e
por isso muitos clientes ficaram anos em versões antigas.

O Business Central online não permite isso. **A aplicação base não pode ser modificada; tudo o que
o cliente acrescenta é uma extensão**, escrita em AL, que fica ao lado da base e se pendura nos
eventos e nas páginas que a Microsoft publica. A Microsoft atualiza a base no calendário dela, e as
extensões sobrevivem porque nunca a mudaram. É o anel do meio da aula 1, "estender ao lado", imposto
pelo produto em vez de pela disciplina de um time.

A Mantiqueira tem seis extensões. A maior vem de um parceiro brasileiro e acrescenta a camada fiscal:
emitir a NF-e e calcular os impostos brasileiros em cada linha da nota. Duas foram escritas para o
próprio queijo, registrando o tempo de maturação de cada peça e o lote de leite de que ela veio. As
outras três são relatórios. Quando o Felipe Arruda recebe o aviso de que a Microsoft vai atualizar a
base, o trabalho dele é testar essas seis contra a versão nova num sandbox, e não fazer merge do
código de ninguém.

Compare com o SAP da Serra Alta, com cerca de 1.800 objetos `Z` customizados (aula 2), cada um dos
quais precisa ser examinado de novo na mudança para o S/4HANA. **Um modelo de extensões muda o custo
da customização do dia da atualização para o dia do projeto.** O parceiro que escreveu a camada
fiscal da Mantiqueira teve de trabalhar dentro dos eventos que a Microsoft expõe, e em troca ninguém
precisa reaplicar esse trabalho todo ano.

## A linha de CRM, e o banco de dados embaixo dela

O Dynamics CRM virou um conjunto de apps, dos quais o Dynamics 365 Sales e o Dynamics 365 Customer
Service são os mais conhecidos. Esses apps são construídos sobre o **Dataverse**: um banco de dados
que a Microsoft opera como serviço, com tabelas, relacionamentos, papéis de segurança e uma API. O
Dataverse se chamava Common Data Service até a Microsoft renomeá-lo em 2020. Ele também é o banco de
dados sob o Power Apps, então um Power App que um departamento constrói pode guardar seus dados no
mesmo tipo de tabela que um CRM usa.

O CRM da Serra Alta é o Salesforce (aula 4). A linha de CRM só importa para ela através do Dataverse,
e só quando o Power App de alguém fica grande demais para a planilha.

## Mesma marca, dados diferentes

A ideia errada que a marca convida é a de que tudo o que se chama Dynamics 365 compartilha um banco
de dados e se integra sozinho. A Regina fez uma versão dessa pergunta no primeiro mês da Joana: já
que a Mantiqueira "tinha Microsoft", os clientes dela não podiam simplesmente aparecer nos sistemas
do grupo? Não podiam, e nada na marca faria isso acontecer.

**Os ERPs guardam os próprios bancos de dados.** O Business Central e o Finance and Supply Chain
Management não ficam no Dataverse. Cada um pode ser conectado a ele (no caso do Finance and Supply
Chain Management, a Microsoft chama essa conexão de dual-write), mas o que aparece no Dataverse é
então uma cópia, com o atraso, o mapeamento e os conflitos que qualquer cópia tem. Um cliente do
Business Central é uma linha no Business Central. Ele só vira outra coisa quando algo o copia, e esse
algo é uma integração que alguém precisa assumir.

O que os produtos compartilham de fato é real e mais estreito: um portal de licenças, um centro de
administração e um login. **Nas versões online, todos eles autenticam seus usuários pelo Microsoft
Entra ID**, o mesmo diretório que guarda as contas de e-mail da Serra Alta. Esse login compartilhado
acaba sendo a integração de maiores consequências desta aula, e é o assunto da próxima seção.

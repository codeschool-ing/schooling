---
title: Um banco só para o negócio inteiro
version: 1
---

**O banco único é o que uma empresa compra quando compra um ERP.** Os módulos podem ser comprados
separados, e antes do ERP eram: um sistema de vendas, um de estoque, um de folha e um pacote de
contabilidade, cada um comprado pelo seu departamento, cada um com o seu banco. O que o ERP vendeu foi
o fim das discussões entre eles.

## Antes: um sistema por departamento

A Serra Alta dos anos 1990 é o exemplo, e é um exemplo típico. Vendas recebia pedidos num programa.
O estoque era contado em outro. A contabilidade rodava um terceiro, alimentado toda noite com um
arquivo das notas do dia. O Coleta, o sistema de coleta de leite, é o sobrevivente dessa época, e a
aula 13 é sobre finalmente aposentá-lo.

Cada sistema guardava a sua cópia das coisas de que todos precisavam. O cliente existia três vezes,
uma em cada, digitado por três pessoas diferentes. Um produto tinha um código em vendas e outro no
armazém. Toda noite, arquivos passavam de um para outro. **E todo mês alguém passava uma semana
fazendo os números baterem**: o estoque que o armazém contou, o estoque que a contabilidade dizia que
deveria estar lá, e as vendas no meio, com uma planilha de diferenças e uma coluna chamada
"explicação".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-before-after\" aria-label=\"Dois painéis. À esquerda, antes do ERP: três sistemas, vendas, estoque e contabilidade, cada um com o próprio banco guardando a própria cópia do cliente e do produto, ligados por arquivos enviados toda noite, e uma planilha de diferenças feita no fim de cada mês. À direita, um ERP: seis módulos, vendas, compras e estoque, finanças, controladoria, produção e qualidade, todos apoiados num único banco que guarda os dados mestres uma vez e as transações que se referem a eles.\"><defs><marker id=\"l01-before-after-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">antes: um sistema por departamento</text><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">depois: módulos sobre um banco só</text><path d=\"M360.0 36.0 L360.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"17.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">vendas</text><rect x=\"25.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cliente</text><text x=\"65.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">produto</text><text x=\"65.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cópia própria</text><path d=\"M65.0 87.0 L65.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"127.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estoque</text><rect x=\"135.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cliente</text><text x=\"175.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">produto</text><text x=\"175.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cópia própria</text><path d=\"M175.0 87.0 L175.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"237.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contabilidade</text><rect x=\"245.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cliente</text><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">produto</text><text x=\"285.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cópia própria</text><path d=\"M285.0 87.0 L285.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M107.0 151.0 L131.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-before-after-es-ah-paper-dim)\"></path><path d=\"M217.0 151.0 L241.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-before-after-es-ah-paper-dim)\"></path><text x=\"120.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivo noturno</text><text x=\"230.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivo noturno</text><rect x=\"40.0\" y=\"232.0\" width=\"270.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo mês: uma planilha de diferenças</text><text x=\"175.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e uma coluna chamada &quot;explicação&quot;</text><rect x=\"386.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SD</text><text x=\"410.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">vendas</text><path d=\"M410.0 104.0 L410.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"464.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MM</text><text x=\"464.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">estoque</text><path d=\"M464.0 104.0 L464.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"494.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">FI</text><text x=\"518.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">finanças</text><path d=\"M518.0 104.0 L518.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"548.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"572.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CO</text><text x=\"572.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">custos</text><path d=\"M572.0 104.0 L572.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"602.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PP</text><text x=\"626.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">produção</text><path d=\"M626.0 104.0 L626.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"656.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"680.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">QM</text><text x=\"680.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">qualidade</text><path d=\"M680.0 104.0 L680.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"384.0\" y=\"150.0\" width=\"324.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"546.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um banco só</text><text x=\"546.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dados mestres, uma vez: clientes, materiais, fornecedores</text><text x=\"546.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">transações que apontam para eles: pedidos, notas, pagamentos</text><text x=\"546.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">nenhum arquivo para atrasar, nenhuma cópia para divergir</text></svg>", "caption": "O que o ERP substituiu. As cópias da esquerda estavam certas cada uma pelas próprias regras, e é por isso que discordavam; à direita há um registro de cada coisa e todo módulo lê o mesmo."}
```

As diferenças não eram descuido. Cada cópia estava certa pelas regras do seu sistema, e as regras
eram diferentes. Vendas contava um pedido como vendido quando o cliente confirmava; o armazém contava
quando o caminhão saía; a contabilidade contava quando a nota era emitida. Três respostas verdadeiras
para "quanto vendemos em março" é o resultado normal de três bancos, e escolher entre elas era uma
reunião por mês.

## Depois: módulos sobre um banco só

Um ERP troca as cópias por um único registro de cada coisa, compartilhado por todos os módulos. **Os
dados se dividem em dois tipos, e a distinção aparece no curso inteiro.**

**Dados mestres** descrevem as coisas com que o negócio lida e mudam devagar: clientes, fornecedores,
materiais, fábricas, preços, contas bancárias. Na Serra Alta isso são cerca de 9.800 clientes, cerca
de 2.600 materiais ativos e as 1.900 fazendas cadastradas como fornecedores. Um cliente é criado uma
vez, por um time, e todo módulo lê o mesmo registro.

**Dados transacionais** registram o que aconteceu: um pedido, uma remessa, uma entrada de mercadoria,
uma nota, um pagamento. Eles apontam para os dados mestres em vez de copiá-los. Um pedido diz *cliente
100482* e *material 4000127*; não repete o endereço do cliente nem a descrição do produto.

Quando o módulo de vendas lança uma remessa, o módulo de estoque e o de contabilidade não ficam
sabendo depois. Estão lendo as mesmas linhas. **Não há arquivo para atrasar nem cópia para divergir**,
e isso é a reconciliação mensal inteira eliminada por uma decisão de desenho.

## O preço de um banco só

O que o banco único compra é real, e se paga de três jeitos que importam a um arquiteto.

**Primeiro, todo mundo tem de concordar com um significado.** Se vendas e finanças leem o mesmo
cadastro de cliente, então "cliente" tem uma definição só, e a empresa precisa decidir qual. Uma rede
de supermercados é um cliente ou um por loja? A padaria que paga por meio de um distribuidor é cliente?
Nos sistemas separados cada departamento respondia por si. No ERP a resposta é uma decisão de
configuração tomada uma vez, e o departamento que perdeu a discussão vive com a definição do outro.
Você viu a mesma tensão em `design-patterns` como contexto delimitado: um modelo para a empresa inteira
é justamente o que o Domain-Driven Design desaconselha. **Um ERP é um contexto delimitado esticado
sobre a empresa inteira de propósito**, e isso funciona porque as funções que ele cobre concordaram, em
décadas de prática contábil, sobre o que a maioria das palavras quer dizer.

**Segundo, o esquema é do fornecedor.** O banco é enorme: um sistema SAP ECC tem dezenas de milhares
de tabelas, quase todas com nomes de poucas letras de abreviação alemã. Os dados mestres de cliente
ficam em tabelas chamadas `KNA1` e `KNB1`, os itens das ordens de venda em `VBAP`. A Serra Alta não
desenhou nenhuma delas e não pode mudá-las, e o fornecedor pode reorganizá-las na próxima versão, que
é exatamente o que a SAP fez ao passar do ECC para o S/4HANA (aula 2). Uma tabela que você consegue
ler não é uma tabela feita para ser lida por você.

**Terceiro, o significado está nos programas, não nas linhas.** Uma linha na tabela de estoque diz que
840 caixas de leite UHT estão na câmara fria de Juiz de Fora. Se alguma delas pode ser prometida a um
cliente depende das reservas para pedidos já feitos, das caixas bloqueadas pela qualidade à espera de
um resultado de laboratório, e do estoque em trânsito vindo de Barbacena. Esse cálculo está no código
do SAP, não em tabela nenhuma. **Quem lê a tabela e pula o código recebe um número que parece certo e
não está.**

## Integração por banco compartilhado, dentro de um produto

No vocabulário que a aula 9 vai dar, os módulos de um ERP se integram pelo mais antigo e mais
acoplado dos quatro estilos de integração: um **banco compartilhado**. Todo módulo lê e escreve as
mesmas tabelas, então uma mudança no significado de uma alcança todos.

Entre sistemas independentes esse estilo costuma ser um erro, porque os acopla por um esquema que
nenhum dos dois controla. **Dentro de um ERP ele funciona, porque um fornecedor é dono de todo programa
que toca o esquema e testa todos juntos.** O acoplamento é real; quem o segura é uma empresa
interessada em mantê-lo consistente.

O problema começa quando um sistema de fora do ERP entra no mesmo banco. Ele traz o acoplamento junto
e nada dos testes do fornecedor. A primeira proposta da Joana na Serra Alta faz exatamente isso, e a
última seção desta aula é sobre por que ela foi recusada.

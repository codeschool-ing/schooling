---
title: Transformação, e o modelo canônico que engoliu um ano
version: 1
---

O roteamento muda para onde uma mensagem vai. **A transformação muda o que a mensagem é, e deixa o
destino em paz.** Dois sistemas que nunca foram desenhados para conversar discordam de quase tudo o
que uma mensagem carrega, e a maior parte do código de uma camada de integração é o código que os põe
de acordo. Rui estima que quatro em cada cinco dos 70 fluxos do ESB são, no fundo, tradutores com
algum roteamento em volta.

## O tradutor de mensagens, em quatro níveis

O *tradutor de mensagens* (*message translator*) é a raiz do grupo: entra uma mensagem, sai a mesma
informação na forma que o receptor espera. O livro observa que dois sistemas podem discordar em
quatro níveis, e um tradutor talvez precise trabalhar em todos ao mesmo tempo. O pedido de
supermercado mostra cada um.

| nível | o que difere | no pedido da Vale Verde |
|---|---|---|
| estruturas de dados | quais são as entidades e como se relacionam | a rede manda um pedido para 12 lojas; o SAP quer uma ordem de venda por loja e fábrica |
| tipos de dados | o que um campo significa e em que unidade | a rede pede em unidades; o SAP vende a maioria dos produtos em caixas de 12 |
| representação dos dados | como os dados são escritos | segmentos EANCOM na mensagem de EDI; XML dentro do barramento |
| transporte | como os bytes viajam | a conexão do provedor de EDI; IBM MQ dentro da empresa |

Os dois níveis de baixo são onde as ferramentas mais ajudam: uma biblioteca lê EANCOM, o MQ carrega
bytes. **Os dois de cima são onde está o conhecimento, e onde os tradutores erram sem ninguém
perceber.** Um tradutor que transforma 48 unidades em 48 caixas produz um pedido perfeitamente válido
de doze vezes o leite.

## Envelope wrapper

Parte da infraestrutura precisa de dados em volta da mensagem que não têm nada a ver com o negócio. Um
*envelope wrapper* põe a mensagem dentro de um envelope que atende a essas necessidades, e quem
desembrulha do outro lado a tira de lá, sem mexer no corpo. Você já viu dois. O envelope SOAP da aula
8 é um. O intercâmbio de EDI é outro: no EANCOM, um intercâmbio abre com um segmento `UNB` e fecha com
`UNZ`, e dentro dele cada mensagem abre com `UNH` e fecha com `UNT`. O intercâmbio leva o remetente, o
destinatário e uma referência de controle; as linhas do pedido vão dentro.

A lição do padrão é manter os dois separados. Pense num fluxo que lê dados de negócio no envelope,
como decidir quem é o cliente pelo id de remetente do intercâmbio. Ele funciona até a rede passar a
mandar por um segundo provedor de EDI, e o id de remetente mudar por um motivo que não tem nada a ver
com o pedido.

## Content enricher, e a chamada que ele esconde

Um *content enricher* acrescenta dados que faltam na mensagem, a partir de uma fonte que quem enviou
não usou. A rede identifica cada loja pelo GLN. O SAP precisa do seu próprio número de cliente para a
loja, que ele chama de recebedor da mercadoria (*ship-to*), e da janela de entrega combinada com ela.
Nenhum dos dois está no pedido, então o fluxo os busca no SAP e os acrescenta.

No diagrama, um enricher é mais um ícone num fluxo assíncrono. **Por baixo, é uma chamada síncrona a
outro sistema, e o fluxo herda a disponibilidade desse sistema.** Quando o SAP está fora para a
manutenção semanal, todo domingo da 01:00 às 05:00 (aula 1), o enricher falha, e todo pedido atrás
dele espera, embora o fluxo tenha sido desenhado com filas justamente para que nada esperasse pelo
SAP. A chamada também custa tempo em cada mensagem, e um fluxo que trata algumas centenas de pedidos
por dia aguenta isso de um jeito que um fluxo que trata uma leitura de cada caminhão não aguenta.

Há três jeitos de desarmar isso, cada um com seu preço:

- *fazer cache* do que o enricher consulta. A Serra Alta tem cerca de 9.800 clientes e 2.600
  materiais ativos no SAP, e eles mudam algumas vezes por semana. Um cache atualizado a cada hora
  responde a quase toda consulta e fica desatualizado por no máximo uma hora.
- *replicar* os dados de referência para o lado do barramento, como uma tabela que o fluxo lê, e
  aceitar que ela pode estar atrasada.
- *pedir a quem envia* que inclua o dado. Às vezes o enriquecimento mais barato é um campo que o
  remetente já tinha e que ninguém pediu.

## Content filter

Um *content filter* é o oposto do enricher: ele remove o que o receptor não precisa. O cadastro de
cliente do SAP leva o limite de crédito, o histórico de pagamentos e os dados bancários. Quando as
mudanças de cliente são publicadas para o Portal B2B, o portal precisa do nome, do endereço de entrega
e da tabela de preços, e de mais nada. **Dado que nunca saiu do SAP é dado
que não vaza pelo portal**, e algumas padarias da Serra Alta são empresários individuais cujo cadastro
traz o CPF de uma pessoa, o que faz dele dado pessoal pela LGPD.

## Claim check

Um *claim check* guarda um payload grande num lugar que os dois lados alcançam e manda uma referência
no lugar dele. O receptor usa a referência para buscar o payload quando precisar.

O time de qualidade da Vale Verde pede o certificado de análise de cada lote que recebe. Os
certificados são PDFs de cerca de 2 MB cada, e ficam no Documentum (aula 5). Pôr o PDF dentro do aviso
de embarque copiaria 2 MB por todos os saltos e para dentro de cada log que um wire tap escreve. Além
disso, ficaria perto do tamanho máximo de mensagem padrão de uma fila do IBM MQ, 4 MB, e um
certificado grande faria um aviso de embarque falhar. Então a mensagem leva o id do objeto no Documentum, e o portal da rede busca o PDF
quando alguém o abre.

O padrão tem dois custos fáceis de esquecer. **O payload guardado precisa sobreviver a toda mensagem
que se refere a ele**, então alguém decide quando ele pode ser apagado. E o receptor precisa de acesso
ao repositório, o que é uma segunda interface para proteger. Aqui os dois já estão pagos: o Documentum
guarda o certificado pelas suas regras de retenção, faça a mensagem o que fizer, e o claim é uma
referência a um registro que existe de qualquer jeito.

## Normalizer

Os pedidos chegam à Serra Alta em três formas: EANCOM do provedor de EDI, JSON do Portal B2B e
pedidos digitados pelos vendedores de grandes contas no Salesforce. Um *normalizer* é um roteador
seguido de um tradutor por formato, de modo que, entre o que entrar, sai um formato só. A pergunta que
ele levanta é que formato deve ser esse, e essa pergunta é o modelo canônico de dados.

## O modelo canônico de dados, e o primeiro erro da Joana com ele

Um *modelo canônico de dados* (*canonical data model*) é um formato independente de todas as
aplicações: cada sistema traduz para ele e a partir dele, e nunca direto para o formato de outro
sistema. O argumento a favor dele é aritmético.

Se cada um de *n* sistemas manda para todos os outros, o ponto a ponto precisa de um tradutor para cada
par ordenado: **n(n − 1)**. Com um modelo canônico, cada sistema precisa de um tradutor para o modelo e
de um a partir dele: **2n**. Cinco sistemas falando todos com todos precisam de 5 × 4 = 20 tradutores
ponto a ponto e de 2 × 5 = 10 com um modelo canônico.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" data-fig=\"l11-translators\" aria-label=\"Dois painéis com os mesmos cinco sistemas: EDI, Portal B2B, Salesforce, SAP e Business Central. À esquerda, ponto a ponto: cada sistema ligado a todos os outros, dez linhas, e cada linha precisa de um tradutor em cada sentido, então 5 vezes 4 dá 20 tradutores. À direita, com um modelo canônico: cada sistema ligado só a um pedido canônico central, cinco linhas, dois tradutores cada, então 2 vezes 5 dá 10 tradutores.\"><text x=\"180.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ponto a ponto</text><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">modelo canônico</text><path d=\"M200.6 61.0 L258.3 102.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M184.9 61.0 L236.3 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M175.1 61.0 L123.7 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M159.4 61.0 L101.7 102.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M274.0 132.9 L246.0 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M258.3 132.9 L139.5 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M224.9 117.9 L135.1 117.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M187.1 234.1 L172.9 234.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M220.5 219.1 L101.7 132.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M114.0 219.1 L86.0 132.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M540.0 142.0 L540.0 59.0\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M582.0 146.4 L604.2 139.2\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M553.1 178.0 L597.3 238.8\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.9 178.0 L482.7 238.8\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M498.0 146.4 L475.8 139.2\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"500.0\" y=\"144.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido</text><text x=\"540.0\" y=\"166.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">canônico</text><rect x=\"128.0\" y=\"33.0\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><rect x=\"226.9\" y=\"104.9\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"278.9\" y=\"117.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"189.1\" y=\"221.1\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"241.1\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><rect x=\"66.9\" y=\"221.1\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"118.9\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"29.1\" y=\"104.9\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"81.1\" y=\"117.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><rect x=\"488.0\" y=\"31.0\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><rect x=\"598.3\" y=\"111.2\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"650.3\" y=\"124.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"556.2\" y=\"240.8\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"608.2\" y=\"253.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><rect x=\"419.8\" y=\"240.8\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"471.8\" y=\"253.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"377.7\" y=\"111.2\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"429.7\" y=\"124.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><path d=\"M360.0 30.0 L360.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"180.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">10 linhas × 2 = 20 tradutores: n(n − 1)</text><text x=\"540.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">5 linhas × 2 = 10 tradutores: 2n</text></svg>", "caption": "Cinco sistemas que falam todos com todos. Ponto a ponto precisa de um tradutor para cada par ordenado; um modelo canônico precisa de dois por sistema. O lado esquerdo cresce com o quadrado de n, o direito em linha reta.", "same": ["Business Central", "EDI", "Portal B2B", "SAP", "Salesforce"]}
```

A aritmética tem um ponto de equilíbrio que vale saber. Com três sistemas, os dois lados dão seis. Com
dois, o ponto a ponto precisa de 2 e o modelo canônico de 4. **Um modelo canônico só começa a
economizar tradutores a partir do quarto sistema**, e traz custos que a conta deixa de fora: um
formato que alguém precisa possuir, versionar e defender.

Joana veio de uma fintech em que todos os serviços falavam um mesmo conjunto de schemas, e no segundo
mês ela propôs um modelo canônico para a empresa toda, começando por *Customer*. Três oficinas depois,
o rascunho tinha 87 campos, quase todos opcionais. Edson explicou que no SAP uma rede de supermercados
não é um cliente, e sim um conjunto de funções de parceiro: quem pede, que lojas recebem, quem é
faturado, quem paga; e a Vale Verde tem um do primeiro e 30 do segundo. O *Account* do Salesforce da
Talita é a relação comercial, com as anotações do vendedor e a próxima visita. O Business Central do
Felipe fatura queijo pela empresa da própria Mantiqueira, com seus próprios números de cliente. O
cliente do Portal B2B é uma padaria com login. A aula 1 encontrou a mesma pergunta dentro do ERP;
espalhada pela empresa, ela não tem resposta.

**Um modelo canônico para a empresa toda vira um comitê, e toda mudança em qualquer sistema espera por
ele.** E um modelo em que todo campo é opcional não promete nada, porque nenhum sistema consegue saber
pelo schema se o registro que recebeu é utilizável. Eric Evans deu nome ao motivo em *Domain-Driven
Design* (2003): uma palavra como *cliente* significa coisas diferentes em contextos delimitados
diferentes, e o desenho honesto traduz nas fronteiras em vez de impor um significado a todos eles.

O que sobreviveu foi menor. **Um modelo canônico compensa quando se restringe a uma troca com várias
partes de cada lado.** Joana largou o *Customer* e ficou com uma *mensagem de pedido* canônica: três
emissores (EDI, Portal B2B, Salesforce) e dois receptores (SAP, Business Central), mantida e
versionada pelo time do Rui.

A conta para esse grafo real não é n(n − 1), porque nem todo mundo manda pedidos para todo mundo. O
ponto a ponto precisa de um tradutor por par de emissor e receptor, 3 × 2 = 6. O modelo canônico
precisa de um por sistema, 3 + 2 = 5, já que um emissor só traduz para o modelo e um receptor só
traduz a partir dele. Isso economiza um tradutor hoje. O argumento a favor dele é o próximo emissor.
Um canal de marketplace que o diretor comercial quer para o ano que vem custa dois tradutores novos no
ponto a ponto e um com o modelo canônico, e é construído sem mexer no lado do SAP nem no do Business
Central.

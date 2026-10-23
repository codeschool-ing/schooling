---
title: Interceptando um sistema que não tem porta da frente
version: 1
---

Quase tudo o que se escreve sobre a figueira estranguladora supõe uma aplicação web: as requisições
chegam por HTTP, um proxy fica na frente, e mudar uma capacidade de lado é mudar uma regra de
roteamento. **O legado corporativo raramente tem essa porta da frente.** O trabalho dele chega como
arquivos largados numa pasta, linhas digitadas em telas de terminal e jobs em lote disparados por
um agendador às duas da manhã, e ele responde gravando mais arquivos. Não existe um lugar único por
onde passe toda requisição, então não existe um lugar único para pôr uma fachada.

O strangler continua funcionando. O que muda é onde você se posiciona para interceptar, e há quatro
técnicas para isso. Três delas colocam você dentro do fluxo de um sistema que você mal pode
alterar, e a quarta é para o código que é seu, do outro lado dele.

## O que entra e o que sai da Coleta

Antes de escolher uma técnica, a Joana desenhou todos os fluxos que cruzam a fronteira da Coleta,
com o volume de cada um, porque a técnica depende da forma de cada fluxo.

- As coletas dos caminhões. Cada motorista leva um coletor portátil que registra, em cada fazenda,
  os litros bombeados, a temperatura do tanque e o código do frasco de amostra. Quando o caminhão
  volta à fábrica, o coletor é encaixado na base, e um PC ao lado manda o arquivo da rota para uma
  pasta no IBM i. Chegam cerca de 130 arquivos de rota por dia, somando as quatro fábricas.
- Os resultados do laboratório. Um laboratório externo credenciado analisa os frascos de amostra e
  manda um arquivo de resultados por dia útil: gordura, proteína, contagem de células somáticas e
  contagem bacteriana de cada amostra. Um programa da Coleta carrega esse arquivo às 22:00.
- As telas dos funcionários. Seis pessoas no setor de pagamento do leite usam terminais de tela
  verde para cadastrar fazendas, corrigir uma coleta que o coletor portátil registrou errado,
  suspender uma fazenda por qualidade e liberá-la de novo.
- O arquivo noturno para o SAP, com cerca de 1.900 linhas, que um programa ABAP carrega às 02:00
  para criar uma entrada de mercadoria por fazenda coletada (a aula 1 acompanha esse documento; a
  aula 9 mostra como se torna seguro um arquivo assim).
- O pagamento mensal. Todo mês a Coleta calcula quanto cada fazenda tem a receber e manda os valores
  para o SAP, onde as fazendas são fornecedores e o financeiro paga no dia 10.
- Os dois fluxos do barramento da seção anterior: a consulta de fazenda para o Rota e o resumo da
  coleta para o painel de qualidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l13-intercept\" aria-label=\"A Coleta, no IBM i, no meio, com todos os fluxos que cruzam a sua fronteira. À esquerda, as entradas: os arquivos de rota dos coletores portáteis dos caminhões passam agora por um serviço novo de recepção, que guarda uma cópia e repassa o arquivo; o arquivo de resultados do laboratório passa pelo novo serviço de qualidade do mesmo jeito; as telas verdes dos funcionários gravam direto na Coleta, sem nada no meio. Em cima, os dois fluxos do barramento, consulta de fazenda para o Rota e o resumo da coleta, que já fazem papel de fachada. À direita, as saídas: o arquivo noturno para o SAP e os valores mensais de pagamento para o SAP. Embaixo, o journal da Coleta alimenta a captura de mudanças, que manda para o lado novo as alterações feitas pelos funcionários. Cada caminho tem o nome da técnica que o alcança.\"><defs><marker id=\"l13-intercept-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-intercept-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-intercept-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"325.0\" y=\"150.0\" width=\"150.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><text x=\"400.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IBM i, RPG</text><rect x=\"10.0\" y=\"93.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos de rota</text><rect x=\"155.0\" y=\"93.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviço de recepção</text><path d=\"M130.0 110.0 L153.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><path d=\"M275.0 110.0 L323.0 165.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"215.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">interceptação de eventos</text><rect x=\"10.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resultados do laboratório</text><rect x=\"155.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviço de qualidade</text><path d=\"M130.0 190.0 L153.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><path d=\"M275.0 190.0 L323.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"215.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">interceptação de eventos</text><rect x=\"10.0\" y=\"273.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">telas dos funcionários</text><path d=\"M130.0 290.0 L323.0 245.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-amber)\"></path><text x=\"215.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nada para interceptar</text><rect x=\"275.0\" y=\"33.0\" width=\"250.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fluxos do barramento: fazenda, resumo</text><path d=\"M400.0 67.0 L400.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"408.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">uma fachada que já existe</text><rect x=\"530.0\" y=\"148.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo noturno para o SAP</text><path d=\"M477.0 165.0 L528.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"228.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">valores de pagamento ao SAP</text><path d=\"M477.0 245.0 L528.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><text x=\"615.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">contratos de saída mantidos</text><rect x=\"340.0\" y=\"320.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">journal</text><path d=\"M400.0 262.0 L400.0 318.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><rect x=\"575.0\" y=\"320.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lado novo</text><path d=\"M462.0 335.0 L573.0 335.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"517.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">captura de mudanças</text></svg>", "caption": "A Coleta não tem porta da frente, então cada fluxo é alcançado onde dá: os arquivos no caminho deles, os fluxos do barramento no barramento, e o que os funcionários digitam só depois, pelo journal.", "same": ["Coleta", "IBM i, RPG", "journal"]}
```

## Interceptação de eventos: ficar no caminho do que entra

Onde o trabalho chega como mensagem ou arquivo, dá para colocar o sistema novo no caminho. O Fowler
chama isso de interceptação de eventos (*event interception*), e a ideia é simples: **o sistema novo
recebe a entrada primeiro, guarda o que precisa e a repassa para o legado sem alteração.** O legado
não fica sabendo de nada. O sistema novo passa a ter uma cópia completa e ao vivo daquela entrada sem
tocar numa linha do código antigo.

Os arquivos dos coletores portáteis são o caso mais claro na Serra Alta. Hoje o PC da base grava
numa pasta do IBM i. Depois da mudança ele manda o mesmo arquivo para um serviço de recepção, que o
armazena, registra e grava na mesma pasta do IBM i, byte a byte. A Coleta carrega como antes. O
serviço novo de coleta tem todos os arquivos de rota daquele dia em diante, e nada na Coleta mudou.

A interceptação só é segura se o repasse for tão confiável quanto o caminho original era. Um arquivo
que o serviço de recepção recebeu e não repassou é uma fazenda que não recebe por aquele dia, e um
arquivo repassado duas vezes é uma fazenda paga duas vezes, a não ser que a Coleta recuse
duplicados. A aula 10 trata dessa maquinaria, garantias de entrega e consumidores idempotentes;
aqui basta saber que o componente que intercepta precisa do mesmo cuidado que o sistema na frente
do qual ele fica.

**A interceptação muda de direção durante a migração.** No começo o sistema novo copia e o legado
decide. Mais tarde, quando o serviço novo de coleta virar o dono das coletas, o serviço de recepção
para de repassar o arquivo bruto e passa a mandar para a Coleta uma versão traduzida do que o
serviço novo aceitou, para que as partes da Coleta que ainda não mudaram de lado continuem vendo as
coletas de que precisam. O caminho físico é o mesmo; quem manda é o contrário.

## Captura de mudanças: ler o que o legado gravou

As telas dos funcionários não podem ser interceptadas desse jeito. Um funcionário digita numa sessão
de terminal no IBM i, e a mudança não existe em lugar nenhum até a Coleta gravá-la nas próprias
tabelas. O único lugar para pegá-la é depois, no banco de dados.

**A captura de mudanças (*change data capture*, CDC) lê o registro de alterações do próprio banco e
transforma cada uma num evento que outro sistema pode consumir.** A aula 9 a apresentou como a
alternativa mais segura a ler as tabelas dos outros. No IBM i o banco registra as alterações de uma
tabela num journal, que existe para recuperação e auditoria, e produtos de replicação leem esses
journals e publicam as mudanças em outro lugar. As tabelas da Coleta já têm journal, porque o
procedimento de backup do Sebastião depende disso, então a matéria-prima está lá.

O CDC tem dois limites que importam num strangler. Ele entrega linhas, não intenções: o journal diz
que o status da fazenda 041327 mudou de `A` para `S` às 14:02, e nada sobre o porquê, então o lado
novo precisa deduzir que um funcionário suspendeu a fazenda por qualidade, e precisa saber o que `S`
significa. Essa dedução é trabalho da camada anticorrupção, na próxima seção. E ele roda numa direção
só, do legado para fora. Ele mantém uma cópia em dia com a Coleta; não deixa mais ninguém mudar a
Coleta.

## Captura de ativos: mudar um tipo de coisa de cada vez

Interceptação e CDC tiram os dados de lá. A decisão sobre o que mudar de lado primeiro é outra, e o
nome que o Fowler dá à resposta habitual é captura de ativos (*asset capture*): **escolher um tipo de
entidade e passar a posse dele inteira para o sistema novo antes de tocar no próximo.** Não "algumas
das fazendas" nem "o histórico das fazendas", mas um tipo de coisa: resultados de laboratório, ou
coletas, ou o cadastro de fazendas.

O primeiro ativo da Joana foram os resultados de laboratório, por quatro motivos que ela escreveu no
plano.

1. Eles chegam de fora, como um arquivo por dia, que é o fluxo mais fácil de interceptar.
2. Ninguém os edita nas telas da Coleta. Um resultado é o que o laboratório mediu, então não há uma
   segunda fonte de alterações para sincronizar de volta.
3. A Coleta os usa num lugar só, o cálculo do pagamento mensal, então uma cópia traduzida devolvida à
   Coleta a mantém funcionando.
4. O time de qualidade quer recebê-los mais cedo. Hoje um resultado que chega ao meio-dia só alcança
   o time da Cláudia na manhã seguinte, depois da carga das 22:00; uma fazenda com contagem ruim
   continua entregando leite por um dia que ninguém precisava perder.

O quarto motivo é o que faz a primeira fatia se pagar. O serviço novo de qualidade vai mostrar cada
resultado minutos depois de o arquivo chegar, e essa vai ser a primeira coisa que a migração entrega
a alguém de fora da TI.

## Branch by abstraction: para o código que é seu

Alguns dos dependentes da Coleta são código da própria Serra Alta. O Rota é uma aplicação Kotlin com
um time de cinco pessoas, e o planejador de rotas dele chama a consulta de fazenda através de uma
classe que sabe que está falando com o barramento. Daria para mudar a consulta de fazenda de lado
inteiramente no barramento, mas o time do Rota também quer usar campos que o serviço novo tem e a
Coleta nunca teve, como a posição GPS da fazenda.

Para isso a técnica é a *branch by abstraction*, que Paul Hammant descreveu em 2007. **Dentro de um
código que você controla, ponha uma interface na frente daquilo que vai ser substituído, leve todos
os chamadores para a interface, construa a implementação nova atrás dela, troque e apague a
antiga** — tudo no branch principal, com o código pronto para ir a produção em cada passo. O Rota
ganha uma interface `FarmDirectory` com duas implementações, uma que chama o barramento e outra que
chama o serviço novo, e uma flag de configuração que escolhe entre as duas. O time pode trocar,
comparar e voltar sem um branch de vida longa.

A branch by abstraction é a mesma ideia da fachada, levada para dentro de um programa. Ela não
funciona dentro da própria Coleta, porque mexer na Coleta é exatamente o que a migração tenta reduzir
ao mínimo, e a única pessoa que mexe nela com segurança é a que está indo embora.

## O que nenhuma delas alcança

As telas são a única coisa que nenhuma técnica muda de lado sozinha. **Quando muda de lado uma
capacidade cuja entrada é digitada por pessoas, as pessoas mudam junto.** Os seis funcionários vão
cadastrar fazendas no sistema novo a partir de uma segunda-feira marcada, e desse dia em diante a
tela da Coleta para isso precisa recusar alterações, senão dois lugares vão aceitá-las. Isso é um
plano de treinamento e uma data tanto quanto um passo técnico, e pertence à coexistência, a seção
depois da próxima.

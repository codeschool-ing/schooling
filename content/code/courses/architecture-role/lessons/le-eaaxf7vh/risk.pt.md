---
title: Risco como probabilidade vezes impacto
version: 1
---

Um risco é algo que ainda não aconteceu e pode acontecer. Quando acontece, vira um **problema**
(*issue*), e um problema se trata em vez de se avaliar. A imagem comum de gestão de risco é um slide
perto do fim de uma proposta com o título "Riscos" e três tópicos que ninguém relê. **Um risco só
vale ser escrito quando carrega uma probabilidade, um impacto, um dono e uma resposta**, e a
resposta é a parte que muda alguma coisa.

## De onde vêm os riscos

A seção anterior deixou Renata com uma pergunta que ela fez para cada linha: "O que faria isto
levar nove semanas?" Cada resposta é um risco na sua primeira forma. O time do Bruno disse que o
sandbox do banco podia não se comportar como o sistema de produção; que o Tracking podia não guardar
evidência suficiente na entrega para confiar num pagamento instantâneo; que Bruno é a única pessoa
que entende o código de conciliação.

É um começo, e tem um ponto cego: só encontra o que um time já teme. O **risk-storming**, uma técnica
que Simon Brown descreve, amplia a sala. Todos os envolvidos olham o mesmo diagrama de arquitetura
— um diagrama de contêineres basta, e a aula 8 o apresentou — e, por dez minutos, cada pessoa escreve
riscos em post-its **sozinha**, sem discussão. Depois os post-its vão para o diagrama, ao lado da
caixa ou da seta de que falam, e o grupo conversa sobre os agrupamentos.

As duas regras carregam a técnica. Escrever sozinho impede que a voz mais sênior decida o que todos
os outros perceberam. Colar os post-its no diagrama põe os riscos onde eles moram: nas partes e,
como a aula 1 argumentou, com a mesma frequência nas conexões entre elas. Renata conduziu uma sessão
com gente de Payments, Tracking, do app do motorista e de Platform. Subiram trinta e um post-its.
Muitos diziam a mesma coisa com outras palavras, e eles se reduziram a **cinco riscos**, três dos
quais ninguém em Payments tinha mencionado. A maior parte dos post-its ficou numa seta só: a chamada
de Payments para o banco.

## Probabilidade vezes impacto

Cada risco recebe duas notas. A **probabilidade** é a chance de acontecer no período que importa. O
**impacto** é o tamanho do estrago se acontecer. A versão mais simples dá nota de 1 a 5 às duas e as
multiplica numa pontuação de 1 a 25, o que dá uma ordem à lista.

| id | risco | probabilidade | impacto | pontuação | dono |
|---|---|---|---|---|---|
| R1 | uma prova de entrega falsa é paga antes que alguém perceba | 2 | 5 | 10 | Bruno |
| R2 | o sandbox do banco se comporta diferente da produção | 3 | 3 | 9 | Bruno |
| R3 | a API de pagamento do banco cai numa sexta à noite, no pico | 4 | 2 | 8 | Paula |
| R4 | só Bruno entende o código de conciliação | 2 | 3 | 6 | Renata |
| R5 | a revisão da loja de apps atrasa em dias a versão do app do motorista | 3 | 1 | 3 | Diego |

A tabela é um **registro de riscos**: uma linha por risco, mantida onde o time trabalha, com um
nome ao lado de cada linha. A grade abaixo desenha os mesmos cinco riscos, porque a posição de um
risco diz mais que a pontuação dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" aria-label=\"Uma grade de cinco por cinco, com a probabilidade de 1 a 5 na horizontal e o impacto de 1 a 5 na vertical. R1, uma prova de entrega falsa paga, fica em probabilidade 2 e impacto 5, numa célula de pontuação alta; uma cópia tracejada de R1 fica uma linha abaixo, em impacto 4, depois do teto de R$ 3.000. R2, o sandbox, fica em 3 e 3. R3, a API do banco fora no pico de sexta, em 4 e 2. R4, uma só pessoa entender a conciliação, em 2 e 3. R5, o atraso na revisão da loja de apps, em 3 e 1.\"><defs><marker id=\"l14grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"116\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"80\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"168\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"80\" y=\"202\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"220\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"80\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"272\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"80\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"324\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"80\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"220\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">probabilidade →</text><text x=\"8\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impacto</text><text x=\"8\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">↑</text><path d=\"M168 77 L168 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l14grid-ah)\"></path><circle cx=\"168\" cy=\"98\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></circle><text x=\"168\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R1</text><circle cx=\"168\" cy=\"46\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"168\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R1</text><circle cx=\"220\" cy=\"150\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"220\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R2</text><circle cx=\"272\" cy=\"202\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"272\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R3</text><circle cx=\"168\" cy=\"150\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"168\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R4</text><circle cx=\"220\" cy=\"254\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"220\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R5</text><text x=\"380\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R1</text><text x=\"408\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prova de entrega falsa paga</text><text x=\"380\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R2</text><text x=\"408\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sandbox diferente da produção</text><text x=\"380\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R3</text><text x=\"408\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API do banco fora no pico de sexta</text><text x=\"380\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R4</text><text x=\"408\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">só uma pessoa entende a conciliação</text><text x=\"380\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R5</text><text x=\"408\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">atraso na revisão da loja de apps</text><text x=\"380\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tracejado: R1 depois do teto de R$ 3.000</text><rect x=\"380\" y=\"222\" width=\"16\" height=\"16\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"404\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pontuação 10 ou mais</text><rect x=\"380\" y=\"248\" width=\"16\" height=\"16\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"404\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pontuação de 5 a 9</text></svg>", "caption": "Os cinco riscos da Carreto para o pagamento instantâneo. A pontuação os ordena; a posição mostra por que R1 e R3 pedem respostas diferentes, e o R1 tracejado é para onde o teto o leva."}
```

**A pontuação é um jeito de ordenar, não uma medida.** Uma escala de 1 a 5 é ordenada, mas os
degraus não são iguais, então multiplicar duas delas é uma conveniência, não uma conta. E o produto
esconde o formato: uma catástrofe rara em 1 × 5 pontua o mesmo que um incômodo semanal em 5 × 1.
Uma regra resolve quase tudo: **leia a coluna de impacto sozinha para cada 5**, e pergunte de cada
um se a Carreto sobreviveria a ele, qualquer que seja a probabilidade.

Quando um risco pode ser precificado, um número funciona melhor que uma pontuação. R1 é o que
preocupava Sílvio, o diretor financeiro, então Renata e o time dele puseram dinheiro nele. Uma
quadrilha forjando entregas para receber pagamentos instantâneos: eles avaliaram 20% de chance de
uma aparecer num trimestre, e cerca de R$ 180.000 pagos antes que alguém percebesse. Probabilidade
vezes impacto vira então um produto de verdade, a **perda esperada** ou **exposição**:

```localised
exposição = probabilidade × impacto
          = 0,20 × R$ 180.000
          = R$ 36.000 por trimestre
```

Uma exposição é o que o risco custa em média, e é o número a comparar com o custo de uma resposta.
Nem os 20% nem os R$ 180.000 são conhecidos; os dois são estimativas e, como toda estimativa desta
aula, merecem uma faixa e as suas suposições escritas ao lado.

## Quatro respostas

Há quatro coisas a fazer com um risco, e o registro deve dizer qual foi escolhida.

**Evitar** é mudar o plano para que o risco não possa acontecer. O primeiro desenho deixava o
motorista digitar qualquer chave Pix ao pedir um pagamento. Quem estivesse com um celular roubado
poderia mandar o dinheiro de um motorista para qualquer lugar. O time mudou o desenho: um pagamento
instantâneo vai só para a chave Pix verificada quando o motorista se cadastrou. Esse risco não
diminuiu; ele saiu do plano, junto com uma funcionalidade que ninguém tinha pedido.

**Mitigar** é baixar a probabilidade, o impacto ou os dois. Para R1, o time do Bruno propôs um teto:
pagamentos instantâneos de no máximo R$ 3.000 por carga para motoristas com menos de dez entregas
concluídas, que é onde ficam as contas falsas. A perda avaliada com uma quadrilha caiu para cerca de
R$ 45.000, então a exposição caiu de R$ 36.000 para R$ 9.000 por trimestre, ao preço de mais ou menos
uma semana de trabalho e de alguns motoristas novos irritados. Na grade, isso é R1 descendo uma
linha. R4 é mitigado no outro eixo: Ícaro Nunes pareia com Bruno no código de conciliação, o que
torna menos provável que a ausência do Bruno pare o trabalho.

**Transferir** é passar a consequência para alguém mais bem posicionado para carregá-la, em geral
por dinheiro: uma seguradora, ou um contrato em que um provedor assume a responsabilidade. Um
provedor de pagamentos que opera com vários bancos transferiria a maior parte de R3, por uma tarifa
por pagamento. Se isso compensa é uma comparação entre alternativas, e a próxima seção a faz.

**Aceitar** é decidir conviver com o risco, e só é uma decisão quando está escrita. R5 é aceito:
atrasos na revisão das lojas de apps são curtos e comuns, e nada do que a Carreto faz muda isso. O
time acrescenta uma **contingência**: publicar a tela nova do app do motorista uma semana antes de o
pagamento ser ligado, escondida atrás de uma flag. Aceitar com um plano para quando acontecer é
diferente de não ter olhado.

## Mantendo o registro vivo

Um registro é revisto ou é enfeite. Cada linha tem um **dono**, uma pessoa e não um time, cujo
trabalho é acompanhá-la e avisar quando a probabilidade mudar. Cada linha também tem uma **data**
para ser olhada de novo. O registro de Renata fica no mesmo repositório que os registros de decisão
da aula 5, e os primeiros dez minutos de cada fórum de arquitetura (aula 10) passam pelo que se
mexeu.

Duas coisas mudam um registro mais que qualquer outra. Um risco que acontece vira problema, sai do
registro e entra no trabalho comum do time. E um spike ou uma decisão remove incerteza, o que baixa
uma probabilidade ou apaga uma linha. R2, o sandbox, é exatamente desse tipo: uma ligação para o
banco e três dias testando o sandbox diriam quanto ele difere da produção.

**Riscos com causa comum também quebram a estimativa da seção anterior.** A conta que somou as
variâncias supôs que as quatro partes variam de forma independente. Se R2 acontecer, ele atrasa a
integração com o banco e os testes de conciliação ao mesmo tempo, então a dispersão real é maior que
1,89 semana. A aula 11 de `process-management` trata disso, e de reservas de contingência, na
profundidade de que um gerente de projeto precisa. Um arquiteto precisa do hábito: quando duas linhas
de uma estimativa dependem da mesma incógnita, escreva essa incógnita como um risco.

---
title: Qual código, e qual não
version: 1
---

O jeito óbvio de um arquiteto continuar programando é pegar uma história do quadro do time, e é o
jeito com mais chance de dar errado. **Um arquiteto escreve código pelo qual a entrega de ninguém
espera**, e há bastante código assim: spikes, protótipos, esqueletos andantes, funções de fitness,
ferramentas, correções pequenas e pareamento. Esta seção explica a regra e depois percorre a lista.

## A regra: fora do caminho crítico

O **caminho crítico** de um time é a cadeia de trabalho que decide quando algo é entregue: as partes
em que o atraso de uma é o atraso da entrega. Quem segura uma parte dele precisa estar disponível
para terminá-la.

A agenda de um arquiteto é feita para outra coisa. A semana de Renata, depois das revisões, do
fórum, das conversas com Helena e Sílvio e das perguntas de cinco times, deixa cerca de **duas
meias jornadas sem interrupção**. Suponha que ela pegue uma história que o time estima em três dias
de trabalho concentrado, ou seja, seis meias jornadas. A duas meias jornadas por semana, isso leva
**três semanas** de tempo corrido. Se a entrega espera por essa história, a entrega espera três
semanas por três dias de trabalho, e o time nem consegue ajudar sem antes entender até onde ela
chegou.

Então a regra é sobre o formato do trabalho, não sobre a sua importância ou dificuldade. **O código
que um arquiteto escreve deve caber nas brechas de uma semana interrompida, e ninguém deve ficar
bloqueado quando ele atrasa.** A aula 16 volta ao caminho crítico pelo outro lado, como um dos
lugares onde o papel termina. Aqui ele decide o que pegar.

A exceção tentadora é a parte mais difícil e mais interessante de um projeto: aquela em que a
experiência do arquiteto parece pesar mais. É também a parte com mais chance de estar no caminho
crítico, e pegá-la faz o time aprender menos justamente onde há mais a aprender. A alternativa é
**parear nela** com quem é o dono: a experiência é usada, o dono continua dono, e ninguém espera
pela agenda do arquiteto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 324\" role=\"img\" aria-label=\"Um gráfico com dois eixos: na horizontal, quanto um trabalho ensina sobre o desenho; na vertical, quanto a entrega do time depende dele. A metade de cima está sombreada como trabalho a evitar assumir, e tem a última história da entrega e a parte mais difícil do projeto. Uma seta leva da parte mais difícil para baixo, até parear nessa parte, na metade de baixo, marcada como onde cabe o código do arquiteto, junto com o esqueleto andante, um protótipo, um spike, uma função de fitness, uma correção pequena e ferramentas. Os que ficam mais à esquerda ensinam menos sobre o desenho e continuam sem bloquear ninguém.\"><defs><marker id=\"l15map-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"80\" y=\"30\" width=\"560\" height=\"125\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"80\" y=\"155\" width=\"560\" height=\"125\" rx=\"0\" fill=\"var(--phosphor-dim)\" fill-opacity=\"0.2\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M80 30 L80 280 L640 280\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M80 155 L640 155\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"80\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quanto a entrega do time depende disso</text><text x=\"72\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais</text><text x=\"72\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">menos</text><text x=\"80\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">menos</text><text x=\"640\" y=\"296\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais</text><text x=\"360\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quanto ensina sobre o desenho</text><text x=\"92\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">evite assumir: pareie nisso</text><text x=\"630\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">onde cabe o código do arquiteto</text><path d=\"M420 78 L420 172\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15map-ah)\"></path><circle cx=\"140\" cy=\"82\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"150\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a última história da entrega</text><circle cx=\"420\" cy=\"70\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"430\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a parte mais difícil do projeto</text><circle cx=\"420\" cy=\"182\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"430\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parear nessa parte</text><circle cx=\"530\" cy=\"210\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"540\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">esqueleto andante</text><circle cx=\"380\" cy=\"214\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"390\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protótipo</text><circle cx=\"430\" cy=\"240\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"440\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">spike</text><circle cx=\"300\" cy=\"246\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"310\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">função de fitness</text><circle cx=\"220\" cy=\"216\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"230\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">correção pequena</text><circle cx=\"110\" cy=\"246\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"120\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text></svg>", "caption": "Duas perguntas decidem se um código é do arquiteto: ele ensina algo sobre o desenho, e alguém espera por ele? A parte mais difícil de um projeto pontua alto nas duas, e é por isso que a resposta para ela é parear.", "same": ["spike"]}
```

A figura põe os candidatos de sempre em dois eixos: quanto o trabalho ensina sobre o desenho, e
quanto a entrega do time depende dele. A região boa é a metade de baixo, e quanto mais à direita,
melhor. O que vem a seguir é a lista, mais ou menos do mais comum para o menos comum.

## Spikes e protótipos

Um **spike** responde a uma pergunta com alguns dias de código e joga o código fora, como na aula
14, quando Ícaro e um engenheiro do Tracking descobriram o que o Tracking registra na entrega. Um
arquiteto está bem posicionado para escrever spikes porque as perguntas muitas vezes são dele: esta
biblioteca aguenta o nosso volume, a replicação deste banco se comporta como a documentação diz,
quanto do monólito este módulo arrasta quando tentamos extraí-lo.

Um **protótipo** é um spike sobre o qual algo é construído: uma versão tosca que uma pessoa consegue
usar, para aprender se a ideia funciona antes de construir a de verdade. O perigo dele é conhecido:
um protótipo que funciona dá vontade de pôr em produção. A defesa é dizer o que ele é no próprio
código, no nome do repositório e na primeira linha do README, e combinar antes de escrevê-lo o que
acontece com ele depois.

## O esqueleto andante

Alistair Cockburn deu nome ao **esqueleto andante** (*walking skeleton*): uma implementação mínima
do sistema que executa uma função pequena de ponta a ponta, ligando entre si as principais partes da
arquitetura. Ele quase não faz nada, mas faz através de todas as camadas: o botão, a API, o banco de
dados, a chamada para o mundo externo, o pipeline de deploy.

Quando Helena e Sílvio escolheram começar o pagamento instantâneo com um provedor, Renata escreveu o
esqueleto nas suas duas meias jornadas por semana, ao longo de quinze dias, antes de o time começar
as partes de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" aria-label=\"Quatro partes em fila: o app do motorista, a API de Payments, o livro-razão e o sandbox do provedor, com o Tracking acima da API de Payments. Cada parte é uma caixa grande tracejada com uma peça pequena sólida dentro: um botão, um endpoint, um tipo de lançamento, uma transferência de R$ 1, e no Tracking um evento de entrega falso. Uma única linha atravessa as peças sólidas, do botão até o sandbox, e o evento do Tracking alimenta a API de Payments.\"><defs><marker id=\"l15skel-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"140\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"90.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">app do motorista</text><rect x=\"32\" y=\"158\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um</text><text x=\"90.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">botão</text><rect x=\"186\" y=\"110\" width=\"140\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"256.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">API de Payments</text><rect x=\"198\" y=\"158\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.0\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um</text><text x=\"256.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">endpoint</text><rect x=\"352\" y=\"110\" width=\"140\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"422.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">livro-razão</text><rect x=\"364\" y=\"158\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"422.0\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um tipo de</text><text x=\"422.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lançamento</text><rect x=\"518\" y=\"110\" width=\"140\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"588.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sandbox do provedor</text><rect x=\"530\" y=\"158\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"588.0\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma transferência</text><text x=\"588.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de R$ 1</text><path d=\"M148 178 L196 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l15skel-ah)\"></path><path d=\"M314 178 L362 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l15skel-ah)\"></path><path d=\"M480 178 L528 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l15skel-ah)\"></path><rect x=\"186\" y=\"8\" width=\"140\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"256.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking</text><rect x=\"198\" y=\"38\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um evento de</text><text x=\"256.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">entrega falso</text><path d=\"M312 78 L312 156\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l15skel-ah)\"></path><text x=\"20\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sólido: o esqueleto, de ponta a ponta · tracejado: o resto de cada parte, construído depois</text></svg>", "caption": "O esqueleto andante de Renata para o pagamento instantâneo. Cada parte do desenho faz uma coisa, e cada conexão entre as partes é exercitada uma vez, antes de o time construir o resto.", "same": ["Tracking", "endpoint"]}
```

**O esqueleto é a arquitetura tornada executável.** Cada conexão do desenho é exercitada uma vez.
Os problemas que moram nas conexões — autenticação entre serviços, uma regra de firewall, um
formato de mensagem que dois times leem de jeitos diferentes — aparecem nas duas primeiras semanas
em vez das duas últimas. Ele também dá ao time um sistema rodando em que acrescentar a carne, o que
transforma "integrar tudo no fim" numa sequência de mudanças pequenas em algo que já funciona.

Ele combina com um arquiteto pelos motivos da seção anterior. Ninguém espera por ele, porque ninguém
consegue começar as partes antes de o desenho estar fechado. E escrevê-lo é a calibragem mais rápida
que existe: Renata descobriu na primeira tarde que o sandbox do provedor exigia um endereço IP numa
lista de liberação, o que significava uma mudança na configuração de rede de Platform e um chamado
para o time da Paula. No projeto de verdade, isso teria sido uma surpresa na nona semana.

## Funções de fitness e ferramentas

A aula 9 construiu uma **função de fitness**: um programa curto que faz o build falhar quando o
código quebra uma regra de arquitetura, como um módulo importar o interior de outro. Funções de
fitness são arquitetura escrita como teste, e o arquiteto muitas vezes é o autor certo, porque a
regra é dele e escrevê-la o obriga a enunciá-la com precisão. O mesmo vale para as **ferramentas**
em volta da arquitetura: um script que desenha as dependências atuais a partir do código, uma
verificação de que todo serviço tem um dono no catálogo, um modelo que cria um serviço novo no
caminho pavimentado da aula 9.

Essas estão entre as coisas mais úteis que um arquiteto pode escrever. Continuam funcionando quando
o arquiteto está numa reunião, transformam um padrão de um documento numa verificação, e estão fora
de qualquer caminho crítico por construção.

## Correções pequenas e pareamento

Uma **correção pequena** é um bug do backlog, uma consulta lenta, uma mensagem de erro confusa: algo
real, no código de produção, por que nenhuma entrega está esperando. Correções pequenas mantêm as
mãos do arquiteto no código que o time escreve todo dia, com os seus testes, a sua revisão e o seu
deploy, que é de onde vem a calibragem da primeira seção. Renata pega uma a cada semana ou duas,
escolhida com o tech lead do time para que seja algo que eles concordam que vale fazer.

O **pareamento** é o mais eficaz de todos, e não é sobre o código do próprio arquiteto. Sentar com
um engenheiro no trabalho de verdade — o engenheiro dirigindo, o arquiteto navegando — dá ao
arquiteto a sensação completa do sistema e dá ao engenheiro o raciocínio do arquiteto, no momento em
que ele se aplica. A tarde de Renata com Ícaro, na seção anterior, foi pareamento; calibrou a ela
e, pelas perguntas que ela fez em voz alta, ensinou a ele como ela pensa sobre transações. O ofício
de fazer isso bem é o assunto da aula 12 de `architect-communication`.

## Ler código, e revisões

Ler também conta. Um arquiteto que lê alguns pull requests por semana, nas partes do sistema onde
moram as decisões importantes, vê como o desenho está saindo na prática. O objetivo é ler, não
aprovar: um arquiteto que precisa aprovar todo pull request se tornou o caminho crítico por outra
via, e a aula 16 põe isso fora do papel. Comentários são bem-vindos; uma catraca, não. Como
transformar uma revisão em ensino é a aula 11 de `architect-communication`.

O que ler não dá é o atrito. Um pull request mostra a mudança e esconde os 41 minutos de espera
pelos testes. Por isso ler complementa escrever, em vez de substituir.

---
title: Quando um processo não basta
version: 1
---

Tudo nesta aula até aqui rodou num processo só do boxoffice. Recursos em tempo real são onde um serviço
sente primeiro a diferença entre um processo e vários, porque uma conexão é uma coisa que vive em
exatamente um deles.

## Dois processos, e a notícia ainda chega

Ponha duas cópias do boxoffice atrás de um balanceador de carga. O fluxo de um visitante cai numa cópia, e
a venda que o altera cai na outra. **Com o desenho da seção 03 isso já funciona**: as duas cópias rodam
`LISTEN availability`, o PostgreSQL entrega toda notificação às duas, e cada hub avisa os próprios
visitantes. É o retorno de tirar a notícia do banco e não do `Sell`. Um hub alimentado direto pelo `Sell`
avisaria só os visitantes da cópia que fez a venda.

Há limites que vale conhecer antes de se apoiar nisso:

- **Toda cópia segura uma conexão para o `LISTEN`**, tirada do pool para sempre.
- **Uma notificação não fica guardada.** Uma cópia cuja conexão de escuta caiu por dez segundos perdeu dez
  segundos de notícias, e nada vai reenviá-las. O `listen` do boxoffice retorna no primeiro erro, e o
  `main` registra o erro e segue em frente. Uma versão de produção o roda num laço: espera um pouco,
  reconecta, roda `LISTEN` de novo. Como cada mensagem é o número inteiro de lugares, a próxima venda
  acerta todas as telas.
- **O conteúdo fica abaixo de 8000 bytes**, e todas as notificações dividem uma fila só no banco. Para um
  número por evento isso sobra; para um feed de toda mudança em toda tabela, a ferramenta é a replicação
  lógica, não o `NOTIFY`.

Quando a notícia não vem do banco, como uma mensagem de chat que nunca é gravada, os processos precisam de
um broker entre eles: o pub/sub do Redis é a escolha comum, e o engine Redis do Centrifugo é esse mesmo
arranjo, já pronto.

## O que conexões abertas custam

| o que cresce | o que acontece | o que fazer |
|---|---|---|
| conexões por processo | cada uma é uma goroutine, um socket e seus buffers; o processo fica sem descritores de arquivo antes de tudo | subir o limite de arquivos abertos, e medir a memória por mil conexões |
| conexões quietas | um proxy ou balanceador de carga fecha uma conexão que não envia nada durante o seu tempo limite de ociosidade, muitas vezes um minuto | mandar algo com regularidade: uma linha de comentário `: ping` num fluxo de server-sent events, um frame de ping num WebSocket |
| leitores lentos | os buffers deles enchem | descartar mensagens, como o hub da seção 03 faz, ou fechar a conexão e deixar que ela reconecte |
| deploys | toda conexão de um processo parado é fechada de uma vez | os clientes reconectam com um atraso aleatório, para que dez mil não cheguem no mesmo segundo |

**Os dois handlers do boxoffice não mandam nada entre uma venda e outra**, então atrás de um proxy com
tempo limite de ociosidade de sessenta segundos, a página de um evento parado perderia a conexão a cada
minuto. O `EventSource` reconectaria e a página receberia o número atual de novo, então quem olha não vê
nada errado; mas cada reconexão é uma requisição nova e uma nova leitura do evento. Um ticker no `select`
do handler que escreve `: ping` a cada trinta segundos evita isso, e o `EventSource` ignora as linhas que
começam com dois-pontos. O Melody manda ping a cada 54 segundos por padrão e o Centrifugo a cada 25, por
esse motivo.

**Descartar é certo para estado e errado para mensagens.** A seção 03 descarta quando um observador fica
para trás porque o próximo número substitui o perdido. Um chat não pode fazer isso: uma mensagem descartada
é uma frase perdida. Ali as escolhas são um buffer maior, fechar a conexão lenta para que ela reconecte e
busque o que perdeu, ou um sistema que guarda histórico para recuperar, que é um dos motivos para recorrer
ao Centrifugo.

## Escolhendo

Para o boxoffice, a versão escrita à mão tem o tamanho certo: uma fonte de notícias, um tipo de mensagem,
um punhado de handlers, e um banco que já espalha as notícias. **Recorra ao Centrifugo**, ou a um serviço
parecido, quando as conexões passam das dezenas de milhares, quando os deploys não podem derrubá-las, ou
quando os clientes precisam de histórico e presença. **Recorra ao Melody** quando o formato é salas de
pessoas conversando entre si e as conexões podem viver no seu processo. E antes de qualquer um deles,
pergunte se um polling a cada trinta segundos resolveria; para a maioria das telas que ninguém fica
encarando, resolveria.

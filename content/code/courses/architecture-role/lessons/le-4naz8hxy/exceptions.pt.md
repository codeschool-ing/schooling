---
title: Exceções, adoção e aposentadoria de um padrão
version: 1
---

Há dois jeitos comuns de errar com exceções, e eles apontam em direções opostas. Um padrão sem jeito de
pedir exceção não impede exceções: elas acontecem do mesmo jeito, em código que ninguém menciona, e o
padrão perde a autoridade na primeira vez que alguém percebe. Um padrão com exceção fácil e informal,
concedida no corredor, vira sugestão. **O caminho do meio é tratar uma exceção como uma pequena decisão
com motivo, data e dono**, e ler a lista delas como evidência sobre o padrão.

## Pedindo

A exceção que a verificação da seção anterior mostra começou como um pedido de Bruno Farias. Payments
precisava da foto do comprovante de entrega para anexá-la à fatura do embarcador. O `api.py` de Tracking
não a oferecia; o `models.py` de Tracking a tinha numa classe chamada `DeliveryProof`. Tracking tinha a
mudança no plano para fevereiro, e fazê-la antes atrasaria o feed de posição ao vivo prometido aos
embarcadores.

O pedido na Carreto são cinco perguntas, respondidas num chamado curto que o dono do padrão lê:

1. Qual padrão, pela redação dele na lista.
2. O que você quer fazer no lugar, com a precisão de um diff: `invoice.py` importa
   `carreto.tracking.models`.
3. Por que o padrão não pode ser cumprido agora, e quanto custaria cumpri-lo.
4. Até quando, como uma data, e o que acontece nessa data.
5. Quem fecha: uma pessoa, não um time.

As respostas do Bruno couberam em oito linhas. O custo de cumprir o padrão agora era atrasar um
compromisso de outro time; a data era 31 de março de 2027, um mês depois da mudança planejada por
Tracking; e quem fecharia era Ícaro Nunes, o desenvolvedor júnior de Payments que tinha escrito
`invoice.py`. Pôr um nome júnior no acompanhamento foi de propósito: Ícaro conversaria com Tracking
sobre como deveria ser a nova função no `api.py`, o que ensina mais sobre fronteiras do que ler o
padrão.

## Concedendo

Quem decide é o dono do padrão, e para a regra dos imports é a Renata. Ela faz três perguntas suas:

- O estrago está contido? Um arquivo lê uma classe e não escreve nada de volta. Se Tracking renomear
  `DeliveryProof`, um import quebra num lugar que todo mundo vê, o que é muito diferente do job de
  repasses quebrando em silêncio numa sexta.
- A data é de verdade? "Quando Tracking tiver tempo" não é data. Um mês depois de uma mudança que já
  está no plano de Tracking é.
- Tem uma pessoa? Uma exceção cujo dono é "Payments" não tem dono quando a data chega.

Concedida, a exceção vai **para onde a verificação a lê**: a entrada em `EXCEPTIONS` no
`check_imports.py`, adicionada num pull request com o link do chamado. Esse lugar importa mais do que
parece. Uma exceção registrada numa planilha ao lado do código pode vencer enquanto o código continua
fazendo a coisa liberada; uma exceção registrada na verificação vence sozinha, porque no dia seguinte à
data o build fica vermelho. **Ninguém precisa lembrar de uma exceção que o build lembra.**

A Carreto pôs mais dois limites: **uma exceção dura no máximo seis meses e pode ser renovada uma vez.**
Depois de um ano, ou o código cumpre o padrão ou o padrão muda. Uma exceção renovada quatro vezes não é
exceção. É um segundo padrão que ninguém escreveu.

## O que a lista de exceções diz

Nos primeiros seis meses depois que os nove padrões foram publicados, os donos receberam 11 pedidos.
Concederam 8 e recusaram 3; cada recusa veio com um jeito mais barato de cumprir o padrão, como ler um
valor por uma função de `api.py` que já existia e que quem pediu não tinha achado.

Dos 8 concedidos, 4 foram fechados antes da data com uma correção no código, 2 foram renovados uma vez,
1 é o do Bruno e continua aberto, e 1 mudou um padrão. Esse último era um job noturno de Payments que
concilia os repasses com o extrato do banco parceiro. Ele pediu para ficar livre de `/healthz` e
`/metrics`, e o motivo era bom: um job que roda vinte minutos às 2 da manhã e termina não tem
requisições para relatar nem nada para um health check sondar. O pedido mostrou que o padrão tinha sido
escrito pensando em serviços web. Paula o reescreveu como duas regras, uma para serviços e outra para
jobs agendados, que informam ao monitor de jobs como terminou cada execução.

**Uma exceção cujo motivo valeria para todo caso do mesmo tipo é uma descoberta sobre o padrão, não
sobre o time.** A regra foi escrita contra uma imagem do sistema, e pedidos como esse mostram onde a
imagem estava errada. Um dono que os recusa protege a redação e perde as pessoas.

## Medindo a adoção

Um padrão foi adotado quando o código o segue, não quando foi anunciado. A medida é a mesma verificação
que o faz valer, rodada sobre tudo e contada, mais as exceções ainda abertas. Na revisão de seis meses
a tabela da Renata tinha uma linha por padrão; quatro delas eram assim:

| padrão | cumprem | exceções abertas | seis meses antes |
|---|---|---|---|
| `/healthz` e `/metrics` (serviços) | 14 de 14 serviços | 0 | 9 de 14 |
| nenhum dado pessoal em linhas de log | 13 de 14 serviços | 1 | não medido |
| implantado pelo pipeline compartilhado | 13 de 14 serviços | 1 | 11 de 14 |
| imports pelos módulos `api` (o monólito) | 6 restantes na base | 1 | 23 na base |

Duas coisas nessa tabela valem ser copiadas. **A última coluna é o que a torna uma medida**: sem um
ponto de partida, 13 de 14 pode ser avanço ou recuo. E a linha que diz "não medido" seis meses antes é
honesta sobre quando o scanner de logs foi ligado, em vez de fingir que o número sempre foi conhecido.

Meça o custo de uma verificação, além da cobertura. Uma verificação que reprova um build pelo motivo
errado ensina as pessoas a rodar o build de novo sem ler a mensagem, e depois de alguns alarmes falsos
ela deixa de ser lida mesmo quando está certa. A Carreto contou os builds que cada verificação reprovou
e quantas dessas reprovações estavam erradas; a primeira versão do scanner de logs marcava todo número
de onze dígitos como CPF, inclusive referências de pedido, e foi corrigida na segunda semana.

## Aposentando um padrão

Padrões se acumulam se nada os tira. Foi assim que a página da wiki chegou a 61. **Um padrão deveria
sair quando o motivo dele saiu**, e a coluna de motivo da primeira seção desta aula é o que torna essa
pergunta rápida de responder.

Antes dos nove, a Carreto tinha uma regra de 2019: toda chamada HTTP entre serviços passa por uma
biblioteca cliente interna, `carreto-http`. O motivo era bom na época: a biblioteca acrescentava
retentativas e um id de requisição a cada chamada. Em 2026 o template de serviço já configurava
retentativas e tracing para todo serviço, o único mantenedor da biblioteca tinha saído, e os times
carregavam uma dependência sem manutenção para cumprir uma regra cujo propósito já era atendido em outro
lugar.

Aposentá-la levou três passos, e nenhum deles foi apagar uma linha de uma página:

1. Anunciar uma data, e dizer o que substitui a regra: as configurações de retentativa e tracing do
   template.
2. Tirar a verificação nessa data, para nenhum build reprovar por uma regra que não existe mais.
3. Marcar como substituído o ADR que a criou (aula 5), apontando para o novo, para que alguém que
   ache `carreto-http` num serviço antigo saiba por que ela está ali e que pode sair.

Antes de tirar uma regra cujo motivo não está escrito, descubra por que ela foi feita. É a cerca de
G. K. Chesterton: uma cerca atravessando uma estrada cujo propósito você não enxerga não prova que ela
não tem nenhum. A coluna de motivo existe para essa investigação levar um minuto em vez de uma tarde.

Hoje a Carreto revisa a lista a cada seis meses. Cada dono diz, para cada padrão seu, manter, mudar ou
aposentar, e a resposta vai para o mesmo registro de ADRs de todas as outras decisões. **A lista
continua com nove porque algo sai sempre que algo entra**, e essa rotação é o sinal de que os padrões
ainda descrevem o sistema que as pessoas estão construindo.

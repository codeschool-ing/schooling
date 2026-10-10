---
title: Por que a decisão precisa ficar escrita
version: 1
---

A objeção aparece de duas formas. "O código é a documentação", de engenheiros que já viram wikis
demais apodrecerem; e "todo mundo aqui sabe por que fizemos assim", de times pequenos o bastante
para isso ainda ser verdade. **As duas descrevem o presente, e um registro de decisão é escrito para
o futuro**: para um leitor que não está na sala, talvez nem tenha entrado na empresa ainda, e que vai
estar prestes a mudar algo que não entende. Três leitores em especial, e mais um benefício que é do
próprio arquiteto.

## O leitor futuro, prestes a consertar alguma coisa

Dezoito meses depois do registro 7, uma engenheira nova no Payments encontra um job noturno que
pergunta à API do Tracking pelas entregas provadas. Todo pagamento já chega por evento. O job não
encontra nada há semanas. Parece sobra de alguma migração, e apagá-lo é uma tarde de trabalho bem
satisfatória.

Sem o registro, o job some. Com ele, a engenheira lê uma consequência: *a checagem noturna é o único
jeito de percebermos um evento perdido.* O job não encontra nada há semanas porque eventos se perdem
raramente, e a noite em que ele encontra alguma coisa é a de um motorista que de outro jeito ficaria
sem receber. **O código mostra o que o job faz; só o registro diz o que daria errado sem ele.**

A cerca de Chesterton é o nome antigo disso: não tire uma cerca antes de saber por que ela foi
posta. Um registro de decisão é o bilhete pregado na cerca. Custa uma frase nas consequências,
escrita por quem sabia.

## A reunião que volta

Toda empresa tem uma decisão que é discutida todo trimestre. Na Carreto, antes do log, era a consulta
periódica. Alguém novo perguntava no fórum de arquitetura por que o Payments não pedia ao Tracking as provas
novas a cada poucos minutos. As pessoas que lembravam da última discussão a reconstruíam, em parte e
cada uma de um jeito, e uma hora depois a reunião terminava onde a anterior tinha terminado.

Com um registro, a conversa é mais curta e melhor. A Kátia Lemos levantou a consulta periódica de
novo para outra integração, e a Renata apontou o registro 7. **A pergunta virou: o que mudou neste
contexto?** Se nada mudou, a decisão continua, e a hora é poupada. Se algo mudou (a API do Tracking
ficou barata de chamar, digamos, ou a folga do orçamento aumentou), reabrir a decisão é legítimo, e o
jeito de fazer isso é um registro novo que substitui o antigo, com o contexto novo escrito.

Essa é a diferença entre revisitar uma decisão e rediscuti-la do zero. **Revisitar começa pelo que
mudou; rediscutir começa do nada**, e só a primeira é possível quando a primeira decisão foi escrita.

A conta é fácil de fazer para o seu time. Um fórum de oito pessoas gastando uma hora numa pergunta já
resolvida custa oito horas de engenharia. Duas vezes por ano durante três anos, são 48 horas, contra
as duas ou três horas que levou para escrever o registro e revisá-lo.

## Quem entra no mês que vem

Uma engenheira nova aprende uma base de código lendo-a, e o código responde *o quê* com fluência e
*por quê* jamais. **Um log de decisões é a história mais curta que existe de um sistema**: uma lista
numerada das escolhas que o moldaram, cada uma com as forças do seu momento. Ler o log da Carreto desde o primeiro registro leva cerca de uma hora. No fim, uma pessoa nova sabe por que o monólito
ainda é dono do módulo de cargas, por que o Tracking tem banco próprio e por que os pagamentos são
movidos por um evento, coisas que antes levavam meses de perguntas.

Isso muda também o que uma pessoa nova se atreve a fazer. Quem sabe por que uma estrutura existe
consegue propor mudá-la com um argumento de verdade. Quem não sabe ou deixa tudo como está, ou muda
coisas que tinham motivo, e nenhuma das duas coisas ajuda.

## Quem decidiu

O quarto leitor é aquele para quem o título desta aula aponta. A aula 3 fez do arquiteto o
responsável pelas escolhas estruturais: quem responde por elas quando dão errado. **Um registro é o
que permite julgar uma decisão pelo que se sabia quando ela foi tomada, e não pelo que aconteceu
depois.**

Decisões são tomadas sob incerteza, e algumas boas decisões terminam mal. Se a abordagem por eventos
do registro 7 um dia causar um incidente porque o broker perdeu mensagens de um jeito que ninguém
previu, o registro mostra que o time sabia que eventos se perdem, construiu a checagem noturna
exatamente para esse caso e escreveu isso. A análise depois do incidente pode então fazer a pergunta
útil, que é se a checagem funcionou, em vez da inútil, que é quem escolheu eventos. Sem o registro,
quem escreve a história é a visão em retrospecto, e ela sempre soube de tudo.

## O que não escrever

Um log que registra tudo não é lido por ninguém. **O teste é o da primeira seção desta aula: portas
de mão única, e decisões que chegam além de um time.** A biblioteca de log do Pricing não precisa de
registro; o armazenamento de posições do Tracking precisa, porque custa caro reverter mesmo ficando
dentro de um time; o registro 7 precisa, pelos dois motivos.

Dois hábitos matam um log mais rápido do que registros faltando:

- **Escrever registros depois que o código foi integrado**, como papelada. Os contextos passam a
  defender o que já foi construído, as opções rejeitadas são inventadas para parecer justas, e os
  leitores aprendem que o log é enfeite.
- **Deixar registros virarem documentos de desenho.** Uma proposta é o lugar certo para um argumento
  longo, e `architect-communication` aula 2 ensina a escrever uma. O registro é a página que sobra
  quando o argumento termina: o que foi decidido, por quê, e quanto custa.

## Onde os registros moram

A Carreto guarda cada registro no repositório do sistema que ele mais muda, num diretório
`docs/adr/`, um arquivo Markdown por registro, revisado em pull requests como código. Uma decisão que
abrange a empresa inteira vai para um repositório combinado, e a Renata mantém ali um índice curto
que lista os registros de todos os repositórios, para que o log possa ser lido num lugar só.

**A responsabilidade do arquiteto é o log como um todo**: que as decisões significativas estejam
nele, que sejam revisadas pelas pessoas que elas afetam, que registros substituídos apontem os
sucessores e que uma pessoa nova consiga encontrá-lo na primeira semana. A aula 8 retoma a questão
mais ampla de manter a documentação viva, da qual o log de decisões é a parte que envelhece melhor,
porque ninguém espera que ele seja mantido atual.

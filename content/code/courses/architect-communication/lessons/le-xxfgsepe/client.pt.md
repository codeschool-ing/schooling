---
title: Escrever para um cliente
version: 1
---

**Um cliente lê cada frase como um compromisso, então uma mensagem para um cliente diz só aquilo de que você
tem certeza, o que isso significa para ele e o que acontece em seguida.** Dentro da Marola, um
palpite errado numa thread de chat é corrigido na mensagem seguinte. Enviado à Boa Praça, o mesmo
palpite pode ser citado de volta numa revisão de contrato seis meses depois.

## O que muda quando o leitor está do lado de fora

Quatro coisas são diferentes quando o leitor é um cliente:

1. **Compromissos obrigam.** "Vai estar corrigido até segunda" é uma promessa com data. Se você não
   tem certeza, diga o que vai fazer até segunda, e não o que vai ser verdade até lá.
2. **Não se especula sobre causas.** "Achamos que pode ser o banco de dados" vira, na caixa de
   entrada de Tânia, "a Marola nos disse que foi o banco de dados". Diga o que você sabe: o que
   aconteceu, e quando vai saber mais.
3. **Nada de nomes internos, nada de culpa.** Tânia não sabe quem é Paulo e não deveria descobrir
   numa mensagem sobre um incidente. "Um processo agendado do nosso lado" é exato e completo.
4. **Uma voz só.** A Boa Praça tem uma pessoa na Marola que é dona do relacionamento, e tudo passa
   por ela ou chega a ela. Dois engenheiros escrevendo separadamente para o mesmo cliente produzem
   duas versões da verdade.

## Uma mensagem, reescrita

Um engenheiro de logística escreveu este rascunho para Tânia depois que as entregas a três lojas da
Boa Praça atrasaram numa terça de manhã:

> Oi Tânia, desculpa pela manhã de hoje!! Tivemos um problema em que o job de recálculo de zonas
> que o Paulo roda não terminou a tempo porque o BD estava sobrecarregado, acho que por causa da
> nova config da réplica, então as rotas foram geradas atrasadas. Amanhã deve estar ok, estamos
> investigando.

Cada frase carrega um risco: um colega nomeado, uma causa chutada, uma tecnologia que não significa
nada para ela e "amanhã deve estar ok", que é uma promessa que ninguém pode cumprir com certeza. O
que Lívia mandou no lugar:

> Tânia, hoje de manhã as entregas a três das suas lojas (Boa Viagem, Casa Forte e Olinda)
> chegaram com 40 a 70 minutos de atraso. A causa foi um atraso no nosso planejamento de rotas, que
> já está funcionando normalmente. Estamos verificando por que isso aconteceu e vamos mandar o que
> encontrarmos, e o que vamos mudar, até quinta às 12:00. Se as entregas de amanhã forem afetadas
> de qualquer forma, eu ligo para você antes das 7:00. — Lívia

O que ela faz: **o efeito para Tânia** primeiro, com as lojas e o tamanho do atraso; a causa no
nível que se sabe com certeza; um compromisso que Lívia consegue cumprir (mandar as conclusões até
um horário, e não garantir um resultado); e o que Tânia vai ouvir se acontecer de novo, antes de as
lojas dela abrirem.

## O que não vai para um cliente

- **Outros clientes.** Nunca "tivemos o mesmo problema com outra rede no mês passado".
- **Detalhes de segurança.** Se um incidente envolve acesso ou dados, a mensagem passa por quem é
  responsável pela comunicação de segurança na Marola, e diz o que o cliente precisa fazer, nada
  sobre como.
- **Divergências internas.** "A engenharia queria corrigir isso no trimestre passado, mas produto
  não priorizou" pode ser verdade e nunca é assunto do cliente.
- **Desculpas que admitem o que não está estabelecido.** "Lamentamos que as entregas tenham
  atrasado" é um fato e uma cortesia. "Lamentamos que nossa negligência tenha causado…" é uma
  declaração jurídica.

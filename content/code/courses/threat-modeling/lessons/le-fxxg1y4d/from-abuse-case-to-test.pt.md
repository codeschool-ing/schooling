---
title: Do caso de abuso ao teste
version: 1
---

Um caso de abuso num slide é lido uma vez. Um caso de abuso na suíte de testes é lido toda vez que o
código muda. **O lugar mais barato para pegar uma ameaça é um teste falhando no dia em que alguém
quebra o controle**, e casos de abuso já estão quase no formato de um: um ator, uma ação, e o que o
sistema deveria fazer.

### Escritos como critérios de aceite

Equipes que escrevem funcionalidades como cenários, no formato *dado, quando, então*, podem
escrever casos de abuso do mesmo jeito, ao lado da funcionalidade que eles abusam. A A3 e a A9
viram:

```
Scenario: a patient asks for another patient's exam
  Given patient P1 is signed in
  And exam E2 belongs to patient P2
  When P1 asks for exam E2
  Then the answer is the same as for an exam that does not exist
  And the attempt is recorded with P1's account and the time

Scenario: the phone number is changed
  Given a patient is signed in
  When they change the phone number on their account
  Then the change waits for a code sent to the old number
  And an e-mail tells them the number is being changed
```

Os cenários ficam em inglês aqui porque são a especificação que a suíte executa, e uma suíte em
português os teria em português. São escritos no vocabulário do produto, e esse é o ponto: o dono
do produto consegue lê-los, discordar deles e pô-los na definição de pronto. Nenhum cita uma
técnica de ataque. O primeiro não diz "IDOR" e o segundo não diz "tomada de conta"; dizem o que o
portal precisa fazer, e um teste que confira isso pega a falha seja qual for o caminho até ela.

### Três hábitos que fazem funcionar

1. **Teste a recusa, não só o sucesso.** Uma suíte que só confere que pacientes veem os próprios
   exames passa num portal que mostra os de todo mundo. O caso de abuso acrescenta o teste de que um
   pedido do exame de outra pessoa é recusado.
2. **Torne a recusa indistinguível.** "A mesma resposta de um exame que não existe" é de propósito:
   uma resposta que diz *proibido* conta a quem pediu que o exame E2 existe, o que é uma saída no
   sentido da aula 6.
3. **Registre a tentativa.** Uma recusa que ninguém vê é uma defesa com que ninguém aprende. A
   segunda linha do primeiro cenário é o que deixa o bruno perceber que alguém está testando
   números de exame em ordem.

### De volta ao modelo

As três ameaças novas da seção anterior entram no `threats.csv`, para que a aula 8 dê requisitos a
elas como às outras:

```
(.venv) ana@vm:~/tm/portal-model$ git diff --stat
 threats.csv | 3 +++
 1 file changed, 3 insertions(+)
(.venv) ana@vm:~/tm/portal-model$ tail -n 3 threats.csv
T15,Staff console,S,A former employee signs in months after leaving because nobody switched the account off.
T16,Sign in and book,I,Someone who knows a patient's password keeps reading their agenda and nothing tells the patient another session is open.
T17,Sign in and book,S,Whoever holds a session changes the phone number with no second confirmation and receives the reminders and the password resets.
(.venv) ana@vm:~/tm/portal-model$ cut -d, -f3 threats.csv | tail -n +2 | sort | uniq -c
      2 D
      3 E
      4 I
      2 R
      5 S
      1 T
(.venv) ana@vm:~/tm/portal-model$ git commit -qam 'Add the threats the abuse cases found'
(.venv) ana@vm:~/tm/portal-model$ git log --oneline -2
72b7507 Add the threats the abuse cases found
23e3e45 Draw the console as it is: reachable from the internet
```

Vale olhar de novo a contagem por letra. **Falsificação foi de três para cinco**, e as duas novas são
sobre quem tem uma conta: um ex-funcionário e quem está com a sessão de um paciente. A passada de
STRIDE da aula 3 perguntou com quem um elemento conversa; os casos de abuso perguntaram quem são as
pessoas, e acharam o que a primeira pergunta não tinha como achar.

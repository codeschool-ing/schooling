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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-refusal\" aria-label=\"A recusa que um teste de caso de abuso exige. A paciente P1 pede o exame E2, que é da paciente P2, e, separadamente, um exame que não existe. O portal dá a mesma resposta aos dois, então quem pede não descobre se o E2 existe, e a primeira tentativa é registrada com a conta de P1 e a hora.\"><defs><marker id=\"l07-refusal-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-refusal-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"28.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">P1 pede o E2 (exame de P2)</text><path d=\"M300.0 50.0 L400.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"108.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">P1 pede um exame que não existe</text><path d=\"M300.0 130.0 L400.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-paper-dim)\"></path><rect x=\"400.0\" y=\"65.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a mesma resposta</text><rect x=\"400.0\" y=\"150.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">registrado: a conta de P1 e a hora</text><path d=\"M330.0 62.0 L400.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-amber)\"></path><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nada se aprende</text></svg>", "caption": "Um “proibido” confirmaria que o E2 existe. Responder como para um exame inexistente faz da recusa nada que quem pede possa usar."}
```

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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-by-letter\" aria-label=\"Ameaças em threats.csv por letra do STRIDE depois dos casos de abuso: S 5, T 1, R 2, I 4, D 2, E 3. Falsificação foi de três para cinco, as duas novas sobre quem está com uma conta.\"><rect x=\"80.0\" y=\"30.0\" width=\"60.0\" height=\"140.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">S</text><rect x=\"180.0\" y=\"142.0\" width=\"60.0\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"210.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">T</text><rect x=\"280.0\" y=\"114.0\" width=\"60.0\" height=\"56.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"310.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">R</text><rect x=\"380.0\" y=\"58.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"410.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">I</text><rect x=\"480.0\" y=\"114.0\" width=\"60.0\" height=\"56.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"510.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">D</text><rect x=\"580.0\" y=\"86.0\" width=\"60.0\" height=\"84.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"610.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">S era 3 antes dos casos de abuso; T15 e T17 o fizeram 5</text></svg>", "caption": "O STRIDE perguntou com quem um elemento conversa; os casos de abuso perguntaram quem são as pessoas, e a coluna S cresceu."}
```

---
title: Pegando uma regressão no mesmo dia
version: 2
---

A tabela da última seção foi impressa depois do fato, para uma aula. Em agosto, nada a imprimiu. O
`85dfa4e` entrou no dia 17, e se alguém rodou o conjunto de teste contra ele, a história não diz.
**Uma regressão é achada quando alguém olha, e o único alguém confiável é uma verificação que roda
sozinha.**

## Uma verificação em toda mudança

A verificação é a mesma comparação que a aula 1 usou para decidir se os exemplos ajudavam, apontada
para o outro lado. Antes de uma mudança no prompt entrar, rode o arquivo novo sobre os conjuntos de
teste, rode o arquivo que está valendo agora e compare mensagem a mensagem. Em 17 de agosto o arquivo
valendo era o do `86913c0` e o novo era a reversão:

```
ana@lab:~/triage$ pl compare runs/86913c0.jsonl runs/now.jsonl
runs/86913c0.jsonl       passes 27/40
runs/now.jsonl           passes 24/40
fixed 1, broken 4
broken: t12 t23 t28 t38
sign test on the 5 that changed: p = 0.375
```

Essa saída teria barrado a entrada, ou pelo menos feito alguém se explicar. Quatro mensagens
quebradas e uma consertada, **e ela nomeia cada uma**, então quem fez a mudança começa pelo `t12` em
vez de por uma contagem. O teste do sinal diz 0.375: cinco mensagens mudadas se dividindo quatro a um
não são uma boa evidência de que a reversão era pior. Não são evidência nenhuma de que era melhor, e
ela custou 1855 tokens por execução. Uma trava não existe para decidir essa pergunta sozinha; existe
para que a pergunta seja feita no dia, por alguém que ainda lembra por que fez a mudança.

Uma trava construída sobre isso tem três partes, e nenhuma é engenhosa:

1. **Roda em toda mudança num arquivo de prompt**, antes de a mudança entrar, no que quer que rode
   os seus outros testes. Uma verificação de que alguém precisa lembrar é uma verificação que roda
   nos dias em que essa pessoa lembra.
2. **Roda todo conjunto de teste que o prompt tem**, não só o dev. O `a0f1d2a` custou duas mensagens
   no dev e ganhou uma nos ataques, e uma trava só no dev teria visto só a perda.
3. **Falha em qualquer mensagem quebrada** e imprime os ids, e quem quiser fazer a mudança entrar
   assim mesmo diz por quê no commit. Às vezes quebrar uma mensagem para consertar cinco é certo;
   nunca deveria acontecer sem ninguém notar.

O total é a linha menos útil da saída. Uma mudança pode consertar uma mensagem, quebrar outra e
deixar o total exatamente onde estava, e a linha que importa para uma trava é a `broken`.

## Uma regressão sem diff

A trava compara execuções, e uma execução é mais que o arquivo. Esta é a execução com temperatura 0,8
de antes, contra a execução do mesmo arquivo no padrão:

```
ana@lab:~/triage$ pl compare runs/now.jsonl runs/hot.jsonl
runs/now.jsonl           passes 24/40
runs/hot.jsonl           passes 24/40
fixed 1, broken 1
broken: t31
sign test on the 2 that changed: p = 1.000
```

Os mesmos 24 de 40, uma mensagem consertada e uma quebrada. **O id do prompt é o mesmo nas duas
execuções, e o `git diff` não mostraria nada**, porque a mudança nunca esteve no arquivo. Uma trava
que só roda quando o arquivo do prompt muda nunca a veria, e uma trava que comparasse totais não
veria nada mesmo que rodasse. Esse é o argumento prático para a regra de *O que é uma versão*: quando
todo parâmetro mora no arquivo, toda mudança no que a produção roda é uma mudança no arquivo, e a
trava vê todas.

A aula 15 escreve o que a reversão deveria ter dito, para que a próxima pessoa que deixar os exemplos
mais fáceis de ler, ou os puser de volta, saiba o que foi medido da última vez que isso foi tentado.

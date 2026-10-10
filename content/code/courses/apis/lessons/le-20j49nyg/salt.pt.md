---
title: Salt
version: 1
---

**Um salt é um valor aleatório, diferente para cada senha, guardado junto do hash e misturado antes
do cálculo.** Ele faz a mesma senha produzir um hash diferente em cada linha, e esse é todo o
trabalho dele.

O erro comum é tratar o salt como segredo e depois se preocupar em onde escondê-lo. Ele não é
segredo. Fica no banco ao lado do hash, à vista, e as próximas seções o mostram dentro do próprio
texto guardado. O que ele precisa ser é **único**, e só.

Sem salt, duas contas com a mesma senha têm o mesmo hash. O `sha256sum` da mesma palavra, para dois
usuários:

```
ana@api:~/shelf$ for user in ana bia; do printf %s sunshine | sha256sum; done
a941a4c4fd0c01cddef61b8be963bf4c1e2b0811c037ce3f1835fddf6ef6c223  -
a941a4c4fd0c01cddef61b8be963bf4c1e2b0811c037ce3f1835fddf6ef6c223  -
```

Essa linha diz duas coisas a quem lê a tabela. Ana e Bia escolheram a mesma senha, o que já é um
vazamento. E uma tabela de hashes calculada uma vez, de antemão, a partir de uma lista de senhas
comuns responde às duas linhas por consulta, junto com cada linha de cada outro banco que guardou o
mesmo hash sem salt.

Um hash de senha sorteia um salt novo a cada vez. A mesma palavra, com o hash do bcrypt calculado
duas vezes:

```
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"sunshine", bcrypt.gensalt()).decode())'
$2b$12$vPe9g2i5PwfDp/R1Y3.FVuhpeWirsJXGy.SOIDrvpBoR8I5G6p7Rm
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"sunshine", bcrypt.gensalt()).decode())'
$2b$12$OOIkx1PD0sVFPNws/R5jc.2XyB28n4CgB6mh.d1b7rLQ8/q2zPl.2
```

Dois textos diferentes para uma senha. Os 22 caracteres depois de `$2b$12$` são o salt, que a
próxima seção desmonta, e são eles que fazem os dois diferirem. Uma tabela calculada de antemão passa
a ser inútil, porque precisaria de uma entrada para cada salt possível, e um palpite testado contra a
linha da Ana não diz nada sobre a da Bia.

**Um salt não deixa um palpite mais caro.** O SHA-256 com salt continua a mais de um milhão de
palpites por segundo contra uma linha; o salt só faz cada linha ser um trabalho à parte. O custo por
palpite é o fator de custo, e os dois trabalham juntos.

Três regras, e as bibliotecas desta lição seguem todas por você:

| regra | por quê |
|---|---|
| um salt novo para cada senha, inclusive uma trocada | um salt antigo reaproveitado são duas linhas com um trabalho só |
| aleatório, do gerador seguro do sistema operacional | um salt previsível pode ser calculado de antemão |
| nunca o nome nem o e-mail do usuário | é igual em todo site, e conhecido antes de qualquer vazamento |

Escrever o próprio esquema de salt é onde essas regras se quebram, então não escreva: chame uma
função de hash de senha que sorteia o próprio salt, como fazem todas as das próximas três seções.

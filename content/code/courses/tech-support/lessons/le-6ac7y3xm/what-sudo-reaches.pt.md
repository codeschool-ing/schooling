---
title: O que o sudo alcança
version: 1
---

A Elisa usa o pc1. A pasta dela é fechada para outros usuários, e a conta da própria técnica é recusada como
a de qualquer um:

```
ana@pc1:~$ ls /home/elisa
ls: cannot open directory '/home/elisa': Permission denied
ana@pc1:~$ sudo ls /home/elisa
letter-to-doctor.txt
```

Com `sudo`, a recusa some. É para isso que serve uma conta de administrador: o próximo chamado pode ser uma
pasta com permissões quebradas, e a técnica precisa conseguir chegar nela. Isso também quer dizer que **as
permissões protegem a Elisa de todo mundo, menos do suporte**.

E o comando acima já mostrou algo que não era da conta da técnica. Ninguém abriu o arquivo, e só o nome dele
já diz algo sobre a saúde da Elisa. Pela LGPD, dados sobre saúde são *dados pessoais sensíveis*, com regras
mais rígidas que o resto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma caixa grande, o que o sudo alcança: toda pasta pessoal, toda cópia impressa, toda caixa de correio num servidor de e-mail, todo log. Dentro dela uma caixa pequena, o que o chamado precisa: a pasta, a fila em questão.\"><defs><marker id=\"rc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que o sudo alcança</text><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda pasta pessoal</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda cópia impressa</text><text x=\"36\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda caixa de e-mail num servidor</text><text x=\"36\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo log</text><rect x=\"430\" y=\"70\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que o chamado precisa</text><text x=\"446\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pasta, a fila em questão</text></svg>", "caption": "A permissão é a caixa grande e o trabalho é a pequena. Nada no computador mantém o técnico dentro da caixa pequena: só o próprio técnico."}
```

A regra que vem daí se chama **necessidade de saber**: olhe o que o chamado precisa, e só isso. Um chamado
sobre disco cheio precisa de tamanhos, o `du` da aula 3, não de nomes de arquivos. Um chamado sobre as
permissões de uma pasta precisa daquela pasta. Se o trabalho pode ser feito sem listar os arquivos de uma
pessoa, ele é feito sem listá-los.

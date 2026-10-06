---
title: Uma rede plana
version: 1
---

Antes de escrever uma regra, veja o que a rede faz sem nenhuma. O firewall do laboratório, `fw`, une
os quatro segmentos e, como foi montado, encaminha tudo. É assim que muitas redes pequenas rodam de
verdade: um roteador que conecta as coisas e um plano que ninguém escreveu.

O `probe` é um pequeno comando do laboratório que tenta abrir uma conexão com uma máquina e uma porta
e diz numa palavra o que aconteceu: **open** (algo respondeu), **refused** (a máquina respondeu que
nada escuta naquela porta) ou **blocked** (nada voltou, que é a cara de um firewall descartando a
tentativa). Aqui ele roda de três lugares:

```
ana@outside:~$ probe www:80 db:5432
www:80                 open
db:5432                open
ana@www:~$ probe db:5432 db:22 laptop:22
db:5432                open
db:22                  refused
laptop:22              refused
ana@laptop:~$ probe www:80 db:5432
www:80                 open
db:5432                open
```

Leia como um atacante leria, uma linha de cada vez.

**Da internet, `db:5432` está aberto.** O banco da loja responde a um estranho. Nada na localização
dele impede isso: o único motivo para esse banco não estar sendo sondado a cada minuto na vida real é
que redes reais costumam ter NAT no caminho, e a primeira leitura desta aula disse que isso não é um
controle que alguém projetou.

**Do `www`, tudo também é alcançável.** `db:22` e `laptop:22` dizem `refused`, o que só quer dizer que
essas máquinas não rodam nada na porta 22; a rede em si entregou a tentativa. Se o `www` fosse
comprometido, o atacante dele conseguiria testar todas as portas de todas as máquinas da empresa, e a
rede levaria cada tentativa.

**Do notebook do escritório, o banco está aberto.** Talvez de propósito, talvez por acidente; ninguém
decidiu nem uma coisa nem outra.

Isso é uma **rede plana**: toda máquina alcança todas as outras em todas as portas. É conveniente, não
quebra nada, e transforma uma máquina comprometida numa empresa comprometida, porque o próximo passo
do atacante, chamado **movimento lateral**, não tem nada no caminho.

---
title: Ainda não é backup, e agora dá para dizer exatamente por quê
version: 1
---

A aula oito disse que sincronizar não é fazer backup e deu a grade. Esta aula forneceu o
mecanismo, então a afirmação pode ser feita com precisão.

**Um backup é uma cópia que não muda quando o original muda. Sincronia é um mecanismo cujo
propósito inteiro é que a cópia mude quando o original muda.** Não são duas qualidades da mesma
coisa; são opostos que por acaso produzem os dois uma segunda cópia.

## As três falhas, nomeadas

- **Uma exclusão se propaga.** Em segundos, para todo aparelho. A lixeira a segura por trinta dias
  e depois ela se foi de todo lugar de uma vez.
- **O estrago se propaga.** Um arquivo criptografado por ransomware é um arquivo que mudou, então
  ele é enviado e empurrado adiante — e um arquivo corrompido é enviado com a mesma fidelidade.
- **A conta é um ponto único.** Suspensa, comprometida, ou fechada por alguém que a divide com
  você, e todo aparelho perde a mesma pasta junto.

Nenhuma dessas é defeito de projeto. As três são o projeto funcionando exatamente como pretendido.

## O que resgata em parte, e até onde

O **histórico de versões** é a defesa de verdade, e os três o têm:

| | guarda |
|---|---|
| **OneDrive** | 30 dias de versões no pessoal, mais no empresarial, e uma detecção de ransomware com reversão |
| **Google Drive** | 30 dias ou 100 versões, o que vier primeiro, salvo se uma versão for marcada para manter |
| **iCloud Drive** | 30 dias para arquivos apagados; versões por arquivo só em aplicativos que suportam |

**Trinta dias é o formato de tudo isso**, que é a mesma figura que a aula oito chamou de mínimo
que vale ter. Então sincronia mais histórico de versões é genuinamente uma defesa contra as duas
primeiras linhas daquela grade — desde que alguém perceba dentro de um mês.

O que não é defesa contra a terceira: uma conta que se vai leva o próprio histórico junto.

## O arranjo que de fato está certo

O mesmo que a aula oito descreveu, com a pasta sincronizada ocupando um dos papéis:

- **a cópia de trabalho** — a sua máquina, com a pasta sincronizada nela;
- **a segunda cópia** — o serviço, que está fora de casa por construção e cobre perfeitamente uma
  máquina roubada ou queimada;
- **a terceira cópia** — um disco externo, desconectado entre os backups, que é o único dos três
  que uma exclusão, um ransomware ou uma conta fechada não alcançam.

**A sincronia ganha a linha do meio e não consegue ganhar a de baixo.** Essa é a versão precisa da
frase, e é por isso que esta aula termina onde as duas anteriores terminaram.

## E um ajuste que vale mudar hoje

Seja qual for o serviço: **ache o alerta de ransomware ou de exclusão em massa e garanta que ele
está ligado.** O OneDrive o tem por padrão; o Drive e o iCloud mandam e-mail sobre atividade
incomum. É a única coisa entre uma hora ruim e a janela de trinta dias se fechando sem ninguém
perceber.

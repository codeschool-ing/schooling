---
title: O sintoma, nas palavras do sistema
version: 1
---

O Daniel, do financeiro, escreve: *Não consigo salvar o relatório de setembro na pasta compartilhada.* A
pasta compartilhada é `/srv/shared`, e o relatório dele é `september.csv`. Reproduzido como o Daniel,
aula 2:

```
ana@pc1:~$ sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/
cp: error writing '/srv/shared/reports/september.csv': No space left on device
```

A mensagem merece ser lida devagar. **`No space left on device`** não é a opinião do programa de cópia; é
a resposta do sistema operacional, repassada palavra por palavra. Uma mensagem muitas vezes nomeia a
própria camada, e esta aponta para o sistema. Ainda é uma pista e não um achado, então as camadas acima
dela são checadas antes, rapidamente.

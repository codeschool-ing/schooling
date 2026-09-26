---
title: Um runbook para uma fila de impressão parada
version: 1
---

Quando uma impressora relata um defeito, como papel preso, o sistema de impressão para a fila dela e **a
deixa parada** depois de o defeito ser resolvido. Os usuários veem uma impressora que funciona e não
imprime nada. O runbook do escritório para isso:

**Runbook: uma fila de impressão que parou**

*Quando usar*: "a impressora está ligada mas nada sai", numa impressora, para todos que a usam.

*Antes de começar*: acesso ao computador que guarda a fila, com `sudo`. Diga ao usuário que você está
checando a fila, e peça para ele não mandar o documento de novo: provavelmente ele já está esperando.

1. `lpstat -p QUEUE`. **Esperado**: `disabled`, com um motivo. Se disser `idle` ou `printing`, o problema
   não é este: pare e use o método geral, aula 1.
2. `lpstat -o QUEUE`. Anote quantos trabalhos estão esperando; eles vão sair quando a fila voltar.
3. **Peça** a quem está perto da impressora para resolver o motivo, e para confirmar: o papel preso
   tirado, papel colocado, a tampa fechada. Não continue até a pessoa dizer que está feito.
4. `sudo cupsenable QUEUE`, depois `lpstat -p QUEUE`. **Esperado**: `idle` e `enabled`.
5. `lpstat -o QUEUE`. **Esperado**: os trabalhos que esperavam sumiram, impressos. Peça ao usuário para
   confirmar que o papel saiu.

*Pare e escalone se*: a fila parar de novo em minutos com o mesmo motivo (a impressora em si está com
defeito: o fornecedor da impressora), ou se o motivo citar qualquer coisa que não seja papel, toner ou uma
tampa.

*Desfazer*: `sudo cupsdisable QUEUE` para a fila de novo.

*Dono*: o service desk. *Última revisão*: quando foi seguido pela última vez e algo estava diferente.

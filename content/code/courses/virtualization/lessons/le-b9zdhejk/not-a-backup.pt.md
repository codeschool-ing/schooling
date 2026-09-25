---
title: Um snapshot não é um backup
version: 1
---

Tudo nesta aula morava no mesmo disco que o convidado: dentro do `vm1.qcow2`, ou num arquivo ao lado dele
que não pode ser lido sem ele. Então um snapshot protege contra **as suas próprias mudanças**, e contra
nada que aconteça com o disco:

| o que dá errado | um snapshot salva você? |
|---|---|
| uma atualização quebra o sistema | sim: reverta |
| uma configuração que você testou piora as coisas | sim: reverta |
| o disco do host falha | não: o snapshot estava nele |
| o arquivo do convidado é apagado ou corrompido | não: o snapshot estava nele, ou depende dele |
| um ransomware cifra os arquivos do host | não |

Um **backup** é uma cópia em outro lugar: outro disco, outro servidor, outro prédio. A regra de sempre são
três cópias, em dois tipos de mídia, uma delas fora do escritório, e o `vzdump` do Proxmox e o servidor de
backup da aula 6 existem exatamente para isso. Um snapshot muitas vezes é *parte* de fazer um, porque dá
ao backup um disco que para de mudar enquanto é copiado, e o snapshot é fundido depois.

Quando um cliente diz "temos snapshots, então temos backup", a tabela acima é a conversa a ter.

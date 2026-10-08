---
title: Recuperando um arquivo apagado
version: 1
---

O `fls -d` lista só as entradas apagadas, e o `istat` lê o inode por trás de uma delas, aqui o número 24. A saída
é longa, e o `sed -n` guarda as linhas que importam:

```
root@soc:~/case# fls -r -d -p work.dd
r/r * 24:	exports/contacts-2026-08.csv
root@soc:~/case# istat work.dd 24 | sed -n '1,2p;7,8p;10,19p'
inode: 24
Not Allocated
Flags: Extents, 
size: 313

Inode Times:
Accessed:	2026-10-07 21:05:18.000000000 (-03)
File Modified:	2026-10-07 21:05:18.000000000 (-03)
Inode Modified:	2026-10-07 21:05:18.000000000 (-03)
File Created:	2026-10-07 21:05:18.000000000 (-03)
Deleted:	2026-10-07 21:05:18 (-03)

Direct Blocks:
1561 
```

`Not Allocated`: o inode está livre, então um arquivo novo pode reutilizá-lo a qualquer momento. `size: 313`.
Cinco horários, com o último, `Deleted`, definido quando o arquivo foi removido. E no fim, **`Direct Blocks:
1561`**: o inode ainda diz onde os dados estão. No ext4 isso não é garantido. Quando o kernel apaga um arquivo,
ele normalmente limpa a lista de blocos no inode, e a recuperação passa a ser procurar o conteúdo no espaço
livre, o que se chama **carving**. O `debugfs` apagou este sem limpá-la, que é o caso fácil, e bom para aprender.

O `icat` lê o conteúdo para o qual um inode aponta, alocado ou não, e o escreve:

```
root@soc:~/case# icat work.dd 24 > recovered-contacts.csv
root@soc:~/case# cat recovered-contacts.csv
client,contact,email
acme-logistica,Gustavo Alves,gustavo@acme-logistica.example
bento-advogados,Caio Prado,caio@bento-advogados.example
casa-verde,Fabiana Reis,fabiana@casa-verde.example
delta-engenharia,Denise Rocha,denise@delta-engenharia.example
estrela-saude,Fabiana Reis,fabiana@estrela-saude.example
root@soc:~/case# sha256sum recovered-contacts.csv
c09cf34009ad7edafeb846e9f6a43df1076ed79371520d2f90cf8d9d2f7428fe  recovered-contacts.csv
```

A exportação de contatos voltou: cinco empresas clientes, um contato em cada, e um endereço de e-mail. **Isso são
dados pessoais**, e é o tipo de achado de que trata a aula 21. O hash do arquivo recuperado vai para o registro
ao lado do da imagem, com o inode de onde veio, para qualquer pessoa conseguir recuperá-lo de novo a partir da
imagem e obter o mesmo arquivo.

O que a recuperação não diz é **quem** apagou o arquivo, nem **por quê**. O sistema de arquivos registrou quando;
a resposta para quem está nos logs do servidor ou com os usuários dele, e no laboratório foi você, no papel de
alguém da equipe arrumando as coisas. Um achado afirma o que a evidência mostra e para aí.

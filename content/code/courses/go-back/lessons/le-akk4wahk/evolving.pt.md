---
title: Mudando um contrato sem quebrar quem chama
version: 1
---

O contrato vai mudar. Os leitores da porta foram feitos com o `seats.proto` de hoje, e no mês que vem a
bilheteria quer que os eventos tragam o local. **Clientes e servidores são publicados em momentos
diferentes**, então por um tempo um leitor antigo conversa com um servidor novo, ou um leitor novo com um
servidor antigo. O Protocol Buffers foi desenhado exatamente para isso, e o desenho se apoia nos números
de campo da seção 04.

## Acrescentando um campo

Uma nova versão do contrato acrescenta `venue` como campo 5. Para ver o que um leitor antigo faz com
ele, codifique um evento com o contrato novo e decodifique com o antigo:

```
ana@vm:~/boxoffice$ sed 's/  int32 sold = 4;/  int32 sold = 4;\n  string venue = 5;/' proto/seats.proto > /tmp/seats_v2.proto && grep -A6 '^message Event' /tmp/seats_v2.proto
message Event {
  int32 id = 1;
  string name = 2;
  int32 seats = 3;
  int32 sold = 4;
  string venue = 5;
}
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2 venue: "Main Hall"' | protoc -I/tmp --encode=boxoffice.v1.Event /tmp/seats_v2.proto | protoc --decode=boxoffice.v1.Event proto/seats.proto
id: 1
name: "Jazz at the Docks"
seats: 120
sold: 2
5: "Main Hall"
```

**O contrato antigo leu todo campo que conhecia e guardou o que não conhecia como `5: "Main Hall"`**, um
número de campo e um valor. Nada falhou. Em Go, um campo assim vai parar no `unknownFields` da mensagem,
a contabilidade da seção 05, e é até repassado se a mensagem seguir adiante. O outro sentido também
funciona: um leitor novo que recebe uma mensagem antiga, sem campo 5, encontra `venue` no valor zero,
`""`. **É por isso que acrescentar um campo é sempre seguro**, e por isso um leitor deve tratar um zero
como possivelmente "não enviado".

## As regras que mantêm isso seguro

| mudança | segura | por quê |
|---|---|---|
| acrescentar um campo com número novo | sim | leitores antigos o guardam como desconhecido; leitores novos veem zero nas mensagens antigas |
| renomear um campo, mesmo número | sim, no fio | só o número viaja; os nomes no Go gerado mudam, então o código que os usa tem de mudar também |
| remover um campo | sim, se o número dele for reservado | `reserved 5;` impede alguém de reusar o número para outra coisa |
| mudar o número de um campo | **não** | para todo leitor existente é outro campo |
| reusar o número de um campo removido | **não** | mensagens antigas em filas e logs seriam lidas com o significado novo |
| mudar o tipo de um campo | quase sempre não | alguns pares compartilham a codificação, a maioria não, e o resultado é lixo em vez de erro |
| renomear ou remover um `rpc` | **não** | clientes antigos chamam um método que não existe mais e recebem `Unimplemented` |

**Os números são o contrato; os nomes são documentação.** Um campo removido de uma mensagem deve deixar
para trás um `reserved` com o número e o nome antigo, para que ninguém, daqui a um ano, dê àquele número
um significado novo no qual mensagens antigas seriam decodificadas.

## Quando a mudança não tem como ser compatível

Algumas mudanças não podem ser feitas com segurança: um campo que precisa mudar de tipo, uma chamada cujo
significado muda. É para isso que existe o `v1` em `package boxoffice.v1`. **Uma mudança que quebra vira
`boxoffice.v2`, um serviço novo ao lado do antigo**, e o servidor atende os dois até o último cliente
antigo sumir. O caminho de toda chamada inclui o pacote, `/boxoffice.v1.Seats/GetEvent` no log da seção
08, então as duas versões nunca colidem.

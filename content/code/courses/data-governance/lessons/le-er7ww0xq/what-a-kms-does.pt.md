---
title: O que um serviço de gestão de chaves faz
version: 1
---

A ideia cabe numa frase: **a chave fica dentro do serviço, e o que sai é o resultado de usá-la.**
Uma aplicação que precisa de um CPF cifrado envia o CPF e o nome de uma chave; o serviço o cifra e
devolve o texto cifrado. Para lê-lo, uma aplicação com direito de decifrar devolve o texto cifrado
e recebe o CPF. Nenhuma das duas jamais tem a chave.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l4-kms\" aria-label=\"O site envia um CPF e o nome de uma chave ao serviço de gestão de chaves e recebe texto cifrado, que guarda no banco. O suporte envia o texto cifrado e recebe o CPF. A chave fica dentro do serviço; nenhuma seta a leva para fora. Toda requisição vai para o log de auditoria.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"dg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o site</text><text x=\"95.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy: encrypt</text><rect x=\"20.0\" y=\"170.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">suporte</text><text x=\"95.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy: decrypt</text><rect x=\"285.0\" y=\"60.0\" width=\"150.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">serviço de chaves</text><rect x=\"310.0\" y=\"102.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ipe-cpf</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a chave nunca</text><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sai</text><rect x=\"550.0\" y=\"50.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banco</text><text x=\"625.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vault:v2:…</text><rect x=\"550.0\" y=\"170.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">log de auditoria</text><path d=\"M170.0 66.0 L283.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CPF</text><path d=\"M283.0 104.0 L170.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cifrado</text><path d=\"M95 50 L95 22 L625 22 L625 48\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-wire)\"></path><text x=\"360.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda o texto cifrado</text><path d=\"M170.0 186.0 L283.0 176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cifrado</text><path d=\"M283.0 196.0 L170.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CPF</text><path d=\"M435.0 190.0 L548.0 195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><text x=\"492.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo uso</text></svg>", "caption": "A chave fica no serviço. O que sai é o resultado de usá-la, e todo uso é registrado."}
```

Cinco coisas decorrem desse arranjo, e cada uma é a resposta a uma etapa da seção anterior:

- **A chave não pode ser copiada por quem a usa**, porque ninguém a tem. Um token de aplicação
  vazado pode ser revogado; uma chave vazada tem de ser tratada como copiada para sempre.
- **Usar é uma permissão.** Cifrar e decifrar são operações separadas, então são concessões
  separadas: o site cifra e nunca decifra, o suporte decifra e nunca cifra, ninguém além do
  administrador da chave lê a configuração dela. A seção 7 escreve essas políticas.
- **Todo uso fica registrado.** O serviço vê toda requisição, então registra quem pediu para
  decifrar o quê, e quando — exatamente a pergunta de uma investigação depois de um vazamento.
  Seção 8.
- **As chaves mudam sem o dado se mover.** Um texto cifrado diz qual versão da chave o fez, então
  uma versão nova cifra a partir de hoje enquanto as antigas ainda decifram. Seção 10.
- **Uma chave pode ser destruída**, deliberadamente, e tudo o que foi cifrado só com ela fica
  ilegível em todo lugar de uma vez, backups incluídos. A seção 13 usa isso de propósito.

## O que ele não faz

**Ele não decide quem deve poder decifrar.** Ele aplica a política que alguém escreve; uma
política que dá decifrar a toda aplicação é uma chave entregue a todo mundo, com mais latência.

**Ele não protege o dado que a aplicação já decifrou.** O suporte decifra um CPF para lê-lo a um
cliente ao telefone, e daquele momento em diante ele é texto claro na tela do suporte. O serviço
estreita quem consegue transformar texto cifrado em texto claro; as aulas 1 e 2 continuam decidindo
quem são essas pessoas.

**Ele vira aquilo de que tudo depende.** Se o serviço cai, nada é cifrado nem decifrado. É por isso
que as próximas seções gastam tempo com como ele sobe, como ele é lacrado e quem tem os meios de
destrancá-lo.

## Onde as chaves moram afinal

Em algum lugar o próprio serviço precisa proteger as chaves dele em repouso. Um KMS de nuvem as
guarda em **módulos de segurança de hardware** (HSMs) — dispositivos feitos para que uma chave
gerada dentro deles possa ser usada mas nunca exportada. O OpenBao, rodando numa máquina comum,
cifra o próprio armazenamento com uma chave que é, ela mesma, dividida entre várias pessoas, e essa
é a primeira coisa que o laboratório faz com ele.

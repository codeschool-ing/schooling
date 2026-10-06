---
title: O dia em que uma chave vaza
version: 1
---

**Os três erros terminam do mesmo jeito: uma chave que precisa ser tratada como conhecida por outra
pessoa. O que acontece a seguir depende muito menos da criptografia do que de alguém saber o que essa
chave protege e já tê-la trocado alguma vez.**

## Antes do dia: um inventário

Uma chave que ninguém listou é uma chave que ninguém vai trocar. A Vereda mantém uma tabela, revista a
cada seis meses, com uma linha por chave: o que ela protege, onde mora, quem pode usá-la, como é
trocada e quando foi trocada pela última vez. A tabela é curta para uma clínica, umas vinte linhas, e
a maioria veio de aulas anteriores: as chaves TLS da aula 10, a chave de webhook da aula 6, as chaves
SSH da aula 12, as frases-senha do LUKS e a chave mestra do KMS da aula 14, o segredo compartilhado do
RADIUS da aula 16.

A última coluna é a que mais importa. **Uma chave que nunca foi trocada é uma que ninguém sabe
trocar**, e a primeira tentativa não deveria acontecer no meio de um incidente. Trocar com
periodicidade, mesmo quando nada vazou, é como o procedimento é testado.

## No dia

1. **Estabeleça o que a chave protege e desde quando ficou exposta.** Para a chave do portal, isso foi
   o `git log -S`: cinco semanas, e todo clone feito nesse intervalo.
2. **Emita uma chave nova e implante-a.** Onde assinaturas ou MACs são conferidos, aceite as duas
   chaves por um curto período de sobreposição, para que mensagens já a caminho ainda sejam
   verificadas, e depois pare de aceitar a antiga. Um identificador de chave em cada mensagem, como o
   `kid` de um JSON Web Token, torna essa sobreposição explícita.
3. **Revogue a chave antiga em todo lugar onde ela é reconhecida**: no provedor que a emitiu, numa CRL
   para um certificado (aula 9), no `authorized_keys` e no `allowed_signers` para chaves SSH, no KMS
   para uma chave de dados.
4. **Cuide do que a chave antiga já protegia.** Dados cifrados com ela são cifrados de novo com a
   nova, como foi feito com a exportação da agenda. O que foi assinado com ela continua assinado; o que
   muda é que uma assinatura feita depois do vazamento não merece mais confiança, então carimbos de
   tempo e logs decidem o que manter.
5. **Olhe para trás.** Os logs do provedor, a trilha de auditoria do KMS e os logs de acesso mostram se
   a chave antiga foi usada de algum lugar de onde não deveria. Se foi, o incidente deixou de ser só
   sobre a chave, e pela LGPD um vazamento de dados pessoais tem prazo próprio para ser comunicado.
6. **Corrija a causa**: o scanner que teria recusado o commit, o nonce tirado de um estado que uma
   restauração voltou, a função caseira trocada pela biblioteca.

## O que revogar significa, chave por chave

| chave | revogar significa |
| --- | --- |
| uma chave de API ou de webhook de um provedor | gerá-la de novo no provedor |
| a chave privada de um certificado TLS | chave e certificado novos, o antigo revogado na AC |
| uma chave SSH | tirar a linha dela de todo `authorized_keys` e `allowed_signers` |
| uma chave de dados em cifragem em envelope | cifrar de novo os dados dela e apagar a chave embrulhada |
| uma chave mestra do KMS | rotacioná-la; desativar a versão antiga quando nada depender dela |
| uma frase secreta de Wi-Fi | uma frase nova no ponto de acesso e em todo aparelho |

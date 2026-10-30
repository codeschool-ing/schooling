---
title: Um segredo nas configurações, e por que ele é o problema
version: 1
---

**Um workflow que implanta no Azure age como uma identidade no Microsoft Entra ID**: um app registration
com o seu service principal, com um papel no grupo de recursos da loja. As lições 7 e 9 de
`azure-foundations` montam essa identidade e esse papel. Esta lição é sobre a outra metade: como o workflow
prova, na hora da execução, que é aquela identidade.

Durante anos a resposta foi um **client secret**. Você criava um no app registration, copiava com os ids do
tenant e do cliente num JSON e colava o JSON nos segredos do repositório:

```yaml
# the old way: a secret that lives as long as somebody remembers it
- uses: azure/login@v2
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

Funciona, e tudo nele é o problema.

- **O segredo é a identidade.** Quem tem a string é o service principal, de qualquer máquina, até ela
  expirar. Ela não sabe que era para um workflow de um repositório.
- **Ele vive meses ou anos**, porque girá-lo depende de alguém se lembrar, e o prazo máximo que a Microsoft
  permite é longo o bastante para esquecer.
- **Ele viaja.** Esteve na área de transferência de alguém, talvez num chat, talvez numa linha de log que um
  passo imprimiu por engano. Cada cópia vale tanto quanto o original, e nenhuma aparece em lugar nenhum.
- **Revogá-lo é um palpite sobre o que quebra.** Nada registra quais workflows o usam.

Um segredo mascarado nos logs e guardado num cofre cifrado é melhor do que um num arquivo, e continua sendo
uma credencial de vida longa que um passo do seu próprio workflow pode vazar. O que tira o problema é não
guardar nenhuma.

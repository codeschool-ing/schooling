---
title: "Product flavours: dois apps a partir de um código"
version: 1
---

**Um flavour é uma versão do app que difere no que ele é, enquanto um tipo de build difere em como
ele é construído.** O planner ganha dois: `play`, o que o Google Play distribui, e `direct`, o mesmo
app entregue como arquivo no site do próprio planner, para estudantes cujo celular não tem a Play
Store. Dois flavours vezes dois tipos de build dão quatro variantes, e o Gradle dá nome a cada uma
juntando os dois: `playDebug`, `playRelease`, `directDebug`, `directRelease`.

Os dois flavours compartilham cada linha de código. O que os separa está no arquivo de build da seção
02: `direct` tem o seu próprio `applicationIdSuffix`, para que os dois possam ser instalados num
celular, e cada um define o seu valor de uma constante numa classe gerada:

```
ana@vm:~/planner$ find app/build/generated -name BuildConfig.java | sort
app/build/generated/source/buildConfig/direct/debug/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/direct/release/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/play/debug/com/example/planner/BuildConfig.java
app/build/generated/source/buildConfig/play/release/com/example/planner/BuildConfig.java
ana@vm:~/planner$ grep -h -E "APPLICATION_ID|UPDATES_FROM" app/build/generated/source/buildConfig/direct/debug/com/example/planner/BuildConfig.java
  public static final String APPLICATION_ID = "com.example.planner.direct.debug";
  public static final String UPDATES_FROM = "the planner's website";
```

**`BuildConfig` é gerada por variante**, quatro vezes, e o app lê `BuildConfig.UPDATES_FROM` como
qualquer constante. No `direct`, o planner pode dizer "as atualizações vêm do site do planner" e
consultar essa página; no `play`, a loja o atualiza e o planner não diz nada sobre isso. O
`APPLICATION_ID` ao lado é aquele com que esta variante se instala, sufixos incluídos.

## Quando um flavour é a ferramenta certa, e quando não é

**Flavours servem para o que se decide na hora do build e muda conforme a distribuição**: de onde vêm
as atualizações, com qual servidor um build de teste conversa, qual biblioteca de pagamento uma loja
exige. Um flavour também pode trazer arquivos inteiros só dele: uma pasta `src/direct/` ao lado de
`src/main/` guarda código ou recursos que só as variantes `direct` recebem, mesclados sobre `main`
do jeito que o `values-pt` da aula 1 foi mesclado sobre `values`.

**Flavours não servem para o que o estudante escolhe**, como um plano premium: dois apps para a mesma
pessoa são duas instalações, dois conjuntos de dados e duas páginas na loja. Isso pertence ao app em
execução. E cada flavour dobra as variantes a construir e testar: duas dimensões de três flavours
cada, com dois tipos de build, dão dezoito. Uma equipe só acrescenta um quando a diferença não cabe
em nenhum outro lugar.

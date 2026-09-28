---
title: No celular
version: 1
---

A outra metade do piso é a largura. Em 320 pixels, um celular estreito, a tabela do loanbook era mais larga
que a tela, então a página rolava para o lado, e o axe apontou um botão pequeno demais para apertar com
segurança. O passo 12 resolveu os dois com um bloco de CSS:

```
ana@laptop:~/loanbook$ git show --format=%s HEAD -- static/style.css
Fit the table on a phone

diff --git a/static/style.css b/static/style.css
index 937365a..5659798 100644
--- a/static/style.css
+++ b/static/style.css
@@ -9,3 +9,9 @@ input, button { font: inherit; padding: 0.25rem 0.5rem; }
 #message:empty { display: none; }
 #message { padding: 0.5rem; border-left: 4px solid #1a5fb4; background: #eef3fb; }
 
+@media (max-width: 36rem) {
+  thead { display: none; }
+  tr, th, td { display: block; }
+  tr { border-bottom: 1px solid #767676; padding: 0.5rem 0; }
+  th, td { border: 0; padding: 0.25rem 0; }
+}
```

Abaixo de 36rem, uns 576 pixels no tamanho de fonte padrão, a tabela deixa de ser tabela. A linha de
cabeçalho some, e cada linha e célula vira um bloco, então cada item vira um pequeno cartão: o nome, o
status, a ação, um embaixo do outro. Nada rola para o lado, e os botões ganham a largura toda da tela.

Duas coisas no jeito como isso foi feito valem copiar. **O ponto de quebra está em `rem`, não em pixels**,
então quem configurou uma fonte maior recebe o layout de celular antes, que é o que precisa. E **o HTML não
mudou**: a mesma `table` serve aos dois layouts, então o leitor de tela da seção anterior ainda
anuncia uma tabela com cabeçalhos numa tela grande.

A verificação é rápida. Abra as ferramentas de desenvolvimento do navegador, escolha uma largura de 320, e
use a página. Depois faça o mesmo num celular de verdade, se tiver, porque um polegar de verdade encontra o
que um simulado não encontra. No loanbook, o briefing da aula 4 exigia isso: *uma professora consegue
emprestar um item pelo celular.*

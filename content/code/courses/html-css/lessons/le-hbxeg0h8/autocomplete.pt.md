---
title: Ajudando o navegador a preencher o formulário
version: 1
---

Os navegadores lembram o que as pessoas digitam em formulários, e preenchem um nome, um endereço ou um número de cartão quando reconhecem um campo que pede um deles. Se reconhecem ou não depende do formulário. **O atributo `autocomplete` diz exatamente que informação um campo quer**, a partir de uma lista fixa de nomes:

```schooling-example
{"language": "html", "file": "delivery.html", "parts": [
 {"code": "<label for=\"fullname\">Name</label>\n<input id=\"fullname\" name=\"fullname\" autocomplete=\"name\">", "note": "`name` é o nome completo da pessoa, num campo só."},
 {"code": "<label for=\"mail\">Email</label>\n<input id=\"mail\" name=\"mail\" type=\"email\" autocomplete=\"email\">", "note": "O type confere o formato; `autocomplete` diz que valor salvo vai aqui."},
 {"code": "<label for=\"street\">Street and number</label>\n<input id=\"street\" name=\"street\" autocomplete=\"address-line1\">", "note": "Endereços vêm em linhas e partes: `address-line1`, `address-level2` para a cidade, `postal-code`."},
 {"code": "<label for=\"zip\">CEP</label>\n<input id=\"zip\" name=\"zip\" inputmode=\"numeric\" autocomplete=\"postal-code\">", "note": "Dígitos com um formato, então texto com teclado numérico em vez de `type=\"number\"`, como a seção 04 disse."},
 {"code": "<label for=\"code\">Code from the SMS</label>\n<input id=\"code\" name=\"code\" inputmode=\"numeric\" autocomplete=\"one-time-code\">", "note": "O celular pode oferecer o código da mensagem que acabou de chegar."}
]}
```

Os atributos `name` desse formulário, `fullname` e `zip`, são o que o servidor recebe, e podem ser o que o servidor esperar. Os valores de `autocomplete` são um vocabulário que o navegador conhece, e não são texto livre: `autocomplete="cep"` não significa nada para navegador nenhum.

## Por que é mais que uma comodidade

Para a maioria das pessoas o preenchimento automático economiza alguns segundos. Para quem tem uma deficiência motora, digitar é lento e cansativo, e para quem tem uma deficiência de memória ou de aprendizagem lembrar um endereço é a parte difícil; a WCAG tem um critério, *Identify Input Purpose*, que pede exatamente este atributo nos campos que coletam informações sobre o usuário. E para qualquer pessoa no celular ele é a diferença entre terminar um formulário e abandoná-lo.

**`autocomplete="off"` é quase sempre ignorado em logins**, de propósito: os navegadores concluíram que bloquear gerenciadores de senha fazia as pessoas escolherem senhas piores. Para um campo em que um valor lembrado está de fato errado, um código de uso único ou uma caixa de busca, `off` continua sendo um pedido razoável.

---
title: O servidor confere tudo de novo
version: 2
---

Tudo nesta aula até aqui acontece no navegador do leitor, e isso tem uma consequência que é questão de segurança, e não de comodidade. **O navegador pertence ao leitor.** A validação nativa é um serviço à pessoa honesta que preenche o formulário; não é um guarda do servidor.

A demonstração é curta. Salve uma cópia de `order.html` como `unchecked.html` e acrescente um atributo ao formulário, `novalidate`, que diz ao navegador para não conferir nada antes de enviar: `<form action="order" method="post" novalidate>`. Depois preencha com bobagem e envie:

```
ana@laptop:~/site$ probe unchecked.html fill '#email' 'not an address' fill '#copies' -40 send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=&email=not+an+address&cep=&copies=-40&title=
```

Um email que não é email, menos quarenta exemplares, um nome vazio e um título vazio, tudo enviado como um POST comum. Ninguém precisa editar a página para fazer isso: qualquer pessoa pode abrir o DevTools e apagar o `required` de um campo, ou dispensar o navegador e enviar a requisição com uma ferramenta de linha de comando, digitando o corpo que quiser. Até onde o servidor consegue saber, cada requisição que recebe pode ter vindo de qualquer lugar.

## O que o servidor faz a respeito

Este curso é sobre a página, e o servidor é assunto dos cursos de back-end, mas o princípio é curto o bastante para dizer aqui, porque é o que as pessoas erram:

- **Toda regra do formulário é conferida de novo no servidor**, com o código do próprio servidor: campos obrigatórios presentes, números na faixa, formatos certos. Um valor que falha é recusado com um erro que a página consegue mostrar, e nada é gravado.
- **O servidor nunca confia num valor por ele estar numa lista que a página ofereceu.** Um `<select>` com duas lojas não impede ninguém de enviar `shop=qualquer-coisa`; o servidor confere contra a própria lista.
- **O que chega é dado, nunca código nem marcação.** Um campo de nome pode conter `<script>`, e tudo o que o servidor puser depois de volta numa página precisa ser escapado para aparecer como texto. `security-fundamentals` é onde isso, o cross-site scripting, é ensinado direito.

Então por que validar no navegador? Porque é **instantâneo e na língua do leitor**, e pega os erros honestos, que são quase todos, antes de uma ida e volta ao servidor. As duas verificações têm trabalhos diferentes: a do navegador ajuda as pessoas, e a do servidor protege o sistema. Um formulário precisa das duas, e só a do servidor é confiável.

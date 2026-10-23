---
title: Duas verificações com dois trabalhos diferentes
version: 1
---

"Isso já é validado no formulário" é uma das frases mais comuns numa revisão de código, e ela
mistura duas verificações que parecem iguais e fazem trabalhos diferentes. **A validação no
navegador serve a quem preenche o formulário. A validação no servidor serve ao sistema.** Um
formulário precisa das duas, por motivos diferentes, e nenhuma substitui a outra.

### Para que serve a verificação do navegador

Um paciente se cadastrando no portal da Vereda digita um nome, um endereço de e-mail e uma data de
nascimento. Se o endereço não tem `@`, o melhor momento para dizer isso é com o cursor ainda na
caixa: sem ida e volta ao servidor, sem recarregar a página, sem perder o que foi digitado. O HTML
entrega isso quase de graça. `required`, `maxlength`, `type="email"`, `type="date"` com `max`, e
`pattern` fazem o navegador recusar o envio e apontar o campo.

É um benefício real, e é todo de **usabilidade**. Deixa o formulário mais rápido de preencher,
ajuda quem usa leitor de tela a achar o problema quando o erro está ligado ao campo, e poupa o
servidor de responder requisições que iam falhar de qualquer jeito. Nada disso é um controle,
porque **o navegador pertence a quem envia a requisição**, não à Vereda.

### Para que serve a verificação do servidor

O servidor é o único lugar por onde passa toda requisição, venha de quem ou do que vier. A
verificação dele é a que decide o que é guardado, e o resto do sistema depende dela. A aula 2
construiu exatamente esse tipo de verificação, numa fronteira só.

| | no navegador | no servidor |
|---|---|---|
| a quem serve | a quem está digitando | ao sistema e a todos cujos dados ele guarda |
| quando roda | antes de a requisição sair, e só num navegador que a execute | em toda requisição, venha de onde vier |
| quem controla | quem controla o navegador | a Vereda |
| se faltar | um formulário mais lento e mais chato | dados errados ou nocivos no banco |
| dá para pular? | sim, enviando a requisição sem o formulário | não, é onde a requisição chega |

A última linha é a que esta aula prova, na próxima seção, com um comando. O resto da aula trata de
manter as duas verificações em sintonia, porque um navegador que aceita 120 caracteres enquanto o
servidor recusa 61 é um formulário que joga o paciente num erro que ele não tinha como evitar.

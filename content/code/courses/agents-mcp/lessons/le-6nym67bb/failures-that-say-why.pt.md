---
title: Falhas que dizem por quê
version: 1
---

As duas chamadas que falharam na captura da seção 04 voltaram diferentes das da aula 13.

**`M-9999`** recebeu *"Error executing tool get_order: no order M-9999; check the number on the confirmation email"*. O servidor da aula 13 respondeu à mesma chamada com *"Error executing tool get_order"* e nada mais, porque a função dele deixou o `LookupError` escapar e o SDK trata qualquer exceção sobre a qual não foi avisado como queda: traceback para o log, uma frase genérica para o cliente. Aqui o `get_order` captura a falha que espera e levanta `ToolError` com uma mensagem escrita para quem a lê. É o único tipo de exceção cujo texto o SDK repassa, e é o padrão certo: uma exceção inesperada pode levar uma string de conexão ou um caminho de arquivo, e isso não pertence ao contexto de um modelo.

**`1043`** recebeu a mensagem de validação: o padrão que devia ter batido. A função nunca rodou e o banco nunca foi tocado. Um modelo a quem se diz *"String should match pattern '^M-[0-9]{4}$'"* tem o que precisa para se corrigir, e a mesma regra estava no esquema que ele recebeu, então na maior parte das vezes ele nem chega lá.

A regra é a da aula 4: **um erro é um resultado, e deve dizer o que falhou**. O SDK traça a linha num lugar útil, entre falhas que você esperava e para as quais escreveu uma mensagem, e falhas que não esperava, cujos detalhes ficam no servidor.

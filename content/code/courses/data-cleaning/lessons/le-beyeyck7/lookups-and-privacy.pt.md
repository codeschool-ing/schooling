---
title: O que uma consulta envia
version: 1
---

O arquivo de clientes tem CEP para quase todo mundo, e há serviços web públicos que recebem um CEP e
devolvem a rua, o bairro e a cidade. Chamar um deles para cada cliente parece o enriquecimento
óbvio. **Esta aula não faz isso, e nada nesta seção foi executado.** Os motivos são o ponto.

**Um CEP enviado a um serviço web é dado pessoal saindo da empresa.** Sozinho, um CEP reduz uma
pessoa a uma rua ou um prédio, e a requisição ainda leva o horário, o endereço de rede da empresa e,
se o código percorre os clientes, a ordem em que eles aparecem. Pela LGPD, entregar dados de
clientes a um terceiro precisa de base legal e tem de estar coberto pelo que a empresa disse aos
seus clientes. É uma pergunta para quem responde pela proteção de dados, antes da primeira
requisição, não depois da centésima.

Mesmo onde é permitido, uma chamada de API tem três propriedades que um arquivo local não tem:

- **Ela muda.** A mesma requisição no mês que vem pode devolver outra resposta, e uma análise que
  não pode ser refeita com as mesmas entradas não pode ser conferida.
- **Ela falha.** Um tempo esgotado, um limite de requisições ou um serviço desligado viram vazios,
  e vazios vindos de um enriquecimento são o problema da aula 3 num lugar novo.
- **Ela não deixa registro** a menos que você crie um. Que versão do serviço respondeu, em que dia, é
  exatamente a procedência que a seção anterior pediu.

Então o padrão seguro, quando dado de fora é mesmo necessário, é o que o laboratório já segue:

1. **Prefira um arquivo de referência baixado a uma consulta por registro.** O IBGE publica os seus
   códigos como arquivos, e diretórios de CEP também são distribuídos como arquivos. Um arquivo é
   buscado uma vez, não manda nada sobre os seus clientes, e pode ser guardado junto da análise.
2. **Quando uma consulta for inevitável, mande o mínimo possível**: um CEP e nunca um nome, um
   e-mail ou um código de cliente.
3. **Guarde o que voltou, com a data**, e enriqueça a partir da cópia guardada. A análise passa a
   depender de um arquivo que você guarda, não de um serviço que você não controla.

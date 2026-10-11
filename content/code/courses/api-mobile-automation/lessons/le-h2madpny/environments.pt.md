---
title: O ambiente do laboratório
version: 1
---

**Um ambiente é um conjunto de variáveis com nome, e trocá-lo aponta as mesmas requisições para
outro servidor.** Um time costuma ter vários: `lab` para um notebook, `staging` para o servidor de
teste compartilhado, às vezes um por desenvolvedor. As requisições continuam as mesmas e só os
valores mudam. A lista suspensa no canto superior direito do Postman diz qual está ativo, e *No
environment* quer dizer que nenhum está.

Este curso precisa de um, chamado `lab`. Abra o seu editor e salve como `postman/lab.postman_environment.json`:

```json
{
  "name": "lab",
  "values": [
    {"key": "baseUrl", "value": "http://localhost:8080", "type": "default", "enabled": true},
    {"key": "clientId", "value": "ci-tests", "type": "default", "enabled": true},
    {"key": "clientSecret", "value": "ci-secret", "type": "secret", "enabled": true},
    {"key": "token", "value": "", "type": "secret", "enabled": true}
  ],
  "_postman_variable_scope": "environment"
}
```

`name` é o que a lista mostra. `values` guarda as variáveis, cada uma com `key`, `value`, `type` e
`enabled`, que permite desligar uma variável sem apagá-la. `_postman_variable_scope` diz a quem
importa que este arquivo é um ambiente, e não uma coleção. O jq diz se o arquivo é JSON válido, o
que vale perguntar de qualquer arquivo editado à mão antes de entregá-lo a outro programa:

```
ana@laptop:~/boxoffice$ jq empty postman/lab.postman_environment.json && echo valid JSON
valid JSON
```

`jq empty` lê um arquivo e não imprime nada quando ele é interpretado sem erro, então o `echo` só
roda quando isso acontece. As variáveis, uma por linha:

```
ana@laptop:~/boxoffice$ jq -r '.values[] | [.key, .type, .value] | @tsv' postman/lab.postman_environment.json
baseUrl	default	http://localhost:8080
clientId	default	ci-tests
clientSecret	secret	ci-secret
token	secret	
```

## Quatro valores, e por que cada um está aqui

- `baseUrl` é o endereço do boxoffice. Um ambiente para outro servidor seria diferente aqui
  primeiro.
- `clientId` e `clientSecret` são as credenciais do cliente `ci-tests` da lição 3, o que pode ler e
  criar pedidos.
- `token` está vazio. Você o preenche à mão na seção 06, depois de pedir um ao boxoffice, e a lição 5
  troca a mão por um script.

**`secret` esconde um valor na tela. Não protege o arquivo.** O Postman desenha o valor de um secret
como pontinhos e pergunta antes de mostrá-lo, o que o mantém fora de um print ou de uma tela
compartilhada. O arquivo no disco continua dizendo `ci-secret` em texto puro, como a transcrição
mostra. Isso é aceitável aqui por um motivo: o boxoffice imprime o mesmo segredo no próprio código e
só atende as suas próprias requisições. Para uma API de verdade, deixe o valor vazio no arquivo que
você compartilha e digite-o no Postman só na sua máquina, pelos motivos que a lição 3 deu sobre
segredos em arquivos.

O Postman guarda dois valores para cada variável justamente para isso: um que viaja quando o
ambiente é exportado ou compartilhado com um time, e outro que fica no seu computador. O aplicativo
já renomeou essas duas colunas ao longo das versões; o que importa é qual delas um arquivo leva, e um
arquivo exportado leva só a compartilhada.

## Importando

No Postman, **Import**, e então escolha o arquivo ou solte-o na janela. O ambiente aparece na lista
de ambientes da barra lateral; escolha `lab` na lista do canto superior direito para ativá-lo. A
requisição da seção 03 agora pode ser escrita `{{baseUrl}}/v1/shows`, e passar o mouse sobre o nome
mostra o valor que vai ser mandado e o escopo de onde ele veio.

## Quando uma importação falha

O motivo mais comum é uma edição à mão que quebrou o JSON. Esta cópia perdeu a vírgula depois do
primeiro valor:

```
ana@laptop:~/boxoffice$ jq empty postman/lab.postman_environment.json
jq: parse error: Expected separator between values at line 5, column 5
```

O jq diz a linha e a coluna onde desistiu, e a coluna fica depois do erro, não em cima dele: a
vírgula falta no fim da linha 4, e o jq só percebeu no começo do valor seguinte. A mensagem do
próprio Postman costuma ser menos precisa, então rode `jq empty` no arquivo primeiro.

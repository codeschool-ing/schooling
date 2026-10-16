---
title: O Selenium IDE e o arquivo .side
version: 1
---

O Selenium IDE é o gravador do próprio projeto Selenium, e o mais antigo dos três. A maioria das
pessoas o conheceu como extensão de navegador para Chrome e Firefox, as versões 3.x. O repositório
dele no GitHub, lido para esta aula num commit de 6 de outubro de 2026, descreve a versão em
desenvolvimento, `4.0.1-beta.14`, como "an electron application written to enable recording and
playback of selenium scripts" (um aplicativo Electron feito para gravar e reproduzir scripts
Selenium). **Nenhuma das duas foi instalada para este curso, e nada aqui foi gravado por ele**: as
duas precisam de uma tela, e esta máquina não tem. O que vem a seguir sai da leitura do código-fonte
do repositório, e a gravação abaixo foi escrita à mão no formato que o IDE salva.

## Uma gravação é um arquivo JSON

O IDE salva um projeto como um arquivo `.side`, e o arquivo é JSON. O pacote `side-model` dele
declara o formato:

| nível | campos | o que guarda |
|---|---|---|
| projeto | `id`, `version`, `name`, `url`, `urls`, `tests`, `suites`, `plugins` | o endereço onde a gravação começou, e tudo o que está abaixo |
| teste | `id`, `name`, `commands` | uma sessão de gravação |
| comando | `id`, `comment`, `command`, `target`, `targets`, `value` | um passo |
| suíte | `id`, `name`, `persistSession`, `parallel`, `timeout`, `tests` | um grupo de testes, nomeados pelos ids |

Uma suíte nomeia os testes pelo `id`, nunca pelo nome nem pela posição, que é a mesma regra sobre a
qual o próprio catálogo deste curso é construído. Aqui está a gravação da loja, nesse formato: abrir
a loja, pôr uma banana e uma manga, conferir que a cesta diz 2. Ela foi escrita para esta aula, não
salva pelo IDE; os ids são aleatórios, como os do IDE, e um arquivo de verdade traz mais
alternativas em cada lista `targets`:

```json
{
  "id": "8cf56054-7eec-43c5-9b43-e8d168f36162",
  "version": "2.0",
  "name": "quitanda",
  "url": "http://localhost:3000",
  "tests": [{
    "id": "65e32ef8-abf6-4431-8975-904e4df9557e",
    "name": "two fruit",
    "commands": [{
      "id": "316bcab5-aef8-484c-a3a1-9420e14605b6",
      "comment": "",
      "command": "open",
      "target": "/",
      "targets": [],
      "value": ""
    }, {
      "id": "f70a4846-d54b-4100-a710-6991378db0f3",
      "comment": "",
      "command": "setWindowSize",
      "target": "1280x800",
      "targets": [],
      "value": ""
    }, {
      "id": "6cd35dcc-81ce-46a0-b8b1-a6aa61a01518",
      "comment": "",
      "command": "click",
      "target": "css=#card-4821 > button",
      "targets": [
        ["css=#card-4821 > button", "css:finder"],
        ["xpath=//button[@type='button' and text()='Add to basket']", "xpath:attributes"],
        ["xpath=//li[@id='card-4821']/button", "xpath:idRelative"],
        ["xpath=//li/button", "xpath:position"],
        ["xpath=//button[contains(.,'Add to basket')]", "xpath:innerText"]
      ],
      "value": ""
    }, {
      "id": "39bd0e5f-ad46-44d2-b977-3f02e2db2fde",
      "comment": "",
      "command": "click",
      "target": "css=#card-1730 > button",
      "targets": [
        ["css=#card-1730 > button", "css:finder"],
        ["xpath=//li[@id='card-1730']/button", "xpath:idRelative"],
        ["xpath=//li[2]/button", "xpath:position"]
      ],
      "value": ""
    }, {
      "id": "4d488bcb-cd0f-4999-b1c8-3330b1a8749f",
      "comment": "the count was still 0 on the first replay",
      "command": "pause",
      "target": "1000",
      "targets": [],
      "value": ""
    }, {
      "id": "0ef44d89-3d4c-40ac-bd9c-83a5277f7ef5",
      "comment": "",
      "command": "assertText",
      "target": "css=[data-testid=\"basket-count\"]",
      "targets": [
        ["css=[data-testid=\"basket-count\"]", "css:data-attr"],
        ["xpath=//span", "xpath:position"]
      ],
      "value": "2"
    }]
  }],
  "suites": [{
    "id": "e84078bf-3142-47f6-9ad6-b91f1e8d3b7e",
    "name": "Default Suite",
    "persistSession": false,
    "parallel": false,
    "timeout": 300,
    "tests": ["65e32ef8-abf6-4431-8975-904e4df9557e"]
  }],
  "plugins": [],
  "urls": ["http://localhost:3000/"]
}
```

## Como o IDE escolheu esses alvos

Os alvos não são inventados; são o que os construtores de localizadores do IDE dão para esses
elementos quando o código deles é lido contra a página da loja. **Os construtores rodam numa ordem
fixa, e o primeiro nome que acha o elemento sozinho vira o `target`.** A ordem, de
`locator-builders.ts`:

1. `css:data-test-id`, que olha só os atributos `data-test-id` e `data-test`;
2. `id`, `linkText` e `name`;
3. `css:data-attr`, o primeiro atributo `data-*` do próprio elemento;
4. `css:finder`, um caminho CSS montado por uma biblioteca;
5. seis tipos de XPath, terminando em `xpath:position` e `xpath:innerText`.

**A contagem da cesta sai bem.** Ela tem `data-testid`, que o primeiro construtor não procura,
porque a loja escreve sem o segundo hífen, mas o terceiro pega: `css=[data-testid="basket-count"]`.
**O botão da banana sai mal.** Ele não tem `id`, nem `name`, nem atributo `data-*` próprio, então o
primeiro construtor que responde é o `css:finder`. Esse passa o elemento a uma biblioteca,
`@medv/finder` 1.1.3, que tenta o `id` do elemento, depois as classes, depois a tag, e sobe rumo à
raiz até o seletor ser único. O botão não tem nenhum dos dois primeiros, a tag dele casa com nove
botões, e o pai tem um `id`: o aleatório. Daí `#card-4821 > button`, um nome que era verdadeiro
enquanto a gravação era feita e falso no carregamento seguinte.

**Mesmo gravador, mesma página, um nome bom e um quebrado.** A diferença nunca foi a habilidade da
ferramenta. Foi se a página tinha uma alça estável no elemento que o construtor precisava nomear, e
os cartões levam o test id no `li`, um nível acima do botão.

## O que a reprodução faz

O pacote `side-runtime` do repositório reproduz uma gravação pelo `selenium-webdriver`, e o código
dele resolve três coisas que um testador precisa saber:

- **Um `click` espera.** Ele consulta até o alvo ser achado e exibido, por até a espera implícita:
  `5 * 1000` milissegundos por padrão, que o `--timeout` do executor de linha de comando muda.
- **Um `assertText` lê uma vez.** Ele espera o elemento existir, lê o texto uma única vez e
  compara. Se a contagem ainda estiver em `0` naquele instante, o passo falha, e é por isso que a
  gravação acima carrega uma `pause` com um comentário ao lado.
- **As alternativas não são tentadas.** A busca pega o primeiro resultado do `target`, e o laço que
  tentaria os `targets` está comentado, sob o comentário "Fallback selectors are not visible or
  editable enough for now." (os seletores alternativos ainda não são visíveis nem editáveis o
  bastante). A lista fica salva para uma pessoa, que pode escolher outra entrada no IDE quando a
  primeira quebra.

Mais dois pacotes do mesmo repositório ampliam o uso de um arquivo `.side`. O executor de linha de
comando, `selenium-side-runner` (4.0.13), reproduz um projeto sem abrir o IDE, então um servidor de
CI consegue rodá-lo. E um conjunto de pacotes de exportação transforma uma gravação num programa:
JavaScript com Mocha, Python com pytest, Java com JUnit, C# com NUnit ou xUnit, e Ruby com RSpec.
Nenhum dos dois foi rodado aqui. O código exportado mantém os alvos que os construtores escolheram,
então um id aleatório sai do IDE dentro do programa.

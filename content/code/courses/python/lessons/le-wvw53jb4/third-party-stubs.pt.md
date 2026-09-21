---
title: A biblioteca sem anotação, e o silêncio com um motivo
version: 1
---

```python
import yaml
```

```text
error: Library stubs not installed for "yaml"  [import-untyped]
note: Hint: "python3 -m pip install types-PyYAML"
note: (or run "mypy --install-types" to install all missing stub packages)
```

**Leia a dica.** Centenas de bibliotecas têm um pacote `types-…` no PyPI — arquivos de stub,
escritos e mantidos por outras pessoas, que dizem o que as funções da biblioteca recebem e
devolvem. Instale no mesmo ambiente e o erro some com tipos de verdade atrás dele, não com um
silêncio.

## Duas mensagens diferentes

```text
error: Library stubs not installed for "yaml"      [import-untyped]
error: Cannot find implementation or library stub for module named "wibblelib"  [import-not-found]
```

A primeira quer dizer que a biblioteca está instalada e não tem tipos. A segunda quer dizer que o
verificador não acha o módulo de jeito nenhum — em geral um erro de digitação, uma instalação que
faltou, ou um `PYTHONPATH` que o verificador não compartilha.

Ligar `ignore_missing_imports` globalmente silencia as duas, e é por isso que ele pertence a uma
exceção por módulo e não ao topo.

## `py.typed`

Uma biblioteca que publica as próprias anotações põe um arquivo vazio chamado `py.typed` no
diretório do pacote. Sem ele, as anotações no código-fonte são ignoradas mesmo estando bem ali — o
marcador é o autor dizendo "estas são para ser verificadas". Se você publica um pacote, esse
arquivo vazio é o que torna as suas anotações úteis para todo mundo.

## O comentário de silenciar, e as duas maneiras de errar nele

```python
valor = lib_sem_tipo.buscar()  # type: ignore[no-any-return]  # o stub mente sobre o retorno
```

Nomeie o código. Um `# type: ignore` pelado silencia **todo** erro daquela linha, inclusive o que
aparecer no ano que vem quando alguém editá-la.

```python
n: int = "a"  # type: ignore[arg-type]
```

```text
error: Incompatible types in assignment ...  [assignment]
note: Error code "assignment" not covered by "type: ignore" comment
```

O código errado não silencia o erro, e a nota diz isso pelo nome. Esse é o caso bom: um silêncio
estreito que deixa de casar volta a relatar.

## E o silêncio que sobreviveu ao seu motivo

```sh
mypy --warn-unused-ignores app/
```

```text
error: Unused "type: ignore" comment  [unused-ignore]
```

O stub foi corrigido, a biblioteca ganhou anotações, o código mudou — e o comentário continua lá,
silenciando nada e mentindo sobre o estado do arquivo. Esta flag está dentro do `--strict`, e vale
ligar muito antes do resto dele.

---
title: Uma correção automática, julgada pelo pipeline
version: 1
---

A mudança de um bot é uma mudança como qualquer outra, e quem a julga é o pipeline. Esta seção torna
isso concreto na branch com o lock de um mês atrás. Primeiro o pipeline acha o aviso; depois uma
ferramenta que escreve correções por você faz uma; depois o pipeline julga a correção.

### O pipeline acha

Envie a branch para o servidor de CI. Toda branch roda o pipeline:

@@FENCE 1@@

O estágio de composição quebrou o build, com o portão da aula 7 dizendo por quê: o werkzeug 3.1.8 tem
um aviso, PYSEC-2026-4312, com versão corrigida, a 3.1.9. Em 20 de setembro não havia nada a
relatar, porque a correção e o aviso vieram depois. **Um lock que era seguro quando foi compilado não
é seguro para sempre**, e é assim que isso aparece: nada na branch mudou, e o veredito mudou.

### A correção automática

O pip-audit consegue corrigir o que acha. `--fix` move cada pacote vulnerável para a primeira versão
que corrige os avisos dele e grava o resultado de volta nos arquivos de requisitos:

@@FENCE 2@@

Ele relata sucesso, e a linha de versão concorda: `werkzeug==3.1.9`. Leia as duas linhas abaixo dela.
**Esses hashes são do werkzeug 3.1.8**; são os mesmos dois hashes que o lock antigo tinha. O
pip-audit editou a versão e deixou o resto da entrada como estava, e fez mais duas mudanças que
ninguém pediu: acrescentou o werkzeug ao `requirements-dev.txt` como um pin próprio, avisando no
warning, e reescreveu a indentação dos comentários `# via`, que são a maior parte das 40 linhas
alteradas do diff. O `requirements.in` continua sem dizer nada sobre o werkzeug, então a próxima
compilação desfaria a correção.

Nada nessa saída parece errado a menos que você saiba para que serve uma linha de hash. Faça o commit
como um bot faria, e deixe o pipeline julgar:

@@FENCE 3@@

O estágio de testes quebrou, antes de qualquer scanner rodar. O uv se recusou a instalar o werkzeug
3.1.9 porque o arquivo que ele baixou não bate com nenhum dos hashes do lock, e **essa recusa é o
controle da aula 15 funcionando como projetado**: um lock que nomeia uma versão e o hash de outro
arquivo é exatamente a cara de uma adulteração, e o instalador não tem como distinguir as duas
coisas, então recusa as duas. A correção automática não consertou o build; ela levou a falha do
portão de segurança para a instalação.

### A correção que um lock pede

Jogue fora o commit do bot e faça a mudança do jeito que a aula 15 fez toda mudança no lock: compilar
de novo. `-P werkzeug` deixa o uv mover esse pacote e mantém todos os outros pins como o arquivo os
tem, e a nova data de `--exclude-newer` permite a versão corrigida:

@@FENCE 4@@

O diff é a linha de cabeçalho, que registra o comando novo, e três linhas do werkzeug: uma versão nova
e os dois hashes que vão com ela. Envie:

@@FENCE 5@@

Todos os estágios passam. O pluggy 1.6.0, o markupsafe 3.0.3 e o iniconfig 2.3.0 continuam antigos, e
tudo bem: eles não têm aviso, e são as atualizações de rotina que os bots vão propor numa segunda,
depois da espera.

### O que isso diz sobre correções automáticas

| | `pip-audit --fix` | `uv pip compile -P werkzeug` |
|---|---|---|
| acha a versão que corrige o aviso | sim | não, você nomeia o pacote |
| sabe que o arquivo é um lock compilado | não | sim, foi ele que o escreveu |
| escreve os hashes da versão nova | não | sim |
| muda só o que foi pedido | não: um pin novo no arquivo de dev, e todo comentário | sim: um pacote e o cabeçalho |
| o veredito do pipeline | quebrado na instalação | passou |

A questão não é que o pip-audit seja uma ferramenta ruim. O `--fix` dele foi escrito para uma lista
simples de pins, e numa lista assim ele faz a coisa certa. **Uma ferramenta de correção vale o quanto
ela entende o arquivo que edita**, e o pull request de um bot merece a mesma pergunta que o de
qualquer pessoa: o pipeline que o julgou conferiu o que importa? Aqui conferiu, porque a aula 15 fez a
instalação checar hashes. Um pipeline sem essa checagem teria instalado o werkzeug 3.1.9, passado em
todos os estágios e entregado um lock cujos hashes não protegiam nada.

A branch cumpriu o papel dela. Deixe-a sem merge: `main` nunca teve o lock antigo, e o merge traria
quatro pins de um mês atrás de volta junto com a única correção.

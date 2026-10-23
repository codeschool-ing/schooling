---
title: Usando o ASVS num projeto
version: 1
---

Um padrão de 345 requisitos se usa um nível e uma seção por vez. Eis a rotina que serve a uma equipe
do tamanho da Vereda, uma desenvolvedora e uma pessoa de operações em meio período.

### 1. Escolha o nível, e escreva

Nível 2, pelos motivos da primeira seção: o portal guarda dados de saúde. Registre a escolha no
repositório, com quem decidiu e quando. É a promessa contra a qual o resto do trabalho se mede.

### 2. Transforme o nível numa lista que mora no repositório

Exporte do CSV os requisitos do nível escolhido para um arquivo que a equipe mantém ao lado do código, uma linha por requisito, com um estado: `met`, `not met` ou `not applicable`. Para cada um cumprido, a linha diz **onde está a evidência**: o nome de um teste, um arquivo de configuração, uma verificação
da aula 19. Um requisito marcado como cumprido sem evidência é uma crença, não um estado.

### 3. Percorra por seção, em ordem de risco

Não em ordem alfabética. Comece por onde uma falha exporia dados de outras pessoas: autorização
(V8), sessões (V7), validação e codificação (V1, V2). As cinco perguntas da aula 18 são uma ordem
razoável.

### 4. Faça de cada requisito um teste, onde der

O V2.2.2, de que a validação no cliente nunca é o controle, virou os testes da aula 3 que enviam
direto para a rota. O V7.4.1, de que uma sessão encerrada não pode ser usada, é um teste que sai da
conta e reenvia o cookie antigo. Alguns requisitos tratam de documentação ou de processo e viram um
documento; a maioria dos requisitos de código dos níveis 1 e 2 pode virar teste.

### 5. Mantenha atualizado

Uma lista envelhece do jeito que as versões fixadas envelhecem. Revise quando uma funcionalidade
chega numa seção que ela cobre, e quando sai uma versão nova do ASVS: a 5.0.1 é a próxima planejada,
e o próprio repositório do projeto diz isso.

::: track devsecops
Na sua trilha, `threat-modeling` vem a seguir, e trabalha sobre este mesmo portal pela outra ponta:
antes de o código existir, pergunta o que pode dar errado, e o ASVS é uma das fontes com que ele
associa as ameaças. Depois dele, `secure-pipeline` põe as verificações da aula 19 num pipeline.
:::

::: track security
Na sua trilha, `networks-security` vem a seguir. A aplicação é uma das camadas do que se defende; a
rede em volta dela é a próxima.
:::

::: track *
O curso `threat-modeling` trabalha sobre este mesmo portal pela outra ponta: antes de o código
existir, pergunta o que pode dar errado, e o ASVS é uma das fontes com que ele associa as ameaças.
:::

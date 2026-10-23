---
title: Runners novos, persistentes e self-hosted
version: 1
---

Um workflow diz o que rodar; um **runner** é a máquina que roda. Tudo o que as seções anteriores
corrigiram pressupõe algo sobre essa máquina: que o job não lê os arquivos de outro job, que nada que
um job deixa fica para o seguinte, e que o alcance do job na rede é o que você espera. **Se esses
pressupostos valem depende de quem roda a máquina e de quanto tempo ela vive.** Esta seção é ensinada
pela documentação do GitHub e do GitLab; nada dela foi executado.

### Efêmero e persistente

| | um runner efêmero | um runner persistente |
|---|---|---|
| tempo de vida | um job, depois é destruído | muitos jobs, muitas vezes por meses |
| o que um job deixa para trás | nada chega ao job seguinte | arquivos, caches, processos e credenciais ficam no disco |
| quem consegue envenená-lo | ninguém depois que o job termina | qualquer job que rodou nele, para todo job seguinte |
| custo | uma máquina iniciada por job | uma máquina mantida ligada |

Os runners hospedados do GitHub são efêmeros: a documentação do GitHub descreve cada job rodando numa
máquina virtual nova, descartada depois. Um runner **persistente** é uma máquina que alguém registrou
uma vez e mantém: um servidor de build num armário, uma máquina virtual na conta de nuvem de uma
empresa. Ele é mais rápido, porque os caches estão quentes, e é exatamente esse o problema. **Um job
que escreve no disco pode deixar algo para o job seguinte**: uma ferramenta alterada no `PATH`, um
cache de dependências envenenado, um processo que espera. O job seguinte, talvez o de release, roda em
cima disso.

### Runners self-hosted e repositórios públicos

A documentação do GitHub recomenda usar runners self-hosted só com repositórios **privados**, e dá o
motivo: num repositório público qualquer um pode fazer um fork e abrir um pull request, e um workflow
que roda em pull requests passa então a rodar o código de um estranho na sua máquina, dentro da sua
rede. Com `pull_request` o token é só de leitura e os segredos ficam retidos, o que protege o
repositório; não protege a máquina em que o código roda, nem nada que essa máquina alcança.

Três arranjos, da documentação, se um runner self-hosted for mesmo necessário:

- **Runners self-hosted efêmeros.** O runner do GitHub pode ser registrado com `--ephemeral`, para
  pegar um job e sair do registro; algo de fora precisa então criar um novo por job, que é o que o
  operador de Kubernetes Actions Runner Controller faz.
- **Grupos de runners separados.** Runners são atribuídos a grupos, e um grupo aos repositórios e
  workflows que podem usá-lo, para que a máquina que faz deploy nunca seja uma em que um pull request
  possa cair.
- **Aprovação para contribuidores de fora.** As configurações do repositório podem exigir a aprovação
  de quem mantém antes de um workflow rodar para o pull request de alguém de fora ou de primeira vez.

O GitLab tem a mesma distinção com outras palavras: runners compartilhados que o GitLab roda para todo
projeto, e runners de projeto ou de grupo que o projeto registra; a documentação dele faz o mesmo
alerta sobre runners que rodam código de forks.

### O runner deste curso

A CI local deste curso é um runner persistente e self-hosted, o arranjo mais confiante da tabela. Ela
roda toda branch que chega a `~/ci/linkbox.git`, como Ana, no laptop da Ana, e toda execução deixa o
checkout em `~/ci/runs`. Isso é aceitável para o laboratório de uma pessoa, em que a única pessoa que
envia é a dona da máquina. **Deixaria de ser aceitável no dia em que uma segunda pessoa pudesse
enviar**, e a próxima seção diz quanto um job nesta máquina consegue fazer.

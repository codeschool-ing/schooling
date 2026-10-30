---
title: Uma versão que chega aos poucos, e o que não volta atrás
version: 1
---

**Publicar não é um momento; uma versão nova chega aos usuários ao longo de dias, e alguns nunca a
recebem.** A imagem comum é que apertar publicar atualiza todo mundo. Num celular, uma atualização
chega quando a loja a entrega e o celular a instala, e as duas lojas deixam você entregá-la devagar de
propósito, para que uma versão ruim chegue a poucas pessoas antes de chegar a todas.

## A liberação em fases da Apple

**A versão da Apple é um cronograma fixo de sete dias para as atualizações automáticas.** A página de
ajuda do App Store Connect sobre liberar uma atualização em fases, lida em 30 de outubro de 2026, diz
que a opção "libera a atualização do app gradualmente ao longo de 7 dias" para "uma amostra aleatória
de usuários com atualizações automáticas em aparelhos compatíveis", e dá o cronograma como tabela:

| dia | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| porcentagem de usuários | 1% | 2% | 5% | 10% | 20% | 50% | 100% |

Três detalhes da mesma página mudam o jeito de ler a tabela. **Qualquer pessoa ainda pode baixar a
versão nova à mão**, pela App Store, a qualquer momento: as fases só regem as atualizações automáticas.
**A liberação pode ser pausada** por um total de 30 dias, "sem limite de número de pausas", e quando
retoma ela "continua do dia em que parou". E ela pode ser liberada para todos a qualquer momento, que é
o botão que uma equipe aperta quando os primeiros dias parecem limpos.

**A versão do Google Play é uma liberação gradual em que a equipe escolhe a porcentagem.** Uma versão
de produção vai para uma fração de usuários que a equipe define, a fração sobe conforme a confiança
cresce, e a liberação pode ser interrompida. A descrição do próprio Google está nas páginas de ajuda
do Play Console, que não puderam ser acessadas quando isto foi escrito, então esta aula não dá
cronograma para o Play: não há um fixo para citar, e as porcentagens são da equipe.

## O cronograma, como programa

O programa abaixo põe o cronograma da Apple sobre o calendário, começando na segunda-feira, 2 de
novembro de 2026, com uma pausa: um relatório de travamento chega no dia 3, e a equipe pausa por dois
dias enquanto investiga. Salve-o como `rollout.ts` em `~/planner`:

```typescript
// rollout.ts: a phased release, day by day, with a pause in the middle
const APPLE = [1, 2, 5, 10, 20, 50, 100]; // percent of automatic updates on day 1 to 7

// Each calendar day from `start`: the phase day reached and its percentage. A paused day
// does not advance the phase, and the release resumes on the day it left off.
export function schedule(start: string, phases: number[], paused: string[]) {
  if (paused.length > 30) throw new Error("a phased release may be paused for 30 days in all");
  const rows: string[] = [];
  const d = new Date(start + "T12:00:00Z");
  let phase = 0;
  while (phase < phases.length) {
    const day = d.toISOString().slice(0, 10);
    if (paused.includes(day)) {
      rows.push(`${day}  paused   still ${phases[phase - 1] ?? 0}%`);
    } else {
      rows.push(`${day}  day ${phase + 1}    ${phases[phase]}%`);
      phase++;
    }
    d.setUTCDate(d.getUTCDate() + 1);
  }
  return rows;
}

// A crash report arrives on day 3; the release is paused for two days, then resumed.
for (const row of schedule("2026-11-02", APPLE, ["2026-11-05", "2026-11-06"])) console.log(row);
```

```
ana@dev:~/planner$ node rollout.ts
2026-11-02  day 1    1%
2026-11-03  day 2    2%
2026-11-04  day 3    5%
2026-11-05  paused   still 5%
2026-11-06  paused   still 5%
2026-11-07  day 4    10%
2026-11-08  day 5    20%
2026-11-09  day 6    50%
2026-11-10  day 7    100%
```

**A pausa segura a porcentagem onde estava.** Por dois dias ninguém novo recebe a atualização, e os
5% que já a têm continuam com ela: pausar interrompe a propagação, não a versão. Em 7 de novembro o
cronograma retoma no dia 4, 10%, e não no dia 6, e a versão chega a todo mundo no dia dez em vez do
dia oito. Se o travamento fosse real, o próximo passo seria um build novo, com número de build maior,
pela revisão de novo, que é a aula 8 inteira do `mobile-delivery`.

## O que não volta atrás

**Uma versão que chegou a um celular fica nele até o dono atualizar, e alguns nunca atualizam.**
Nenhuma das lojas consegue desinstalar a sua versão antiga do celular de um usuário. Um usuário com as
atualizações automáticas desligadas, ou com um celular velho demais para o sistema mínimo da versão
nova, fica com o build antigo indefinidamente. Três consequências decorrem disso, e o planner precisa
conviver com todas:

- **O número de build está gasto.** Um código de versão ou número de build que saiu não pode ser
  reusado, como a seção anterior mostrou, e a próxima versão precisa ser maior.
- **Clientes antigos continuam chamando o seu servidor.** Se o planner sincroniza, o servidor precisa
  responder à versão do ano passado tanto quanto à desta semana, que é a aula 20 do `mobile-delivery`,
  "o app que nunca atualiza".
- **Uma versão ruim se corrige para frente.** Não existe voltar um celular para o build anterior; o
  remédio é um build mais novo, e é exatamente por isso que a liberação em fases existe, para deixar
  pequeno o número de celulares com uma versão ruim.

## O app que você publicou continua vivo

**Um app publicado também está sujeito a regras que mudam depois que ele saiu.** A documentação do
Android sobre o requisito de nível de API alvo do Google Play, lida em 30 de outubro de 2026, diz que a
partir de **31 de agosto de 2026** "apps novos e atualizações de apps precisam ter como alvo o Android
16 (nível de API 36) ou superior" para serem enviados, com exceções para Wear OS, Android Automotive
OS, Android TV e Android XR. Apps existentes precisam ter como alvo o Android 15 (nível de API
35) ou superior "para continuar disponíveis a novos usuários" em aparelhos mais novos. Quem precisa de
mais tempo pode pedir uma extensão até **1º de novembro de 2026**. Então um app que ninguém mexeu por
um ano pode deixar de ser oferecido a novos usuários em celulares novos sem que ninguém tenha mudado
uma linha dele.

**Os sistemas também se mexem.** Uma versão nova do Android ou do iOS muda uma permissão, um limite de
segundo plano ou uma regra de layout, os assuntos das aulas 12, 15 e 9, e um app construído contra o
sistema do ano passado encontra o deste ano no primeiro dia da atualização. Um planner publicado é um
planner para o qual alguém da equipe lê notas de versão, todo ano, enquanto ele estiver à venda.

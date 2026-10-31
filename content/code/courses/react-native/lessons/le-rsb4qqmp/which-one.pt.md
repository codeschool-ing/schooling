---
title: Onde um pedaço de estado deve morar
version: 1
---

**Ponha o estado o mais perto possível de onde é usado, e não mais perto do que todos que precisam dele.** O
planner agora tem os três níveis, e cada pedaço do estado dele está onde está por um motivo.

| estado | onde mora | por quê |
|---|---|---|
| se uma linha está apertada | dentro do `Pressable` | ninguém mais se importa |
| o texto sendo digitado num campo (aula 11) | `useState` no formulário | só o formulário o lê até ele ser salvo |
| o plano | um contexto na raiz | toda tela o lê, e duas o mudam |
| que tela está aberta, e os parâmetros dela | o estado de navegação | o React Navigation é dono dele, e o endereço o acompanha |
| dados de um servidor (aula 10) | o cache do TanStack Query | eles têm as próprias regras de frescor |
| milhares de itens lidos linha a linha | uma store com seletores | um contexto redesenharia toda linha |

## Dois erros que vale reconhecer

**Copiar props para o estado.** `const [name, setName] = useState(props.course.name)` pega o nome uma vez, na
primeira renderização, e ignora toda mudança depois. Use a prop, ou, se o componente precisa editar um
rascunho, dê ao componente a chave do id do curso para que outro curso comece um rascunho novo.

**Guardar um valor que pode ser calculado.** O total da semana nunca é guardado: ele é calculado a partir do
plano a cada renderização, então não consegue discordar dele. Estado que duplica outro estado são dois lugares
para atualizar e mais um jeito de estar errado.

## A regra por trás de tudo

**Um dono para cada fato.** O plano tem um dono, o provider, e um jeito de mudá-lo, uma ação. As telas o leem e
pedem mudanças; nenhuma guarda uma cópia. É a mesma disciplina que os dados do planner seguem quando uma sessão
cita o curso pelo id, e o motivo de um toque numa aba ser confiável para aparecer na outra.

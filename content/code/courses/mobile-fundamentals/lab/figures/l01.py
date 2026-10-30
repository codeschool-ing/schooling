"""Lesson 1: the planner's core, as an annotated example."""

EXAMPLES = {
    "the-planner": [
        {"language": "typescript", "file": "planner.ts", "parts": [
            ("// planner.ts: the study planner's data, and the sums every screen needs\nexport type Course = { id: string; title: string };\nexport type Session = {\n  id: string;\n  courseId: string;\n  date: string; // YYYY-MM-DD, the day it is planned for\n  minutes: number;\n  done: boolean;\n};\nexport type Plan = { courses: Course[]; sessions: Session[] };\n",
             "The data. A session points at its course by the course's `id`, never by its title, so renaming a course loses nothing. The types are what `node` strips before running the file.",
             'Os dados. Uma sessão aponta para o curso pelo `id` dele, nunca pelo título, então renomear um curso não perde nada. Os tipos são o que o `node` remove antes de rodar o arquivo.'),
            ('// The Monday of the week a date falls in, as YYYY-MM-DD.\nexport function mondayOf(date: string): string {\n  const d = new Date(date + "T12:00:00Z");\n  const back = (d.getUTCDay() + 6) % 7; // Monday 0 ... Sunday 6\n  d.setUTCDate(d.getUTCDate() - back);\n  return d.toISOString().slice(0, 10);\n}\n',
             'A week starts on Monday here. The date is read at noon UTC, so no time zone can move it to the day before; `getUTCDay` counts from Sunday, and the `+ 6` makes Monday zero.',
             'Aqui a semana começa na segunda-feira. A data é lida ao meio-dia UTC, então nenhum fuso horário a empurra para o dia anterior; `getUTCDay` conta a partir do domingo, e o `+ 6` faz a segunda valer zero.'),
            ('export function addSession(plan: Plan, s: Session): Plan {\n  if (!plan.courses.some((c) => c.id === s.courseId)) {\n    throw new Error(`no course ${s.courseId}`);\n  }\n  return { ...plan, sessions: [...plan.sessions, s] };\n}\n',
             'A session for a course that does not exist is refused, loudly, rather than added and lost later. The plan that comes back is a new object; the old one is untouched.',
             'Uma sessão de um curso que não existe é recusada, com erro, em vez de entrar e se perder depois. O plano devolvido é um objeto novo; o antigo fica intacto.'),
            ('export function markDone(plan: Plan, id: string): Plan {\n  return {\n    ...plan,\n    sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)),\n  };\n}\n',
             'Done is set and never unset, the same way a finished step stays finished.',
             'Concluída é marcada e nunca desmarcada, do mesmo jeito que uma etapa terminada continua terminada.'),
            ('// Minutes planned and minutes done in the week that contains `today`.\nexport function weekTotal(plan: Plan, today: string) {\n  const monday = mondayOf(today);\n  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);\n  const planned = week.reduce((sum, s) => sum + s.minutes, 0);\n  const done = week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0);\n  return { monday, planned, done };\n}',
             'The one sum every screen shows. `today` is an argument, not the clock, so the same plan always gives the same answer and a test can pin it.',
             'A soma que toda tela mostra. `today` é um argumento, não o relógio, então o mesmo plano sempre dá a mesma resposta e um teste consegue fixá-la.'),
        ]},
    ],
}

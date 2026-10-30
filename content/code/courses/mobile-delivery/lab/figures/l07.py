"""Lesson 7: Play's tracks as a script."""
P = [
    ("// tracks.ts: Google Play's testing tracks as data, and which build each person gets\ntype Track = \"internal\" | \"closed\" | \"open\" | \"production\";\nconst onTrack = new Map<Track, number>();\nconst used = new Set<number>();",
     "Each track holds one version code. `used` remembers every code ever uploaded, on any track.",
     "Cada faixa guarda um version code. `used` lembra todo código já enviado, em qualquer faixa."),
    ("function upload(code: number, track: Track) {\n  if (used.has(code)) return console.log(`upload ${code} to ${track}: refused, version code already used`);\n  used.add(code);\n  onTrack.set(track, code);\n  console.log(`upload ${code} to ${track}`);\n}",
     "An upload with a code that was ever used is refused, whatever the track.",
     "Um envio com um código que já foi usado é recusado, seja qual for a faixa."),
    ("function promote(from: Track, to: Track) {\n  const code = onTrack.get(from)!;\n  onTrack.set(to, code);\n  console.log(`promote ${code} from ${from} to ${to}`);\n}",
     "A promotion uploads nothing: the same code is placed on a wider track.",
     "Uma promoção não envia nada: o mesmo código é posto numa faixa mais ampla."),
    ("const people: [string, Track[]][] = [\n  [\"Ana\", [\"internal\", \"closed\", \"production\"]],\n  [\"Bruno\", [\"closed\", \"production\"]],\n  [\"Carla\", [\"production\"]],\n];\nfunction show() {\n  for (const [who, tracks] of people) {\n    const codes = tracks.flatMap((t) => (onTrack.has(t) ? [onTrack.get(t)!] : []));\n    console.log(`    ${who.padEnd(6)} gets ${Math.max(...codes)}`);\n  }\n}",
     "Each person sees the highest code among the tracks they are on.",
     "Cada pessoa vê o código mais alto entre as faixas em que está."),
    ("upload(41, \"internal\"); promote(\"internal\", \"closed\"); promote(\"closed\", \"production\"); show();\nupload(42, \"closed\"); show();\nupload(43, \"internal\"); show();\nupload(42, \"production\"); promote(\"closed\", \"production\"); show();",
     "Four moments in the planner's month, in order.",
     "Quatro momentos do mês do planner, em ordem."),
]
EXAMPLES = {"one-build-promoted": [{"language": "typescript", "file": "tracks.ts", "parts": P}]}

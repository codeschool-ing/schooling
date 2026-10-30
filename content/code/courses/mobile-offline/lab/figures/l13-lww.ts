// lww.ts: two devices edit one session offline, and the server keeps the last write.
type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
type Change = Partial<Pick<Session, "minutes" | "done">>;

const [policy = "device-clock", ...args] = process.argv.slice(2);
const skew: Record<string, number> = {}; // minutes a device's clock is ahead
for (const a of args) {
  const [device, by] = a.split("=");
  skew[device] = Number(by);
}

function at(hhmm: string, plus = 0): string {
  const [h, m] = hhmm.split(":").map(Number);
  const t = h * 60 + m + plus;
  return `${String(Math.floor(t / 60)).padStart(2, "0")}:${String(t % 60).padStart(2, "0")}`;
}

let server = { session: { id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: false }, stamp: "09:00" };
const copies: Record<string, { session: Session; stamp: string }> = {
  phone: structuredClone(server),
  tablet: structuredClone(server),
};

// What happened, at the true time it happened. Both devices are offline until they sync.
const events: { time: string; device: string; change?: Change }[] = [
  { time: "10:05", device: "phone", change: { minutes: 30 } },
  { time: "10:20", device: "tablet", change: { done: true } },
  { time: "10:40", device: "tablet" },
  { time: "11:00", device: "phone" },
];

console.log(`policy: ${policy}` + (args.length ? `, ${args.join(" ")}` : ""));
for (const e of events) {
  const copy = copies[e.device];
  const who = `${e.time} ${e.device.padEnd(7)}`;
  if (e.change) {
    const [field, value] = Object.entries(e.change)[0];
    const before = copy.session[field as keyof Change];
    copy.session = { ...copy.session, ...e.change };
    copy.stamp = at(e.time, skew[e.device] ?? 0);
    console.log(`${who} edits s3: ${field} ${before} -> ${value}, stamped ${copy.stamp}`);
    continue;
  }
  // Last write wins: the newer stamp replaces the whole row; the older one is dropped.
  const stamp = policy === "server-clock" ? e.time : copy.stamp;
  if (stamp > server.stamp) {
    server = { session: copy.session, stamp };
    console.log(`${who} syncs: ${stamp} is newer than the server's row, kept`);
  } else {
    console.log(`${who} syncs: ${stamp} is older than the server's ${server.stamp}, dropped`);
  }
}
console.log(`server s3: minutes ${server.session.minutes}, done ${server.session.done}`);

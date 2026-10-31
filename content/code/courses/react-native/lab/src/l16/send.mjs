// send.mjs: what the planner's server would do to remind one phone, through Expo's push service.
//
//   node send.mjs 'ExponentPushToken[…]'
const [to] = process.argv.slice(2);
const res = await fetch("https://exp.host/--/api/v2/push/send", {
  method: "POST",
  headers: { "content-type": "application/json", accept: "application/json" },
  body: JSON.stringify([
    { to, title: "Guitar: 20 min today", body: "Tap to open the course.", data: { url: "planner://course/guitar" } },
  ]),
});
// One ticket per message: accepted for delivery, or refused with a reason.
const { data } = await res.json();
for (const ticket of data) {
  if (ticket.status === "ok") console.log("accepted:", ticket.id);
  else console.log("refused:", ticket.message, ticket.details?.error ?? "");
}

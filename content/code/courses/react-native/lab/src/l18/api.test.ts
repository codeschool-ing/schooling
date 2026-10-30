// __tests__/api.test.ts: a plan in a shape the app cannot read is refused at the door, with a sentence.
import { fetchPlan } from "../src/api";

const answer = (body: unknown) =>
  jest.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify(body), { status: 200 }));

test("a plan with courses and sessions is accepted", async () => {
  answer({ courses: [], sessions: [] });
  await expect(fetchPlan()).resolves.toEqual({ courses: [], sessions: [] });
});

test("a plan whose sessions were renamed is refused", async () => {
  answer({ courses: [], items: [] });
  await expect(fetchPlan()).rejects.toThrow("cannot read");
});

// src/validate.ts: what the form refuses, and the sentence it gives for each refusal.
export type Draft = { date: string; minutes: string };
export type Errors = Partial<Record<keyof Draft, string>>;

export function validate({ date, minutes }: Draft): Errors {
  const errors: Errors = {};
  const d = new Date(`${date}T12:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== date) {
    errors.date = "Write the date as YYYY-MM-DD, for example 2026-10-23.";
  }
  const n = Number(minutes);
  if (minutes.trim() === "" || !Number.isInteger(n)) errors.minutes = "Write the minutes as a whole number.";
  else if (n < 5 || n > 240) errors.minutes = "A session is between 5 and 240 minutes.";
  return errors;
}

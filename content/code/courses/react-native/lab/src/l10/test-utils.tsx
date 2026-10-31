// test-utils.tsx: what a screen test puts around a screen: a query client whose plan has already loaded.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement } from "react";
import data from "./src/courses.json";
import type { Plan } from "./src/planner";

export function withPlan(ui: ReactElement, plan: Plan = data) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  client.setQueryData(["plan"], plan);
  return <QueryClientProvider client={client}>{ui}</QueryClientProvider>;
}

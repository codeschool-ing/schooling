// What every route needs to answer.
export function send(res, status, body, headers = {}) {
  const json = typeof body !== 'string';
  res.writeHead(status, {
    'Content-Type': json ? 'application/json' : 'text/plain; charset=utf-8',
    ...headers,
  });
  res.end(json ? JSON.stringify(body) : body);
}

export const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

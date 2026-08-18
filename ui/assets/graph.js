/* ==========================================================================
   Schooling — a track, drawn

   PORTED FROM THE PREDECESSOR rather than reinvented, because the parts that
   are hard here were paid for once already: the ordering that minimises
   crossings, and the router that takes a line around a card instead of through
   it. What changed is the data — a track arrives from the API as steps, and a
   course's prerequisites arrive on the catalogue listing — and the comments,
   which are kept where they carry a reason and dropped where they described
   something that no longer exists.

   # WHAT A NODE IS

   A course is a node. A FORK IS ONE NODE, not one per option: it is a decision,
   and drawing three boxes where the student takes one would say the track is
   three times as wide as it is.

   # WHERE THE ARROWS COME FROM

   `requires` — knowledge, not sequence. A course whose prerequisites are all
   outside this track has none inside it, and would otherwise land on level one
   beside the entry course; so a node with no arrow into it inherits one from
   the step before it in the curriculum. That is the track's order standing in
   for knowledge it does not have, and it is the only place the two are mixed.

   # AND WHY THE ORDERING IS AN ALGORITHM AND NOT A FIELD

   Nothing is pinned per track. The order inside each column is measured — the
   drawing that comes out is scored — so a track added tomorrow is laid out as
   well as the ones here today, with nobody editing a list of positions.
   ========================================================================== */

/* ---------- the graph ---------- */

export function buildGraph(track, courses, chosen = {}) {
  const byId = new Map(courses.map((c) => [c.id, c]));

  const nodes = [];
  const ofCourse = {};      // course id -> the node that contains it
  const inSomeOption = {};  // course id in any branch -> its fork node

  (track.steps || []).forEach((step, index) => {
    if (!step.options || !step.options.length) {
      nodes.push({ id: step.course, kind: 'course', courses: [step.course] });
      ofCourse[step.course] = step.course;
      return;
    }

    const id = `fork:${index}`;
    const taken = step.options[chosen[index] || 0] || step.options[0];
    nodes.push({ id, kind: 'fork', step, index, courses: taken.courses || [] });

    step.options.forEach((option) => (option.courses || []).forEach((c) => {
      inSomeOption[c] = id;
    }));
    (taken.courses || []).forEach((c) => { ofCourse[c] = id; });
  });

  nodes.forEach((node, i) => {
    const deps = new Set();
    node.courses.forEach((id) => {
      const course = byId.get(id);
      ((course && course.requires) || []).forEach((needed) => {
        const target = ofCourse[needed] || inSomeOption[needed];
        if (target && target !== node.id) deps.add(target);
      });
    });

    // See the header: the curriculum's order, standing in for a prerequisite
    // this track does not contain.
    if (!deps.size && i > 0) deps.add(nodes[i - 1].id);
    node.deps = [...deps];
  });

  /* A finish node, so the drawing does not end in loose courses with no
     outgoing arrow — which reads as unfinished rather than as finished. */
  const hasSuccessor = {};
  nodes.forEach((n) => n.deps.forEach((d) => { hasSuccessor[d] = true; }));
  nodes.push({
    id: '@finish', kind: 'finish', courses: [],
    deps: nodes.filter((n) => !hasSuccessor[n.id]).map((n) => n.id),
  });

  const columns = levels(nodes);
  order(nodes, columns);
  return { nodes, columns };
}

/* Levels by Kahn's algorithm, iteratively.
   ITERATIVELY BECAUSE THE RECURSIVE VERSION HAD A DEPTH CEILING, and the two
   longest tracks in the predecessor hit it and rendered nothing at all. */
function levels(nodes) {
  const successors = {};
  nodes.forEach((n) => n.deps.forEach((d) => { (successors[d] = successors[d] || []).push(n.id); }));

  const level = {};
  const remaining = {};
  nodes.forEach((n) => { remaining[n.id] = n.deps.length; });

  const queue = nodes.filter((n) => !n.deps.length).map((n) => n.id);
  queue.forEach((id) => { level[id] = 0; });

  for (let i = 0; i < queue.length; i += 1) {
    (successors[queue[i]] || []).forEach((s) => {
      level[s] = Math.max(level[s] === undefined ? 0 : level[s], level[queue[i]] + 1);
      remaining[s] -= 1;
      if (remaining[s] <= 0) queue.push(s);
    });
  }

  /* A cycle drains the queue before the end. The validator refuses one in
     `requires`, so reaching here means the curriculum fallback closed a loop —
     and a node with no level made the whole track disappear, which is a worse
     answer to bad data than a slightly wrong drawing. */
  nodes.filter((n) => level[n.id] === undefined).forEach((n) => {
    const resolved = n.deps.map((d) => level[d]).filter((v) => v !== undefined);
    level[n.id] = resolved.length ? Math.max(...resolved) + 1 : 0;
  });

  const byLevel = {};
  nodes.forEach((n) => { (byLevel[level[n.id]] = byLevel[level[n.id]] || []).push(n); });

  const columns = Object.keys(byLevel).map(Number).sort((a, b) => a - b).map((v) => byLevel[v]);
  columns.forEach((column, i) => column.forEach((n) => { n.level = i; }));
  return columns;
}

/* ---------- the order inside each column ----------

   Sugiyama's method, in three pieces, and the third is the one people leave
   out:

     1. barycentre — each node is pulled towards the average height of its
        neighbours in the next column. It converges fast and it gets stuck: some
        arrangements only improve by moving TWO columns at once, and no single
        swap improves anything on its own;
     2. transposition — swap neighbouring pairs while that does not make things
        worse. ACCEPTING THE TIED SWAPS is what unlocks the two-column cases:
        the first swap moves sideways for nothing, the second collects the gain;
     3. several starting orders — the two above are greedy, so the result
        depends on where they begin. It restarts from the curriculum's order,
        its reverse, and a few shuffled ones, and keeps the best. The shuffle is
        seeded, so a track does not change shape between one visit and the next.

   THE COST IS THREE NUMBERS COMPARED IN ORDER, never summed: the second is
   consulted only when the first ties. That way no lesser criterion can buy an
   extra crossing. */
function order(nodes, columns) {
  const position = {};
  const reindex = () => columns.forEach((column) => column.forEach((n, i) => {
    position[n.id] = column.length > 1 ? i / (column.length - 1) : 0.5;
  }));

  const level = {};
  nodes.forEach((n) => { level[n.id] = n.level; });

  const edges = [];
  nodes.forEach((n) => n.deps.forEach((d) => {
    if (level[d] < level[n.id]) edges.push({ from: d, to: n.id, span: level[n.id] - level[d] });
  }));

  const curriculum = {};
  nodes.forEach((n, i) => { curriculum[n.id] = i; });

  const gaps = [];
  const cost = () => {
    for (let g = 0; g < columns.length - 1; g += 1) gaps[g] = [];
    edges.forEach((e) => {
      if (e.span === 1) gaps[level[e.from]].push({ a: position[e.from], b: position[e.to] });
    });

    /* 1) CROSSINGS — what the drawing actually shows. Two edges between
          neighbouring columns cross when the vertical order of their endpoints
          inverts. An edge that skips columns is not drawn straight: the router
          takes it out to a free lane, where it crosses whatever passes above or
          below on the way. The cost counts the side the router will pick. */
    let crossings = 0;
    gaps.forEach((list) => {
      for (let i = 0; i < list.length; i += 1) {
        for (let j = i + 1; j < list.length; j += 1) {
          if ((list[i].a - list[j].a) * (list[i].b - list[j].b) < 0) crossings += 1;
        }
      }
    });

    /* 2) UPWARD BIAS — with up and down tied, the detour goes up. A convention,
          but a uniform one: with every shortcut leaving the same side, the
          track's body stays contiguous instead of being split by lines passing
          on both sides. */
    let bias = 0;
    edges.forEach((e) => {
      if (e.span === 1) return;
      const from = position[e.from], to = position[e.to];
      const out = gaps[level[e.from]] || [], into = gaps[level[e.to] - 1] || [];
      let above = 0, below = 0;
      out.forEach((s) => { if (s.a < from) above += 1; else if (s.a > from) below += 1; });
      into.forEach((s) => { if (s.b < to) above += 1; else if (s.b > to) below += 1; });
      crossings += Math.min(above, below);
      bias += from + to;
    });

    /* 3) CURRICULUM ORDER — among equally clean drawings, the one that keeps
          the courses in the sequence the track declares. Without it every start
          returns an arbitrary permutation among the good ones, and a column
          comes out shuffled for no gain at all. */
    let outOfOrder = 0;
    columns.forEach((column) => {
      for (let i = 0; i < column.length; i += 1) {
        for (let j = i + 1; j < column.length; j += 1) {
          if (curriculum[column[i].id] > curriculum[column[j].id]) outOfOrder += 1;
        }
      }
    });

    return [crossings, bias, outOfOrder];
  };

  const worse = (a, b) => {
    for (let i = 0; i < a.length; i += 1) {
      if (a[i] !== b[i]) return a[i] > b[i];
    }
    return false;
  };

  const mean = (v) => v.reduce((a, b) => a + b, 0) / v.length;
  const median = (v) => {
    const s = v.slice().sort((a, b) => a - b);
    return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2;
  };

  const predecessors = {};
  const successors = {};
  nodes.forEach((n) => n.deps.forEach((d) => {
    (predecessors[n.id] = predecessors[n.id] || []).push(d);
    (successors[d] = successors[d] || []).push(n.id);
  }));

  const sortColumn = (column, neighbours, aggregate) => {
    const keys = column.map((n, i) => {
      const v = (neighbours[n.id] || []).map((id) => position[id]).filter((x) => x !== undefined);
      return { n, b: v.length ? aggregate(v) : null, i };
    });
    keys.sort((a, b) => (a.b === null || b.b === null ? a.i - b.i : (a.b - b.b) || (a.i - b.i)));
    return keys.map((x) => x.n);
  };

  const transpose = (acceptTies) => {
    let improved = true;
    for (let lap = 0; improved && lap < 8; lap += 1) {
      improved = false;
      columns.forEach((column) => {
        for (let i = 0; i < column.length - 1; i += 1) {
          const before = cost();
          [column[i], column[i + 1]] = [column[i + 1], column[i]];
          reindex();
          const after = cost();
          const keep = acceptTies ? !worse(after, before) : worse(before, after);
          if (keep) {
            if (worse(before, after)) improved = true;
          } else {
            [column[i], column[i + 1]] = [column[i + 1], column[i]];
            reindex();
          }
        }
      });
    }
  };

  /* A seeded shuffle: the same track draws the same way every time it is
     opened. A layout that moved between visits would be a layout nobody could
     learn. */
  let seed = 20260818;
  const random = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };

  const starts = [
    () => columns.forEach((c) => c.sort((a, b) => curriculum[a.id] - curriculum[b.id])),
    () => columns.forEach((c) => c.sort((a, b) => curriculum[b.id] - curriculum[a.id])),
    () => columns.forEach((c) => c.sort(() => random() - 0.5)),
    () => columns.forEach((c) => c.sort(() => random() - 0.5)),
  ];

  let best = null;
  starts.forEach((start) => {
    start();
    reindex();

    for (let pass = 0; pass < 6; pass += 1) {
      const aggregate = pass % 2 ? median : mean;
      const forwards = pass % 4 < 2;
      const range = forwards
        ? columns.map((_, i) => i) : columns.map((_, i) => columns.length - 1 - i);

      range.forEach((i) => {
        const neighbours = forwards ? predecessors : successors;
        columns[i] = sortColumn(columns[i], neighbours, aggregate);
        reindex();
      });
      transpose(false);
    }
    transpose(true);

    const here = cost();
    if (!best || worse(best.cost, here)) {
      best = { cost: here, order: columns.map((c) => c.map((n) => n.id)) };
    }
  });

  // Put the best arrangement back, since the last start is not always it.
  best.order.forEach((ids, i) => {
    columns[i] = ids.map((id) => nodes.find((n) => n.id === id));
  });
  reindex();
}

/* ---------- the edges ----------

   THE ROUTER RUNS IN ONE AXIS AND SERVES BOTH. Everything below thinks the
   graph goes left to right: an edge leaves a card's right side, crosses a
   corridor, and comes in on the next card's left. Flowing downwards, the boxes
   go in with x and y swapped and every point comes back swapped — so "the lane
   above the cards" is the margin to their left, and not one line of the routing
   is written twice. */

/* How far a detour stays from the card it goes around. Eleven pixels put some
   of them within a hair of one; sixteen gives room without stretching the curve
   into an arc. */
const CLEARANCE = 16;

/* The narrowest gap between two cards a line may thread, which is NOT the same
   number. Clearance is for going around something with open space on the far
   side; threading needs only enough to read as a corridor. Demanding the larger
   value here rejected every real gap and sent edges over the top of the
   drawing. */
const CORRIDOR = 14;

/* What a curve leaves between itself and the card it stops short of. Without
   it the rise ended EXACTLY on the neighbour's edge: `clearance / 2` doubled
   back into `out * 2`, so every detour was tangent to the next card and correct
   only by rounding. Four pixels is the difference between a drawing that is
   right and one that is right on this machine. */
const BREATH = 4;

export function routeEdges(container, graph, down) {
  const svg = container.querySelector('.graph-edges');
  if (!svg) return;

  const base = container.getBoundingClientRect();
  const scrolledX = container.scrollLeft, scrolledY = container.scrollTop;

  const boxOf = (id) => {
    const node = container.querySelector(`[data-node="${CSS.escape(id)}"]`);
    if (!node) return null;
    const r = node.getBoundingClientRect();
    const b = {
      x: r.left - base.left + scrolledX, y: r.top - base.top + scrolledY,
      w: r.width, h: r.height,
    };
    return down ? { x: b.y, y: b.x, w: b.h, h: b.w } : b;
  };

  const far = down ? container.scrollWidth : container.scrollHeight;
  const P = (x, y) => (down ? `${y},${x}` : `${x},${y}`);

  svg.setAttribute('width', container.scrollWidth);
  svg.setAttribute('height', container.scrollHeight);
  svg.setAttribute('viewBox', `0 0 ${container.scrollWidth} ${container.scrollHeight}`);

  const boxes = graph.nodes.map((n) => {
    const c = boxOf(n.id);
    return c && { id: n.id, ...c };
  }).filter(Boolean);

  if (!boxes.length) { svg.textContent = ''; return; }

  /* The detour lanes sit just above and just below the cards rather than at the
     container's edges: short curves instead of arcs crossing the screen. */
  const top = Math.min(...boxes.map((c) => c.y));
  const bottom = Math.max(...boxes.map((c) => c.y + c.h));
  const detourUp = Math.max(6, top - CLEARANCE);
  const detourDown = Math.min(far - 6, bottom + CLEARANCE);

  /* WHETHER A LINE IS BLOCKED IS GEOMETRY, not a count of skipped columns.
     Counting missed the case where a column splits into sub-columns and a
     neighbouring card sits in the corridor — with the edge joining ADJACENT
     columns, so no count would ever have flagged it. */
  const inTheWay = (xa, xb, ya, yb, ignore) => boxes.filter((c) =>
    ignore.indexOf(c.id) < 0 &&
    c.x + c.w > xa && c.x < xb &&
    c.y < yb && c.y + c.h > ya);

  /* Every free horizontal corridor across a span: above the cards in the way,
     below them, and each gap between them wide enough for the line and its
     clearance. Overlapping cards are merged first, or the gap between two cards
     in one column would be offered while a third card spans across it. */
  const freeLanes = (xa, xb, ignore) => {
    const spans = boxes
      .filter((c) => ignore.indexOf(c.id) < 0 && c.x + c.w > xa && c.x < xb)
      .map((c) => [c.y, c.y + c.h])
      .sort((a, b) => a[0] - b[0]);
    if (!spans.length) return [];

    const merged = [spans[0].slice()];
    spans.forEach((s) => {
      const last = merged[merged.length - 1];
      if (s[0] <= last[1]) last[1] = Math.max(last[1], s[1]);
      else merged.push(s.slice());
    });

    const lanes = [merged[0][0] - CLEARANCE, merged[merged.length - 1][1] + CLEARANCE];
    for (let i = 0; i < merged.length - 1; i += 1) {
      if (merged[i + 1][0] - merged[i][1] >= CORRIDOR) {
        lanes.push((merged[i][1] + merged[i + 1][0]) / 2);
      }
    }
    return lanes;
  };

  /* Free horizontal room from an x, within the band the curve travels through.
     It is what limits the width of the rise: with sub-columns the gap beside a
     card falls to fourteen pixels, and a fixed twenty-six-pixel rise would pass
     straight through the neighbour. */
  const clearance = (x, ya, yb, ignore, rightwards) => {
    let limit = Infinity;
    boxes.forEach((c) => {
      if (ignore.indexOf(c.id) >= 0) return;
      if (c.y >= yb || c.y + c.h <= ya) return;
      const d = rightwards ? c.x - x : x - (c.x + c.w);
      if (d >= 0) limit = Math.min(limit, d);
    });
    return limit;
  };

  /* Where the rise may begin. A card that STRADDLES the x the edge leaves from
     is invisible to `clearance`, which measures a distance and drops the
     negative one — so the curve swept from the card's centre out to the lane
     while still inside that neighbour, drawn by the very code that exists to
     avoid it. It happens when two cards share a level and are not the same
     height: one's edge is past the other's, in the band the rise crosses.

     The answer is not a smaller rise, which starts inside the card either way.
     It is to run straight along the line's own height until the card is behind,
     and rise there.

     A card lying ACROSS that height is left alone: the straight run would cross
     it, and nothing this function can return avoids a card sitting on top of
     the line's own y. */
  const beyond = (x, home, lane, ignore, rightwards) => {
    let at = x;
    const ya = Math.min(home, lane), yb = Math.max(home, lane);
    boxes.forEach((c) => {
      if (ignore.indexOf(c.id) >= 0) return;
      if (c.y >= yb || c.y + c.h <= ya) return;
      if (c.y < home + 3 && c.y + c.h > home - 3) return;
      if (rightwards) {
        if (c.x <= x && c.x + c.w > x) at = Math.max(at, c.x + c.w + BREATH);
      } else if (c.x < x && c.x + c.w >= x) {
        at = Math.min(at, c.x - BREATH);
      }
    });
    return at;
  };

  const drawn = [];
  graph.nodes.forEach((node) => {
    const b = boxOf(node.id);
    if (!b) return;

    node.deps.forEach((from) => {
      const a = boxOf(from);
      if (!a) return;

      const x1 = a.x + a.w, y1 = a.y + a.h / 2;
      const x2 = b.x, y2 = b.y + b.h / 2;
      const ignore = [from, node.id];

      /* The simple curve keeps its control points at the endpoints' heights, so
         it never leaves the band between them: that rectangle is all there is
         to check. */
      const blocked = inTheWay(x1 + 2, x2 - 2, Math.min(y1, y2) - 4, Math.max(y1, y2) + 4, ignore);

      let d;
      if (blocked.length) {
        const lanes = freeLanes(x1 + 2, x2 - 2, ignore);
        let lane = null, cheapest = Infinity;
        lanes.forEach((y) => {
          if (inTheWay(x1 + 2, x2 - 2, y - 3, y + 3, ignore).length) return;
          const price = Math.abs(y1 - y) + Math.abs(y2 - y) + Math.abs(y - (y1 + y2) / 2) / 1000;
          if (price < cheapest) { cheapest = price; lane = y; }
        });

        // Nothing free between the two: the lane above or below the whole
        // drawing is, and it always is.
        if (lane === null) {
          lane = (y1 - detourUp) + (y2 - detourUp) <= (detourDown - y1) + (detourDown - y2)
            ? detourUp : detourDown;
        }

        /* Clamping keeps the lane inside the drawing, and can therefore push it
           into a card sitting against the edge. When it does, the other side is
           tried before a line is drawn through anything. */
        const clamp = (y) => Math.max(6, Math.min(far - 6, y));
        lane = clamp(lane);
        if (inTheWay(x1 + 2, x2 - 2, lane - 3, lane + 3, ignore).length) {
          const other = clamp(lane <= (detourUp + detourDown) / 2 ? detourDown : detourUp);
          if (!inTheWay(x1 + 2, x2 - 2, other - 3, other + 3, ignore).length) lane = other;
        }

        /* Past whatever straddles the ends, and only then out to the lane. */
        let riseAt = beyond(x1, y1, lane, ignore, true);
        let dropAt = beyond(x2, y2, lane, ignore, false);
        if (riseAt >= dropAt) { riseAt = x1; dropAt = x2; }

        // Each end uses the room it actually has, less the breath it leaves.
        const width = (x, rightwards) => {
          const ya = Math.min(rightwards ? y1 : y2, lane), yb = Math.max(rightwards ? y1 : y2, lane);
          const room = clearance(x, ya, yb, ignore, rightwards);
          return Math.max(1, Math.min(26, (room - BREATH) / 2));
        };
        let out = width(riseAt, true), into = width(dropAt, false);

        /* The rise and the drop have to fit between them, or one runs into the
           other and the lane is never reached. */
        const span = dropAt - riseAt;
        if ((out + into) * 2 > span) {
          const shrink = span / ((out + into) * 2);
          out *= shrink; into *= shrink;
        }

        d = `M${P(x1, y1)}`
          + (riseAt > x1 ? ` L${P(riseAt, y1)}` : '')
          + ` C${P(riseAt + out, y1)} ${P(riseAt + out, lane)} ${P(riseAt + out * 2, lane)}`
          + ` L${P(dropAt - into * 2, lane)}`
          + ` C${P(dropAt - into, lane)} ${P(dropAt - into, y2)} ${P(dropAt, y2)}`
          + (dropAt < x2 ? ` L${P(x2, y2)}` : '');
      } else {
        const dx = Math.max(18, (x2 - x1) / 2);
        d = `M${P(x1, y1)} C${P(x1 + dx, y1)} ${P(x2 - dx, y2)} ${P(x2, y2)}`;
      }

      drawn.push({ from, to: node.id, d, tipX: down ? y2 : x2, tipY: down ? x2 : y2 });
    });
  });

  svg.textContent = '';
  const NS = 'http://www.w3.org/2000/svg';
  drawn.forEach((line) => {
    const g = document.createElementNS(NS, 'g');
    g.setAttribute('class', 'edge');
    g.dataset.from = line.from;
    g.dataset.to = line.to;

    const path = document.createElementNS(NS, 'path');
    path.setAttribute('class', 'row');
    path.setAttribute('d', line.d);
    g.append(path);

    const tip = document.createElementNS(NS, 'circle');
    tip.setAttribute('class', 'tip');
    tip.setAttribute('cx', line.tipX);
    tip.setAttribute('cy', line.tipY);
    tip.setAttribute('r', '3');
    g.append(tip);

    svg.append(g);
  });
}

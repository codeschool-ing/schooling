/* ==========================================================================
   Schooling — the small Markdown a lesson is written in

   WHY THERE IS A RENDERER HERE AT ALL. A section's prose is Markdown in a file,
   because a diff per paragraph is the entire reason the catalogue is files
   (C-11). Something has to turn it into a page, and the two places to do it are
   the server and here. It is here because the server has no Markdown dependency
   and adding one is a decision about a dependency that outlives this screen,
   while the subset a lesson actually uses is small enough to read in one
   sitting.

   IT IS A SUBSET AND IT SAYS SO. Headings, paragraphs, lists, fenced code,
   blockquotes, and inline code, bold, italic and links. Anything else comes out
   as the text it is. A renderer that quietly supported half of a feature —
   tables with no header row, nested lists one level deep — would be worse than
   one that supports none: the author would write it, see something that almost
   worked, and never be told.

   EVERYTHING IS ESCAPED FIRST, and then a fixed set of tags is put back. The
   prose comes from our own repository rather than from a student, so this is
   not the last line of defence — but a renderer that pastes source into
   innerHTML is a renderer that turns one bad paste into an injection, and the
   escaping costs one function.
   ========================================================================== */

function escapeHTML(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* Inline markers, applied to text that is ALREADY escaped. The order matters:
   code first, so that a backtick span containing an asterisk is not turned into
   emphasis on its way past. */
function inline(text) {
  return text
    .replace(/`([^`]+)`/g, (_, code) => `<code>${code}</code>`)
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^*])\*([^*]+)\*/g, '$1<em>$2</em>')
    /* Only http(s) and fragments. A link is written by us, but `javascript:`
       arriving through a paste is the one shape of link worth refusing by
       construction rather than by review. */
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+|#[^)\s]*)\)/g,
      '<a href="$2" rel="noopener">$1</a>');
}

export function render(markdown) {
  if (!markdown) return '';

  const lines = escapeHTML(String(markdown)).split('\n');
  const out = [];

  let paragraph = [];
  let list = null;       // 'ul' | 'ol' | null
  let fence = null;      // the language, or '' inside an unlabelled fence

  const closeParagraph = () => {
    if (paragraph.length) {
      out.push(`<p>${inline(paragraph.join(' '))}</p>`);
      paragraph = [];
    }
  };
  const closeList = () => {
    if (list) { out.push(`</${list}>`); list = null; }
  };

  for (const line of lines) {
    const fenced = line.match(/^```\s*([A-Za-z0-9+-]*)\s*$/);
    if (fenced) {
      if (fence === null) {
        closeParagraph(); closeList();
        fence = fenced[1] || '';
        out.push(fence ? `<pre><code class="language-${fence}">` : '<pre><code>');
      } else {
        out.push('</code></pre>');
        fence = null;
      }
      continue;
    }
    if (fence !== null) {
      /* Inside a fence nothing is interpreted, which is the entire point of a
         fence — a lesson about Markdown has to be able to show Markdown. */
      out.push(line + '\n');
      continue;
    }

    if (!line.trim()) { closeParagraph(); closeList(); continue; }

    const heading = line.match(/^(#{1,4})\s+(.*)$/);
    if (heading) {
      closeParagraph(); closeList();
      const level = heading[1].length + 1;   // `#` is the section's own title, so it starts at h2
      out.push(`<h${Math.min(level, 5)}>${inline(heading[2].trim())}</h${Math.min(level, 5)}>`);
      continue;
    }

    const quote = line.match(/^>\s?(.*)$/);
    if (quote) {
      closeParagraph(); closeList();
      out.push(`<blockquote>${inline(quote[1])}</blockquote>`);
      continue;
    }

    const bullet = line.match(/^[-*]\s+(.*)$/);
    const numbered = line.match(/^\d+\.\s+(.*)$/);
    if (bullet || numbered) {
      closeParagraph();
      const want = bullet ? 'ul' : 'ol';
      if (list !== want) { closeList(); out.push(`<${want}>`); list = want; }
      out.push(`<li>${inline((bullet || numbered)[1])}</li>`);
      continue;
    }

    closeList();
    paragraph.push(line.trim());
  }

  closeParagraph();
  closeList();
  if (fence !== null) out.push('</code></pre>');   // an unclosed fence, rendered rather than lost

  return out.join('');
}

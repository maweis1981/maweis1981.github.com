// Markdown -> WeChat-compatible HTML.
//
// WeChat 公众号 article content has hard restrictions:
//   - No <style> blocks. No external CSS. Only inline `style="..."` is preserved.
//   - Classes are mostly stripped by the editor.
//   - Some tags get reformatted (e.g. <table> needs explicit borders).
//
// This converter:
//   1. Runs the body through markdown-it (no plugins, html: true)
//   2. Detects Chirpy's `{: .prompt-info | tip | warning | danger }` markers
//      that follow a blockquote and rewrites that blockquote with a colored box
//   3. Walks the remaining tags and injects an inline style if none is set yet
//
// Only AI Daily-style posts are exercised here. If you start using inline
// images or KaTeX in posts, the rules below probably need to be extended.

import MarkdownIt from 'markdown-it';

const STYLE = {
  h1: 'font-size:22px;font-weight:600;margin:1.6em 0 0.6em;color:#222;line-height:1.4',
  h2: 'font-size:18px;font-weight:600;margin:1.4em 0 0.5em;color:#1c1c1c;border-left:4px solid #2d8cf0;padding-left:10px;line-height:1.5',
  h3: 'font-size:16px;font-weight:600;margin:1.2em 0 0.4em;color:#222;line-height:1.5',
  h4: 'font-size:15px;font-weight:600;margin:1em 0 0.4em;color:#333;line-height:1.5',
  p:  'font-size:15px;line-height:1.75;margin:0.7em 0;color:#3f3f3f',
  blockquote: 'border-left:3px solid #ccc;padding:0.4em 1em;margin:1em 0;color:#666;font-size:14px;background:#fafafa',
  ul: 'padding-left:1.6em;margin:0.6em 0;color:#3f3f3f',
  ol: 'padding-left:1.6em;margin:0.6em 0;color:#3f3f3f',
  li: 'margin:0.35em 0;line-height:1.75;font-size:15px',
  strong: 'color:#1c1c1c;font-weight:600',
  em: 'color:#333',
  code: 'background:#f3f3f3;padding:1px 6px;border-radius:3px;font-family:Menlo,Consolas,"Microsoft YaHei Mono",monospace;font-size:13px;color:#c7254e',
  pre:  'background:#282c34;color:#e6e6e6;padding:1em;border-radius:6px;overflow-x:auto;font-family:Menlo,Consolas,monospace;font-size:13px;line-height:1.55;margin:1em 0',
  hr:   'border:none;border-top:1px solid #e3e3e3;margin:1.6em 0',
  table: 'border-collapse:collapse;margin:1em 0;width:100%;font-size:13px',
  th:    'background:#f3f3f3;padding:8px 10px;border:1px solid #d8d8d8;text-align:left;font-weight:600',
  td:    'padding:8px 10px;border:1px solid #d8d8d8;vertical-align:top',
  img:  'max-width:100%;height:auto;display:block;margin:1em auto',
  a:    'color:#2d8cf0;text-decoration:none;word-break:break-all',
};

const PROMPT_BOX = {
  info:    { bg: '#eef5fc', bar: '#2d8cf0' },
  tip:     { bg: '#eef9ef', bar: '#3eaf7c' },
  warning: { bg: '#fff8e6', bar: '#e7c000' },
  danger:  { bg: '#fef0f0', bar: '#cf222e' },
};

function promptBoxStyle(type) {
  const c = PROMPT_BOX[type] || PROMPT_BOX.info;
  return `background:${c.bg};border-left:4px solid ${c.bar};padding:12px 16px;border-radius:4px;margin:1.2em 0;color:#333;font-size:14.5px;line-height:1.7`;
}

// Two possible layouts in the source:
//   1. The marker is on its own line right after the blockquote with NO blank
//      line in between. Markdown-it (CommonMark) treats this as a lazy
//      continuation of the blockquote paragraph, so the marker text ends up
//      INSIDE the rendered <blockquote>.
//   2. The marker is preceded by a blank line and renders as its own <p> after
//      the </blockquote>.
function rewritePromptBoxes(html) {
  let out = html;

  // Case 1: marker absorbed inside the blockquote.
  out = out.replace(
    /<blockquote(?![^>]*style=)>([\s\S]*?)<\/blockquote>/g,
    (full, inner) => {
      const m = inner.match(/\{:\s*\.prompt-(info|tip|warning|danger)\s*\}/);
      if (!m) return full;
      const cleaned = inner.replace(/\s*\{:\s*\.prompt-\w+\s*\}\s*/g, '');
      return `<blockquote style="${promptBoxStyle(m[1])}">${cleaned}</blockquote>`;
    }
  );

  // Case 2: marker as its own <p> after a blockquote (kramdown-style with blank line).
  out = out.replace(
    /<blockquote(?![^>]*style=)>([\s\S]*?)<\/blockquote>\s*<p>\s*\{:\s*\.prompt-(\w+)\s*\}\s*<\/p>/g,
    (_full, inner, type) =>
      `<blockquote style="${promptBoxStyle(type)}">${inner}</blockquote>`
  );

  return out;
}

function injectInlineStyles(html) {
  let out = html;
  for (const [tag, style] of Object.entries(STYLE)) {
    // Match tag opens without an existing style attribute, preserving any other attrs.
    const re = new RegExp(`<${tag}((?:\\s[^>]*)?)>`, 'g');
    out = out.replace(re, (full, attrs) => {
      if (/\sstyle=/.test(attrs)) return full;
      return `<${tag}${attrs} style="${style}">`;
    });
  }
  return out;
}

// Some markdown sources put `{:` markers on lines other than after a blockquote
// (e.g. heading attribute lists in kramdown). WeChat shows them as literal text,
// so strip any leftover.
function stripStaleAttrMarkers(html) {
  return html.replace(/<p>\s*\{:[^}]*\}\s*<\/p>/g, '');
}

export function convertMarkdown(markdownBody) {
  const md = new MarkdownIt({ html: true, breaks: false, linkify: true, typographer: false });

  // markdown-it's default fence renderer wraps code in <pre><code class="language-x">.
  // We collapse to just <pre>...</pre> with the code's text, since WeChat strips
  // class-based syntax highlighting anyway.
  md.renderer.rules.fence = (tokens, idx) => {
    const token = tokens[idx];
    const escaped = md.utils.escapeHtml(token.content);
    return `<pre><code>${escaped}</code></pre>\n`;
  };

  // WeChat's editor renders native <ul>/<li> bullets unreliably — it injects a
  // stray empty bullet before each item (see IMG_5628). The robust fix used by
  // md->WeChat tools (Mdnice etc.): don't emit <ul>/<li> at all. Render each
  // item as a <section> with a manual "• " (or "N. ") marker and a hanging
  // indent. We override the list renderer rules with a per-render marker stack
  // so ordered lists number correctly and nesting indents.
  const listStack = [];
  md.renderer.rules.bullet_list_open = () => { listStack.push({ type: 'ul' }); return ''; };
  md.renderer.rules.bullet_list_close = () => { listStack.pop(); return ''; };
  md.renderer.rules.ordered_list_open = (tokens, idx) => {
    const start = Number(tokens[idx].attrGet('start') || 1);
    listStack.push({ type: 'ol', n: start });
    return '';
  };
  md.renderer.rules.ordered_list_close = () => { listStack.pop(); return ''; };
  md.renderer.rules.list_item_open = () => {
    const ctx = listStack[listStack.length - 1] || { type: 'ul' };
    const marker = ctx.type === 'ol' ? `${ctx.n++}. ` : '• ';
    const depth = Math.max(1, listStack.length);
    const padLeft = (0.4 + 1.1 * depth).toFixed(2);
    // <section> (not <p>) so a loose-list inner <p> stays valid markup;
    // text-indent gives the hanging-bullet effect for the common tight list.
    return `<section style="margin:0.3em 0;padding-left:${padLeft}em;text-indent:-1.1em;line-height:1.75;font-size:15px;color:#3f3f3f"><span style="color:#9a9a9a">${marker}</span>`;
  };
  md.renderer.rules.list_item_close = () => '</section>\n';

  const rendered = md.render(markdownBody);
  return injectInlineStyles(stripStaleAttrMarkers(rewritePromptBoxes(rendered)));
}

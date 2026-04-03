/** Minimal Markdown: headings, bold, italic, links, lists, paragraphs */
export function parseMarkdown(md) {
  const lines = md.split('\n');
  let html = '';
  let inList = false;

  for (let line of lines) {
    const trimmed = line.trim();

    // Close list if line is not a list item
    if (inList && !trimmed.startsWith('- ') && !trimmed.startsWith('* ')) {
      html += '</ul>';
      inList = false;
    }

    if (trimmed === '') {
      html += '';
    } else if (trimmed.startsWith('### ')) {
      html += `<h4>${inline(trimmed.slice(4))}</h4>`;
    } else if (trimmed.startsWith('## ')) {
      html += `<h3>${inline(trimmed.slice(3))}</h3>`;
    } else if (trimmed.startsWith('# ')) {
      html += `<h2>${inline(trimmed.slice(2))}</h2>`;
    } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      if (!inList) { html += '<ul>'; inList = true; }
      html += `<li>${inline(trimmed.slice(2))}</li>`;
    } else {
      html += `<p>${inline(trimmed)}</p>`;
    }
  }
  if (inList) html += '</ul>';
  return html;
}

function inline(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
}

const STATUS_LABELS = {
  scheduled: 'Geplant',
  live: 'Live',
  completed: 'Beendet',
  pause: 'Pause',
};

const STATUS_ORDER = { live: 0, scheduled: 1, pause: 1, completed: 2 };

export function formatTime(isoString) {
  const d = new Date(isoString);
  return d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
}

export function formatScore(scoreA, scoreB) {
  if (scoreA == null || scoreB == null) return '';
  return `${scoreA} : ${scoreB}`;
}

export function getStatusClass(status) {
  return `match-card--${status}`;
}

export function getStatusLabel(status) {
  return STATUS_LABELS[status] || status;
}

export function sortMatches(matches) {
  return [...matches].sort((a, b) => {
    const orderDiff = (STATUS_ORDER[a.status] ?? 9) - (STATUS_ORDER[b.status] ?? 9);
    if (orderDiff !== 0) return orderDiff;
    return new Date(a.startTime) - new Date(b.startTime);
  });
}

export function timeAgo(isoString) {
  if (!isoString) return '';
  const diff = Math.floor((Date.now() - new Date(isoString).getTime()) / 1000);
  if (diff < 60) return 'gerade eben';
  if (diff < 3600) return `vor ${Math.floor(diff / 60)} Min.`;
  return `vor ${Math.floor(diff / 3600)} Std.`;
}

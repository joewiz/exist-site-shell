/**
 * Function documentation hover popups and LSP integration.
 *
 * Provides two capabilities:
 * 1. Hover popups on prose function reference links ({docs}/functions/...)
 * 2. LSP helper for code cells (hover, completions, diagnostics)
 *
 * Uses exist-api's REST LSP endpoints — the same infrastructure that
 * powers eXide and VS Code.
 *
 * @module function-docs
 */

const LSP_BASE = '/exist/apps/exist-api';
const CACHE = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

// ========== LSP REST Client ==========

/**
 * Send a hover request to the LSP endpoint.
 * @param {string} expression - XQuery expression
 * @param {number} line - 0-based line number
 * @param {number} column - 0-based column number
 * @param {string} [moduleLoadPath] - optional module load path
 * @returns {Promise<{contents: string, kind: string}|null>}
 */
export async function lspHover(expression, line, column, moduleLoadPath) {
    const body = { expression, line, column };
    if (moduleLoadPath) body['module-load-path'] = moduleLoadPath;
    return lspRequest('/api/lsp/hover', body);
}

/**
 * Send a completions request to the LSP endpoint.
 * @param {string} expression - XQuery expression
 * @param {string} [moduleLoadPath] - optional module load path
 * @returns {Promise<Array>}
 */
export async function lspCompletions(expression, moduleLoadPath) {
    const body = { expression };
    if (moduleLoadPath) body['module-load-path'] = moduleLoadPath;
    return lspRequest('/api/lsp/completions', body);
}

/**
 * Send a diagnostics request to the LSP endpoint.
 * @param {string} expression - XQuery expression
 * @param {string} [moduleLoadPath] - optional module load path
 * @returns {Promise<Array>}
 */
export async function lspDiagnostics(expression, moduleLoadPath) {
    const body = { expression };
    if (moduleLoadPath) body['module-load-path'] = moduleLoadPath;
    return lspRequest('/api/lsp/diagnostics', body);
}

async function lspRequest(path, body) {
    try {
        const resp = await fetch(LSP_BASE + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'same-origin',
            body: JSON.stringify(body)
        });
        if (!resp.ok) return null;
        return resp.json();
    } catch (e) {
        console.debug('LSP request failed:', e);
        return null;
    }
}

// ========== Function Hover for Prose Links ==========

/**
 * Get function documentation by library and name.
 *
 * Fetches from the docs app's Roaster API: GET {docs}/api/functions/{prefix}/{name}
 * Falls back to exist-db.org if the local docs app is not available.
 * No synthetic expressions or LSP hacks — the docs app serves its own
 * pre-indexed function data directly.
 *
 * @param {string} library - module prefix (e.g., 'fn', 'util', 'crypto')
 * @param {string} name - function local name (e.g., 'hash')
 * @returns {Promise<{signature: string, description: string, url: string}|null>}
 */
export async function getFunctionDocs(library, name) {
    const cacheKey = `${library}:${name}`;
    const cached = CACHE.get(cacheKey);
    if (cached && Date.now() - cached.time < CACHE_TTL) {
        return cached.data;
    }

    // Try local docs app, then exist-db.org fallback
    const contextPath = window.location.pathname.replace(/\/apps\/.*/, '');
    const localUrl = `${contextPath}/apps/docs/api/functions/${library}/${name}`;
    const fallbackUrl = `https://exist-db.org/exist/apps/docs/api/functions/${library}/${name}`;

    let result = await fetchJson(localUrl);
    if (!result) {
        result = await fetchJson(fallbackUrl);
    }
    if (!result || !result.signatures) return null;

    // Use the first signature (there may be multiple arities)
    const first = result.signatures[0] || {};
    const signature = first.signature || `${library}:${name}()`;
    const description = first.description || '';

    const data = { signature, description, url: result.url || null };
    CACHE.set(cacheKey, { data, time: Date.now() });
    return data;
}

async function fetchJson(url) {
    try {
        const resp = await fetch(url, {
            headers: { 'Accept': 'application/json' },
            credentials: 'same-origin'
        });
        if (!resp.ok) return null;
        return resp.json();
    } catch (e) {
        return null;
    }
}

// ========== Tooltip UI ==========

let activeTooltip = null;

function createTooltip(anchor, docs) {
    removeTooltip();

    const tooltip = document.createElement('div');
    tooltip.className = 'fn-docs-tooltip';
    tooltip.innerHTML = `
        <div class="fn-docs-signature"><code>${escapeHtml(docs.signature)}</code></div>
        ${docs.description ? `<div class="fn-docs-description">${escapeHtml(docs.description)}</div>` : ''}
        ${docs.url ? `<a class="fn-docs-link" href="${docs.url}">View full docs &rarr;</a>` : ''}
    `;

    // Position: prefer below-right, flip if it would overflow viewport
    const rect = anchor.getBoundingClientRect();
    tooltip.style.position = 'fixed';
    tooltip.style.zIndex = '10000';
    tooltip.style.visibility = 'hidden';
    document.body.appendChild(tooltip);

    const tw = tooltip.offsetWidth;
    const th = tooltip.offsetHeight;
    const vw = window.innerWidth;
    const vh = window.innerHeight;

    let left = rect.left;
    let top = rect.bottom;

    if (top + th > vh) top = rect.top - th;           // flip above
    if (left + tw > vw) left = Math.max(0, vw - tw - 8); // shift left
    if (top < 0) top = 4;
    if (left < 0) left = 4;

    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${top}px`;
    tooltip.style.visibility = '';
    activeTooltip = tooltip;

    // Close with a short grace period so the mouse can cross to the tooltip
    let closeTimer = null;
    const scheduleClose = () => {
        closeTimer = setTimeout(() => {
            if (!tooltip.matches(':hover') && !anchor.matches(':hover')) {
                removeTooltip();
                anchor.removeEventListener('mouseleave', scheduleClose);
                tooltip.removeEventListener('mouseleave', scheduleClose);
            }
        }, 200);
    };
    const cancelClose = () => {
        if (closeTimer) { clearTimeout(closeTimer); closeTimer = null; }
    };
    anchor.addEventListener('mouseleave', scheduleClose);
    anchor.addEventListener('mouseenter', cancelClose);
    tooltip.addEventListener('mouseleave', scheduleClose);
    tooltip.addEventListener('mouseenter', cancelClose);
}

function removeTooltip() {
    if (activeTooltip) {
        activeTooltip.remove();
        activeTooltip = null;
    }
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ========== Auto-attach to Prose Links ==========

/**
 * Initialize hover popups on all function documentation links.
 * Call this after the page content is rendered.
 *
 * Looks for links matching the pattern:
 *   href="...functions/{library}/{name}"
 *   href="{docs}/functions/{library}/{name}"
 *
 * Also resolves {docs} tokens to the local docs app URL if available,
 * or to exist-db.org as fallback.
 */
export function initProseHovers() {
    // Resolve {docs} tokens in href attributes
    resolveDocsTokens();

    const links = document.querySelectorAll('a[href*="/functions/"]');
    const fnPattern = /\/functions\/([a-z]+)\/([a-z][\w-]*)/;

    for (const link of links) {
        const match = link.href.match(fnPattern) || link.getAttribute('href').match(fnPattern);
        if (!match) continue;

        const [, library, name] = match;
        let hoverTimer = null;

        link.addEventListener('mouseenter', () => {
            hoverTimer = setTimeout(async () => {
                const docs = await getFunctionDocs(library, name);
                if (docs) {
                    docs.url = link.href;
                    createTooltip(link, docs);
                }
            }, 300); // 300ms delay to avoid flicker
        });

        link.addEventListener('mouseleave', () => {
            if (hoverTimer) {
                clearTimeout(hoverTimer);
                hoverTimer = null;
            }
        });
    }
}

/**
 * Resolve {docs} tokens in href attributes to actual URLs.
 * Checks if the local docs app is available; falls back to exist-db.org.
 */
function resolveDocsTokens() {
    const links = document.querySelectorAll('a[href*="{docs}"]');
    if (!links.length) return;

    // Try local docs app first
    const contextPath = document.querySelector('html')?.dataset?.contextPath
        || window.location.pathname.replace(/\/apps\/.*/, '');
    const localDocsBase = contextPath + '/apps/docs';
    const fallbackBase = 'https://exist-db.org/exist/apps/docs';

    // Resolve all {docs} links — optimistically use local, the browser
    // will follow redirects to exist-db.org if local isn't available
    for (const link of links) {
        const href = link.getAttribute('href');
        link.setAttribute('href', href.replace('{docs}', localDocsBase));
    }
}

// Auto-init when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initProseHovers);
} else {
    // Defer to allow dynamic content to render
    setTimeout(initProseHovers, 100);
}

/**
 * Search scope selector for the site shell nav bar.
 *
 * Shows a dropdown on focus that lets the user restrict the search
 * to a specific app (or "All apps"). Pressing Enter or submitting the
 * form includes ?app=<abbrev> in the request.
 *
 * Keyboard: ArrowDown/Up to navigate, Enter/Space to select, Escape to close.
 * The dropdown also closes when focus moves outside the wrapper.
 */
(function () {
    'use strict';

    const wrapper = document.querySelector('.site-search-wrapper');
    if (!wrapper) { return; }

    const input     = document.getElementById('site-search-input');
    const scopeBtn  = document.getElementById('search-scope-btn');
    const scopeLabel = document.getElementById('search-scope-label');
    const popup     = document.getElementById('search-scope-popup');
    const appInput  = document.getElementById('search-app-input');

    if (!input || !popup || !appInput) { return; }

    // ── Helpers ────────────────────────────────────────────────────────────

    function openPopup() {
        popup.hidden = false;
        scopeBtn.setAttribute('aria-expanded', 'true');
    }

    function closePopup() {
        popup.hidden = true;
        scopeBtn.setAttribute('aria-expanded', 'false');
    }

    function selectOption(opt, returnFocus) {
        const abbrev = opt.dataset.abbrev;
        const label  = opt.dataset.label;

        appInput.value = abbrev;

        // Update button label — show app title when scoped, "All" otherwise
        if (scopeLabel) {
            scopeLabel.textContent = abbrev ? label : 'All';
        }
        if (scopeBtn) {
            scopeBtn.setAttribute('aria-label', 'Search scope: ' + (abbrev ? label : 'All apps'));
        }

        // Update aria-selected on all options
        popup.querySelectorAll('.scope-opt').forEach(function (o) {
            o.setAttribute('aria-selected', o === opt ? 'true' : 'false');
        });

        closePopup();
        if (returnFocus) { input.focus(); }
    }

    // ── Initial state: pre-select the active app if there is one ───────────

    const activeOpt = popup.querySelector('.scope-opt[data-active="true"]');
    const allOpt    = popup.querySelector('.scope-opt[data-abbrev=""]');

    if (allOpt) {
        allOpt.setAttribute('aria-selected', activeOpt ? 'false' : 'true');
    }
    if (activeOpt) {
        // Auto-scope to the current app on page load (no focus — avoid opening popup)
        selectOption(activeOpt, false);
    }

    // ── Open on input focus ────────────────────────────────────────────────

    input.addEventListener('focus', openPopup);

    // ── Toggle on scope button click ───────────────────────────────────────

    scopeBtn.addEventListener('click', function () {
        if (popup.hidden) { openPopup(); } else { closePopup(); }
    });

    // ── Option click ───────────────────────────────────────────────────────

    popup.addEventListener('click', function (e) {
        const opt = e.target.closest('.scope-opt');
        if (opt) { selectOption(opt, true); }
    });

    // ── Close when focus leaves the entire wrapper ─────────────────────────
    // Use focusout with a small delay to allow focus to settle inside the popup

    wrapper.addEventListener('focusout', function () {
        setTimeout(function () {
            if (!wrapper.contains(document.activeElement)) {
                closePopup();
            }
        }, 150);
    });

    // ── Close on click outside the wrapper ────────────────────────────────

    document.addEventListener('click', function (e) {
        if (!wrapper.contains(e.target)) {
            closePopup();
        }
    });

    // ── Keyboard: input ────────────────────────────────────────────────────

    input.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            closePopup();
            return;
        }
        if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (popup.hidden) { openPopup(); }
            const first = popup.querySelector('.scope-opt');
            if (first) { first.focus(); }
        }
    });

    // ── Keyboard: popup list ───────────────────────────────────────────────

    popup.addEventListener('keydown', function (e) {
        const items = Array.from(popup.querySelectorAll('.scope-opt'));
        const idx   = items.indexOf(document.activeElement);

        switch (e.key) {
            case 'ArrowDown':
                e.preventDefault();
                if (idx < items.length - 1) { items[idx + 1].focus(); }
                break;
            case 'ArrowUp':
                e.preventDefault();
                if (idx > 0) {
                    items[idx - 1].focus();
                } else {
                    closePopup();
                    input.focus();
                }
                break;
            case 'Enter':
            case ' ':
                e.preventDefault();
                if (idx >= 0) { selectOption(items[idx], true); }
                break;
            case 'Escape':
                closePopup();
                input.focus();
                break;
            case 'Tab':
                closePopup();
                break;
        }
    });
}());

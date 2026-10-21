"""Collect public Murlok Meta as rendered, not the stale initial HTML response.

Runs only in the external data job. No browser, network code or new dependency
is shipped inside the WoW addon. A stale or blocked page is a failed refresh.
"""
import datetime as dt
from pathlib import Path
from collect_gear import source_date


def verify_date(html, now=None):
    stamp = source_date(html, None)
    published = dt.datetime.fromisoformat(stamp.replace('Z', '+00:00'))
    now = now or dt.datetime.now(dt.timezone.utc)
    if not -300 <= (now - published).total_seconds() <= 36 * 3600:
        raise ValueError('Murlok rendered Meta is older than 36 hours or future-dated')
    return stamp


def collect_pages(cache):
    """Return each role independently; a browser/source failure never becomes OK."""
    result = {}
    try:
        from playwright.sync_api import sync_playwright, Error
    except ImportError:
        return result
    try:
        with sync_playwright() as runtime:
            browser = runtime.chromium.launch(headless=True)
            context = browser.new_context(locale='en-US')
            for role, count in [('dps', 27), ('healer', 7), ('tank', 6)]:
                page = context.new_page()
                try:
                    response = page.goto('https://murlok.io/meta/' + role + '/m%2B', wait_until='domcontentloaded', timeout=45000)
                    if not response or response.status != 200:
                        raise ValueError('Public Meta page unavailable')
                    page.locator('#app-wasm-loader').wait_for(state='hidden', timeout=30000)
                    # Wait for hydration, not merely SSR rows. Cached initial HTML
                    # can contain a full but several-days-old ranking.
                    page.wait_for_function('''expected => {
                        const rows = document.querySelectorAll('a.meta-item');
                        const stamp = document.querySelector('time')?.getAttribute('datetime');
                        const age = Date.now() - Date.parse(stamp);
                        return rows.length === expected && age >= -300000 && age <= 129600000;
                    }''', arg=count, timeout=30000)
                    html = page.content()
                    verify_date(html)
                    result[role] = html
                    Path(cache, 'meta-' + role + '.html').write_text(html, encoding='utf-8')
                except (Error, OSError, ValueError):
                    print('Murlok rendered Meta ' + role + ': unavailable/stale; previous snapshot will be retained')
                finally:
                    page.close()
            browser.close()
    except (Error, OSError):
        print('Murlok renderer unavailable; no successful refresh will be claimed')
    return result

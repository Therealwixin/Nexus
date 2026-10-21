"""Collect public Murlok Meta as rendered, not the stale initial HTML response.

Runs only in the external data job. No browser, network code or new dependency
is shipped inside the WoW addon. A stale or blocked page is a failed refresh.
"""
import datetime as dt
import asyncio
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


def collect_gear_pages(cache):
    """One shared browser, at most two aggregate pages at once; never profiles."""
    from catalog import SPECS

    async def run():
        from playwright.async_api import async_playwright, Error
        result = {}
        async with async_playwright() as runtime:
            browser = await runtime.chromium.launch(headless=True)
            context = await browser.new_context(locale='en-US')
            limit = asyncio.Semaphore(2)

            async def collect(spec):
                async with limit:
                    page = await context.new_page()
                    slug = spec['classSlug'] + '-' + spec['slug']
                    try:
                        url = 'https://murlok.io/' + spec['classSlug'] + '/' + spec['slug'] + '/m%2B'
                        response = await page.goto(url, wait_until='domcontentloaded', timeout=45000)
                        if not response or response.status != 200:
                            raise ValueError('Public aggregate page unavailable')
                        await page.locator('#app-wasm-loader').wait_for(state='hidden', timeout=30000)
                        await page.wait_for_function('''() => {
                            const stamp = document.querySelector('time')?.getAttribute('datetime');
                            const age = Date.now() - Date.parse(stamp);
                            return age >= -300000 && age <= 129600000
                                && document.querySelectorAll('#gear h3').length >= 12
                                && document.querySelector('#stat-priority');
                        }''', timeout=30000)
                        html = await page.content()
                        verify_date(html)
                        # Validate the entire aggregate before saving the rendered cache.
                        from parsers import parse_murlok
                        parse_murlok(html, verify_date(html))
                        Path(cache, slug + '-murlok.html').write_text(html, encoding='utf-8')
                        result[str(spec['id'])] = html
                        print('Rendered aggregate: ' + slug, flush=True)
                    except (Error, OSError, ValueError):
                        print('Rendered aggregate unavailable: ' + slug, flush=True)
                    finally:
                        await page.close()

            try:
                await asyncio.gather(*(collect(spec) for spec in SPECS))
            finally:
                await browser.close()
        return result

    try:
        return asyncio.run(run())
    except (ImportError, OSError) as error:
        raise ValueError('Rendered aggregate collector unavailable') from error


def render_raid_page(url):
    """One normal public-page fallback when direct U.GG HTML is unavailable."""
    try:
        from playwright.sync_api import sync_playwright, Error
    except ImportError:
        return None
    try:
        with sync_playwright() as runtime:
            browser = runtime.chromium.launch(headless=True)
            page = browser.new_page(locale='en-US')
            try:
                response = page.goto(url, wait_until='domcontentloaded', timeout=45000)
                if not response or response.status != 200:
                    return None
                page.wait_for_function("document.documentElement.innerHTML.includes('raid-default-tierlist.json')", timeout=20000)
                return page.content()
            finally:
                browser.close()
    except (Error, OSError):
        return None

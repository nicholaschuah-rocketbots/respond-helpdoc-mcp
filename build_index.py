"""
build_index.py — Fetches the respond.io help sitemap and builds index.md.

Usage:
    uv run python build_index.py
"""

import re
import sys
import xml.etree.ElementTree as ET
from datetime import date

import frontmatter
import httpx

SITEMAP_URL = "https://respond.io/sitemap-help-articles.xml"
ENGLISH_URL_RE = re.compile(r"^https://respond\.io/help/[^/]+/[^/]+$")
OUTPUT_FILE = "index.md"


def fetch_sitemap(client: httpx.Client) -> list[str]:
    resp = client.get(SITEMAP_URL)
    resp.raise_for_status()
    root = ET.fromstring(resp.text)
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    urls = [loc.text.strip() for loc in root.findall(".//sm:loc", ns) if loc.text]
    return [u for u in urls if ENGLISH_URL_RE.match(u)]


def parse_slug(url: str) -> tuple[str, str]:
    """Return (category, slug) derived from the URL."""
    # url like https://respond.io/help/quick-start/getting-started-with-respond-io
    path_parts = url.split("/help/", 1)[1].split("/")
    category = path_parts[0]
    article = path_parts[1]
    slug = f"{category}/{article}"
    return category, slug


def fetch_article(client: httpx.Client, url: str) -> dict | None:
    """Fetch {url}.md and return parsed frontmatter fields, or None on error."""
    try:
        resp = client.get(f"{url}.md", timeout=15.0)
        resp.raise_for_status()
    except httpx.HTTPStatusError as exc:
        print(f"  WARNING: HTTP {exc.response.status_code} for {url}", file=sys.stderr)
        return None
    except httpx.RequestError as exc:
        print(f"  WARNING: Request error for {url}: {exc}", file=sys.stderr)
        return None

    try:
        post = frontmatter.loads(resp.text)
    except Exception as exc:
        print(f"  WARNING: Could not parse frontmatter for {url}: {exc}", file=sys.stderr)
        return None
    title = post.metadata.get("title", "")
    description = post.metadata.get("description") or title
    return {"title": title, "description": description}


def title_case_category(category: str) -> str:
    return category.replace("-", " ").title()


def build_index(articles_by_category: dict[str, list[dict]]) -> str:
    today = date.today().isoformat()
    lines = [
        "# Respond.io Help — Topic Index",
        "",
        f"> Last built: {today}. Run `python build_index.py` to refresh.",
    ]
    for category, articles in articles_by_category.items():
        heading = title_case_category(category)
        lines.append("")
        lines.append(f"## {heading}")
        for article in articles:
            lines.append(f"- `{article['slug']}` — {article['description']}")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    with httpx.Client(follow_redirects=True, timeout=30.0) as client:
        print("Fetching sitemap…", file=sys.stderr)
        try:
            urls = fetch_sitemap(client)
        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            print(f"ERROR: Could not fetch sitemap: {e}", file=sys.stderr)
            sys.exit(1)
        total = len(urls)
        print(f"Found {total} English articles", file=sys.stderr)

        articles_by_category: dict[str, list[dict]] = {}

        for n, url in enumerate(urls, start=1):
            category, slug = parse_slug(url)
            print(f"Fetching {n}/{total}: {slug}", file=sys.stderr)

            data = fetch_article(client, url)
            if data is None:
                continue

            entry = {"slug": slug, "description": data["description"]}
            articles_by_category.setdefault(category, []).append(entry)

    content = build_index(articles_by_category)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    total_articles = sum(len(v) for v in articles_by_category.values())
    total_categories = len(articles_by_category)
    print(
        f"Built index.md with {total_articles} articles in {total_categories} categories"
    )


if __name__ == "__main__":
    main()

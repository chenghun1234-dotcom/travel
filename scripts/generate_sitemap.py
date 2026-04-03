"""
generate_sitemap.py
──────────────────
assets/posts/index.json 기반으로 web/sitemap.xml 생성.
Flutter build 시 web/ 정적 파일이 build/web로 복사되어 함께 배포됩니다.
"""
from __future__ import annotations

import json
import logging
import os
from datetime import date
from pathlib import Path

from config import POSTS_DIR, WEB_DIR

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

INDEX_FILE = POSTS_DIR / "index.json"
SITEMAP_FILE = WEB_DIR / "sitemap.xml"
ROBOTS_FILE = WEB_DIR / "robots.txt"


def build_url(base: str, path: str) -> str:
    return f"{base.rstrip('/')}/{path.lstrip('/')}"


def generate_sitemap(base_url: str, posts: list[dict]) -> str:
    today = date.today().isoformat()
    lines: list[str] = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
        "  <url>",
        f"    <loc>{base_url.rstrip('/')}/</loc>",
        f"    <lastmod>{today}</lastmod>",
        "    <changefreq>daily</changefreq>",
        "    <priority>1.0</priority>",
        "  </url>",
    ]

    for post in posts:
        slug = post.get("slug", "")
        if not slug:
            continue
        post_url = build_url(base_url, f"post/{slug}")
        lastmod = str(post.get("publishedAt", "")).split("T")[0]
        lines.extend(
            [
                "  <url>",
                f"    <loc>{post_url}</loc>",
                f"    <lastmod>{lastmod}</lastmod>" if lastmod else "    <changefreq>weekly</changefreq>",
                "    <changefreq>daily</changefreq>",
                "    <priority>0.8</priority>",
                "  </url>",
            ]
        )

    lines.append("</urlset>")
    return "\n".join(lines) + "\n"


def main() -> None:
    WEB_DIR.mkdir(parents=True, exist_ok=True)

    base_url = os.environ.get(
        "GITHUB_PAGES_BASE_URL",
        "https://YOUR_GITHUB_USERNAME.github.io/YOUR_REPOSITORY_NAME",
    )

    posts: list[dict] = []
    if INDEX_FILE.exists():
        posts = json.loads(INDEX_FILE.read_text(encoding="utf-8"))

    sitemap_xml = generate_sitemap(base_url, posts)
    SITEMAP_FILE.write_text(sitemap_xml, encoding="utf-8")
    log.info("sitemap.xml 생성 완료: %s (%d개 URL)", SITEMAP_FILE, len(posts) + 1)

    robots_txt = (
        "User-agent: *\n"
        "Allow: /\n\n"
        "User-agent: Googlebot\n"
        "Allow: /\n\n"
        "User-agent: Yeti\n"
        "Allow: /\n\n"
        f"Sitemap: {base_url.rstrip('/')}/sitemap.xml\n"
    )
    ROBOTS_FILE.write_text(robots_txt, encoding="utf-8")
    log.info("robots.txt 생성 완료: %s", ROBOTS_FILE)


if __name__ == "__main__":
    main()
"""
update_seo_meta.py
──────────────────
index.json의 최신 포스트를 읽어 web/index.html의 <meta> 태그를
동적으로 업데이트합니다. GitHub Actions 빌드 전에 실행됩니다.
"""
from __future__ import annotations

import json
import logging
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from config import POSTS_DIR, WEB_DIR

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

INDEX_FILE = POSTS_DIR / "index.json"
HTML_FILE = WEB_DIR / "index.html"

SITE_URL = os.environ.get(
    "GITHUB_PAGES_BASE_URL",
    "https://YOUR_GITHUB_USERNAME.github.io/YOUR_REPOSITORY_NAME",
)
ROOT_URL = SITE_URL.rstrip("/")
SITE_NAME = "한국 축제 여행 블로그"
DEFAULT_DESC = "AI가 매일 업데이트하는 대한민국 전국 축제 여행 가이드"
DEFAULT_KEYWORDS = "한국 축제, 국내 여행, 축제 일정, 여행 블로그, 2026 축제"
GOOGLE_SITE_VERIFICATION = os.environ.get("GOOGLE_SITE_VERIFICATION", "")
NAVER_SITE_VERIFICATION = os.environ.get("NAVER_SITE_VERIFICATION", "")


def load_latest_post() -> dict | None:
    if not INDEX_FILE.exists():
        return None
    posts = json.loads(INDEX_FILE.read_text(encoding="utf-8"))
    return posts[0] if posts else None


def replace_meta_tag(html: str, name_or_property: str, value: str) -> str:
    """name 또는 property 기반 meta content 교체"""
    # <meta name="..." content="..."> 패턴
    pattern_name = rf'(<meta\s+name="{re.escape(name_or_property)}"\s+content=")([^"]*)(">)'
    # <meta property="..." content="..."> 패턴
    pattern_prop = rf'(<meta\s+property="{re.escape(name_or_property)}"\s+content=")([^"]*)(">)'

    result = re.sub(pattern_name, rf'\g<1>{value}\g<3>', html)
    result = re.sub(pattern_prop, rf'\g<1>{value}\g<3>', result)
    return result


def replace_title(html: str, title: str) -> str:
    return re.sub(r"<title>.*?</title>", f"<title>{title}</title>", html)


def replace_canonical(html: str, url: str) -> str:
    pattern = r'(<link\s+rel="canonical"\s+href=")([^"]*)("\s*/?>)'
    if re.search(pattern, html):
        return re.sub(pattern, rf'\g<1>{url}\g<3>', html)

    insert_point = html.find("</head>")
    if insert_point == -1:
        return html
    return html[:insert_point] + f'  <link rel="canonical" href="{url}">\n' + html[insert_point:]


def replace_placeholder_urls(html: str, base_url: str) -> str:
    return re.sub(
        r"https://YOUR_GITHUB_USERNAME\.github\.io(?:/YOUR_REPOSITORY_NAME)?/?",
        f"{base_url.rstrip('/')}/",
        html,
    )


def upsert_meta_name(html: str, key: str, value: str) -> str:
    pattern = rf'(<meta\s+name="{re.escape(key)}"\s+content=")([^"]*)("\s*/?>)'
    if re.search(pattern, html):
        return re.sub(pattern, rf'\g<1>{value}\g<3>', html)

    insert_point = html.find("</head>")
    if insert_point == -1:
        return html
    return html[:insert_point] + f'  <meta name="{key}" content="{value}">\n' + html[insert_point:]


def update_index_html(post: dict | None) -> None:
    if not HTML_FILE.exists():
        log.warning("web/index.html을 찾을 수 없습니다. 먼저 flutter build web을 실행하세요.")
        return

    html = HTML_FILE.read_text(encoding="utf-8")
    original = html

    html = replace_placeholder_urls(html, ROOT_URL)
    html = replace_canonical(html, f"{ROOT_URL}/")
    html = upsert_meta_name(html, "robots", "index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1")
    html = upsert_meta_name(html, "googlebot", "index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1")
    if GOOGLE_SITE_VERIFICATION:
        html = upsert_meta_name(html, "google-site-verification", GOOGLE_SITE_VERIFICATION)
    if NAVER_SITE_VERIFICATION:
        html = upsert_meta_name(html, "naver-site-verification", NAVER_SITE_VERIFICATION)

    if post:
        seo = post.get("seo", {})
        meta_title = seo.get("metaTitle", SITE_NAME)
        meta_desc = seo.get("metaDescription", DEFAULT_DESC)
        keywords = seo.get("keywords", DEFAULT_KEYWORDS)
        og_image = seo.get("ogImage", "")

        html = replace_title(html, meta_title)
        html = replace_meta_tag(html, "description", meta_desc)
        html = replace_meta_tag(html, "keywords", keywords)
        html = replace_meta_tag(html, "og:title", meta_title)
        html = replace_meta_tag(html, "og:description", meta_desc)
        html = replace_meta_tag(html, "og:url", f"{ROOT_URL}/")
        html = replace_meta_tag(html, "og:locale", "ko_KR")
        if og_image:
            html = replace_meta_tag(html, "og:image", og_image)
        html = replace_meta_tag(html, "twitter:title", meta_title)
        html = replace_meta_tag(html, "twitter:description", meta_desc)
        if og_image:
            html = replace_meta_tag(html, "twitter:image", og_image)
    else:
        html = replace_title(html, SITE_NAME)
        html = replace_meta_tag(html, "description", DEFAULT_DESC)
        html = replace_meta_tag(html, "keywords", DEFAULT_KEYWORDS)

    if html != original:
        HTML_FILE.write_text(html, encoding="utf-8")
        log.info("web/index.html SEO 메타 태그 업데이트 완료")
    else:
        log.info("변경사항 없음")


def inject_seo_tags_if_missing(html: str) -> str:
    """필수 SEO 태그가 없으면 <head> 내에 삽입"""
    tags_to_ensure = [
        '<meta name="description" content="">',
        '<meta name="keywords" content="">',
        '<meta name="robots" content="index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1">',
        '<meta name="googlebot" content="index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1">',
        '<meta property="og:title" content="">',
        '<meta property="og:description" content="">',
        '<meta property="og:url" content="">',
        '<meta property="og:image" content="">',
        '<meta property="og:type" content="website">',
        '<meta name="twitter:card" content="summary_large_image">',
        '<meta name="twitter:title" content="">',
        '<meta name="twitter:description" content="">',
        '<meta name="twitter:image" content="">',
    ]
    insert_point = html.find("</head>")
    if insert_point == -1:
        return html

    to_insert = []
    for tag in tags_to_ensure:
        # 이미 해당 name/property가 있으면 스킵
        key_match = re.search(r'(?:name|property)="([^"]+)"', tag)
        if key_match:
            key = key_match.group(1)
            if re.search(rf'(?:name|property)="{re.escape(key)}"', html):
                continue
        to_insert.append(tag)

    if to_insert:
        injection = "\n  " + "\n  ".join(to_insert) + "\n"
        html = html[:insert_point] + injection + html[insert_point:]
        log.info("%d개 SEO 메타 태그 주입됨", len(to_insert))

    return html


def main() -> None:
    post = load_latest_post()
    if post:
        log.info("최신 포스트 SEO 반영: %s", post.get("title", ""))
    else:
        log.info("포스트가 없어 기본 메타 정보를 사용합니다.")

    if HTML_FILE.exists():
        html = HTML_FILE.read_text(encoding="utf-8")
        patched = inject_seo_tags_if_missing(html)
        if patched != html:
            HTML_FILE.write_text(patched, encoding="utf-8")

    update_index_html(post)


if __name__ == "__main__":
    main()

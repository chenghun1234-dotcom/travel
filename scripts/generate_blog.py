"""
generate_blog.py
────────────────
raw_festivals.json → Gemini 1.5 Flash API →
감성적인 한국어 블로그 포스트 생성 → posts/*.md + index.json 업데이트
"""
from __future__ import annotations

import json
import logging
import re
import sys
import time
from datetime import datetime
from pathlib import Path

import google.generativeai as genai

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    DATA_DIR,
    GEMINI_API_KEY,
    GEMINI_MAX_TOKENS,
    GEMINI_MODEL,
    GEMINI_TEMPERATURE,
    POSTS_DIR,
    get_affiliate_info,
    generate_refined_mrt_links,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

RAW_INPUT = POSTS_DIR / "raw_festivals.json"
INDEX_OUTPUT = POSTS_DIR / "index.json"
LEGACY_OUTPUT = DATA_DIR / "festivals.json"

# ── 지역코드 → 광역시도 매핑 (TourAPI areaCode 기준) ──────────
AREA_CODE_MAP: dict[str, str] = {
    "1": "서울", "2": "인천", "3": "대전", "4": "대구",
    "5": "광주", "6": "부산", "7": "울산", "8": "세종",
    "31": "경기", "32": "강원", "33": "충북", "34": "충남",
    "35": "전북", "36": "전남", "37": "경북", "38": "경남", "39": "제주",
}


# ── 프롬프트 ──────────────────────────────────────────────────
def build_prompt(festival: dict) -> str:
    return f"""당신은 대한민국 여행 전문 블로거입니다.
아래 축제 정보를 바탕으로, 독자가 실제로 방문하고 싶은 마음이 생기도록
감성적이고 생동감 있는 한국어 블로그 글을 작성해주세요.
문체는 네이버 여행 블로그 스타일로, 검색 유입과 클릭을 고려한 마케팅 문구를 자연스럽게 섞어주세요.

[축제 정보]
- 축제명: {festival['title']}
- 위치: {festival['addr1']} {festival['addr2']}
- 기간: {festival['eventStartDate']} ~ {festival['eventEndDate']}
- 전화: {festival.get('tel', '정보 없음')}
- 개요: {festival.get('overview', '정보 없음')}
- 홈페이지: {festival.get('homepage', '')}

[작성 요건]
1. 제목 (# 으로 시작, 축제명 + 감성 문구, 60자 이내)
2. 도입부 (2~3문장, 독자의 감성을 자극하는 훅)
3. 축제 핵심 3가지 (## 소제목, 각 2~3문장씩)
4. 방문 꿀팁 (## 방문 꿀팁, bullet list 3~4개)
5. 가는 방법 (## 가는 방법, 대중교통/자가용 안내)
6. 주변 숙소 및 투어 예약 팁 (## 주변 숙소 및 투어 예약 팁, 2~3문장)
7. 마무리 (1~2문장, 방문 독려 문구)

[추가 규칙]
- 전체 길이: 600~900자
- Markdown 형식 엄수
- 과장 없이 진정성 있게 작성
- 계절감과 감성적 묘사 포함
- 실제 URL은 넣지 말고, 숙소/투어 예약이 왜 유용한지만 설명하세요
"""


def slugify(text: str, date_str: str) -> str:
    """축제명 → URL 슬러그 변환"""
    # 한글 → 로마자 간단 변환 (pinyin 없이 날짜 + ID 조합)
    clean = re.sub(r"[^\w\s-]", "", text).strip().lower()
    clean = re.sub(r"[\s_-]+", "-", clean)
    # 한글이 남아있으면 날짜 기반 슬러그
    if re.search(r"[가-힣]", clean):
        safe = re.sub(r"[^\w]", "", text)[:20]
        return f"{safe}-{date_str}"
    return f"{clean[:40]}-{date_str}" if clean else f"festival-{date_str}"


def extract_title_from_md(md: str, fallback: str) -> str:
    """Markdown h1 제목 추출"""
    match = re.search(r"^#\s+(.+)", md, re.MULTILINE)
    return match.group(1).strip() if match else fallback


def extract_excerpt(md: str, length: int = 120) -> str:
    """Markdown 본문에서 순수 텍스트 발췌"""
    text = re.sub(r"^#{1,6}\s+.+", "", md, flags=re.MULTILINE)
    text = re.sub(r"\*{1,3}|_{1,3}|`{1,3}", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\n+", " ", text).strip()
    return text[:length] + "…" if len(text) > length else text


def resolve_region(festival: dict) -> str:
    """주소에서 지역명 추출"""
    addr = festival.get("addr1", "")
    area_code = festival.get("areaCode", "")

    # 주소 파싱 우선
    for key in ["서울", "부산", "대구", "인천", "광주", "대전", "울산", "세종",
                "제주", "전주", "강릉", "경주", "안동", "수원", "춘천", "여수", "통영"]:
        if key in addr:
            return key

    # areaCode 폴백
    return AREA_CODE_MAP.get(area_code, addr.split()[0] if addr else "전국")


def generate_post(festival: dict, model: genai.GenerativeModel) -> str | None:
    """Gemini API로 블로그 글 생성"""
    prompt = build_prompt(festival)
    try:
        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                max_output_tokens=GEMINI_MAX_TOKENS,
                temperature=GEMINI_TEMPERATURE,
            ),
        )
        return response.text
    except Exception as exc:
        log.error("Gemini 생성 실패 '%s': %s", festival.get("title"), exc)
        return None


def build_post_record(festival: dict, md_content: str) -> dict:
    """최종 포스트 JSON 레코드 구성"""
    today = datetime.now()
    date_str = today.strftime("%Y%m%d")
    content_id = festival.get("contentId", date_str)

    region = resolve_region(festival)
    affiliate = get_affiliate_info(region)
    refined_links = generate_refined_mrt_links(
        festival.get("addr1", ""),
        festival.get("title", ""),
    )

    title = extract_title_from_md(md_content, festival["title"])
    excerpt = extract_excerpt(md_content)
    marketing_copy = extract_excerpt(md_content, 80)
    slug = slugify(festival["title"], date_str)

    # 날짜 파싱
    def parse_date(d: str) -> str:
        try:
            return datetime.strptime(d, "%Y%m%d").isoformat()
        except Exception:
            return today.isoformat()

    festival_start = parse_date(festival.get("eventStartDate", ""))
    festival_end = parse_date(festival.get("eventEndDate", ""))

    tags = [region, festival["title"][:8], "한국축제", "국내여행"]

    return {
        "id": content_id,
        "slug": slug,
        "title": title,
        "excerpt": excerpt,
        "marketingCopy": marketing_copy,
        "content": md_content,
        "region": region,
        "festivalName": festival["title"],
        "imageUrl": festival.get("imageUrl", ""),
        "affiliateLink": refined_links["stay_link"] or affiliate["url"],
        "affiliateLinkText": f"{refined_links['city']} 숙소 최적가 확인하기 🏨",
        "festivalAffiliateLink": refined_links["festival_link"],
        "festivalAffiliateLinkText": f"{festival['title']} 입장권/투어 확인하기 🎟️",
        "publishedAt": today.isoformat(),
        "festivalStart": festival_start,
        "festivalEnd": festival_end,
        "tags": tags,
        "seo": {
            "metaTitle": f"{festival['title']} 2026 | 한국 축제 여행 가이드",
            "metaDescription": excerpt[:155],
            "keywords": f"{festival['title']}, {region} 축제, {region} 여행, 국내 축제, 2026 축제",
            "ogImage": festival.get("imageUrl", ""),
        },
    }


def load_existing_index() -> list[dict]:
    if INDEX_OUTPUT.exists():
        try:
            return json.loads(INDEX_OUTPUT.read_text(encoding="utf-8"))
        except Exception:
            return []
    return []


def export_flutter_festival_json(posts: list[dict]) -> None:
    """Flutter 단순 리스트 렌더링 호환용 JSON 생성 (assets/data/festivals.json)"""
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    simplified: list[dict] = []
    for p in posts:
        start = str(p.get("festivalStart", "")).split("T")[0]
        end = str(p.get("festivalEnd", "")).split("T")[0]
        date_range = f"{start} ~ {end}" if start and end else "일정 추후 공지"

        simplified.append(
            {
                "id": str(p.get("id", "")),
                "slug": p.get("slug", ""),
                "title": p.get("title", ""),
                "image": p.get("imageUrl", ""),
                "date": date_range,
                "location": p.get("region", "전국"),
                "content": p.get("content", ""),
                "affiliate_link": p.get("affiliateLink", ""),
            }
        )

    LEGACY_OUTPUT.write_text(
        json.dumps(simplified, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    log.info("Flutter 호환 JSON 저장 완료: %s (%d개)", LEGACY_OUTPUT, len(simplified))


def main() -> None:
    if not GEMINI_API_KEY:
        log.error("GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")
        sys.exit(1)

    if not RAW_INPUT.exists():
        log.error("raw_festivals.json 파일이 없습니다. fetch_festivals.py를 먼저 실행하세요.")
        sys.exit(1)

    POSTS_DIR.mkdir(parents=True, exist_ok=True)

    # Gemini 초기화
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel(GEMINI_MODEL)

    # 원본 데이터 로드
    festivals: list[dict] = json.loads(RAW_INPUT.read_text(encoding="utf-8"))
    log.info("%d개 축제 블로그 글 생성 시작", len(festivals))

    # 기존 인덱스 로드 (중복 방지)
    existing = load_existing_index()
    existing_ids = {p["id"] for p in existing}

    new_posts: list[dict] = []

    for i, festival in enumerate(festivals, 1):
        content_id = festival.get("contentId", "")
        if content_id in existing_ids:
            log.info("[%d/%d] 스킵 (이미 존재): %s", i, len(festivals), festival["title"])
            continue

        log.info("[%d/%d] 생성 중: %s", i, len(festivals), festival["title"])
        md_content = generate_post(festival, model)

        if not md_content:
            continue

        # 개별 Markdown 파일 저장
        record = build_post_record(festival, md_content)
        md_path = POSTS_DIR / f"{record['slug']}.md"
        md_path.write_text(md_content, encoding="utf-8")
        log.info("  → 저장: %s", md_path.name)

        new_posts.append(record)
        time.sleep(1.5)  # Gemini API rate limit

    # 인덱스 업데이트 (새 글을 앞에 추가)
    all_posts = new_posts + existing
    INDEX_OUTPUT.write_text(
        json.dumps(all_posts, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    log.info("인덱스 업데이트 완료: %d개 신규, 총 %d개", len(new_posts), len(all_posts))

    # Flutter 호환용 단순 데이터도 함께 생성
    export_flutter_festival_json(all_posts)


if __name__ == "__main__":
    main()

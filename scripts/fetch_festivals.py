"""
fetch_festivals.py
──────────────────
한국관광공사 TourAPI 4.0 → searchFestival 엔드포인트 호출
이번 달~3개월 이내 시작 예정인 축제 목록을 수집하여
raw_festivals.json으로 저장합니다.
"""
from __future__ import annotations

import json
import logging
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

import requests

# 스크립트 디렉터리 기준으로 config import
sys.path.insert(0, str(Path(__file__).parent))
from config import (
    FESTIVAL_SEARCH_DAYS_AHEAD,
    IMAGES_DIR,
    POSTS_DIR,
    TOUR_API_BASE,
    TOUR_API_KEY,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

RAW_OUTPUT = POSTS_DIR / "raw_festivals.json"


def build_festival_url(event_start_date: str, page: int = 1, rows: int = 50) -> str:
    """searchFestival API URL 생성"""
    params = {
        "serviceKey": TOUR_API_KEY,
        "numOfRows": rows,
        "pageNo": page,
        "MobileOS": "ETC",
        "MobileApp": "TravelBlog",
        "_type": "json",
        "listYN": "Y",
        "arrange": "R",          # 수정일 역순 정렬 (최신순)
        "eventStartDate": event_start_date,
        "areaCode": "",           # 전국
    }
    return f"{TOUR_API_BASE}/searchFestival1?{urlencode(params)}"


def fetch_page(url: str) -> dict[str, Any]:
    """단일 페이지 요청"""
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()
    data = resp.json()
    return data.get("response", {})


def parse_items(response_body: dict) -> list[dict]:
    """API 응답에서 아이템 목록 파싱"""
    body = response_body.get("body", {})
    items = body.get("items", {})
    if not items:
        return []
    raw = items.get("item", [])
    return raw if isinstance(raw, list) else [raw]


def fetch_detail(content_id: str) -> dict:
    """축제 상세 정보 + 소개 정보 조회"""
    detail_url = (
        f"{TOUR_API_BASE}/detailCommon1?"
        f"serviceKey={TOUR_API_KEY}"
        f"&contentId={content_id}"
        f"&contentTypeId=15"
        f"&MobileOS=ETC&MobileApp=TravelBlog"
        f"&_type=json"
        f"&defaultYN=Y&firstImageYN=Y&areacodeYN=Y&addrinfoYN=Y&overviewYN=Y"
    )
    try:
        resp = requests.get(detail_url, timeout=10)
        resp.raise_for_status()
        items = parse_items(resp.json().get("response", {}))
        return items[0] if items else {}
    except Exception as exc:
        log.warning("상세 조회 실패 contentId=%s: %s", content_id, exc)
        return {}


def fetch_image(content_id: str) -> str:
    """첫 번째 이미지 URL 반환 (제1유형 저작권 우선)"""
    img_url = (
        f"{TOUR_API_BASE}/detailImage1?"
        f"serviceKey={TOUR_API_KEY}"
        f"&contentId={content_id}"
        f"&imageYN=Y&subImageYN=Y"
        f"&MobileOS=ETC&MobileApp=TravelBlog&_type=json"
    )
    try:
        resp = requests.get(img_url, timeout=10)
        resp.raise_for_status()
        items = parse_items(resp.json().get("response", {}))
        # 제1유형(copyrightDiv=1) 우선, 없으면 첫 번째
        copyright1 = [i for i in items if str(i.get("cpyrhtDivCd", "")) == "1"]
        chosen = copyright1[0] if copyright1 else (items[0] if items else {})
        return chosen.get("originimgurl", chosen.get("smallimageurl", ""))
    except Exception as exc:
        log.warning("이미지 조회 실패 contentId=%s: %s", content_id, exc)
        return ""


def fetch_all_festivals(start_date: str) -> list[dict]:
    """전체 페이지 순회하며 모든 축제 수집"""
    festivals: list[dict] = []
    page = 1
    total_count: int | None = None

    while True:
        url = build_festival_url(start_date, page=page)
        log.info("TourAPI 요청 page=%d …", page)
        try:
            resp = fetch_page(url)
            body = resp.get("body", {})
            if total_count is None:
                total_count = int(body.get("totalCount", 0))
                log.info("총 %d개 축제 발견", total_count)

            items = parse_items(resp)
            if not items:
                break

            festivals.extend(items)
            if len(festivals) >= total_count:
                break
            page += 1
            time.sleep(0.3)   # API rate limit 준수
        except Exception as exc:
            log.error("페이지 %d 수집 실패: %s", page, exc)
            break

    return festivals


def is_within_search_window(item: dict, now: datetime) -> bool:
    """FESTIVAL_SEARCH_DAYS_AHEAD 일 이내에 시작되거나 진행 중인 축제만 필터"""
    start_raw = str(item.get("eventstartdate", ""))
    end_raw = str(item.get("eventenddate", ""))
    try:
        start = datetime.strptime(start_raw, "%Y%m%d")
        end = datetime.strptime(end_raw, "%Y%m%d")
    except ValueError:
        return False

    window_end = now + timedelta(days=FESTIVAL_SEARCH_DAYS_AHEAD)
    # 축제가 오늘 이전에 끝났으면 제외, 검색 창 안에서 시작하면 포함
    return end >= now and start <= window_end


def enrich_festival(item: dict) -> dict:
    """축제 아이템에 상세 정보와 이미지 추가"""
    content_id = str(item.get("contentid", ""))
    time.sleep(0.2)  # API 호출 간격

    detail = fetch_detail(content_id)
    image_url = item.get("firstimage", "")
    if not image_url:
        image_url = fetch_image(content_id)

    return {
        "contentId": content_id,
        "title": item.get("title", ""),
        "addr1": item.get("addr1", ""),
        "addr2": item.get("addr2", ""),
        "areaCode": str(item.get("areacode", "")),
        "sigunguCode": str(item.get("sigungucode", "")),
        "mapX": item.get("mapx", ""),
        "mapY": item.get("mapy", ""),
        "tel": item.get("tel", ""),
        "eventStartDate": item.get("eventstartdate", ""),
        "eventEndDate": item.get("eventenddate", ""),
        "imageUrl": image_url,
        "overview": detail.get("overview", ""),
        "homepage": detail.get("homepage", ""),
        "firstImage": detail.get("firstimage", image_url),
    }


def main() -> None:
    if not TOUR_API_KEY:
        log.error("TOUR_API_KEY 환경변수가 설정되지 않았습니다.")
        sys.exit(1)

    POSTS_DIR.mkdir(parents=True, exist_ok=True)
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    today = datetime.now()
    start_date = today.strftime("%Y%m%d")   # 오늘 이후 시작 축제

    log.info("축제 데이터 수집 시작 (기준일: %s, 탐색 창: %d일)", start_date, FESTIVAL_SEARCH_DAYS_AHEAD)
    raw_items = fetch_all_festivals(start_date)
    raw_items = [item for item in raw_items if is_within_search_window(item, today)]
    log.info("검색 창 %d일 필터 후 %d개 축제 유지", FESTIVAL_SEARCH_DAYS_AHEAD, len(raw_items))

    log.info("%d개 축제 상세 정보 수집 중 …", len(raw_items))
    enriched: list[dict] = []
    for i, item in enumerate(raw_items[:30], 1):   # 일일 호출 한도를 위해 30개 제한
        log.info("[%d/%d] %s", i, min(len(raw_items), 30), item.get("title", ""))
        enriched.append(enrich_festival(item))

    RAW_OUTPUT.write_text(
        json.dumps(enriched, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    log.info("저장 완료: %s (%d개)", RAW_OUTPUT, len(enriched))


if __name__ == "__main__":
    main()

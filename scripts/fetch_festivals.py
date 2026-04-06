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


def build_common_params() -> dict[str, Any]:
    return {
        "serviceKey": TOUR_API_KEY,
        "MobileOS": "ETC",
        "MobileApp": "TravelBlog",
        "_type": "json",
    }


def build_festival_params(event_start_date: str, page: int = 1, rows: int = 50) -> dict[str, Any]:
    """searchFestival API 파라미터 생성"""
    params = {
        **build_common_params(),
        "numOfRows": rows,
        "pageNo": page,
        "listYN": "Y",
        "arrange": "R",          # 수정일 역순 정렬 (최신순)
        "eventStartDate": event_start_date,
        "areaCode": "",           # 전국
    }
    return params


def request_api(endpoint: str, params: dict[str, Any], timeout: int = 15, retries: int = 3) -> dict[str, Any]:
    """TourAPI 공통 요청 (일시적 오류 재시도 + resultCode 검사)"""
    url = f"{TOUR_API_BASE}/{endpoint}"
    last_exc: Exception | None = None

    for attempt in range(1, retries + 1):
        try:
            resp = requests.get(url, params=params, timeout=timeout)
            resp.raise_for_status()
            data = resp.json().get("response", {})

            header = data.get("header", {})
            result_code = str(header.get("resultCode", ""))
            result_msg = header.get("resultMsg", "")
            if result_code and result_code != "0000":
                raise RuntimeError(f"TourAPI resultCode={result_code}, resultMsg={result_msg}")

            return data
        except Exception as exc:
            last_exc = exc
            if attempt < retries:
                backoff = 1.2 * attempt
                log.warning("TourAPI 요청 실패(%s, 시도 %d/%d): %s", endpoint, attempt, retries, exc)
                time.sleep(backoff)
                continue
            raise

    if last_exc:
        raise last_exc
    return {}


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
    params = {
        **build_common_params(),
        "contentId": content_id,
        "contentTypeId": 15,
        "defaultYN": "Y",
        "firstImageYN": "Y",
        "areacodeYN": "Y",
        "addrinfoYN": "Y",
        "overviewYN": "Y",
    }
    try:
        items = parse_items(request_api("detailCommon1", params, timeout=10))
        return items[0] if items else {}
    except Exception as exc:
        log.warning("상세 조회 실패 contentId=%s: %s", content_id, exc)
        return {}


def fetch_image(content_id: str) -> str:
    """첫 번째 이미지 URL 반환 (제1유형 저작권 우선)"""
    params = {
        **build_common_params(),
        "contentId": content_id,
        "imageYN": "Y",
        "subImageYN": "Y",
    }
    try:
        items = parse_items(request_api("detailImage1", params, timeout=10))
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
        log.info("TourAPI 요청 page=%d …", page)
        try:
            params = build_festival_params(start_date, page=page)
            resp = request_api("searchFestival1", params)
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


def dedupe_festivals(items: list[dict]) -> list[dict]:
    unique: dict[str, dict] = {}
    for item in items:
        content_id = str(item.get("contentid") or item.get("contentId") or "")
        if not content_id:
            continue
        unique[content_id] = item

    def sort_key(item: dict) -> tuple[str, str]:
        return (str(item.get("eventstartdate", "99999999")), str(item.get("title", "")))

    return sorted(unique.values(), key=sort_key)


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
    start_dates = [
        today.strftime("%Y%m%d"),
        (today - timedelta(days=30)).strftime("%Y%m%d"),
        (today - timedelta(days=90)).strftime("%Y%m%d"),
    ]

    raw_items: list[dict] = []
    for idx, start_date in enumerate(start_dates, 1):
        log.info("축제 데이터 수집 시작 (%d/%d, 기준일: %s, 탐색 창: %d일)", idx, len(start_dates), start_date, FESTIVAL_SEARCH_DAYS_AHEAD)
        fetched = fetch_all_festivals(start_date)
        if fetched:
            raw_items.extend(fetched)
            if idx == 1:
                break
        else:
            log.warning("기준일 %s 결과가 비어 있습니다.", start_date)

    raw_items = dedupe_festivals(raw_items)

    raw_items = [item for item in raw_items if is_within_search_window(item, today)]
    log.info("검색 창 %d일 필터 후 %d개 축제 유지", FESTIVAL_SEARCH_DAYS_AHEAD, len(raw_items))

    if not raw_items:
        # TourAPI 장애 시 기존 raw_festivals.json 재사용 (파이프라인 중단 방지)
        if RAW_OUTPUT.exists():
            existing = json.loads(RAW_OUTPUT.read_text(encoding="utf-8"))
            if existing:
                log.warning(
                    "TourAPI 응답 없음 — 기존 raw_festivals.json (%d개) 재사용합니다.",
                    len(existing),
                )
                return  # 기존 파일 유지, 정상 종료
        log.error("수집 가능한 축제 데이터가 없습니다. TOUR_API_KEY 또는 TourAPI 응답 상태를 확인하세요.")
        RAW_OUTPUT.write_text("[]\n", encoding="utf-8")
        sys.exit(1)

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

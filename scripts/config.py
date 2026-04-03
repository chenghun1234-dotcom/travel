# ============================================================
# config.py - 전체 파이프라인 설정 (환경변수 기반)
# ============================================================
import os
import urllib.parse
from pathlib import Path

# ── 디렉토리 경로 ─────────────────────────────────────────────
ROOT_DIR = Path(__file__).parent.parent
POSTS_DIR = ROOT_DIR / "assets" / "posts"
DATA_DIR = ROOT_DIR / "assets" / "data"
IMAGES_DIR = ROOT_DIR / "assets" / "images"
WEB_DIR = ROOT_DIR / "web"

# ── API 키 (GitHub Secrets → 환경변수 주입) ──────────────────
TOUR_API_KEY = os.environ.get("TOUR_API_KEY", "")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

# ── TourAPI 4.0 설정 ─────────────────────────────────────────
TOUR_API_BASE = "https://apis.data.go.kr/B551011/KorService1"
TOUR_API_LANG = "ko"

# 검색 범위: 오늘부터 90일 이내 시작하는 축제
FESTIVAL_SEARCH_DAYS_AHEAD = 90

# ── Gemini 설정 ───────────────────────────────────────────────
GEMINI_MODEL = "gemini-1.5-flash"
GEMINI_MAX_TOKENS = 2048
GEMINI_TEMPERATURE = 0.85   # 창의적 글쓰기를 위해 약간 높게

# ── 마이리얼트립 제휴 링크 매핑 ───────────────────────────────
# MYREALTRIP_REFERRER_ID 또는 MRT_PARTNER_ID 둘 다 지원
# (사용자 워크플로우 예시와 기존 워크플로우를 동시에 호환)
MYREALTRIP_REFERRER_ID = (
    os.environ.get("MYREALTRIP_REFERRER_ID")
    or os.environ.get("MRT_PARTNER_ID")
    or "YOUR_REFERRER_ID"
)

REGION_AFFILIATE_LINKS: dict[str, dict] = {
    "서울": {
        "url": f"https://www.myrealtrip.com/cities/seoul?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "서울 여행 최적가 숙소 확인하기 🏨",
    },
    "부산": {
        "url": f"https://www.myrealtrip.com/cities/busan?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "부산 여행 최적가 숙소 확인하기 🏖️",
    },
    "제주": {
        "url": f"https://www.myrealtrip.com/cities/jeju?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "제주 여행 최적가 숙소 확인하기 🌊",
    },
    "전주": {
        "url": f"https://www.myrealtrip.com/cities/jeonju?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "전주 여행 최적가 숙소 확인하기 🏯",
    },
    "강릉": {
        "url": f"https://www.myrealtrip.com/search?q=강릉숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "강릉 여행 최적가 숙소 확인하기 🌊",
    },
    "경주": {
        "url": f"https://www.myrealtrip.com/search?q=경주숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "경주 여행 최적가 숙소 확인하기 🏛️",
    },
    "인천": {
        "url": f"https://www.myrealtrip.com/cities/incheon?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "인천 여행 최적가 숙소 확인하기 ✈️",
    },
    "안동": {
        "url": f"https://www.myrealtrip.com/search?q=안동숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "안동 여행 최적가 숙소 확인하기 🎭",
    },
    "수원": {
        "url": f"https://www.myrealtrip.com/search?q=수원숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "수원 여행 최적가 숙소 확인하기 🏰",
    },
    "여수": {
        "url": f"https://www.myrealtrip.com/search?q=여수숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "여수 여행 최적가 숙소 확인하기 🌅",
    },
    "광주": {
        "url": f"https://www.myrealtrip.com/cities/gwangju?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "광주 여행 최적가 숙소 확인하기 🌿",
    },
    "대구": {
        "url": f"https://www.myrealtrip.com/cities/daegu?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "대구 여행 최적가 숙소 확인하기 🍎",
    },
    "대전": {
        "url": f"https://www.myrealtrip.com/cities/daejeon?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "대전 여행 최적가 숙소 확인하기 🚀",
    },
    "춘천": {
        "url": f"https://www.myrealtrip.com/search?q=춘천숙소&referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "춘천 여행 최적가 숙소 확인하기 🌲",
    },
    "기본": {
        "url": f"https://www.myrealtrip.com/?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "여행 최적가 숙소 & 투어 확인하기 ✨",
    },
}


def get_affiliate_info(region: str) -> dict:
    """지역명에서 마이리얼트립 제휴 링크 정보 반환"""
    # 부분 문자열 매칭 (예: '전라북도 전주시' → '전주')
    for key in REGION_AFFILIATE_LINKS:
        if key != "기본" and key in region:
            return REGION_AFFILIATE_LINKS[key]
    return REGION_AFFILIATE_LINKS["기본"]


def _extract_city(addr1: str) -> str:
    """주소 문자열에서 대표 도시명 추출 (예: 전주시 -> 전주)"""
    parts = [p.strip() for p in addr1.split() if p.strip()]
    if not parts:
        return "전국"

    # 시/군/구 단위를 우선 선택
    city = ""
    for token in parts[1:]:
        if token.endswith(("시", "군", "구")):
            city = token
            break
    if not city:
        city = parts[1] if len(parts) > 1 else parts[0]

    # 접미사 제거 (전주시 -> 전주, 강릉시 -> 강릉)
    city = city.removesuffix("특별자치시")
    city = city.removesuffix("광역시")
    city = city.removesuffix("특별시")
    city = city.removesuffix("자치시")
    city = city.removesuffix("자치군")
    city = city.removesuffix("시")
    city = city.removesuffix("군")
    city = city.removesuffix("구")

    if len(city) >= 3 and city.endswith(("천", "산", "주", "릉", "포", "양", "성", "원", "산", "항")):
        return city
    return city[:2] if len(city) > 2 else city


def generate_refined_mrt_links(addr1: str, festival_title: str, partner_id: str | None = None) -> dict[str, str]:
    """
    주소 + 축제명 기반 정교한 마이리얼트립 링크 생성
    - stay_link: 지역 숙소 검색
    - festival_link: 축제명 입장권/투어 검색
    """
    pid = partner_id or MYREALTRIP_REFERRER_ID
    city = _extract_city(addr1)
    base_url = "https://www.myrealtrip.com/search"

    query_stays = urllib.parse.quote(f"{city} 숙소")
    query_fest = urllib.parse.quote(f"{festival_title} 입장권")

    return {
        "city": city,
        "stay_link": f"{base_url}?q={query_stays}&referrer_id={pid}",
        "festival_link": f"{base_url}?q={query_fest}&referrer_id={pid}",
    }

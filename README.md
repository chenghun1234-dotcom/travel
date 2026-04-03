# 🇰🇷 한국 축제 여행 블로그 — 0원 서버리스 자동화 파이프라인

> **AI가 매일 오전 7시 전국 축제 블로그를 자동 업데이트하는 완전 무료 시스템**
>
> TourAPI 4.0 → Gemini 1.5 Flash → Flutter Web → GitHub Pages

---

## 📐 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions (매일 KST 07:00)               │
│                                                                  │
│  ① fetch_festivals.py          ② generate_blog.py               │
│    한국관광공사 TourAPI 4.0  →   Gemini 1.5 Flash                 │
│    축제 목록 + 상세 + 이미지       감성적 블로그 글 생성            │
│                                                                  │
│  ③ update_seo_meta.py          ④ flutter build web              │
│    index.html <meta> 자동 갱신  →  canvaskit 렌더러 빌드          │
│                                                                  │
│  ⑤ GitHub Pages 자동 배포 → https://YOUR_ID.github.io           │
└─────────────────────────────────────────────────────────────────┘
```

### 비용 구조 (월 기준)

| 서비스 | 무료 한도 | 예상 사용량 | 비용 |
|--------|-----------|------------|------|
| GitHub Actions | 2,000분/월 | ~30분/월 | **₩0** |
| GitHub Pages | 무제한 | - | **₩0** |
| TourAPI 4.0 | 1,000 콜/일 | ~60 콜/일 | **₩0** |
| Gemini 1.5 Flash | 15 req/분, 1M tok/일 | ~30 req/일 | **₩0** |
| **합계** | | | **₩0/월** |

---

## 🚀 빠른 시작 (5단계)

### 1단계 — API 키 발급

**한국관광공사 TourAPI 4.0**
1. [공공데이터포털](https://www.data.go.kr) 회원가입
2. "한국관광공사\_국문 관광정보 서비스\_GW" 신청
3. 발급된 `serviceKey` 복사

**Google Gemini API**
1. [Google AI Studio](https://aistudio.google.com) 접속
2. "Get API Key" → 새 키 생성
3. 발급된 키 복사

**마이리얼트립 파트너**
1. [마이리얼트립 파트너센터](https://partners.myrealtrip.com) 신청
2. 파트너 ID 발급 후 GitHub Secrets에 `MRT_PARTNER_ID` 또는 `MYREALTRIP_REFERRER_ID` 등록

### 2단계 — GitHub Secrets 설정

GitHub 저장소 → **Settings → Secrets and variables → Actions → New repository secret**

| Secret 이름 | 값 |
|-------------|-----|
| `TOUR_API_KEY` | TourAPI 서비스키 |
| `GEMINI_API_KEY` | Gemini API 키 |
| `MRT_PARTNER_ID` | 마이리얼트립 파트너 ID (권장) |
| `MYREALTRIP_REFERRER_ID` | 마이리얼트립 파트너 ID (기존 호환용) |
| `GOOGLE_SITE_VERIFICATION` | Google Search Console 메타 인증 코드 (선택) |
| `NAVER_SITE_VERIFICATION` | 네이버 서치어드바이저 메타 인증 코드 (선택) |

### 3단계 — GitHub Pages 활성화

저장소 → **Settings → Pages → Source: Deploy from a branch → Branch: gh-pages**

### 4단계 — 배포 URL 업데이트

기본 URL 플레이스홀더를 실제 값으로 교체:

```
web/index.html                 → YOUR_GITHUB_USERNAME
scripts/update_seo_meta.py     → fallback SITE_URL
```

### 5단계 — 첫 실행

```bash
# Actions 탭 → "Daily Blog Auto-Update" → "Run workflow"
```

또는 로컬 테스트:

```bash
cd scripts
pip install -r requirements.txt

# 환경변수 설정
export TOUR_API_KEY="your_key"
export GEMINI_API_KEY="your_key"
export MRT_PARTNER_ID="your_id"

# 전체 파이프라인 실행
python pipeline.py
```

---

## 📁 프로젝트 구조

```
여행 블로그/
├── .github/
│   └── workflows/
│       └── daily_blog.yml          # GitHub Actions 자동화 워크플로우
│       └── main.yml                # 단일 Job 자동 업데이트 워크플로우
│
├── lib/                            # Flutter 소스코드
│   ├── main.dart                   # 앱 진입점 + GoRouter + SeoRenderer
│   ├── models/
│   │   └── blog_post.dart          # 데이터 모델 (SEO 메타 포함)
│   ├── screens/
│   │   ├── home_screen.dart        # 메인 목록 화면
│   │   ├── post_detail_screen.dart # 포스트 상세 + 제휴 링크 카드
│   │   └── about_screen.dart      # 소개 페이지
│   ├── services/
│   │   └── blog_service.dart       # JSON 로딩 서비스
│   ├── theme/
│   │   └── app_theme.dart          # 디자인 시스템
│   └── widgets/
│       └── post_card.dart          # SEO TextRenderer 적용 카드
│
├── scripts/                        # Python 자동화 스크립트
│   ├── config.py                   # 전역 설정 + 지역별 제휴 링크 맵
│   ├── fetch_festivals.py          # TourAPI 4.0 데이터 수집
│   ├── generate_blog.py            # Gemini AI 블로그 글 생성
│   ├── update_seo_meta.py          # HTML <meta> 태그 자동 업데이트
│   ├── pipeline.py                 # 전체 파이프라인 오케스트레이터
│   └── requirements.txt            # Python 의존성
│
├── assets/
│   └── posts/
│       ├── index.json              # 전체 포스트 인덱스 (Flutter가 로드)
│       └── *.md                    # 개별 Markdown 포스트 파일
│
├── web/
│   ├── index.html                  # SEO 최적화 HTML (meta 자동 갱신)
│   └── manifest.json               # PWA 매니페스트
│
└── pubspec.yaml                    # Flutter 의존성
```

---

## 🔍 SEO 전략 상세

### 문제: Flutter Web은 기본적으로 SEO가 취약

Flutter Web의 CanvasKit 렌더러는 Canvas로 그리기 때문에 검색 봇이 텍스트를 읽지 못합니다.

### 해결책 (3중 방어)

**① `seo_renderer` 패키지 (`RobotDetector` + `RendererWidgets`)**
```dart
// 텍스트가 HTML 태그로도 렌더링되어 봇이 읽을 수 있음
RendererWidgets.text(
  tag: RenderTag.h2,
  text: '축제 제목',
  child: Text('축제 제목'),
)
```

**② 정적 `<meta>` 태그 업데이트**
```python
# update_seo_meta.py가 빌드마다 최신 포스트 정보로 교체
replace_meta_tag(html, "og:title", latest_post_title)
```

**③ JSON-LD 구조화 데이터**
```html
<!-- web/index.html에 포함 -->
<script type="application/ld+json">
{ "@type": "Blog", "name": "한국 축제 여행 블로그" ... }
</script>
```

**검색 등록 필수 마무리**
- Google Search Console: 사이트 등록 후 `sitemap.xml` 제출
- 네이버 서치어드바이저: 사이트 등록 후 `sitemap.xml` 제출
- 사이트맵 주소 예시: `https://<github-id>.github.io/<repo>/sitemap.xml`

---

## 💰 마이리얼트립 수익화

기본 지역 매핑 + 정교한 동적 링크 생성이 함께 동작합니다.

- 지역 숙소 전환형 링크: `전주 숙소`, `강릉 숙소` 형태 자동 생성
- 축제명 직접검색 링크: `축제명 입장권` 형태 자동 생성

생성 함수는 `scripts/config.py`의 `generate_refined_mrt_links(addr1, festival_title)` 입니다.

`scripts/config.py`의 `REGION_AFFILIATE_LINKS` 딕셔너리에 지역을 추가하세요:

```python
REGION_AFFILIATE_LINKS = {
    "전주": {
        "url": f"https://www.myrealtrip.com/cities/jeonju?referrer_id={MYREALTRIP_REFERRER_ID}",
        "text": "전주 여행 최적가 숙소 확인하기 🏯",
    },
    # 새 지역 추가...
}
```

포스트 상세 페이지 하단에 자동으로 카드 형태로 표시됩니다.

---

## 🛠️ 로컬 개발

```bash
# Flutter 실행
flutter pub get
flutter run -d chrome

# Python 스크립트 단독 테스트
python scripts/fetch_festivals.py    # 축제 데이터 수집만
python scripts/generate_blog.py      # AI 글 생성만
python scripts/update_seo_meta.py    # SEO 메타 업데이트만
```

---

## 📊 자동화 스케줄

| 시간 (KST) | 작업 |
|-----------|------|
| 07:00 | GitHub Actions 트리거 |
| 07:01 | TourAPI 축제 데이터 수집 (~2분) |
| 07:03 | Gemini AI 블로그 글 생성 (~5분) |
| 07:08 | SEO 메타 업데이트 (~30초) |
| 07:09 | Flutter Web 빌드 (~8분) |
| 07:17 | GitHub Pages 배포 완료 ✅ |

---

## 🤝 기여

새로운 지역 매핑이나 프롬프트 개선이 있으면 PR을 보내주세요!

---

*Powered by [한국관광공사 TourAPI 4.0](https://www.data.go.kr) · [Google Gemini](https://ai.google.dev) · [Flutter](https://flutter.dev) · [GitHub Pages](https://pages.github.com)*

"""
pipeline.py
───────────
전체 파이프라인을 순서대로 실행하는 오케스트레이터.
GitHub Actions에서는 이 파일 하나만 호출합니다.

  python scripts/pipeline.py
"""
from __future__ import annotations

import logging
import subprocess
import sys
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

SCRIPTS_DIR = Path(__file__).parent
PYTHON = sys.executable


def run_step(name: str, script: str) -> bool:
    """단일 스텝 실행, 실패 시 False 반환"""
    log.info("=" * 50)
    log.info("▶ %s", name)
    log.info("=" * 50)
    result = subprocess.run(
        [PYTHON, str(SCRIPTS_DIR / script)],
        check=False,
    )
    if result.returncode != 0:
        log.error("✗ %s 실패 (exit code: %d)", name, result.returncode)
        return False
    log.info("✓ %s 완료", name)
    return True


def main() -> None:
    steps = [
        ("1단계: TourAPI 축제 데이터 수집", "fetch_festivals.py"),
        ("2단계: Gemini AI 블로그 글 생성", "generate_blog.py"),
        ("3단계: SEO 메타 태그 업데이트", "update_seo_meta.py"),
        ("4단계: sitemap.xml 생성", "generate_sitemap.py"),
    ]

    for name, script in steps:
        if not run_step(name, script):
            sys.exit(1)

    log.info("")
    log.info("🎉 전체 파이프라인 완료!")
    log.info("GitHub Actions가 변경 파일을 자동 커밋합니다.")


if __name__ == "__main__":
    main()

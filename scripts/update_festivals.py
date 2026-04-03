"""
update_festivals.py
──────────────────
GitHub Actions에서 직접 호출하기 위한 진입 스크립트.
기존 pipeline.py를 재사용해 완전 무인 자동화를 유지합니다.
"""
from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    pipeline_path = Path(__file__).with_name("pipeline.py")
    runpy.run_path(str(pipeline_path), run_name="__main__")


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""PDF를 MarkItDown으로 마크다운 텍스트로 바꾸고, 믿을 수 있는 텍스트인지 먼저 판정한다.

사용법: python pdf2md.py <PDF 경로> [출력 폴더(기본: 임시 폴더)]
종료 코드와 첫 줄
  0 OK        변환 완료. out=<md 경로>, low_pages=<글자가 거의 없는 쪽 번호(그림 쪽일 수 있음)>
  1 ERROR     파일 없음·읽기 실패
  2 MISSING   Python 3.10 미만, 또는 markitdown(0.1.6 이상) 미설치·낡은 버전 — 설치는 사용자 확인 후
  3 SCANNED   쪽당 글자 수가 적어 스캔본으로 판정 — 변환 결과를 쓰지 않는다(빈 결과를 성공으로 오인하는 사고 방지)
  4 GARBLED   글자는 있지만 "(cid:1234)"·대체 문자로 깨짐 — 변환 결과를 쓰지 않는다(한글 CID 폰트, pdfminer.six #1035)
"""
import os
import re
import sys
import tempfile

MIN_VERSION = (0, 1, 6)   # 0.1.4에서 CVE-2025-64512 패치, 0.1.6에서 PDF 변환 메모리 증가 수정
AVG_SCANNED = 100         # 쪽당 평균 글자 수가 이보다 적으면 스캔본
LOW_PAGE = 20             # 이보다 적은 쪽은 그림·스캔 쪽으로 보고 low_pages에 적는다
GARBLED_RATIO = 0.05      # 깨진 글자(cid 토큰·대체 문자)가 전체 글자의 5%를 넘으면 깨진 것으로 본다


def parse_version(text):
    """'0.1.8b1' 같은 베타 표기도 앞 세 숫자로 비교한다."""
    m = re.match(r'(\d+)\.(\d+)\.(\d+)', text)
    return tuple(int(x) for x in m.groups()) if m else (0, 0, 0)


def garbled_ratio(text):
    """"(cid:123)" 토큰은 원래 글자 하나로 치고, 대체 문자와 함께 전체 대비 비율을 낸다."""
    cid = len(re.findall(r'\(cid:\d+\)', text))
    bad = cid + text.count('�')
    total = len(''.join(re.sub(r'\(cid:\d+\)', '_', text).split()))
    return bad / total if total else 0.0


def main():
    if len(sys.argv) < 2:
        print('ERROR 사용법: python pdf2md.py <PDF> [출력 폴더]')
        return 1
    pdf = sys.argv[1]
    out_dir = sys.argv[2] if len(sys.argv) > 2 else tempfile.gettempdir()
    if not os.path.isfile(pdf):
        print(f'ERROR 파일 없음: {pdf}')
        return 1
    if sys.version_info < (3, 10):
        print(f'MISSING Python {sys.version.split()[0]} — markitdown은 3.10 이상 필요')
        return 2
    try:
        import markitdown
        from markitdown import MarkItDown
        from pdfminer.high_level import extract_pages
        from pdfminer.layout import LTTextContainer
    except ImportError:
        print('MISSING markitdown[pdf] 미설치')
        return 2
    if parse_version(markitdown.__version__) < MIN_VERSION:
        print(f'MISSING markitdown {markitdown.__version__} — 0.1.6 이상 필요')
        return 2

    try:
        texts = [''.join(el.get_text() for el in page if isinstance(el, LTTextContainer))
                 for page in extract_pages(pdf)]
    except Exception as e:  # 암호·손상 PDF
        print(f'ERROR PDF 읽기 실패: {e}')
        return 1
    counts = [len(''.join(t.split())) for t in texts]
    pages = len(counts)
    avg = sum(counts) / pages if pages else 0
    low = [i + 1 for i, c in enumerate(counts) if c < LOW_PAGE]
    if pages == 0 or avg < AVG_SCANNED:
        print(f'SCANNED pages={pages} avg_chars_per_page={avg:.0f}')
        return 3
    ratio = garbled_ratio(''.join(texts))
    if ratio > GARBLED_RATIO:
        print(f'GARBLED pages={pages} garbled_ratio={ratio:.0%}')
        return 4

    text = MarkItDown().convert(pdf).text_content
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, os.path.splitext(os.path.basename(pdf))[0] + '.md')
    with open(out, 'w', encoding='utf-8') as f:
        f.write(text)
    lines = text.count('\n') + 1
    print(f'OK pages={pages} chars={len(text)} lines={lines} low_pages={",".join(map(str, low)) or "-"} out={out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

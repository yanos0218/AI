"""baseline-guard 본체(Issue #144, 이 저장소 전용). 공통 모듈은 저장소의 base/hooks/hooklib.py를 쓴다. 기본 영역 base/를 고치려 하면 확인 창(ask)을 띄운다.
막는 훅이라 판정은 보수적으로 한다(명령은 heredoc 본문까지 본다, python이 base/를 언급하면 쓰기로 본다).
옛 셸판과 달라진 점
- 입력 JSON을 정확히 읽는다(파일 경로에 붙은 다른 필드 글까지 훑지 않음), NotebookEdit의 notebook_path도 본다
- 출력 버리기(>/dev/null, 2>&1)와 따옴표 안의 >는 쓰기로 보지 않는다(ls base/ 2>/dev/null이 확인 창을 띄우던 오탐)
이 파일이 오류로 끝나면 셸 입구가 확인 창으로 처리한다."""
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'base', 'hooks'))
import hooklib as h  # noqa: E402

BASE = re.compile(r'(^|[/\\"\' ])base[/\\]')
EXEMPT = re.compile(r'(?:[A-Za-z]:)?[^ "\']*base[/\\]skills[/\\]_[^ "\']*')      # base/skills/_template 같은 틀
WRITES = re.compile(r'sed\s+-i|tee\s|(^|[;&|\s(])(cp|mv|rm|python|python3)\s|git\s+mv|Set-Content|Out-File|Copy-Item|Move-Item|Remove-Item|Add-Content')
REDIRECT = re.compile(r'(?<![0-9&])>>?(?!\s*/dev/null)(?!&)')
REASON = '기본 영역(base/) 변경입니다 (baseline-guard). 검증이 끝나고 사용자가 기본 반영을 요청한 변경이 맞는지 확인하세요. 초안은 drafts/ 에서.'


def hit(inp):
    tool = inp.get('tool_name') or ''
    if tool in ('Edit', 'Write', 'MultiEdit', 'NotebookEdit'):
        return bool(BASE.search(EXEMPT.sub('', h.path_of(inp))))
    if tool in ('Bash', 'PowerShell'):
        cmd = EXEMPT.sub('', h.command_of(inp))
        if not BASE.search(cmd):
            return False
        return bool(WRITES.search(cmd) or REDIRECT.search(h.quote_mask(cmd)))
    return False


def main():
    if hit(h.read_input()):
        h.decision('ask', REASON)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        h.log_error('baseline-guard', e)
        sys.exit(3)

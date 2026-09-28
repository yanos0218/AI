"""verifier-guard 본체(Issue #144). verifier 에이전트가 파일·저장소·외부 상태를 바꾸는 명령을 실행하려 하면 차단(deny).
막는 훅이라 판정은 보수적으로 한다(명령 이름은 따옴표 안까지 보고, > 리다이렉션만 따옴표 밖에서 본다).
이 파일이 오류로 끝나면 셸 입구(verifier-guard.sh)가 차단으로 처리한다."""
import re
import sys

import hooklib as h

A = r'(?:^|[;&|(`\n])\s*(?:sudo\s+)?'
RULES = [
    (A + r'git(?:\s+-C\s+\S+)?\s+(commit|push|reset|checkout|clean|rebase|merge|tag|stash|add|rm|mv|restore|switch|revert|'
         r'cherry-pick|am|apply|branch|init|clone|pull|fetch)(\s|$)', 'git 상태를 바꾸는 명령'),
    (A + r'(rm|rmdir|mv|cp|chmod|chown|touch|mkdir|ln|dd|truncate|tee)(\s|$)', '파일을 만들거나 바꾸거나 지우는 명령'),
    (r'(sed|perl)\s+(-[a-zA-Z]*i|--in-place)', '파일을 제자리에서 고치는 명령'),
    (A + r'(npm|pnpm|yarn|bun|pip|pip3|uv|brew|apt|apt-get|dnf|yum|choco|winget)\s+(install|i|add|remove|uninstall|publish|update|upgrade)(\s|$)',
     '패키지 설치·배포 명령'),
    (r'gh\s+(issue|pr|release|repo|label|workflow|run)\s+(create|edit|close|reopen|comment|delete|merge|rerun|cancel|enable|disable)'
     r'|gh\s+api.*(-X|--method)\s*(POST|PUT|PATCH|DELETE)', 'GitHub에 쓰는 명령'),
    (r'curl.*((-X|--request)\s*(POST|PUT|PATCH|DELETE)|\s(-d|--data[a-z-]*|-F|--form)\s)', '외부로 데이터를 보내는 요청'),
]
REDIRECT = re.compile(r'(?<![0-9&])>>?(?!\s*/dev/null)(?!&)')


def verdict(cmd):
    for pat, reason in RULES:
        if re.search(pat, cmd, re.M):
            return reason
    if REDIRECT.search(h.mask_heredocs(h.quote_mask(cmd))):
        return '출력을 파일로 쓰는 리다이렉션'
    return None


def main():
    reason = verdict(h.command_of(h.read_input()))
    if reason:
        h.decision('deny', f'verifier는 검사 실행만 한다(verifier-guard): {reason}은 차단. 우회하지 말고 막혔다고 보고할 것.')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        h.log_error('verifier-guard', e)
        sys.exit(3)       # 셸 입구가 차단으로 바꾼다

"""easy-explain-hint.sh 본체(Issue #222). 3.6 호환, 표준 라이브러리만 쓴다."""
import json
import os
import re
import sys

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'base', 'hooks'))
import hooklib  # noqa: E402

# 좁게 잡는다: "쉽게 고칠 수 있나" 같은 일상 표현은 제외하고 설명 요청 꼴만 본다.
ASK = re.compile(r'(쉽게|쉬운\s*말(로)?|쉬운\s*설명)\s*(다시\s*)?(설명|말해|얘기|풀어|알려)'
                 r'|다시\s*쉽게|이해가?\s*(안|못)\s*(돼|되|가)|무슨\s*말(인지|이야|이에요)')

HINT = ('[easy-explain-hint] 사용자가 쉬운 설명을 다시 요청함. 전역 §2대로 결론 한 줄을 먼저 쓰고, '
        '바로 뒤에 일상의 비유나 구체적 예시 하나를 붙일 것. 용어 풀이만으로 끝내지 말 것.')


def main():
    try:
        prompt = hooklib.read_input().get('prompt') or ''
        if ASK.search(prompt):
            print(json.dumps({'hookSpecificOutput': {'hookEventName': 'UserPromptSubmit',
                                                     'additionalContext': HINT}}, ensure_ascii=False))
    except Exception as e:  # 훅 오류로 사용자 입력을 막지 않는다
        hooklib.log_error('easy-explain-hint', e)


main()

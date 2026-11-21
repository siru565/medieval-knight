# 인수인계 (2026-11-22, 작성: Claude Code)

## 목표
Blender MCP와 AI 에이전트로 게임잼용 로우폴리 중세 기사를 만든다. 모델링, Unity Humanoid 리그, 제자리 걷기 애니메이션, GIF 미리보기, Unity용 FBX까지가 범위다.

## 현재 상태
- 완료: 모델링, 리깅(`Knight_Armature`, Humanoid 본 이름), 걷기 액션 `Knight_Walk`(24fps, 프레임 1~25, Fake User 켜짐), GIF와 FBX 첫 출력, GitHub 푸시, 환경 구축 스크립트
- 완료(파일로 확인함): 뷰포트 복구. 월드 배경이 (0.05, 0.05, 0.05)로 돌아와 있고, GIF 렌더용 `Walk_Backdrop`과 `Walk_Floor` 오브젝트가 따로 있다.
- 확인 안 됨: 방패를 타지처럼 팔뚝에 매다는 수정(PROMPTS.md 4번). `Shield.L`의 부모는 `LowerArm.L`이지만, 이건 처음 리깅할 때부터 그랬다. 가죽 끈과 방어 자세 왼팔이 실제로 들어갔는지는 Blender에서 `look`으로 확인해야 한다.
- 오래된 출력물: `Knight.blend`(11-20 03:08)가 `Knight_Walk.gif`(11-19 14:24)와 `Knight.fbx`(11-19 14:01)보다 나중에 수정됐다. GIF와 FBX에는 최근 수정이 빠져 있다.
- 빌드/테스트: 해당 없음. 새 PC에서 `setup.ps1`을 실행해 보지는 않았다.

## 파일
- `Knight.blend`: 원본. 오브젝트는 `Knight_Body`(Join된 단일 스킨 메시), `Knight_Armature`, `Camera`, `Light_Key`/`Light_Fill`/`Light_Rim`, `Walk_Backdrop`, `Walk_Floor`
- `Knight.fbx`, `Knight_Walk.gif`: 출력물 (위 내용대로 오래됨)
- `PROMPTS.md`: 에이전트에 넣은 프롬프트 최종본 (1 모델링 ~ 5 뷰포트 복구)
- `setup.ps1`: uv 설치, Blender 애드온 설치와 활성화, Antigravity와 Claude Code MCP 설정에 `blender` 서버 등록
- `.gitignore`: `*.blend1`, `walk_frames/` 제외

## 다음 할 일
1. 새 PC라면 `powershell -ExecutionPolicy Bypass -File .\setup.ps1`을 실행하고, 에이전트를 재시작한 뒤 Blender에서 `Knight.blend`를 연다. N 사이드바 > BlenderMCP 탭에서 서버를 켠다.
2. `get_scene_info`와 `look`으로 방패 상태를 확인한다. 타지 형태가 아니면 PROMPTS.md 4번을 실행한다.
3. GIF를 다시 렌더한다 (PROMPTS.md 3번의 렌더와 GIF 부분). 월드 색은 바꾸지 않는다.
4. FBX를 다시 익스포트한다. 이번에는 애니메이션이 있으므로 Bake Animation을 켠다.
5. 바뀐 파일을 커밋하고 푸시한다.
6. (선택) Unity 프로젝트에 FBX를 넣는다. Rig > Animation Type을 Humanoid로 설정한다.

## 결정한 것
- 스타일: 스타일라이즈드 로우폴리. 정면 -Y, 발바닥 Z=0, 키 약 1.8m
- 스키닝: 갑옷은 파트마다 본 하나에 웨이트 1.0으로 묶는 리지드 바인딩. 서코트 천 부분만 블렌딩 허용
- 방패: 손으로 쥐지 않고 왼쪽 팔뚝에 끈으로 묶는 타지 형태. 방향은 월드 기준이 아니라 `LowerArm.L` 기준으로 정한다.
- 걷기: 제자리 걷기(루트가 이동하지 않음). 이동은 Unity에서 코드로 처리한다.
- GIF: 512px, 24프레임. 배경은 단색(투명 배경은 쓰지 않음)
- 저장소: 공개 저장소 `siru565/medieval-knight`. 커밋 이메일은 GitHub noreply 주소(저장소 로컬 git config)

## 주의
- 렌더하려고 월드 배경색을 바꾸지 말 것. 바꾸면 뷰포트 전체가 하얗게 된다(실제로 겪은 문제). 배경은 `Walk_Backdrop`을 쓰거나, try/finally로 원래 값을 복원한다.
- 화면에 보이는 검은 삼각형은 카메라 표시이고, 문제가 아니다.
- 셰이더 노드는 이름이 아니라 타입으로 찾는다 (`n.type == "BSDF_PRINCIPLED"`). 노드 이름은 Blender 언어 설정에 따라 바뀐다.
- Blender 파이썬에는 Pillow가 없다. GIF를 만들 때는 `pip install --user pillow`로 설치한다. PC에 ffmpeg와 ImageMagick도 없다.
- MCP 클라이언트는 하나만 Blender에 연결한다. 여러 개를 연결하면 포트가 충돌한다.
- `.blend`는 바이너리 파일이라 병합이 안 된다. 작업을 시작하기 전에 `git pull`을 하고, 두 PC에서 동시에 수정하지 않는다.
- 공개 저장소이므로 개인 경로, 이메일, 토큰을 커밋하지 않는다.

## 참고
- Blender MCP 도구: `get_addon_status`, `get_scene_info`, `execute_blender_code`, `look`
- 애드온 출처: https://github.com/ahujasid/blender-mcp (`addon.py`), 서버 패키지는 `uvx blender-mcp`
- 작성 시점 환경: Blender 5.3, blender-mcp 2.0.0

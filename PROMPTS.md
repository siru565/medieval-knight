# 에이전트 프롬프트 모음

Blender MCP에 연결된 에이전트(Gemini / Antigravity, Claude Code 등)에 넣어서 이 기사를 만든 프롬프트예요. 작업한 순서대로 정리했어요.

---

## 1. 모델링

```
너는 Blender MCP로 연결된 Blender를 직접 조작하는 3D 아티스트야.
목표: 게임에 쓸 스타일라이즈드 로우폴리 "중세 기사" 캐릭터를 하나 만들어.

## 작업 순서
1. get_addon_status와 get_scene_info로 Blender 버전과 현재 씬 상태를 먼저 확인해.
2. 기본 큐브, 라이트, 카메라 중 필요 없는 것을 지우고 빈 씬에서 시작해.
3. execute_blender_code로 파트를 하나씩 만들어. 한 번에 다 만들지 말고 파트별로 나눠서 실행해.
4. 파트를 하나 만들 때마다 look으로 결과를 확인하고, 비율이나 위치가 어긋났으면 고친 다음 넘어가.

## 기사 구성 (키 약 1.8m, 발바닥이 Z=0, 정면이 -Y 방향)
- 투구: 그레이트 헬름 형태. 원통을 기반으로 만들고, 눈 부분에 가로 슬릿, 정수리에 빨간 깃털 장식
- 몸통: 흉갑(가슴판)과 그 아래 체인메일 느낌의 튜닉
- 서코트(Surcoat): 흉갑 위에 걸친 천 조끼. 파란색 바탕에 금색 십자 문양
- 어깨: 둥근 견갑(폴드런) 좌우 한 쌍
- 팔, 다리: 판금 갑옷. 팔꿈치와 무릎에 둥근 관절 보호대
- 장갑, 부츠: 판금 건틀릿, 사바통
- 벨트: 갈색 가죽 벨트와 금속 버클
- 무기: 오른손에 롱소드(십자형 가드, 가죽 그립, 폼멜)
- 방패: 왼팔에 카이트 실드. 서코트와 같은 파란색 바탕에 금색 문장

## 머티리얼 (Principled BSDF)
- 강철: 회색 계열, Metallic 1.0, Roughness 0.35
- 금 장식: 금색, Metallic 1.0, Roughness 0.3
- 천(서코트): 진한 파랑, Metallic 0, Roughness 0.8
- 가죽: 갈색, Roughness 0.6
- 깃털: 빨강, Roughness 0.9

## 기술 규칙
- 셰이더 노드는 이름이 아니라 타입으로 찾아:
  next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
- 색은 셰이더 노드 입력(Base Color)에 넣어. diffuse_color는 쓰지 마.
- 오브젝트 이름은 영어로, 파트를 알 수 있게 지어 (Knight_Helmet, Knight_Sword 등).
- 모든 파트를 빈 오브젝트 "Knight_Root" 아래에 부모로 묶어.
- 로우폴리를 유지해: 원통은 버텍스 12~16개, Subdivision은 최대 레벨 1.
- 이 모델은 나중에 Unity로 FBX 익스포트할 거야. 모든 파트에 스케일과 회전을 적용(Apply)해 둬.

## 마무리
1. 정면에서 3/4 각도로 보는 카메라를 두고, 3점 조명(키, 필, 림)을 설치해.
2. look으로 정면, 측면, 3/4 뷰를 각각 확인하고 어색한 곳을 고쳐.
3. 끝나면 만든 파트 목록과 총 폴리곤 수를 알려줘.
```

---

## 2. 리깅 (Unity Humanoid)

```
너는 Blender MCP로 연결된 Blender를 조작하는 리깅 아티스트야.
씬에 있는 "Knight_Root" 아래의 중세 기사 모델에 Unity Humanoid용 리그를 만들어.

## 0. 사전 점검
1. get_scene_info로 Knight_ 오브젝트 목록, 위치, 크기를 확인해.
2. look으로 정면과 측면을 보고 포즈를 확인해.
   - 팔이 T포즈나 A포즈가 아니면, 리깅 전에 팔 파트를 어깨 기준으로 회전시켜 T포즈로 맞춰.
   - 정면이 -Y, 발바닥이 Z=0인지 확인해.
3. 모든 메시에 스케일과 회전을 적용(Apply)해.

## 1. 아머처 생성 ("Knight_Armature", 좌우 대칭 본은 .L / .R)
Hips
├─ Spine
│  └─ Chest
│     └─ UpperChest
│        ├─ Neck
│        │  └─ Head
│        ├─ Shoulder.L → UpperArm.L → LowerArm.L → Hand.L
│        └─ Shoulder.R → UpperArm.R → LowerArm.R → Hand.R
├─ UpperLeg.L → LowerLeg.L → Foot.L → Toes.L
└─ UpperLeg.R → LowerLeg.R → Foot.R → Toes.R
추가 본: Weapon.R (Hand.R의 자식, 칼 손잡이), Shield.L (LowerArm.L의 자식, 방패)

## 2. 본 배치 규칙
- 각 본의 head는 실제 관절 위치에 둬. 메시 바운딩 박스로 계산해.
- 무릎은 앞(-Y), 팔꿈치는 뒤(+Y)로 아주 살짝 미리 꺾어 둬.
- 본 roll: 다리와 척추는 Global +Y, 팔은 Global -Z 기준.
- 왼쪽 본을 먼저 만들고 Symmetrize로 오른쪽 본을 생성해.
- look으로 X-ray 상태의 본 배치를 확인해.

## 3. 스키닝 (딱딱한 갑옷 = 리지드 바인딩)
자동 웨이트를 쓰지 마. 각 파트를 담당 본 하나에 웨이트 1.0으로 묶어.
- 투구, 깃털 → Head / 흉갑 → UpperChest / 튜닉 상단 → Chest / 벨트 → Hips
- 견갑, 팔 상단 → UpperArm / 팔꿈치 보호대, 팔뚝 → LowerArm / 건틀릿 → Hand
- 허벅지 → UpperLeg / 무릎 보호대, 정강이 → LowerLeg / 사바통 → Foot
- 칼 → Weapon.R / 방패 → Shield.L
- 서코트처럼 천으로 된 부분만 Hips, Spine, UpperLeg에 걸쳐 부드럽게 블렌딩해도 돼.
모든 메시를 "Knight_Body"로 Join하고, Armature 모디파이어를 추가한 다음 부모를 Knight_Armature로 설정해.

## 4. 포즈 테스트
팔 들기, 팔꿈치와 무릎 90도 굽히기, 허리 숙이기, 고개 돌리기를 하나씩 해 보고 look으로 확인해. 확인이 끝나면 Rest로 되돌려.

## 5. FBX 익스포트
Apply Scalings: FBX All / -Z Forward, Y Up / Add Leaf Bones 끄기 / 애니메이션이 있으면 Bake Animation 켜기
```

---

## 3. 걷기 애니메이션과 GIF 출력

```
너는 Blender MCP로 연결된 Blender를 조작하는 애니메이터야.
"Knight_Armature"에 걷기 애니메이션을 만들고, 그걸 GIF로 출력해.

## 1. 걷기 사이클 (제자리 걷기, 24fps, 프레임 1~24)
- 액션 이름은 "Knight_Walk". Hips가 앞으로 이동하지 않는 제자리 걷기로 만들어.
- 키 포즈: 1 Contact / 4 Down (Hips -4cm) / 7 Passing / 10 Up (+2cm) / 13~22 좌우 반전 / 25 = 1
- 반대쪽 포즈는 Paste Flipped로 만들어. 모든 F-Curve에 Cycles 모디파이어를 추가해.
- 무거운 갑옷을 입은 느낌으로: 보폭은 작게, Hips는 Z축 ±5도 회전하고 Chest는 반대로 회전, 칼 든 팔은 스윙 20도.
- 지지하는 발이 미끄러지거나 바닥을 뚫지 않게 해.

## 2. 렌더
- EEVEE (엔진은 try/except TypeError로 설정), 512x512, 3/4 측면 고정 카메라
- 월드 배경색은 바꾸지 마. 연한 배경이 필요하면 카메라에만 보이는 배경 평면을 쓰거나, 렌더할 때만 바꾸고 try/finally로 복원해.
- PNG 시퀀스 1~24를 //walk_frames/frame_####.png로 저장해.

## 3. GIF 변환
Blender 파이썬에 Pillow를 설치해 (ensurepip --user, pip install --user pillow).
duration=42, loop=0, disposal=2, 프레임마다 ADAPTIVE 팔레트 256색으로 변환한 뒤 .blend 파일 옆에 Knight_Walk.gif로 저장해.
액션 Knight_Walk에 Fake User를 켜.
```

---

## 4. 방패를 타지처럼 팔뚝에 매달기

```
방패를 손으로 쥐지 말고, 타지(Targe)처럼 왼쪽 팔뚝에 가죽 끈으로 묶어서 매단 형태로 바꿔.
방향은 월드 기준이 아니라 팔뚝(LowerArm.L) 기준으로 정해.

- 방패 뒷면을 팔뚝 바깥쪽에 평평하게 붙여. 방패 평면은 LowerArm.L의 로컬 Y축과 평행하게.
- 앞면 법선은 팔뚝과 수직이고, 몸 바깥쪽을 향하게. 손은 방패를 쥐지 않아.
- Shield.L 본의 부모를 LowerArm.L로 설정하고 (Hand.L이면 안 돼), 방패 버텍스는 Shield.L에만 웨이트 1.0으로 묶어.
- 손목과 팔꿈치 근처에 갈색 가죽 끈 2개를 추가해.
- 걷기 애니메이션의 왼팔은 방어 자세로: 팔꿈치 약 90도, 팔뚝은 몸 앞에 수평, 스윙 ±3도.
- 검증: 1, 7, 13, 19 프레임에서 |방패 법선 · 팔뚝 방향| < 0.15인지, 보스가 팔뚝보다 바깥에 있는지, 몸통과 겹치지 않는지 확인해.
```

---

## 5. 뷰포트가 하얗게 됐을 때

```
뷰포트 화면이 전체적으로 하얗게 떠 보여. 원래의 어두운 화면으로 되돌려줘. 카메라 오브젝트는 건드리지 마.
1. 월드 Background 노드(type == "BACKGROUND")의 Color/Strength, view_transform, exposure, gamma, 라이트 energy를 먼저 보고해.
2. 월드 배경색을 (0.05, 0.05, 0.05), Strength 1로 되돌리고, 바뀐 색 관리 값과 과한 라이트 energy도 원래대로 돌려.
3. 앞으로 GIF를 렌더할 때는 월드 색을 바꾸지 마.
4. look으로 어두운 배경과 원래 재질 색이 보이는지 확인해.
```

# Procedural Character Demo

이 프로젝트는 Godot 4.x stable 기준으로, 외부 캐릭터 PNG 없이 32x32 도트 캐릭터를 코드만으로 생성하고 `AnimatedSprite2D + SpriteFrames`로 재생하는 데모입니다.

## 포함 구조

- `scripts/character_dna.gd`
  - 시드 기반 외형 데이터와 팔레트/스타일/체형 파라미터를 관리합니다.
- `scripts/part_library.gd`
  - 앞머리 6종, 뒷머리 4종, 상의 4종, 하의 3종, 액세서리 3종을 좌표 마스크와 규칙 데이터로 제공합니다.
- `scripts/pose_solver.gd`
  - `idle`/`walk`, `down`/`left`/`right`/`up` 조합에 대해 정수 픽셀 앵커를 계산합니다.
- `scripts/pixel_rasterizer.gd`
  - 실제 `Image.create_empty(..., Image.FORMAT_RGBA8)` 기반 픽셀 프레임을 생성합니다.
- `scripts/frame_compiler.gd`
  - 애니메이션 프레임을 한 번에 구워 `SpriteFrames`로 만듭니다.
- `scripts/frame_cache.gd`
  - `DNA hash + animation set version + frame_size + palette signature` 키로 번들 캐시를 유지합니다.
- `scripts/character_archetype_library.gd`
  - 게임 기획에서 잡은 베이스 캐릭터를 `DNA 템플릿`으로 정의하는 샘플 라이브러리입니다.
- `scripts/procedural_character.gd`
  - 공개 API를 가진 래퍼 노드입니다. `get_dna_dictionary()` / `set_dna_from_dictionary()` / `apply_motion_vector()`를 제공합니다.
- `scripts/demo_controller.gd`
  - 데모 씬 입력과 상태 UI를 담당합니다.
- `scripts/game_integration_demo_controller.gd`
  - 커스터마이징 프리뷰와 실제 게임 월드 캐릭터를 연결하는 통합 데모 컨트롤러입니다.
- `scripts/procedural_character_self_check.gd`
  - 스모크 테스트 겸 self-check 로직입니다.
- `scenes/procedural_character_demo.tscn`
  - 실행 즉시 캐릭터가 보이는 데모 씬입니다.
- `scenes/game_integration_demo.tscn`
  - 베이스 캐릭터 선택 -> 커스터마이징 -> 인게임 자동 걷기 적용까지 한 화면에서 확인하는 데모 씬입니다.

## 생성 파이프라인

1. `CharacterDNA.randomized(seed)`가 재현 가능한 외형 값을 결정합니다.
2. `FrameCompiler`가 `idle` 4프레임, `walk` 6프레임, 4방향 전체를 한 번에 생성합니다.
3. 각 프레임마다 `PoseSolver`가 뼈대 앵커를 계산합니다.
4. `PixelRasterizer`가 레이어 순서대로 실제 픽셀을 채우고 외곽선을 둘러 `Image`를 만듭니다.
5. 생성된 `Image`는 `ImageTexture`로 바뀌어 `SpriteFrames`에 들어갑니다.
6. 재생 중에는 이미 구워 둔 `SpriteFrames`만 재생하고, DNA/팔레트가 바뀔 때만 다시 생성합니다.

## 게임 적용 구조

이 모듈은 "아무 캐릭터 스타일이나 자동으로 맞춰 주는 범용 생성기"가 아니라, `같은 스타일 계열의 캐릭터군`을 커스터마이징 가능한 모듈로 묶는 방식에 적합합니다.

1. 기획된 캐릭터의 기본 모습을 `CharacterDNA` 템플릿으로 정의합니다.
2. 커스터마이징 씬에서는 템플릿을 복사한 `preview DNA`만 수정합니다.
3. 저장 시에는 `dna.to_dictionary()` 결과만 세이브 데이터에 넣습니다.
4. 실제 게임 씬에서는 `character.set_dna_from_dictionary(saved_data)`로 외형을 복원합니다.
5. 이동 로직에서는 `character.apply_motion_vector(velocity)`를 호출해서 커스터마이징된 외형으로 `idle/walk` 애니메이션을 재생합니다.

`scenes/game_integration_demo.tscn`은 이 흐름을 그대로 보여주는 샘플입니다. 왼쪽 프리뷰에서 바꾼 외형은 바로 오른쪽 게임 캐릭터에 반영되지 않고, `Apply To Game`을 눌렀을 때만 저장 payload가 적용됩니다.

## 데모 조작

- `R`: 전체 랜덤
- `1/2/3`: 머리색 변경
- `4/5/6`: 상의/하의 색 변경
- `H`: 헤어스타일 변경
- `T`: 상의 스타일 변경
- `B`: 하의 스타일 변경
- `A`: 액세서리 토글 순환
- `방향키`: 방향 전환
- `Space`: `idle` / `walk` 전환
- `C`: self-check 재실행

## 실행 방법

1. Godot 4.x stable로 프로젝트를 엽니다.
2. 메인 씬은 이미 `res://scenes/game_integration_demo.tscn`으로 설정되어 있습니다.
3. 실행하면 왼쪽에는 커스터마이징 프리뷰, 오른쪽에는 실제 게임 월드에서 자동으로 걷는 캐릭터가 표시됩니다.
4. 기본 동작/셀프체크만 보고 싶으면 `res://scenes/procedural_character_demo.tscn`을 직접 실행하면 됩니다.

## Self-check

데모 시작 시 `scripts/procedural_character_self_check.gd`가 자동으로 실행되어 다음을 검사합니다.

- 필수 애니메이션 이름 존재 여부
- `idle` 4프레임 이상, `walk` 6프레임 이상 여부
- 서로 다른 3개 seed 결과가 완전히 같지 않은지
- 동일 seed를 두 번 생성했을 때 동일한지

Godot Output 패널과 데모 상단 라벨에서 결과를 확인할 수 있습니다.

## 디버그 PNG

`ProceduralCharacter.debug_save_png = true`로 켜면 프레임 생성 시 `user://generated_debug/` 아래에 PNG가 저장됩니다.

## 확장 포인트

- `PoseSolver`에 `attack`, `jump`, `sit` 같은 상태를 추가할 수 있습니다.
- `PartLibrary`에 신규 헤어/상의/하의/액세서리 마스크를 더 넣을 수 있습니다.
- `PixelRasterizer`의 레이어를 세분화하면 NPC 배치 생성이나 장비 슬롯 추가에 대응하기 쉽습니다.
- `FrameCache`는 현재 메모리 캐시만 쓰지만, 필요하면 디스크 캐시로 확장할 수 있습니다.
- `CharacterArchetypeLibrary`를 프로젝트별로 바꾸면 "기획된 기본 캐릭터들"을 같은 모듈 안에서 출발점으로 사용할 수 있습니다.

## 현재 제약

- 파츠 실루엣은 읽힘 위주로 단순화되어 있고, 아주 복잡한 헤어 물리나 장식 흔들림은 아직 없습니다.
- 얼굴 정보는 작은 해상도에 맞춰 최소화되어 있습니다.
- 좌우 방향은 규칙 기반 미러와 보정 로직을 혼합해서 사용합니다.
- self-check는 자동화 테스트 프레임워크가 아니라 런타임 스모크 테스트입니다.
- 현재 기본 모션 세트는 `idle` / `walk`뿐이므로, 실제 게임에서 `attack`, `jump`, `run`이 필요하면 `PoseSolver`와 `FrameCompiler`를 확장해야 합니다.

# dig-game

PC와 모바일 웹을 목표로 만드는 Godot 4 격자 기반 땅파기 퍼즐이다. 프로젝트 설정 이름은 `DigGame`이며 Compatibility 렌더러를 사용한다.

첫 Scene은 `Main`(Node2D)과 자식 `Ground`(TileMapLayer)로 구성했다. [흙 이미지](tiles/dirt.png)를 TileSet의 Atlas Source로 등록하고 테스트 지형을 배치했다. [첫 개발 기록](docs/devlog/2026-11-10.md)

프로젝트를 실행하면 Main에서 방향키로 Player를 움직일 수 있다. 키를 누르고 있으면 Ground의 사용 영역 안에서 32픽셀씩 반복 이동한다. [격자 이동 개발 기록](docs/devlog/2026-11-11.md)

다음 실습은 이동하려는 칸의 흙을 제거하면서 전진하는 기본 땅파기다. 장기적으로 보석을 모으며 어떤 땅을 먼저 팔지 판단하고, 출구에 도달하거나 목표를 채우면 스테이지를 클리어하는 게임을 구상하고 있다.

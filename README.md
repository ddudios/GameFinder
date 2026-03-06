<img width="100" height="100" alt="GameFinder" src="https://github.com/user-attachments/assets/e4b8274e-7595-4ae8-bef8-8ce2f685f542" />

# GameFinder

게임 탐색, 일정 관리, 다이어리 기록, 알림, 위젯 연동을 하나의 흐름으로 연결한 앱입니다.

|<img width="200" alt="IMG_3889" src="https://github.com/user-attachments/assets/c17d36cf-38aa-4d01-b3dc-9479c7d99541" />|<img width="200"  alt="IMG_3890" src="https://github.com/user-attachments/assets/fccfeee6-8441-4046-8fb4-a00e8ac6c542" />|<img width="200" alt="IMG_3884" src="https://github.com/user-attachments/assets/b58163c9-5147-421a-8fa1-cc9f48cc0aea" />|<img width="200" alt="IMG_3887" src="https://github.com/user-attachments/assets/eb3d603c-a63c-4ce9-8078-ff571f58a31d" />|
|:-:|:-:|:-:|:-:|

|구분|내용|
|:--:|:--|
|**팀 인원**|iOS 개발 1명|
|**기획 및 개발 기간**|2025.09.27 - 2025.11.01|
|**최소 지원 버전**|iOS 16.0+|

## 핵심 기능

- RAWG/CheapShark API 기반 게임 탐색(인기/무료/출시예정/할인)
- 검색 및 플랫폼별 결과 탐색
- 게임 상세 정보, 스크린샷, 태그/평점/출시일 조회
- Realm 기반 다이어리/즐겨찾기/알림 로컬 관리
- 출시일 기반 캘린더 탐색 및 게임별 일정 확인
- 로컬 알림 + Firebase Messaging 원격 푸시
- WidgetKit + App Group 기반 위젯 데이터 동기화
- `gamefinder://game/{id}` 딥링크를 통한 상세 화면 이동
- 한국어/영어/일본어 다국어 지원

## 기술 스택

|분류|기술 스택|
|:--:|:--|
|**Language**|![Swift](https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white)|
|**UI Framework**|![UIKit](https://img.shields.io/badge/UIKit-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**Architecture**|![MVVM](https://img.shields.io/badge/MVVM-0A66C2?style=flat-square) ![Repository](https://img.shields.io/badge/Repository-111111?style=flat-square) ![RxSwift](https://img.shields.io/badge/RxSwift-B7178C?style=flat-square&logo=reactivex&logoColor=white)|
|**Database**|![RealmSwift](https://img.shields.io/badge/RealmSwift-39477F?style=flat-square&logo=realm&logoColor=white)|
|**Networking**|![Alamofire](https://img.shields.io/badge/Alamofire-D92C2C?style=flat-square&logo=alamofire&logoColor=white)|
|**Image/Media**|![Kingfisher](https://img.shields.io/badge/Kingfisher-1F8B4C?style=flat-square) ![AVFoundation](https://img.shields.io/badge/AVFoundation-007AFF?style=flat-square&logo=apple&logoColor=white) ![AVKit](https://img.shields.io/badge/AVKit-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**Layout**|![SnapKit](https://img.shields.io/badge/SnapKit-4F46E5?style=flat-square)|
|**Calendar**|![FSCalendar](https://img.shields.io/badge/FSCalendar-0F766E?style=flat-square)|
|**Push/Infra**|![Firebase_Messaging](https://img.shields.io/badge/Firebase_Messaging-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Firebase_Analytics](https://img.shields.io/badge/Firebase_Analytics-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Crashlytics](https://img.shields.io/badge/Crashlytics-FFCA28?style=flat-square&logo=firebase&logoColor=black)|
|**Widget**|![WidgetKit](https://img.shields.io/badge/WidgetKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![App_Groups](https://img.shields.io/badge/App%20Groups-111111?style=flat-square&logo=apple&logoColor=white)|
|**Localization**|![ko](https://img.shields.io/badge/ko-111111?style=flat-square) ![en](https://img.shields.io/badge/en-111111?style=flat-square) ![ja](https://img.shields.io/badge/ja-111111?style=flat-square)|

## 전체 구조

### 아키텍처

- 화면 로직은 `ViewController + ViewModel(MVVM)`로 분리
- 비동기 이벤트/상태 바인딩은 `RxSwift/RxCocoa`로 처리
- 네트워크 통신은 `Router + NetworkManager(Alamofire)`로 캡슐화
- 로컬 영속성은 `Realm Repository` 계층에서 관리
- 공통 UI/유틸/테마는 `Shared` 모듈로 분리

### 주요 데이터 흐름

- 홈/탐색: `RAWG/CheapShark API 조회 -> Realm 캐시 저장 -> 화면 반영`
- 다이어리/즐겨찾기/알림: `사용자 액션 -> Realm 저장/관찰 -> UI 자동 갱신`
- 로컬 알림: `알림 등록 -> 출시 하루 전 스케줄링 -> 배지 재계산`
- 푸시: `Firebase Messaging 토큰 등록 -> 원격 푸시 수신 -> 상세 화면 이동`
- 위젯: `앱 데이터 수집 -> App Group 저장 -> Widget Timeline 갱신`
- 딥링크: `gamefinder://game/{id} -> SceneDelegate/AppDelegate 라우팅 -> 상세 화면 Push`

## 주요 기능

### 홈/탐색 (Finder)

|<img width="200" alt="IMG_3901" src="https://github.com/user-attachments/assets/a4b9b310-f6f0-40e2-9551-3fe8d4994e47" />|<img width="200" alt="IMG_3890" src="https://github.com/user-attachments/assets/6c871070-1dab-4c98-aa6f-046cdc5b1bff" />|
|:-:|:-:|

- 인기 게임, 무료 게임, 출시 예정 게임, 할인 딜 섹션 제공
- 섹션별 네트워크 실패 시 캐시 기반 fallback 처리
- 게임 카드 탭으로 상세 화면 이동
- 스켈레톤 UI/이미지 로딩으로 초기 체감 성능 보완

### 검색 (Search)

|<img width="200" alt="IMG_3882" src="https://github.com/user-attachments/assets/fcf3b823-970c-4779-961b-da94903cd26b" />|<img width="200" alt="Screenshot 2026-03-06 at 10 05 56 AM" src="https://github.com/user-attachments/assets/f92488e8-87f8-4700-b2a0-5b17ac1786ec" />|
|:-:|:-:|

- 키워드 기반 게임 검색 지원
- 플랫폼 필터(PC/콘솔/모바일) 기반 결과 탐색
- 검색 결과 카드에서 상세 화면으로 연계

### 게임 상세 (Detail)

|<img width="200" alt="IMG_3911" src="https://github.com/user-attachments/assets/44d260ef-a99d-4753-b152-09e94dd92471" />|
|:-:|

- 게임 기본 정보(제목/출시일/평점/장르/태그) 조회
- 스크린샷/플랫폼/개발사/퍼블리셔/공식 사이트 정보 제공
- 즐겨찾기/다이어리/알림 액션 버튼 제공

### 다이어리 (Diary)

|<img width="200" alt="IMG_3897" src="https://github.com/user-attachments/assets/c2e9efa9-4003-4640-b1bf-fc1b93f82453" />|<img width="200" alt="IMG_4154" src="https://github.com/user-attachments/assets/0f51528d-5af0-491d-924d-6fb29d28b43a" />|
|:-:|:-:|

- 게임별 플레이 다이어리 작성/수정/삭제 지원
- 텍스트와 이미지/영상 첨부 기록 관리
- AVPlayer 기반 영상 미리보기/재생 지원
- Realm observe 기반 변경사항 즉시 반영

### 라이브러리 (Library)

|<img width="200" alt="IMG_4156" src="https://github.com/user-attachments/assets/3d657383-a20f-4988-9190-b5c31ea4216d" />|
|:-:|

- 다이어리/즐겨찾기/알림을 카테고리별로 통합 조회
- PageView 기반 카테고리 전환 UI 구성
- 저장된 게임 데이터 재사용으로 탐색 흐름 단축

### 캘린더 (Calendar)

|<img width="200" alt="IMG_3884" src="https://github.com/user-attachments/assets/fef5e3eb-0f46-4077-ad55-ade38ded0796" />|
|:-:|

- FSCalendar 기반 월간 출시일 탐색
- 날짜 선택 시 해당 일자의 출시 게임 목록 표시
- 빈 상태 UI와 diffable data source 기반 목록 업데이트

### 알림/푸시

||
|:-:|

- 출시 하루 전 로컬 알림 스케줄링
- 게임별 알림 on/off 및 전역 알림 토글 지원
- Firebase Messaging 기반 원격 푸시 수신
- 포그라운드/백그라운드 진입 시 배지 동기화 처리

### 위젯/딥링크

|<img width="200" alt="스크린샷 2026-03-06 오전 10 34 53" src="https://github.com/user-attachments/assets/f57268df-8706-4edd-a0f7-bdb8190adfc7" />|<img width="200" alt="스크린샷 2026-03-06 오전 10 33 51" src="https://github.com/user-attachments/assets/3369975c-ae9b-4f4b-9119-95e1f183d1ed" />
|:-:|:-:|

- WidgetKit Extension으로 출시 예정 게임 정보 노출
- App Group(UserDefaults/Shared Container)로 앱-위젯 데이터 공유
- 위젯 탭 시 `gamefinder://game/{id}` 딥링크로 상세 진입

### 설정

|<img width="200" alt="IMG_3899" src="https://github.com/user-attachments/assets/b9eb1d69-2490-49bb-b488-8cf3e6e8017a" />|<img width="200" alt="IMG_3992" src="https://github.com/user-attachments/assets/6d16dd7d-9e91-4c5a-82fe-bc4fb65e84d6" />|
|:-:|:-:|

- 알림 권한 확인 및 설정 화면 연동
- 앱 내 언어 전환(ko/en/ja) 지원
- 문의 메일 작성 및 디바이스/버전 정보 자동 첨부

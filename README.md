# 할 일 (todolist)

날짜별·프로젝트별로 업무를 정리하는 **개인용 todo 웹앱**.
PC(집/회사)와 폰 어디서든 같은 데이터로 접속한다.

- 사이트: https://yunyuk.github.io/todolist/
- 화면: GitHub Pages (정적 호스팅)
- 데이터·로그인: [Supabase](https://supabase.com) (PostgreSQL + 이메일/비밀번호 로그인)
- 빌드 도구 없음: 순수 HTML/CSS/JS, Supabase JS는 CDN으로 로드

## 버전 기록

| 버전 | 날짜 | 내용 |
|---|---|---|
| v1.1 | 2026-11-06 | 화면 제목 아이콘, 프로젝트 드래그&드롭 순서 변경, 반복(X일/X주/X개월마다·횟수·종료일) + 반복 메뉴, 놓친 반복 밀린 일 표시, 일간 메뉴 삭제, 하루 시작 아침 8시 |
| v1.0 | 2026-11-05 | 최초 배포 |

## 기능

| 화면 | 내용 |
|---|---|
| ☀️ 오늘 (첫 화면) | 오늘 할 일 + 지난 날짜인데 못 끝낸 **밀린 일** (빨간색) |
| 🗓️ 주간 | **금요일~목요일** 한 주를 요일별로 표시 (회사 주간보고 기준). ◀ ▶ 📅로 다른 주 이동, 이 주에 완료한 다른 일도 함께 표시 |
| 🔁 반복 | 모든 반복하는 일을 한곳에서: **진행 중 / ⏳ 시작 예정 / 끝난 반복**. 시작 전인 반복도 여기서 수정 |
| 💡 꿀팁 | 메모장. 카드에는 제목만 표시 (최근 수정순). 누르면 내용 보기 → [수정] 버튼으로 편집, 삭제 |
| 프로젝트 | 색상 지정, 프로젝트별 할 일 / 완료 내역. 왼쪽 메뉴에서 **드래그&드롭으로 순서 변경** (PC) |

- **하루의 시작은 아침 8시**: 0시~8시 전은 아직 전날로 취급 (오늘·밀린 일·반복 모두 8시에 넘어감)
- 할 일마다 제목·날짜·프로젝트·메모 (날짜는 필수: 비워두면 오늘)
- 날짜 그룹 안에서 **프로젝트별 서브그룹**으로 묶어 표시 (프로젝트 없는 일은 `etc`)
- 체크하면 그 자리에 취소선으로 남음 (다음 날부터 숨김, '주간'에서는 그 주 내내 표시)
- 추가할 때 `오늘` / `내일` 빠른 날짜 선택, `🔁 반복` 설정
- **🔁 반복하는 일**: **X일마다 / X주마다 / X개월마다** 반복 (X는 직접 입력). 끝은 **계속 반복 / N회 반복 / 종료 날짜까지** 중 선택.
  반복 날짜마다 **아침 8시**에 그날 목록에 나타나고 그날마다 따로 체크 (프로젝트 화면엔 그룹으로 표시).
  월 반복에서 그 달에 없는 날짜(예: 31일)는 말일로 맞춤.
  **놓쳤을 때 '밀린 일'에 표시** 옵션(기본 켬): 반복 날짜에 체크 못 하고 지나가면 다음 반복 날까지 밀린 일에 놓친 날짜(`📅 11/5`)와 함께 표시
  할 일을 눌러 **완료**를 누르면 종결 (그날까지만 표시). 종결 후 **다시 진행**도 가능
- 다른 기기에서 바꾼 내용은 탭(앱)으로 돌아오면 자동으로 다시 불러옴
- **날씨** (PC 넓은 화면 1280px 이상에서만 오른쪽에 표시): 현재 날씨·체감·습도·바람·강수확률, 미세먼지/초미세먼지, 시간별(3시간 간격), 5일 예보.
  [Open-Meteo](https://open-meteo.com) 무료 API, 위치는 브라우저 위치 권한 (거절 시 서울). 30분마다 갱신
- 다크 모드 기본 (라이트 색상도 코드에 남아 있음), 모바일 화면(760px 이하) 대응
- PWA: 폰 홈 화면에 앱처럼 설치 가능

## 파일 구성

| 파일 | 역할 |
|---|---|
| `index.html` | 앱 전체 (화면 + 스타일 + 로직, 단일 파일) |
| `config.js` | Supabase 접속 정보 (Project URL, Publishable key) |
| `schema.sql` | DB 테이블 + 보안 정책(RLS) 생성 SQL |
| `manifest.webmanifest`, `sw.js` | PWA 설정 / 오프라인 캐시 |
| `icon/icon-192.png`, `icon/icon-512.png` | 앱 아이콘 |

## DB 구조

```
projects(id, user_id, name, color, sort_order, created_at)
todos(id, user_id, project_id, title, memo, due_date, done, done_at, daily, created_at)
todo_checks(todo_id, day, user_id, created_at)   -- 반복하는 일의 날짜별 체크
-- todos 반복 칸: repeat_unit(day/week/month), repeat_every, repeat_count, repeat_until
notes(id, user_id, title, body, created_at, updated_at)   -- 꿀팁 메모
```

- `user_id`는 로그인한 사용자로 자동 입력 (`default auth.uid()`)
- 두 테이블 모두 **RLS**로 본인(`user_id = auth.uid()`) 데이터만 읽기/쓰기 가능
- 프로젝트를 지우면 그 안의 할 일은 남고 '프로젝트 없음'으로 바뀜

## 보안

- `config.js`의 **Publishable key**는 공개돼도 되는 키다. RLS 때문에 로그인한 본인 데이터만 접근된다.
  - 로그인 없이 조회하면 빈 목록만 나오는 것 확인함
- **Secret key(`sb_secret_...`) / `service_role` 키는 절대 저장소에 넣지 않는다.** (RLS 우회 가능)
- 새 계정 가입은 막아둠 → 다른 사람은 계정을 만들 수 없다.

## 처음부터 다시 세팅하는 법

### 1. Supabase 프로젝트 + 테이블
1. supabase.com 가입 → Organization 생성 (Personal / Free)
2. New project (Region: **Northeast Asia (Seoul)**)
3. **SQL Editor → New query** → `schema.sql` 전체 붙여넣고 **Run**
4. **Table Editor**에 `projects`, `todos`가 생기고 RLS가 켜져 있는지 확인

### 2. 접속 정보 → `config.js`
- Project URL: `https://<Project ID>.supabase.co`
  (Project ID는 **Project Settings → General**, 또는 상단 **Connect** 버튼)
- Publishable key: **Project Settings → API Keys** → `sb_publishable_...` 복사 버튼

### 3. 로그인 설정
**Authentication → Sign In / Providers → User Signups**
- **Confirm email**: 끔 (혼자 쓰는 용도라 메일 확인 생략)
- **Allow new users to sign up**: 일단 켜둠 (5단계에서 끔)

### 4. GitHub Pages 배포
1. Public 저장소 `todolist` 생성 후 파일 push
2. **Settings → Pages** → Source: Deploy from a branch / Branch: `main`, `/(root)`
3. 1~2분 뒤 `https://<GitHub아이디>.github.io/todolist/` 접속

### 5. 계정 만들고 가입 막기
1. 사이트에서 **계정 만들기**로 가입 → 로그인 확인
2. Supabase에서 **Allow new users to sign up** 끄기

### 6. 폰에 설치
- 안드로이드(크롬): 메뉴 ⋮ → **홈 화면에 추가** / **앱 설치**
- 아이폰(사파리): 공유 → **홈 화면에 추가**

## 수정하고 반영하기

```bash
# 1) 로컬에서 확인
python3 -m http.server 8000      # → http://localhost:8000

# 2) 반영 (push 후 1~2분 뒤 사이트에 적용)
git add .
git commit -m "변경 내용"
git push
```

- ⚠️ 로컬에서 띄워도 **실제 Supabase DB**에 연결된다. 테스트 중 삭제하면 실제 데이터가 지워진다.
- 데이터(할 일/프로젝트)와 Supabase 설정은 git과 무관하게 즉시 반영된다. git push가 필요한 건 **코드 변경**뿐.
- `sw.js`의 캐시 파일 목록을 바꾸면 `CACHE` 버전(`todo-v2` → `todo-v3`)도 올린다.
- 폰에서 안 바뀌어 보이면 앱을 완전히 닫았다 다시 열기. PC는 `Ctrl+Shift+R`.
- DB 구조를 바꾸면 `schema.sql`도 갱신하고, 새 테이블/컬럼에는 RLS 정책을 반드시 추가한다.

## 참고

- Supabase 무료 플랜은 일주일 넘게 활동이 거의 없으면 프로젝트가 **일시정지**된다.
  데이터는 남아 있고, 대시보드에서 다시 켜면 된다.

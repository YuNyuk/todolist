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
| v1.0 | 2026-11-05 | 첫 배포: 오늘/날짜별/날짜 없음/완료/프로젝트 화면, 로그인, PWA<br>아이콘 `icon/` 폴더로 정리, README 추가, PC 화면 오른쪽 아래 버전 표시, 다크 모드 기본 |

## 기능

| 화면 | 내용 |
|---|---|
| ☀️ 오늘 | 오늘 할 일 + 지난 날짜인데 못 끝낸 **밀린 일** (빨간색) |
| 📅 날짜별 | 남은 할 일을 날짜 순으로 묶어서 표시 |
| 📥 날짜 없음 | 날짜를 정하지 않은 할 일 |
| ✅ 완료 | 완료한 날짜별 기록 (최근 500개) |
| 프로젝트 | 색상 지정, 프로젝트별 할 일 / 완료 내역 |

- 할 일마다 제목·날짜·프로젝트·메모
- 추가할 때 `오늘` / `내일` / `없음` 빠른 날짜 선택
- 다른 기기에서 바꾼 내용은 탭(앱)으로 돌아오면 자동으로 다시 불러옴
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
projects(id, user_id, name, color, created_at)
todos(id, user_id, project_id, title, memo, due_date, done, done_at, created_at)
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

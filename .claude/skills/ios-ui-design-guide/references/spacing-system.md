# iOS 간격 시스템 (iOS Spacing System)

## 8pt 그리드 시스템 (8pt Grid System)

iOS는 **8포인트(pt) 그리드 시스템**을 사용합니다. 웹의 8px와 유사하지만 물리적 크기가 아닌 논리적 포인트 단위입니다.

## 포인트(pt) vs 픽셀(px)

- **1pt = 1픽셀** (@1x 디바이스)
- **1pt = 2픽셀** (@2x 디바이스, iPhone 대부분)
- **1pt = 3픽셀** (@3x 디바이스, iPhone Pro 시리즈)

**중요**: 디자인 시 픽셀이 아닌 **포인트(pt)** 단위 사용

---

## 간격 스케일 (Spacing Scale)

모든 margin, padding, spacing은 **8의 배수**:

| 값 (pt) | SwiftUI | 사용 용도 |
|---------|---------|-----------|
| `4`     | (예외적) | 매우 작은 간격, 아이콘-텍스트 |
| `8`     | `.padding(8)` | 최소 간격, 인접 요소 |
| `12`    | `.padding(12)` | 컴팩트한 padding |
| `16`    | `.padding()` | **기본 padding** (SwiftUI 기본값) |
| `20`    | `.padding(20)` | 중간 간격 |
| `24`    | `.padding(24)` | 섹션 간격 |
| `32`    | `.padding(32)` | 큰 섹션 간격 |
| `40`    | `.padding(40)` | 헤더/푸터 영역 |
| `48`    | `.padding(48)` | 페이지 레벨 간격 |
| `64`    | `.padding(64)` | 대형 여백 |

---

## SwiftUI Padding Modifiers

### 기본 Padding

```swift
// 모든 방향 16pt (기본값)
Text("Hello").padding()

// 특정 값 지정
Text("Hello").padding(24)

// 방향별 지정
Text("Hello")
    .padding(.horizontal, 20)
    .padding(.vertical, 12)

// 개별 방향
Text("Hello")
    .padding(.leading, 16)
    .padding(.trailing, 16)
    .padding(.top, 8)
    .padding(.bottom, 8)
```

### Safe Area

```swift
// Safe Area 무시 (전체 화면)
.ignoresSafeArea()

// Safe Area 포함 (권장)
.padding()  // 자동으로 Safe Area 고려
```

---

## 컴포넌트별 간격 가이드

### 버튼 (Button)

```swift
// 표준 버튼 padding
Button("확인") { }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(10)

// 작은 버튼
Button("취소") { }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)

// 큰 버튼
Button("시작하기") { }
    .padding(.horizontal, 32)
    .padding(.vertical, 16)
```

**버튼 간격**:
- 인접한 버튼: 8-12pt
- 버튼 그룹 간: 16-24pt

---

### 카드/섹션 (Card/Section)

```swift
VStack(spacing: 16) {  // 카드 내부 요소 간격
    Text("제목")
    Text("설명")
}
.padding(20)  // 카드 내부 padding
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
```

**카드 간격**:
- 내부 padding: 16-24pt
- 카드 간 간격: 12-16pt (List에서)
- 카드 좌우 여백: 16-20pt

---

### 리스트 (List)

```swift
List {
    ForEach(items) { item in
        HStack(spacing: 12) {  // 아이템 내부 간격
            Image(systemName: item.icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)  // 리스트 아이템 상하 여백
    }
}
.listStyle(.insetGrouped)
```

**리스트 간격**:
- 아이템 내부 수평 간격: 12pt
- 아이템 내부 수직 간격: 4-8pt
- 아이템 padding: 8-12pt (상하)
- 섹션 간: 32pt (자동)

---

### 폼 (Form)

```swift
Form {
    Section {
        TextField("이름", text: $name)
            .padding(.vertical, 12)  // 입력 필드 높이

        TextField("이메일", text: $email)
            .padding(.vertical, 12)
    }

    Section {
        Button("제출") { }
    }
}
```

**폼 간격**:
- Label-TextField: 4-8pt (Section이 자동 처리)
- TextField 내부 padding: 12pt (상하)
- 섹션 간: 32pt (자동)

---

### 네비게이션 바 (Navigation Bar)

```swift
NavigationView {
    List { }
        .navigationTitle("제목")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("추가") { }
            }
        }
}
```

**네비게이션 간격**:
- 기본 높이: 44pt (표준 터치 영역)
- Large Title 높이: 96pt
- Toolbar 아이템 간격: 16pt

---

### 스택 간격 (VStack/HStack/ZStack)

```swift
// 수직 스택
VStack(spacing: 16) {  // 요소 간 16pt 간격
    Text("제목")
    Text("부제목")
    Text("설명")
}

// 수평 스택
HStack(spacing: 12) {  // 요소 간 12pt 간격
    Image(systemName: "star.fill")
    Text("평점")
}

// 간격 없음
VStack(spacing: 0) {
    Text("A")
    Divider()
    Text("B")
}
```

**스택 간격 권장값**:
- 작은 간격: 4-8pt
- 중간 간격: 12-16pt (기본)
- 큰 간격: 20-32pt

---

## Safe Area 처리

### Safe Area Insets

```swift
// Safe Area 자동 적용 (권장)
VStack {
    Text("Content")
}
.padding()  // Safe Area 포함

// Safe Area 무시
Image("background")
    .resizable()
    .ignoresSafeArea()
```

### Safe Area Insets 값

- **상단**: 노치/Dynamic Island (44-59pt)
- **하단**: 홈 인디케이터 (34pt)
- **좌우**: 0pt (일반), 44pt (Landscape)

---

## 반응형 간격 (Adaptive Spacing)

### Size Classes

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var padding: CGFloat {
    horizontalSizeClass == .compact ? 16 : 32
}

VStack {
    Text("Content")
}
.padding(padding)
```

### Dynamic Type 고려

```swift
// Dynamic Type에 따라 간격 조정
@ScaledMetric var spacing: CGFloat = 16

VStack(spacing: spacing) {
    Text("제목")
    Text("본문")
}
```

---

## 금지 사항 (Avoid)

❌ **임의의 값**: 13pt, 27pt, 35pt 등 (8의 배수가 아님)
❌ **픽셀 단위**: px 대신 pt 사용
❌ **과도한 밀집**: 모든 요소가 붙어있어 답답함
❌ **Safe Area 무시**: 콘텐츠가 노치/홈 인디케이터에 가려짐
❌ **고정된 간격**: Dynamic Type 무시

---

## 올바른 사용 예시

### ✅ 카드 레이아웃

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("제목")
        .font(.headline)
    Text("설명")
        .font(.body)
        .foregroundColor(.secondary)
}
.padding(20)
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
.padding(.horizontal, 16)  // 화면 좌우 여백
```

### ✅ 폼 레이아웃

```swift
Form {
    Section {
        TextField("이름", text: $name)
        TextField("이메일", text: $email)
    }

    Section {
        Button("저장") { }
    }
}
// Form이 자동으로 적절한 간격 적용
```

### ✅ 리스트 아이템

```swift
HStack(spacing: 12) {
    Image(systemName: "person.circle.fill")
        .font(.system(size: 40))

    VStack(alignment: .leading, spacing: 4) {
        Text("이름")
            .font(.headline)
        Text("직책")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}
.padding(.vertical, 8)
```

---

## 참고 자료

- [HIG - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [SwiftUI Layout System](https://developer.apple.com/documentation/swiftui/layout)

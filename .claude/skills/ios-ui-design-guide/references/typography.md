# iOS 타이포그래피 시스템 (iOS Typography System)

## 시스템 폰트: SF Pro

iOS는 **SF Pro (San Francisco)** 폰트를 시스템 기본 폰트로 사용합니다.

### SF Pro 특징
- **가독성 최적화**: 작은 크기에서도 선명
- **Dynamic Type 지원**: 사용자 설정에 따라 크기 자동 조정
- **다양한 Weight**: Ultralight부터 Black까지 9단계
- **숫자 최적화**: 표 형식(Tabular) 숫자 지원

---

## Dynamic Type

iOS의 핵심 접근성 기능으로, 사용자가 시스템 설정에서 텍스트 크기를 조정할 수 있습니다.

### Dynamic Type 지원 (필수)

```swift
// ✅ Dynamic Type 자동 지원
Text("제목")
    .font(.title)  // 시스템 텍스트 스타일 사용

// ❌ Dynamic Type 미지원
Text("제목")
    .font(.system(size: 24))  // 고정 크기
```

### 텍스트 스타일 (Text Styles)

SwiftUI에서 제공하는 시스템 텍스트 스타일:

| 스타일 | SwiftUI | 기본 크기 | 용도 |
|--------|---------|-----------|------|
| **Large Title** | `.largeTitle` | 34pt | 네비게이션 바 큰 제목 |
| **Title** | `.title` | 28pt | 페이지 제목 |
| **Title 2** | `.title2` | 22pt | 섹션 제목 |
| **Title 3** | `.title3` | 20pt | 서브섹션 제목 |
| **Headline** | `.headline` | 17pt (Bold) | 강조 제목, 리스트 제목 |
| **Body** | `.body` | 17pt | 본문 텍스트 (기본) |
| **Callout** | `.callout` | 16pt | 보조 정보 |
| **Subheadline** | `.subheadline` | 15pt | 서브헤딩, 메타데이터 |
| **Footnote** | `.footnote` | 13pt | 각주, 추가 정보 |
| **Caption** | `.caption` | 12pt | 캡션, 라벨 |
| **Caption 2** | `.caption2` | 11pt | 보조 캡션 |

---

## 폰트 Weight (Font Weight)

SF Pro는 9단계 weight 제공:

| Weight | SwiftUI | 값 | 용도 |
|--------|---------|---|------|
| **Ultralight** | `.ultraLight` | 100 | 대형 디스플레이 전용 |
| **Thin** | `.thin` | 200 | 대형 디스플레이 전용 |
| **Light** | `.light` | 300 | 큰 텍스트 |
| **Regular** | `.regular` | 400 | 본문 (기본) |
| **Medium** | `.medium` | 500 | 강조, 버튼 |
| **Semibold** | `.semibold` | 600 | 서브헤딩, 중요 정보 |
| **Bold** | `.bold` | 700 | 제목, 강조 |
| **Heavy** | `.heavy` | 800 | 매우 강한 강조 |
| **Black** | `.black` | 900 | 특별한 강조 |

### 사용 예시

```swift
// 시스템 스타일 + Weight
Text("제목")
    .font(.title.weight(.bold))

// 커스텀 크기 + Weight
Text("라벨")
    .font(.system(size: 16, weight: .medium))
```

---

## 텍스트 계층 구조

### 페이지 제목

```swift
Text("설정")
    .font(.largeTitle)
    .fontWeight(.bold)
```

### 섹션 제목

```swift
Text("일반")
    .font(.title2)
    .fontWeight(.semibold)
```

### 리스트 아이템

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("제목")
        .font(.headline)  // 17pt Bold
    Text("설명")
        .font(.subheadline)  // 15pt Regular
        .foregroundColor(.secondary)
}
```

### 본문 텍스트

```swift
Text("긴 본문 텍스트...")
    .font(.body)  // 17pt Regular
    .lineSpacing(4)  // 줄 간격 추가
```

---

## 텍스트 정렬 (Text Alignment)

```swift
// 왼쪽 정렬 (기본)
Text("Hello").multilineTextAlignment(.leading)

// 중앙 정렬
Text("제목").multilineTextAlignment(.center)

// 오른쪽 정렬
Text("날짜").multilineTextAlignment(.trailing)
```

---

## 줄 간격 및 제한 (Line Spacing & Limit)

### 줄 간격

```swift
Text("긴 본문 텍스트")
    .lineSpacing(8)  // 줄 간격 8pt
```

### 줄 수 제한

```swift
Text("매우 긴 텍스트...")
    .lineLimit(2)  // 최대 2줄
    .truncationMode(.tail)  // 말줄임표
```

---

## 커스텀 폰트 (Custom Fonts)

브랜드 아이덴티티를 위해 커스텀 폰트 사용 가능:

### 1. 폰트 파일 추가

1. `.ttf` 또는 `.otf` 파일을 프로젝트에 추가
2. `Info.plist`에 폰트 등록:

```xml
<key>UIAppFonts</key>
<array>
    <string>CustomFont-Regular.ttf</string>
    <string>CustomFont-Bold.ttf</string>
</array>
```

### 2. SwiftUI에서 사용

```swift
Text("커스텀 폰트")
    .font(.custom("CustomFont-Regular", size: 17))

// Dynamic Type 지원
Text("커스텀 폰트")
    .font(.custom("CustomFont-Regular", size: 17, relativeTo: .body))
```

### 권장 사항

- **시스템 폰트 우선**: SF Pro가 이미 최적화되어 있음
- **브랜딩 목적만**: 브랜드 아이덴티티가 중요한 경우만 커스텀 폰트
- **Dynamic Type 지원**: 커스텀 폰트도 `relativeTo` 사용
- **최대 2개 폰트**: 제목용 1개 + 본문용 1개

---

## 색상과 타이포그래피

```swift
// 주요 텍스트
Text("제목")
    .font(.headline)
    .foregroundColor(.primary)

// 보조 텍스트
Text("설명")
    .font(.subheadline)
    .foregroundColor(.secondary)

// 3차 텍스트
Text("부가 정보")
    .font(.caption)
    .foregroundColor(Color(.tertiaryLabel))
```

---

## 접근성 고려사항

### Dynamic Type 지원 (필수)

```swift
// ✅ 권장: 시스템 텍스트 스타일
Text("본문").font(.body)

// ⚠️ 주의: 고정 크기는 relativeTo 사용
Text("커스텀").font(.system(size: 17, relativeTo: .body))

// ❌ 금지: 완전 고정 크기
Text("고정").font(.system(size: 17))
```

### 최소 텍스트 크기

- **본문 텍스트**: 최소 11pt (Caption2)
- **터치 타겟 라벨**: 최소 17pt (Body) 권장

### Bold Text 지원

```swift
@Environment(\.legibilityWeight) var legibilityWeight

var textWeight: Font.Weight {
    legibilityWeight == .bold ? .semibold : .regular
}

Text("텍스트").fontWeight(textWeight)
```

---

## 컴포넌트별 타이포그래피

### 버튼

```swift
// 표준 버튼
Button("확인") { }
    .font(.body.weight(.semibold))  // 17pt Semibold

// 작은 버튼
Button("취소") { }
    .font(.subheadline.weight(.medium))  // 15pt Medium

// 큰 버튼 (Call-to-Action)
Button("시작하기") { }
    .font(.title3.weight(.bold))  // 20pt Bold
```

### 입력 필드

```swift
TextField("이름", text: $name)
    .font(.body)  // 17pt Regular

// 플레이스홀더는 자동으로 .secondary 색상
```

### 네비게이션 타이틀

```swift
NavigationView {
    List { }
        .navigationTitle("설정")  // Large Title 자동
        .navigationBarTitleDisplayMode(.large)
}
```

### 리스트

```swift
List {
    ForEach(items) { item in
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)  // 17pt Bold
            Text(item.subtitle)
                .font(.subheadline)  // 15pt Regular
                .foregroundColor(.secondary)
        }
    }
}
```

---

## 금지 사항 (Avoid)

❌ **고정 크기**: Dynamic Type 미지원
```swift
// 나쁜 예
Text("제목").font(.system(size: 24))

// 좋은 예
Text("제목").font(.title2)
```

❌ **너무 작은 텍스트**: 11pt 미만
❌ **과도한 Weight**: Ultralight, Thin은 대형 화면 전용
❌ **3개 이상 폰트**: 시각적 혼란
❌ **낮은 대비**: 읽기 어려운 색상 조합

---

## 올바른 사용 예시

### ✅ 프로필 화면

```swift
VStack(spacing: 8) {
    Image(systemName: "person.circle.fill")
        .font(.system(size: 80))

    Text("홍길동")
        .font(.title2.weight(.bold))

    Text("iOS 개발자")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
```

### ✅ 설정 리스트

```swift
List {
    Section {
        HStack {
            Text("알림")
                .font(.body)
            Spacer()
            Toggle("", isOn: $isEnabled)
        }
    }
}
```

### ✅ 폼 입력

```swift
Form {
    Section(header: Text("개인 정보").font(.headline)) {
        TextField("이름", text: $name)
            .font(.body)
        TextField("이메일", text: $email)
            .font(.body)
    }
}
```

---

## 참고 자료

- [HIG - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [SF Pro Font](https://developer.apple.com/fonts/)
- [Dynamic Type](https://developer.apple.com/design/human-interface-guidelines/accessibility#Dynamic-Type)

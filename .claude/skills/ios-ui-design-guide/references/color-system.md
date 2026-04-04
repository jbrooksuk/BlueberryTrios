# iOS 색상 시스템 (iOS Color System)

## 시스템 컬러 (System Colors)

iOS는 **시스템 컬러(System Colors)**를 제공하여 다크 모드와 라이트 모드를 자동으로 지원합니다.

## 기본 원칙

1. **시스템 컬러 우선 사용**: 커스텀 컬러보다 시스템 컬러 권장
2. **다크 모드 고려**: 모든 컬러는 다크/라이트 모드 대응
3. **의미론적 컬러**: 기능에 맞는 의미 있는 이름 사용
4. **접근성**: 충분한 대비(WCAG AA 이상)

---

## 시스템 컬러 카테고리

### 1. Adaptive Colors (적응형 컬러)

다크/라이트 모드에서 자동으로 색상 변경:

```swift
// Label Colors (텍스트)
Color.primary          // 주요 텍스트
Color.secondary        // 보조 텍스트
Color(.tertiaryLabel)  // 3차 텍스트
Color(.quaternaryLabel) // 4차 텍스트 (플레이스홀더)

// Fill Colors (배경, 채우기)
Color(.systemFill)           // 주요 채우기
Color(.secondarySystemFill)  // 보조 채우기
Color(.tertiarySystemFill)   // 3차 채우기
Color(.quaternarySystemFill) // 4차 채우기

// Background Colors (배경)
Color(.systemBackground)              // 주요 배경 (화면 전체)
Color(.secondarySystemBackground)     // 그룹화된 콘텐츠 배경
Color(.tertiarySystemBackground)      // 3차 배경 (카드 내부)

// Grouped Background Colors (그룹 배경)
Color(.systemGroupedBackground)       // 그룹 뷰 배경
Color(.secondarySystemGroupedBackground)
Color(.tertiarySystemGroupedBackground)
```

### 2. Standard Colors (표준 컬러)

```swift
// UI Element Colors
Color.blue       // 링크, 액션
Color.green      // 성공, 확인
Color.red        // 에러, 삭제
Color.orange     // 경고
Color.yellow     // 주의
Color.purple, Color.pink, Color.indigo, Color.teal, Color.cyan
```

### 3. Semantic Colors (의미론적 컬러)

기능에 따른 색상:

```swift
// Separator (구분선)
Color(.separator)               // 불투명 구분선
Color(.opaqueSeparator)        // 투명하지 않은 구분선

// Link
Color(.link)                   // 링크 텍스트

// Placeholder
Color(.placeholderText)        // 입력 필드 플레이스홀더
```

---

## 커스텀 컬러 (Custom Colors)

시스템 컬러로 충분하지 않을 때만 사용:

### Asset Catalog 활용 (권장)

```
Assets.xcassets/
└── Colors/
    ├── BrandPrimary.colorset
    │   ├── Contents.json
    │   └── (다크/라이트 모드 별도 정의)
    └── BrandSecondary.colorset
```

```swift
// Asset에서 색상 로드
Color("BrandPrimary")  // 다크 모드 자동 대응
```

### 코드로 정의

```swift
extension Color {
    static let brandPrimary = Color(
        light: Color(red: 0.2, green: 0.4, blue: 0.8),
        dark: Color(red: 0.4, green: 0.6, blue: 1.0)
    )
}

// Helper
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark: return UIColor(dark)
            default: return UIColor(light)
            }
        })
    }
}
```

---

## 색상 사용 가이드

### 텍스트 색상

| 용도 | SwiftUI | 예시 |
|------|---------|------|
| 주요 텍스트 | `Color.primary` | 제목, 본문 |
| 보조 텍스트 | `Color.secondary` | 설명, 메타데이터 |
| 3차 텍스트 | `Color(.tertiaryLabel)` | 비활성 항목 |
| 플레이스홀더 | `Color(.placeholderText)` | 입력 필드 힌트 |

### 배경 색상

| 용도 | SwiftUI | 예시 |
|------|---------|------|
| 화면 배경 | `Color(.systemBackground)` | 전체 뷰 배경 |
| 카드 배경 | `Color(.secondarySystemBackground)` | 리스트 내 카드 |
| 카드 내부 | `Color(.tertiarySystemBackground)` | 중첩된 섹션 |

### 액센트 컬러

앱 전체의 주요 색상 (버튼, 링크, 강조):

```swift
// 프로젝트 설정에서 Accent Color 정의
// 또는 코드로:
.accentColor(.blue)
```

---

## 다크 모드 지원

### 자동 대응

시스템 컬러 사용 시 자동으로 다크 모드 적용:

```swift
VStack {
    Text("제목")
        .foregroundColor(.primary)  // 라이트: 검정, 다크: 흰색
    Text("설명")
        .foregroundColor(.secondary)  // 자동 조정
}
.background(Color(.systemBackground))  // 자동 조정
```

### 수동 테스트

```swift
// Preview에서 다크 모드 테스트
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .preferredColorScheme(.light)

        MyView()
            .preferredColorScheme(.dark)
    }
}
```

---

## 접근성 고려사항

### 대비 검사

- **WCAG AA**: 텍스트 대비비 4.5:1 이상
- **WCAG AAA**: 텍스트 대비비 7:1 이상

### Increase Contrast 모드

```swift
@Environment(\.colorSchemeContrast) var contrast

var textColor: Color {
    contrast == .increased ? .black : .primary
}
```

---

## 금지 사항 (Avoid)

❌ **고정된 컬러**: `.white`, `.black` 직접 사용 (다크 모드 미대응)
```swift
// 나쁜 예
Text("제목").foregroundColor(.black)  // 다크 모드에서 안 보임

// 좋은 예
Text("제목").foregroundColor(.primary)  // 자동 적응
```

❌ **RGB 하드코딩**: 다크 모드 고려 없이 RGB 값 사용
```swift
// 나쁜 예
Color(red: 1, green: 1, blue: 1)  // 항상 흰색

// 좋은 예
Color(.systemBackground)  // 모드에 따라 변경
```

❌ **너무 많은 커스텀 컬러**: 시스템 컬러로 충분한 경우

❌ **낮은 대비**: 회색 배경에 밝은 회색 텍스트

---

## 올바른 사용 예시

### ✅ 버튼

```swift
// Primary 버튼
Button("확인") { }
    .buttonStyle(.borderedProminent)  // 시스템 액센트 컬러

// Secondary 버튼
Button("취소") { }
    .buttonStyle(.bordered)
```

### ✅ 카드

```swift
VStack {
    Text("제목").foregroundColor(.primary)
    Text("설명").foregroundColor(.secondary)
}
.padding()
.background(Color(.secondarySystemBackground))
.cornerRadius(10)
```

### ✅ 리스트

```swift
List {
    ForEach(items) { item in
        VStack(alignment: .leading) {
            Text(item.title).foregroundColor(.primary)
            Text(item.subtitle).foregroundColor(.secondary)
        }
    }
}
.listStyle(.insetGrouped)  // 자동 배경 색상
```

---

## 참고 자료

- [HIG - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [UIColor Documentation](https://developer.apple.com/documentation/uikit/uicolor)
- [SwiftUI Color](https://developer.apple.com/documentation/swiftui/color)

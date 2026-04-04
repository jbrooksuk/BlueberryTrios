# iOS 디자인 핵심 원칙 (iOS Design Principles)

## 철학 (Philosophy)

Apple Human Interface Guidelines(HIG)는 **명료성(Clarity)**, **존중(Deference)**, **깊이(Depth)** 세 가지 핵심 원칙을 중심으로 합니다.

## HIG 핵심 원칙

### 1. 명료성 (Clarity)
**정의**: 콘텐츠와 기능이 명확하게 전달되어야 함

**적용 방법**:
- 읽기 쉬운 텍스트 (Dynamic Type 지원)
- 명확한 아이콘과 그래픽
- 적절한 간격과 여백
- 기능을 명확히 나타내는 UI 요소

**예시**:
```swift
// ✅ 명확한 버튼 레이블
Button("사진 추가") { }

// ❌ 모호한 레이블
Button("추가") { }
```

---

### 2. 존중 (Deference)
**정의**: UI가 콘텐츠를 방해하지 않고 돕는 역할

**적용 방법**:
- 미니멀한 UI 요소
- 콘텐츠가 전체 화면 활용
- 반투명 배경, 블러 효과로 맥락 유지
- 제스처 기반 상호작용

**예시**:
```swift
// ✅ 콘텐츠 우선
ZStack {
    Image("photo")
        .resizable()
        .aspectRatio(contentMode: .fill)

    // 반투명 오버레이로 콘텐츠 존중
    VStack {
        Spacer()
        Text("제목")
            .background(.ultraThinMaterial)
    }
}
```

---

### 3. 깊이 (Depth)
**정의**: 계층과 애니메이션을 통해 이해와 즐거움 제공

**적용 방법**:
- 시각적 계층 구조 (foreground, midground, background)
- 부드러운 애니메이션과 전환
- 실감나는 피드백 (Haptic Feedback)
- 모션으로 관계 전달

**예시**:
```swift
// ✅ 깊이를 나타내는 애니메이션
Button("펼치기") {
    withAnimation(.spring(response: 0.3)) {
        isExpanded.toggle()
    }
}
```

---

## Flexible 확장 원칙

HIG를 기반으로 현대적 미니멀 디자인 추가:

### 4. 간결함 (Simplicity)
- 불필요한 요소 제거
- 핵심 기능에 집중
- 명확한 정보 계층

### 5. 일관성 (Consistency)
- 플랫폼 표준 컴포넌트 우선 사용
- 시스템 컬러, 시스템 폰트 활용
- 네이티브 인터랙션 패턴 준수

### 6. 접근성 우선 (Accessibility-First)
- Dynamic Type 지원 (모든 텍스트)
- VoiceOver 최적화
- 색상 대비 WCAG AA 준수
- 다크 모드 지원

---

## 플랫폼 특성

### SwiftUI 권장 사항
- Declarative UI로 코드 간결성 극대화
- `.padding()`, `.frame()` 등 Modifier 체인 활용
- `@State`, `@Binding` 등 상태 관리 명확히
- Preview로 실시간 디자인 검증

### UIKit 보조 사용
- SwiftUI로 구현 어려운 복잡한 애니메이션
- 레거시 코드 통합
- UIHostingController로 SwiftUI 임베딩

---

## 디자인 체크리스트

모든 iOS UI는 다음 기준을 충족해야 함:

- ✅ **명료성**: 사용자가 기능을 즉시 이해할 수 있는가?
- ✅ **존중**: UI가 콘텐츠를 돋보이게 하는가?
- ✅ **깊이**: 계층과 애니메이션이 이해를 돕는가?
- ✅ **간결함**: 불필요한 요소가 제거되었는가?
- ✅ **일관성**: 플랫폼 표준을 따르는가?
- ✅ **접근성**: 모든 사용자가 사용 가능한가?

---

## 참고 자료

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

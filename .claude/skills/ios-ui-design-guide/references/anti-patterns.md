# iOS 디자인 안티패턴 (iOS Design Anti-Patterns)

피해야 할 iOS 디자인 실수와 대안

---

## Dynamic Type 관련

### ❌ 고정 크기 텍스트

**문제**: Dynamic Type 미지원

```swift
// 나쁜 예
Text("제목").font(.system(size: 24))
```

**대안**:
```swift
// 좋은 예
Text("제목").font(.title2)

// 또는 커스텀 크기에도 relativeTo 사용
Text("커스텀").font(.system(size: 24, relativeTo: .title2))
```

---

### ❌ 너무 작은 터치 영역

**문제**: 44x44pt 미만의 터치 타겟

```swift
// 나쁜 예
Button(action: { }) {
    Image(systemName: "star")
        .frame(width: 20, height: 20)  // 너무 작음
}
```

**대안**:
```swift
// 좋은 예
Button(action: { }) {
    Image(systemName: "star")
        .font(.title3)  // 적절한 크기
        .frame(minWidth: 44, minHeight: 44)  // 최소 터치 영역
}
```

---

## 색상 관련

### ❌ 다크 모드 미지원

**문제**: 고정된 색상 사용

```swift
// 나쁜 예
Text("제목")
    .foregroundColor(.black)  // 다크 모드에서 안 보임
    .background(Color.white)
```

**대안**:
```swift
// 좋은 예
Text("제목")
    .foregroundColor(.primary)
    .background(Color(.systemBackground))
```

---

### ❌ 커스텀 컬러 남용

**문제**: 시스템 컬러 무시

```swift
// 나쁜 예
let myGray = Color(red: 0.5, green: 0.5, blue: 0.5)
Text("텍스트").foregroundColor(myGray)
```

**대안**:
```swift
// 좋은 예
Text("텍스트").foregroundColor(.secondary)  // 자동 다크 모드 대응
```

---

### ❌ 낮은 대비

**문제**: 읽기 어려운 색상 조합

```swift
// 나쁜 예
Text("텍스트")
    .foregroundColor(.gray)
    .background(Color(.systemGray5))  // 대비 낮음
```

**대안**:
```swift
// 좋은 예
Text("텍스트")
    .foregroundColor(.primary)
    .background(Color(.secondarySystemBackground))
```

---

## 레이아웃 관련

### ❌ Safe Area 무시

**문제**: 노치/홈 인디케이터에 콘텐츠 가려짐

```swift
// 나쁜 예
VStack {
    Text("제목")
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(Color.blue)
.ignoresSafeArea()  // 텍스트가 노치에 가려질 수 있음
```

**대안**:
```swift
// 좋은 예
ZStack {
    Color.blue.ignoresSafeArea()  // 배경만 확장

    VStack {
        Text("제목")  // 콘텐츠는 Safe Area 유지
    }
    .padding()
}
```

---

### ❌ 고정된 레이아웃

**문제**: 다양한 화면 크기 미대응

```swift
// 나쁜 예
VStack {
    Text("제목")
}
.frame(width: 375, height: 812)  // iPhone X 고정 크기
```

**대안**:
```swift
// 좋은 예
GeometryReader { geometry in
    VStack {
        Text("제목")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

// 또는 더 간단하게
VStack {
    Text("제목")
}
.frame(maxWidth: .infinity)
```

---

### ❌ 임의의 간격 값

**문제**: 8pt 그리드 미준수

```swift
// 나쁜 예
VStack(spacing: 13) {  // 임의의 값
    Text("A")
    Text("B")
}
.padding(27)  // 임의의 값
```

**대안**:
```swift
// 좋은 예
VStack(spacing: 12) {  // 8의 배수
    Text("A")
    Text("B")
}
.padding(24)  // 8의 배수
```

---

## 네비게이션 관련

### ❌ 여러 모달 중첩

**문제**: 사용자 혼란

```swift
// 나쁜 예
.sheet(isPresented: $showFirst) {
    FirstView()
        .sheet(isPresented: $showSecond) {
            SecondView()
                .sheet(isPresented: $showThird) {
                    ThirdView()  // 너무 많은 중첩
                }
        }
}
```

**대안**:
```swift
// 좋은 예
// NavigationStack 또는 단일 모달 사용
NavigationStack {
    FirstView()
        .navigationDestination(for: Screen.self) { screen in
            // 네비게이션으로 화면 전환
        }
}
```

---

### ❌ 불명확한 뒤로 가기

**문제**: 커스텀 뒤로 가기 버튼

```swift
// 나쁜 예
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("뒤로") {
            // 커스텀 액션 - 표준 제스처 작동 안 함
        }
    }
}
```

**대안**:
```swift
// 좋은 예
// 기본 뒤로 버튼 사용 (스와이프 제스처 지원)
// 정말 필요한 경우에만:
@Environment(\.dismiss) var dismiss

.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button {
            dismiss()  // 시스템 dismiss 사용
        } label: {
            HStack {
                Image(systemName: "chevron.left")
                Text("뒤로")
            }
        }
    }
}
```

---

## 버튼 관련

### ❌ 불명확한 버튼 레이블

**문제**: 모호한 텍스트

```swift
// 나쁜 예
Button("확인") { deleteAccount() }  // 위험한 작업인데 모호함
```

**대안**:
```swift
// 좋은 예
Button("계정 삭제", role: .destructive) {
    deleteAccount()
}
```

---

### ❌ 여러 Primary 버튼

**문제**: 주요 액션이 명확하지 않음

```swift
// 나쁜 예
HStack {
    Button("저장") { }
        .buttonStyle(.borderedProminent)
    Button("공유") { }
        .buttonStyle(.borderedProminent)  // 둘 다 Primary
}
```

**대안**:
```swift
// 좋은 예
HStack {
    Button("취소") { }
        .buttonStyle(.bordered)  // Secondary

    Button("저장") { }
        .buttonStyle(.borderedProminent)  // Primary는 하나만
}
```

---

## 리스트 관련

### ❌ 리스트 항목이 너무 복잡

**문제**: 한 항목에 너무 많은 정보

```swift
// 나쁜 예
List {
    ForEach(items) { item in
        VStack {
            Text(item.title)
            Text(item.description)
            Text(item.date)
            Text(item.author)
            Text(item.category)
            // 너무 많은 정보
        }
    }
}
```

**대안**:
```swift
// 좋은 예
List {
    ForEach(items) { item in
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        // 자세한 정보는 상세 화면에
    }
}
```

---

### ❌ 커스텀 리스트 스타일 남용

**문제**: iOS 표준과 다른 스타일

```swift
// 나쁜 예
List {
    ForEach(items) { item in
        Text(item.name)
            .padding()
            .background(Color.gray)  // 비표준 스타일
            .cornerRadius(20)
    }
}
.listStyle(.plain)
.background(Color.purple)  // 비표준 배경
```

**대안**:
```swift
// 좋은 예
List {
    ForEach(items) { item in
        Text(item.name)  // 시스템 스타일 사용
    }
}
.listStyle(.insetGrouped)  // iOS 표준 스타일
```

---

## 애니메이션 관련

### ❌ 과도한 애니메이션

**문제**: 산만하고 느린 UI

```swift
// 나쁜 예
.animation(.spring(duration: 2.0), value: isExpanded)  // 너무 느림
```

**대안**:
```swift
// 좋은 예
.animation(.spring(response: 0.3), value: isExpanded)  // 빠르고 자연스러움
```

---

### ❌ 애니메이션 없음

**문제**: 상태 변화가 갑작스러움

```swift
// 나쁜 예
Button("펼치기") {
    isExpanded.toggle()  // 애니메이션 없이 즉시 변경
}
```

**대안**:
```swift
// 좋은 예
Button("펼치기") {
    withAnimation(.spring(response: 0.3)) {
        isExpanded.toggle()
    }
}
```

---

## 폼 관련

### ❌ 라벨 없는 입력 필드

**문제**: 접근성 및 사용성 저하

```swift
// 나쁜 예
TextField("", text: $email)  // 라벨 없음
```

**대안**:
```swift
// 좋은 예
VStack(alignment: .leading) {
    Text("이메일")
        .font(.caption)
        .foregroundColor(.secondary)
    TextField("example@email.com", text: $email)
}

// 또는 Form 사용
Form {
    TextField("이메일", text: $email)  // Form이 라벨 자동 처리
}
```

---

### ❌ 에러 피드백 부재

**문제**: 사용자가 문제를 모름

```swift
// 나쁜 예
TextField("이메일", text: $email)
// 유효성 검사 없음
```

**대안**:
```swift
// 좋은 예
VStack(alignment: .leading) {
    TextField("이메일", text: $email)
        .textFieldStyle(.roundedBorder)
        .border(isValid ? Color.clear : Color.red)

    if !isValid {
        Text("유효한 이메일을 입력하세요")
            .font(.caption)
            .foregroundColor(.red)
    }
}
```

---

## 이미지 관련

### ❌ 고정 이미지 크기

**문제**: 다양한 화면 크기 미대응

```swift
// 나쁜 예
Image("photo")
    .frame(width: 375, height: 200)  // 고정 크기
```

**대안**:
```swift
// 좋은 예
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(height: 200)  // 높이만 고정, 너비는 유동적
    .clipped()
```

---

### ❌ SF Symbols 색상 오용

**문제**: 멀티컬러 아이콘에 커스텀 색상

```swift
// 나쁜 예
Image(systemName: "person.crop.circle.fill.badge.checkmark")
    .foregroundColor(.red)  // 멀티컬러 무시
```

**대안**:
```swift
// 좋은 예
Image(systemName: "person.crop.circle.fill.badge.checkmark")
    .symbolRenderingMode(.multicolor)  // 원래 색상 유지

// 또는 단색 렌더링
Image(systemName: "person.crop.circle.fill")
    .foregroundColor(.red)  // 단색 아이콘에만
```

---

## 일반 원칙

1. **시스템 표준 우선**: SwiftUI 기본 컴포넌트와 스타일 사용
2. **접근성 필수**: Dynamic Type, VoiceOver 항상 고려
3. **플랫폼 일관성**: iOS HIG 준수
4. **테스트**: 다양한 기기, 다크 모드, Dynamic Type에서 테스트
5. **피드백**: 상태 변화 시 애니메이션과 피드백 제공

---

## 참고 자료

- [HIG - Best Practices](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

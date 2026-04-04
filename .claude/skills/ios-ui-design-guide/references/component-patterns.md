# iOS 컴포넌트 디자인 패턴 (iOS Component Design Patterns)

SwiftUI 중심의 iOS 컴포넌트 모범 사례

---

## 버튼 (Button)

### 기본 스타일

```swift
// Bordered Prominent (Primary)
Button("확인") { }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)

// Bordered (Secondary)
Button("취소") { }
    .buttonStyle(.bordered)

// Borderless (Tertiary)
Button("건너뛰기") { }
    .buttonStyle(.borderless)

// Plain (Minimal)
Button("더 보기") { }
    .buttonStyle(.plain)
```

### 커스텀 버튼

```swift
Button(action: { }) {
    Text("커스텀 버튼")
        .font(.body.weight(.semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue)
        .cornerRadius(12)
}
.padding(.horizontal, 20)
```

### 버튼 크기

```swift
Button("작은 버튼") { }
    .buttonStyle(.borderedProminent)
    .controlSize(.small)  // small, regular, large

Button("큰 버튼") { }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
```

### 비활성 상태

```swift
Button("저장") { }
    .disabled(isSaveDisabled)
    .opacity(isSaveDisabled ? 0.5 : 1.0)
```

### 금지 사항
❌ 너무 작은 버튼 (최소 44x44pt 터치 영역)
❌ 불명확한 레이블 ("확인" 대신 "변경사항 저장")
❌ 여러 Primary 버튼 (하나의 주요 액션만)

---

## 리스트 (List)

### 기본 리스트

```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
}
.listStyle(.insetGrouped)  // 권장 스타일
```

### 리스트 스타일

```swift
// Inset Grouped (iOS 표준)
.listStyle(.insetGrouped)

// Plain
.listStyle(.plain)

// Grouped
.listStyle(.grouped)

// Sidebar (iPad)
.listStyle(.sidebar)
```

### 리스트 아이템 디자인

```swift
List {
    ForEach(items) { item in
        HStack(spacing: 12) {
            // 아이콘 (선택적)
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            // 콘텐츠
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Accessory (선택적)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
    }
}
```

### 스와이프 액션

```swift
List {
    ForEach(items) { item in
        Text(item.name)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteItem(item)
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
    }
}
```

### Section 사용

```swift
List {
    Section("일반") {
        NavigationLink("프로필") { ProfileView() }
        NavigationLink("설정") { SettingsView() }
    }

    Section("고급") {
        NavigationLink("개발자 옵션") { DeveloperView() }
    }
}
```

---

## 폼 (Form)

### 기본 폼

```swift
Form {
    Section {
        TextField("이름", text: $name)
        TextField("이메일", text: $email)
    }

    Section {
        Toggle("알림 받기", isOn: $isNotificationsEnabled)
        Picker("언어", selection: $language) {
            Text("한국어").tag("ko")
            Text("English").tag("en")
        }
    }

    Section {
        Button("저장") {
            saveSettings()
        }
    }
}
```

### 입력 필드

```swift
// 텍스트 입력
TextField("플레이스홀더", text: $text)
    .textInputAutocapitalization(.never)
    .keyboardType(.emailAddress)

// 보안 입력
SecureField("비밀번호", text: $password)

// 여러 줄 텍스트
TextEditor(text: $notes)
    .frame(height: 100)
```

### Picker

```swift
// Menu Picker (기본)
Picker("옵션", selection: $selectedOption) {
    ForEach(options) { option in
        Text(option.name).tag(option.id)
    }
}

// Segmented Picker
Picker("유형", selection: $type) {
    Text("개인").tag(0)
    Text("비즈니스").tag(1)
}
.pickerStyle(.segmented)
```

### Toggle & Stepper

```swift
// Toggle
Toggle("다크 모드", isOn: $isDarkMode)

// Stepper
Stepper("수량: \(quantity)", value: $quantity, in: 1...10)
```

---

## 네비게이션 (Navigation)

### NavigationStack (iOS 16+)

```swift
NavigationStack {
    List {
        NavigationLink("상세보기") {
            DetailView()
        }
    }
    .navigationTitle("제목")
    .navigationBarTitleDisplayMode(.large)
}
```

### Toolbar

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("취소") { }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
        Button("완료") { }
    }

    ToolbarItem(placement: .bottomBar) {
        Button("추가") { }
    }
}
```

### Tab View

```swift
TabView {
    HomeView()
        .tabItem {
            Label("홈", systemImage: "house")
        }

    SearchView()
        .tabItem {
            Label("검색", systemImage: "magnifyingglass")
        }

    ProfileView()
        .tabItem {
            Label("프로필", systemImage: "person")
        }
}
```

---

## 카드 (Card)

### 기본 카드

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("제목")
        .font(.headline)

    Text("카드 내용을 여기에 작성합니다.")
        .font(.body)
        .foregroundColor(.secondary)

    HStack {
        Button("취소") { }
            .buttonStyle(.bordered)

        Spacer()

        Button("확인") { }
            .buttonStyle(.borderedProminent)
    }
}
.padding(20)
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
.padding(.horizontal, 16)
```

### 이미지 카드

```swift
VStack(spacing: 0) {
    AsyncImage(url: URL(string: imageURL)) { image in
        image.resizable()
            .aspectRatio(contentMode: .fill)
    } placeholder: {
        ProgressView()
    }
    .frame(height: 200)
    .clipped()

    VStack(alignment: .leading, spacing: 8) {
        Text("제목")
            .font(.headline)
        Text("설명")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
}
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
```

---

## 모달 & 시트 (Modal & Sheet)

### Sheet (Modal)

```swift
Button("설정 열기") {
    showSettings = true
}
.sheet(isPresented: $showSettings) {
    SettingsView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

### Full Screen Cover

```swift
.fullScreenCover(isPresented: $showOnboarding) {
    OnboardingView()
}
```

### Alert

```swift
.alert("경고", isPresented: $showAlert) {
    Button("취소", role: .cancel) { }
    Button("삭제", role: .destructive) {
        deleteItem()
    }
} message: {
    Text("이 작업은 되돌릴 수 없습니다.")
}
```

### Confirmation Dialog

```swift
.confirmationDialog("옵션 선택", isPresented: $showDialog) {
    Button("사진 촬영") { }
    Button("사진 앨범") { }
    Button("취소", role: .cancel) { }
}
```

---

## 검색 (Search)

### Searchable

```swift
List {
    ForEach(filteredItems) { item in
        Text(item.name)
    }
}
.searchable(text: $searchText, prompt: "검색")
```

### Search with Suggestions

```swift
.searchable(text: $searchText) {
    ForEach(suggestions) { suggestion in
        Text(suggestion.name)
            .searchCompletion(suggestion.name)
    }
}
```

---

## 이미지 (Image)

### SF Symbols

```swift
// 기본 사용
Image(systemName: "star.fill")
    .foregroundColor(.yellow)

// 크기 조정
Image(systemName: "heart.fill")
    .font(.system(size: 32))

// 멀티컬러 (일부 아이콘 지원)
Image(systemName: "person.crop.circle.fill.badge.checkmark")
    .symbolRenderingMode(.multicolor)
```

### 커스텀 이미지

```swift
Image("logo")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 100, height: 100)
    .clipShape(Circle())
```

### AsyncImage

```swift
AsyncImage(url: URL(string: imageURL)) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
.frame(width: 200, height: 200)
.clipped()
```

---

## 프로그레스 인디케이터 (Progress Indicator)

### Activity Indicator

```swift
ProgressView()
    .progressViewStyle(.circular)

// 라벨 포함
ProgressView("로딩 중...")
```

### 진행률 바

```swift
ProgressView(value: progress, total: 100)
    .progressViewStyle(.linear)

// 커스텀 라벨
ProgressView(value: progress, total: 100) {
    Text("업로드 중")
} currentValueLabel: {
    Text("\(Int(progress))%")
}
```

---

## 배지 (Badge)

### TabView Badge

```swift
TabView {
    HomeView()
        .tabItem {
            Label("홈", systemImage: "house")
        }
        .badge(notificationCount)
}
```

### 커스텀 배지

```swift
Text("새로운")
    .font(.caption.weight(.semibold))
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.red)
    .cornerRadius(12)
```

---

## 일반 원칙

1. **시스템 컴포넌트 우선**: SwiftUI 기본 제공 컴포넌트 사용
2. **HIG 준수**: Apple 디자인 가이드라인 따르기
3. **접근성**: Dynamic Type, VoiceOver 지원
4. **일관성**: 플랫폼 표준 인터랙션 패턴
5. **반응형**: Safe Area, Size Class 고려

---

## 참고 자료

- [SwiftUI Views](https://developer.apple.com/documentation/swiftui/views)
- [HIG - Components](https://developer.apple.com/design/human-interface-guidelines/components)

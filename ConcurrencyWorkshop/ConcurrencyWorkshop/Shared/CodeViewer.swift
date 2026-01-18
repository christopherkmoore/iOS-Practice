import SwiftUI

/// Data model for an exercise/challenge
struct ExerciseItem: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let hint: String?

    init(title: String, prompt: String, hint: String? = nil) {
        self.title = title
        self.prompt = prompt
        self.hint = hint
    }
}

/// A scrollable, read-only code viewer with monospace font
/// Supports full-screen landscape mode for easier code reading
/// Optionally shows exercise challenges when available
struct CodeViewer: View {
    let title: String
    let code: String
    var exercises: [ExerciseItem] = []

    @State private var isLandscape = false
    @State private var showFullScreen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Exercises section (only shown when exercises exist)
                if !exercises.isEmpty {
                    ExercisesSection(exercises: exercises)
                        .padding(.horizontal)
                }

                Text(title)
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: true) {
                    SyntaxHighlightedCode(code: code, fontSize: 12)
                        .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let orientation = UIDevice.current.orientation
            if orientation.isLandscape {
                isLandscape = true
                showFullScreen = true
            } else if orientation.isPortrait {
                isLandscape = false
                showFullScreen = false
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenCodeView(title: title, code: code, isPresented: $showFullScreen)
        }
    }
}

// MARK: - Full Screen Code View

private struct FullScreenCodeView: View {
    let title: String
    let code: String
    @Binding var isPresented: Bool

    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            // Code content
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                SyntaxHighlightedCode(code: code, fontSize: 14)
                    .padding()
                    .padding(.top, 60) // Space for header
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
            }
            .coordinateSpace(name: "scroll")
            .background(Color(.systemGray6))
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let scrollingDown = offset < lastScrollOffset
                if abs(offset - lastScrollOffset) > 5 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHeader = !scrollingDown || offset > -10
                    }
                    lastScrollOffset = offset
                }
            }

            // Header overlay
            if showHeader {
                VStack(spacing: 0) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)

                    Divider()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let orientation = UIDevice.current.orientation
            if orientation.isPortrait {
                isPresented = false
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Exercises Section

private struct ExercisesSection: View {
    let exercises: [ExerciseItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard")
                    .foregroundColor(.orange)

                Text("Exercises")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            // Exercise cards
            ForEach(exercises) { exercise in
                ExerciseCard(exercise: exercise)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

private struct ExerciseCard: View {
    let exercise: ExerciseItem
    @State private var showHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(exercise.prompt)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let hint = exercise.hint {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHint.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                            .font(.caption)
                        Text(showHint ? "Hide Hint" : "Show Hint")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)

                if showHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Syntax Highlighted Code

private struct SyntaxHighlightedCode: View {
    let code: String
    let fontSize: CGFloat

    var body: some View {
        Text(highlightedCode)
            .font(.system(size: fontSize, design: .monospaced))
            .textSelection(.enabled)
    }

    private var highlightedCode: AttributedString {
        var attributed = AttributedString(code)

        // Comments first - gray (so they don't get overwritten)
        highlightPattern("//.*$", in: &attributed, color: .gray, options: .anchorsMatchLines)

        // Keywords - purple
        let keywords = [
            // Declarations
            "import", "struct", "class", "enum", "protocol", "extension", "func",
            "actor", "macro", "typealias", "associatedtype",
            // Variable declarations
            "var", "let", "inout",
            // Control flow
            "if", "else", "guard", "switch", "case", "default",
            "for", "while", "repeat", "return", "throw", "throws", "rethrows",
            "try", "do", "catch", "defer", "break", "continue", "fallthrough",
            // Async
            "await", "async", "nonisolated", "isolated",
            // Access control
            "private", "public", "internal", "fileprivate", "open",
            // Modifiers
            "static", "final", "override", "mutating", "nonmutating", "lazy",
            "weak", "unowned", "required", "convenience", "dynamic",
            // Other keywords
            "init", "deinit", "self", "Self", "super", "nil", "true", "false",
            "in", "is", "as", "where", "some", "any", "get", "set", "willSet", "didSet",
            "#available", "#if", "#else", "#endif", "#selector", "#keyPath"
        ]

        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", in: &attributed, color: .purple)
        }

        // Property wrappers & attributes - purple
        let attributes = [
            "@State", "@Binding", "@Published", "@ObservedObject", "@StateObject",
            "@EnvironmentObject", "@Environment", "@AppStorage", "@SceneStorage",
            "@FocusState", "@FocusedValue", "@GestureState",
            "@MainActor", "@Sendable", "@escaping", "@autoclosure", "@discardableResult",
            "@available", "@objc", "@IBAction", "@IBOutlet", "@NSManaged",
            "@ViewBuilder", "@resultBuilder", "@propertyWrapper", "@dynamicMemberLookup",
            "@frozen", "@inlinable", "@usableFromInline", "@preconcurrency"
        ]

        for attr in attributes {
            highlightPattern(attr.replacingOccurrences(of: "@", with: "\\@"), in: &attributed, color: .purple)
        }

        // SwiftUI Views - teal
        let swiftUIViews = [
            // Layout
            "VStack", "HStack", "ZStack", "LazyVStack", "LazyHStack",
            "LazyVGrid", "LazyHGrid", "Grid", "GridRow",
            "Spacer", "Divider", "GeometryReader", "ScrollView", "ScrollViewReader",
            // Controls
            "Text", "Label", "TextField", "SecureField", "TextEditor",
            "Button", "Link", "Menu", "Toggle", "Picker", "DatePicker", "ColorPicker",
            "Slider", "Stepper", "ProgressView", "Gauge",
            // Containers
            "List", "ForEach", "Form", "Section", "Group", "GroupBox",
            "NavigationStack", "NavigationLink", "NavigationSplitView",
            "TabView", "TabSection",
            // Presentation
            "Sheet", "Alert", "ConfirmationDialog", "Popover",
            // Images & Shapes
            "Image", "AsyncImage", "Shape", "Rectangle", "RoundedRectangle",
            "Circle", "Ellipse", "Capsule", "Path",
            // Other views
            "Color", "Gradient", "LinearGradient", "RadialGradient", "AngularGradient",
            "EmptyView", "AnyView", "EquatableView",
            "TimelineView", "Canvas", "ShareLink", "PasteButton",
            "ContentView", "App", "Scene", "WindowGroup", "DocumentGroup"
        ]

        for view in swiftUIViews {
            highlightPattern("\\b\(view)\\b", in: &attributed, color: .teal)
        }

        // Foundation & Swift types - teal
        let types = [
            // Primitives
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "String", "Character", "Bool", "Double", "Float", "CGFloat",
            // Collections
            "Array", "Dictionary", "Set", "Optional", "Result",
            // Foundation
            "URL", "Data", "Date", "UUID", "TimeInterval", "DateFormatter",
            "NSObject", "NSError", "Notification", "Timer", "RunLoop",
            "DispatchQueue", "DispatchGroup", "DispatchSemaphore",
            "URLSession", "URLRequest", "URLResponse", "HTTPURLResponse",
            // Concurrency
            "Task", "TaskGroup", "AsyncSequence", "AsyncIterator", "AsyncIteratorProtocol",
            "AsyncStream", "AsyncThrowingStream", "CheckedContinuation",
            // Combine
            "Publisher", "Subscriber", "AnyPublisher", "AnyCancellable",
            "PassthroughSubject", "CurrentValueSubject", "Future", "Just", "Empty",
            // Protocols
            "View", "App", "Scene", "ObservableObject", "Observable",
            "Identifiable", "Sendable", "Hashable", "Equatable", "Comparable", "Codable",
            "Encodable", "Decodable", "CustomStringConvertible", "Error",
            // Special
            "Any", "AnyObject", "Void", "Never", "Self", "Type"
        ]

        for type in types {
            highlightPattern("\\b\(type)\\b", in: &attributed, color: .teal)
        }

        // Method calls and properties (dot notation) - orange
        let methods = [
            // View modifiers
            "font", "foregroundColor", "foregroundStyle", "background", "overlay",
            "padding", "frame", "offset", "position", "edgesIgnoringSafeArea",
            "cornerRadius", "clipShape", "mask", "shadow", "blur", "opacity",
            "rotationEffect", "scaleEffect", "rotation3DEffect",
            "border", "stroke", "fill", "strokeBorder",
            // Layout
            "spacing", "alignment", "lineSpacing", "multilineTextAlignment",
            "fixedSize", "layoutPriority", "alignmentGuide",
            // Size
            "width", "height", "minWidth", "maxWidth", "minHeight", "maxHeight", "infinity",
            // Text
            "bold", "italic", "underline", "strikethrough", "fontWeight", "fontDesign",
            "monospaced", "monospacedDigit", "kerning", "tracking", "baselineOffset",
            "textCase", "textSelection", "lineLimit", "truncationMode", "allowsTightening",
            // Interaction
            "onTapGesture", "onLongPressGesture", "gesture", "highPriorityGesture",
            "simultaneousGesture", "onDrag", "onDrop", "draggable", "dropDestination",
            "onAppear", "onDisappear", "task", "onChange", "onReceive", "onSubmit",
            "disabled", "allowsHitTesting", "contentShape",
            // Navigation
            "navigationTitle", "navigationBarTitleDisplayMode", "toolbar", "toolbarBackground",
            "navigationDestination", "sheet", "fullScreenCover", "popover", "alert",
            "confirmationDialog", "presentationDetents", "presentationDragIndicator",
            // Lists
            "listStyle", "listRowBackground", "listRowInsets", "listRowSeparator",
            "swipeActions", "refreshable", "searchable",
            // Buttons & Controls
            "buttonStyle", "toggleStyle", "pickerStyle", "datePickerStyle",
            "labelStyle", "menuStyle", "textFieldStyle", "progressViewStyle",
            // Styles
            "bordered", "borderedProminent", "borderless", "plain", "automatic",
            "insetGrouped", "grouped", "inset", "sidebar",
            "circular", "linear", "segmented", "wheel", "menu", "palette",
            "roundedBorder", "squareBorder",
            // Animation
            "animation", "withAnimation", "transition", "matchedGeometryEffect",
            // Environment
            "environment", "environmentObject", "preferredColorScheme",
            // Accessibility
            "accessibilityLabel", "accessibilityHint", "accessibilityValue",
            "accessibilityIdentifier", "accessibilityHidden",
            // Other modifiers
            "tag", "id", "zIndex", "drawingGroup", "compositingGroup",
            "clipped", "ignoresSafeArea", "safeAreaInset", "containerRelativeFrame",
            "scrollContentBackground", "scrollIndicators", "scrollTargetLayout",
            "hidden", "labelsHidden", "tint", "accentColor",
            // Combine
            "sink", "store", "assign", "map", "flatMap", "filter", "compactMap",
            "receive", "subscribe", "eraseToAnyPublisher", "handleEvents",
            "debounce", "throttle", "delay", "timeout", "retry",
            "merge", "combineLatest", "zip", "switchToLatest", "prepend", "append",
            "removeDuplicates", "replaceError", "replaceEmpty", "collect",
            "first", "last", "prefix", "drop", "output",
            // Async
            "sleep", "checkCancellation", "yield", "finish", "cancel",
            "value", "result", "get",
            // System
            "system", "title", "headline", "subheadline", "body", "caption", "caption2",
            "callout", "footnote", "largeTitle", "title2", "title3",
            "primary", "secondary", "tertiary", "quaternary",
            "red", "blue", "green", "orange", "yellow", "purple", "pink", "teal", "cyan",
            "gray", "black", "white", "clear", "accentColor",
            // Common methods
            "append", "remove", "insert", "contains", "count", "isEmpty", "first", "last",
            "sorted", "reversed", "joined", "split", "components",
            "print", "debugPrint", "dump", "fatalError", "precondition", "assert"
        ]

        for method in methods {
            highlightPattern("\\.\(method)\\b", in: &attributed, color: .orange)
        }

        // Strings - red
        highlightPattern("\"\"\"[\\s\\S]*?\"\"\"", in: &attributed, color: .red) // Multi-line strings
        highlightPattern("\"[^\"\\n]*\"", in: &attributed, color: .red) // Single-line strings

        // Numbers - blue
        highlightPattern("\\b\\d+\\.?\\d*\\b", in: &attributed, color: .blue)

        return attributed
    }

    private func highlightPattern(
        _ pattern: String,
        in attributed: inout AttributedString,
        color: Color,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }

        let string = String(attributed.characters)
        let range = NSRange(string.startIndex..., in: string)
        let matches = regex.matches(in: string, range: range)

        for match in matches {
            guard let swiftRange = Range(match.range, in: string) else { continue }

            // Convert String.Index range to AttributedString.Index range
            let startOffset = string.distance(from: string.startIndex, to: swiftRange.lowerBound)
            let endOffset = string.distance(from: string.startIndex, to: swiftRange.upperBound)

            let attribStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attribEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)

            attributed[attribStart..<attribEnd].foregroundColor = color
        }
    }
}

#Preview("With Exercises") {
    CodeViewer(
        title: "AsyncSequenceExample.swift",
        code: """
        import SwiftUI

        struct NumberStream: AsyncSequence {
            typealias Element = Int

            let count: Int
            let delay: TimeInterval

            struct AsyncIterator: AsyncIteratorProtocol {
                var current = 0
                let count: Int
                let delay: TimeInterval

                // Returns the next value
                mutating func next() async throws -> Int? {
                    guard current < count else { return nil }
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    current += 1
                    return current
                }
            }

            func makeAsyncIterator() -> AsyncIterator {
                AsyncIterator(count: count, delay: delay)
            }
        }

        let message = "Hello, World!"
        let number = 42
        """,
        exercises: [
            ExerciseItem(
                title: "Spot the Bug",
                prompt: "The code uses try? which swallows cancellation errors. What happens when the task is cancelled?",
                hint: "Change try? to try and handle cancellation properly"
            ),
            ExerciseItem(
                title: "Modify the Code",
                prompt: "Add a delay parameter that increases with each iteration"
            )
        ]
    )
}

#Preview("Without Exercises") {
    CodeViewer(
        title: "SimpleExample.swift",
        code: """
        let greeting = "Hello, World!"
        print(greeting)
        """
    )
}

import SwiftUI
import ComposableArchitecture


struct AppState: Equatable {

    var text: String
    var addTextViewState: AddTextViewState?
}

enum AppAction {
    case showText
    case addTextView(AddTextViewAction)
}


let appReducer: Reducer<AppState, AppAction, Void> = .combine(
    addTextViewReducer.optional.pullback(
        state: \.addTextViewState,
        action: /AppAction.addTextView,
        environment: { _ in () }),

    Reducer<AppState, AppAction, Void> { state, action, _ in
        switch action {

        case .showText:
            state.addTextViewState = .init(
                title: "",
                placeholderText: nil,
                requiredText: false,
                text: state.text)
            return .none

        case .addTextView(let addTextAction):
            switch addTextAction {

            case .addText:
                return .none

            case .dismiss:
                state.addTextViewState = nil
                return .none
                
            case .textCompleted:
                state.text = state.addTextViewState?.text ?? ""
//                state.addTextViewState = nil
                return .init(value: .addTextView(.dismiss))


            }
        }
    }
)

struct ContentView: View {
    var store: Store<AppState, AppAction>


    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Text(viewStore.text)
                Button.init("add text") {
                    viewStore.send(.showText)
                }
            }.sheet(
                isPresented: .constant(viewStore.addTextViewState != nil)) {
                IfLetStore(self.store.scope(state: \.addTextViewState, action: AppAction.addTextView), then: AddTextView.init(store:))
            }
        }
    }
}




struct AddTextViewState: Equatable {

    let title: String
    let placeholderText: String?
    let requiredText: Bool

    var text: String

    var textCompleted: Bool {
        guard requiredText else { return true }
        return !text.isEmpty
    }
}


enum AddTextViewAction: Equatable {
    case addText(String)
    case textCompleted
    case dismiss
}


let addTextViewReducer = Reducer<AddTextViewState, AddTextViewAction, Void> { state, action, _ in
    switch action {

    case .dismiss:
        return .none
        
    case .addText(let text):
        if !text.isEmpty {
            state.text = text
        } else {
            state.text = ""
        }

    case .textCompleted:
        return .none
    }
    return .none
}


struct AddTextView: View {

    let store: Store<AddTextViewState, AddTextViewAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Button(
                    action: { viewStore.send(.textCompleted) },
                    label: { Text("Add") })
                    .disabled(!viewStore.textCompleted)

                Form {
                    TextField(
                        "",
                        text: viewStore.binding(
                            get: \.text,
                            send: { .addText($0) }))

                }
            }
        }
    }
}

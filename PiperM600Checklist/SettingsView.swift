import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ChecklistStore
    @State private var showResetAlert = false
    @State private var showResetAcknowledgment = false
    @AppStorage("editPasscode") private var editPasscode: String = ""
    @AppStorage("tailNumber") private var tailNumber: String = ""
    @State private var isUnlocked = false
    @State private var showUnlockPopup = false
    @State private var unlockInput = ""
    @State private var newPasscodeInput = ""
    @State private var unlockError: String?

    private var isEditingLocked: Bool {
        !isUnlocked
    }

    var body: some View {
        List {
            Section {
                lockableField {
                    TextField("Tail Number", text: $tailNumber)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
            } header: {
                Text("Aircraft")
            } footer: {
                Text("Displayed on the main menu.")
            }

            Section {
                ForEach(store.sections.indices, id: \.self) { index in
                    if isEditingLocked {
                        Button {
                            presentUnlockPrompt()
                        } label: {
                            sectionRow(for: index)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            SectionEditorView(section: binding(for: index), store: store)
                        } label: {
                            sectionRow(for: index)
                        }
                    }
                }
            } header: {
                Text("Edit Checklist")
            } footer: {
                if isEditingLocked {
                    Text("Tap any editable field to unlock editing.")
                } else {
                    Text("Editing is unlocked for this session.")
                }
            }

            Section {
                Button(role: .destructive) {
                    if isEditingLocked {
                        presentUnlockPrompt()
                    } else {
                        showResetAlert = true
                    }
                } label: {
                    Text("Reset to Default")
                }
            } footer: {
                Text("Changes are saved automatically.")
            }

        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .alert("Reset checklist?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetToDefault()
                showResetAcknowledgmentBanner()
            }
        } message: {
            Text("This will overwrite any edits you’ve made.")
        }
        .overlay {
            ZStack(alignment: .top) {
                if showResetAcknowledgment {
                    resetAcknowledgmentBanner
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showUnlockPopup {
                    unlockOverlay
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showResetAcknowledgment)
        .onAppear {
            isUnlocked = false
        }
    }

    private func sectionRow(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.sections[index].title)
                .font(.custom("Avenir Next Demi Bold", size: 16))
            Text("\(store.sections[index].items.count) items")
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)
        }
    }

    private func presentUnlockPrompt() {
        unlockInput = ""
        newPasscodeInput = ""
        unlockError = nil
        showUnlockPopup = true
    }

    private var resetAcknowledgmentBanner: some View {
        Text("Data have been reset")
            .font(.custom("Avenir Next Demi Bold", size: 13))
            .foregroundColor(AppTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private func showResetAcknowledgmentBanner() {
        showResetAcknowledgment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showResetAcknowledgment = false
        }
    }

    private func handleUnlockSubmit() {
        if editPasscode.isEmpty {
            let trimmed = newPasscodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                unlockError = "Enter a new passcode."
                return
            }
            editPasscode = trimmed
            isUnlocked = true
            showUnlockPopup = false
            unlockError = nil
            return
        }

        if unlockInput == editPasscode {
            isUnlocked = true
            showUnlockPopup = false
            unlockError = nil
        } else {
            unlockError = "Incorrect passcode."
        }
    }

    @ViewBuilder
    private func lockableField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            content()
                .disabled(isEditingLocked)
            if isEditingLocked {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        presentUnlockPrompt()
                    }
            }
        }
    }

    private var unlockOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    showUnlockPopup = false
                    unlockError = nil
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Are you sure?")
                    .font(.custom("Avenir Next Demi Bold", size: 16))
                    .foregroundColor(AppTheme.text)

                if editPasscode.isEmpty {
                    Text("No passcode is set. Enter a new passcode to unlock checklist editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("New Passcode", text: $newPasscodeInput)
                        .textContentType(.newPassword)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                } else {
                    Text("Enter passcode to unlock checklist editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("Passcode", text: $unlockInput)
                        .textContentType(.password)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                }

                if let unlockError {
                    Text(unlockError)
                        .font(.custom("Avenir Next Regular", size: 12))
                        .foregroundColor(.red)
                }

                HStack(spacing: 10) {
                    Button("Cancel") {
                        showUnlockPopup = false
                        unlockError = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.cardHighlight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)

                    Button(editPasscode.isEmpty ? "Set & Unlock" : "Unlock") {
                        handleUnlockSubmit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.bezelLight, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private func binding(for index: Int) -> Binding<ChecklistSection> {
        Binding(
            get: { store.sections[index] },
            set: { newValue in
                store.sections[index] = newValue
                store.save()
            }
        )
    }
}

struct SectionEditorView: View {
    @Binding var section: ChecklistSection
    @ObservedObject var store: ChecklistStore

    var body: some View {
        List {
            Section {
                TextField("Section Title", text: $section.title)
                    .font(.custom("Avenir Next Demi Bold", size: 16))
                    .onChange(of: section.title) { _ in store.save() }
                    .foregroundColor(AppTheme.text)
                    .listRowBackground(AppTheme.card)
            } header: {
                Text("Title")
                    .foregroundColor(AppTheme.muted)
            }

            Section {
                ForEach(section.items.indices, id: \.self) { index in
                    TextField("Item", text: bindingForItem(index))
                        .font(.custom("Avenir Next Regular", size: 15))
                        .foregroundColor(AppTheme.text)
                        .listRowBackground(AppTheme.card)
                }
                .onDelete { offsets in
                    section.items.remove(atOffsets: offsets)
                    store.save()
                }

                Button {
                    section.items.append(ChecklistItem(text: "New Item"))
                    store.save()
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .listRowBackground(AppTheme.card)
            } header: {
                Text("Items")
                    .foregroundColor(AppTheme.muted)
            } footer: {
                Text("Swipe left on an item to delete it.")
                    .foregroundColor(AppTheme.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle(section.title)
        .onDisappear { store.save() }
    }

    private func bindingForItem(_ index: Int) -> Binding<String> {
        Binding(
            get: { section.items[index].text },
            set: { newValue in
                section.items[index].text = newValue
                store.save()
            }
        )
    }
}

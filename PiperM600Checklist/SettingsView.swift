import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ChecklistStore
    @State private var showResetAlert = false
    @AppStorage("editPasscode") private var editPasscode: String = ""
    @AppStorage("tailNumber") private var tailNumber: String = ""
    @State private var isUnlocked = false
    @State private var showPasscodeSheet = false
    @State private var passcodeInput = ""
    @State private var passcodeError: String?
    @State private var newPasscode = ""
    @State private var showPOHRebuildConfirm = false
    @State private var showPOHRebuildResult = false
    @State private var pohRebuildMessage = ""

    var body: some View {
        List {
            Section {
                TextField("Tail Number (e.g., TC-EZP)", text: $tailNumber)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            } header: {
                Text("Aircraft")
            } footer: {
                Text("Displayed on the main menu.")
            }

            if editPasscode.isEmpty {
                Section {
                    SecureField("New Passcode", text: $newPasscode)
                    Button("Select Password") {
                        guard !newPasscode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        editPasscode = newPasscode
                        newPasscode = ""
                    }
                } header: {
                    Text("Set Editing Passcode")
                } footer: {
                    Text("Select password.")
                }
            } else {
                Section {
                    if isUnlocked {
                        Button("Lock Editing") {
                            isUnlocked = false
                        }
                    } else {
                        Button("Unlock Editing") {
                            passcodeInput = ""
                            passcodeError = nil
                            showPasscodeSheet = true
                        }
                    }

                    Button("Clear Passcode") {
                        editPasscode = ""
                        isUnlocked = false
                        passcodeInput = ""
                        passcodeError = nil
                    }
                } footer: {
                    Text(isUnlocked ? "Editing is unlocked for this session." : "Enter password to unlock editing.")
                }
            }

            Section {
                ForEach(store.sections.indices, id: \.self) { index in
                    NavigationLink {
                        SectionEditorView(section: binding(for: index), store: store)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.sections[index].title)
                                .font(.custom("Avenir Next Demi Bold", size: 16))
                            Text("\(store.sections[index].items.count) items")
                                .font(.custom("Avenir Next Regular", size: 12))
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                    .disabled(!isUnlocked)
                }
            } header: {
                Text("Edit Checklist")
            } footer: {
                if !isUnlocked {
                    Text("Unlock editing to modify or delete items.")
                }
            }

            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text("Reset to Default")
                }
                .disabled(!isUnlocked)
            } footer: {
                Text("Changes are saved automatically.")
            }

            Section {
                Button {
                    showPOHRebuildConfirm = true
                } label: {
                    Text("Rebuild POH Search Index")
                }
            } footer: {
                Text("Clears the cached POH index and rebuilds it next time POH is opened.")
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
            }
        } message: {
            Text("This will overwrite any edits you’ve made.")
        }
        .alert("Rebuild POH Index?", isPresented: $showPOHRebuildConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebuild", role: .destructive) {
                let success = POHIndexCache.clear()
                pohRebuildMessage = success
                    ? "POH index cleared. It will rebuild next time you open POH."
                    : "Could not clear the POH index. Please try again."
                showPOHRebuildResult = true
            }
        } message: {
            Text("This clears the cached POH index and forces a rebuild.")
        }
        .alert("POH Index", isPresented: $showPOHRebuildResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pohRebuildMessage)
        }
        .sheet(isPresented: $showPasscodeSheet) {
            PasscodePromptView(
                passcode: $passcodeInput,
                errorMessage: passcodeError
            ) {
                if passcodeInput == editPasscode {
                    isUnlocked = true
                    showPasscodeSheet = false
                } else {
                    passcodeError = "Incorrect passcode."
                }
            } onCancel: {
                showPasscodeSheet = false
            }
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

private struct PasscodePromptView: View {
    @Binding var passcode: String
    let errorMessage: String?
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Enter Passcode")
                    .font(.custom("Avenir Next Demi Bold", size: 18))
                    .foregroundColor(AppTheme.text)

                SecureField("Passcode", text: $passcode)
                    .textContentType(.password)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(.red)
                }

                Button("Unlock") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
            .padding(24)
            .navigationTitle("Editing Locked")
            .background(InstrumentBackground().ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

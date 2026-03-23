import SwiftUI
import SwiftData
import ContactsUI

struct EmergencyContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [EmergencyContact]
    
    @State private var showingContactPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("紧急联系人 (最多3个)")) {
                ForEach(contacts) { contact in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            testNotification(for: contact)
                        }) {
                            Text("测试通知")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.borderless)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteContact(contact)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            
            if contacts.count < 3 {
                Button(action: checkPermissionAndShowPicker) {
                    Label("添加联系人", systemImage: AppAssets.Symbols.addContact)
                        .foregroundColor(AppAssets.Colors.primary)
                }
            }
        }
        .navigationTitle("紧急联系人")
        .sheet(isPresented: $showingContactPicker) {
            ContactPicker(onContactSelected: saveContact)
        }
        .alert("权限请求", isPresented: $showAlert) {
            Button("去设置", action: openSettings)
            Button("取消", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func checkPermissionAndShowPicker() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    showingContactPicker = true
                } else {
                    alertMessage = "需要通讯录权限来添加紧急联系人，请前往设置开启。"
                    showAlert = true
                }
            }
        }
    }
    
    private func saveContact(_ contact: CNContact) {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        guard let phone = contact.phoneNumbers.first?.value.stringValue else { return }
        
        let newContact = EmergencyContact(name: name, phoneNumber: phone)
        modelContext.insert(newContact)
    }
    
    private func deleteContact(_ contact: EmergencyContact) {
        modelContext.delete(contact)
    }
    
    private func testNotification(for contact: EmergencyContact) {
        NotificationManager.shared.sendTestNotification(for: contact.name)
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// CNContactPicker wrapper
struct ContactPicker: UIViewControllerRepresentable {
    var onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onContactSelected(contact)
        }
    }
}

#Preview {
    EmergencyContactView()
        .modelContainer(for: EmergencyContact.self, inMemory: true)
}

import SwiftUI

/// Closes a sheet whose changes apply as they are made, so there is nothing for
/// the button to confirm. Sheets that commit a draft keep a Done button instead.
///
/// The iOS 26 branch is the one to keep: `ButtonRole.close` draws the system's
/// close control and labels it, but the SDK marks it `iOS 26.0`. Once the
/// deployment target reaches 26, delete the `else` branch and the check with it.
/// Runtime `#available` rather than a declaration `@available`, which would take
/// the fallback down with it.
struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close")
        }
    }
}

#Preview {
    NavigationStack {
        Text("Sheet body")
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    SheetCloseButton {}
                }
            }
    }
}

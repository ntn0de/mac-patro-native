import SwiftUI

public struct UpdateBadgeView: View {
    var onDismiss: () -> Void
    
    public var body: some View {
        Spacer(minLength: 3)
        HStack {
            Text("A new version is available. Click here to go to settings")
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
            }.buttonStyle(.plain)
        }
        .padding(2)
        .background(Color.blue).opacity(0.8)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

#if DEBUG
struct UpdateBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateBadgeView(onDismiss: {})
            .padding()
    }
}
#endif

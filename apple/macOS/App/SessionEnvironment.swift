import SwiftUI

extension View {
    func session(_ session: MacSession) -> some View {
        environment(session).environment(session.store).environment(session.host)
    }
}

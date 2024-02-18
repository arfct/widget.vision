import SwiftUI

struct WidgetListItem: View {
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  var widget: Widget
  @State var asDrag = false;
  
  let iconSize = CGSize(width: 200, height: 141)
  
  var body: some View {
    VStack(alignment: .center) {
      Button {
        openWindow(id: "widget", value: widget.persistentModelID)
      } label: {
        
        
        ZStack() {
          if let image = widget.thumbnail {
            if (image.size.width / image.size.height > 1.618) {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth:iconSize.width, maxHeight:iconSize.height, alignment: .center)
                .fixedSize()
            } else {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth:iconSize.width, maxHeight:iconSize.height, alignment: .top)
                .fixedSize()
            }
          } else {
            VStack {
              Image(systemName: widget.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .font(Font.title.weight(.light))
            }
            .frame(minWidth:iconSize.width, maxWidth:.infinity, minHeight:iconSize.height, maxHeight:iconSize.height, alignment: .center)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 40))
          }
        }
        .background(widget.backColor)
        .background(asDrag ? .white.opacity(0.05) : .clear)
        .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 40),
                               displayMode: (true && !asDrag) ? .always : .never)
        .cornerRadius(30)
        .frame(maxWidth:.infinity)
        
      }
      
      .frame(maxWidth: .infinity)
      
      HStack(alignment: .center, spacing: 10) {
        Text(widget.displayName)
          .font(.headline)
          .lineLimit(1)
          .opacity(asDrag ? 0.0 : 1.0)
      }.padding(.top, 16)
    }
    .buttonBorderShape(.roundedRectangle(radius: 40))
    .buttonStyle(.borderless)
    .hoverEffect(.lift)
    .frame(maxWidth: .infinity, alignment:.leading)
  }
}


#Preview("Preview", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
  WidgetListItem(widget: .preview)
}

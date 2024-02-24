import Foundation
import SwiftUI
import SwiftData



@Model final class Widget: Transferable, ObservableObject {
  
  var id: UUID
  var name: String = ""
  var title: String?
  var image: String?
  var location: String?
  var originalLocation: String?
  
  var style: ViewStyle
  var backHex: String?
  var foreHex: String?
  var tintHex: String?
  var fontName: String?
  var fontWeight: String?

  var width: CGFloat = 360
  var height: CGFloat = 360
  var minWidth: CGFloat = 320
  var minHeight: CGFloat = 180
  var maxWidth: CGFloat = CGFloat.infinity
  var maxHeight: CGFloat = CGFloat.infinity
  
  var radius: CGFloat = 30

  var zoom: CGFloat = 1.0
  var viewport: String?
  var userAgent: String = "mobile"
  
  var lastOpened: Date?
  var options: String = ""
  var icon: String = "globe"
  
  // Overrides
  @Attribute(originalName: "clearClasses")
  var clearSelectors: String?
  @Attribute(originalName: "removeClasses")
  var removeSelectors: String?
  var injectCSS: String?
  var injectJS: String?
  
  var favorite: Bool = false
  
  @Transient
  var isLoading: Bool = false

  func delete() {
    try? modelContext?.delete(self)
    try? modelContext?.save()
  }

  func sizeFor(dimensions: String) -> CGSize {
    let dims = dimensions.split(separator: "x")
    var size = CGSize()
    if let width = dims.first.map(String.init), let widthDouble = Double(width) {
      size.width = CGFloat(widthDouble)
    }
    if let height = dims.last.map(String.init), let heightDouble = Double(height) {
      size.height = CGFloat(heightDouble)
    }
    return size;
  }
  
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.safeShareURL)
  }
  
  // MARK: Init
  
  convenience init(url: URL) {
    
    print("🌐 Opening URL: \(url.absoluteString)")
    var location = url.absoluteString
    var parameters: String?
    if let regex = try? Regex(#"(?:\?)format=widget\&(.*)"#) {
      if let match = location.firstMatch(of: regex) {
        parameters = String(match[1].substring!)
        location = location.replacing(regex, with: "")
      }
    }
    
    if let decodedLocation = location.removingPercentEncoding {
      location = decodedLocation
    }
    location = location
      .replacingOccurrences(of: "widget-http", with: "http")
      .replacingOccurrences(of: "https://widget.vision/http", with: "http")
      .replacingOccurrences(of: "https://www.widget.vision/http", with: "http")
    
    self.init( name:url.host() ?? "NAME", location: location, options:parameters)
  }
  
  init(id: UUID = UUID(), name: String, image:String? = nil, location: String, style: ViewStyle = .glass, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, options: String? = nil) {
    self.id = id
    self.name = name
    if let image = image { self.image = image }
    self.location = location
    self.originalLocation = location
    self.style = style
    if let width = width {self.width = width }
    if let height = height {self.height = height }
    
    if let options = options {
      if options.contains("transparent") {
        self.style = .transparent;
      }
      options.split(separator: "&").forEach({ param in
        let kv = param.split(separator:"=")
        if let key = kv.first?.removingPercentEncoding, let value = kv.last?.replacingOccurrences(of: "+", with: " ").removingPercentEncoding {
          switch key {
          case "style":
            if (value == "transparent") { self.style = .transparent}
          case "name":
            self.name = String(value)
          case "bg", "back":
            self.backHex = String(value)
          case "fg", "fore":
            self.foreHex = String(value)
          case "tg", "tint":
            self.tintHex = String(value)
          case "ms", "sz", "size":
            let size = sizeFor(dimensions: String(value))
            self.width = size.width
            self.height = size.height
          case "minsize", "min":
            let size = sizeFor(dimensions: String(value))
            self.minWidth = size.width
            self.minHeight = size.height
          case "maxsize", "max":
            let size = sizeFor(dimensions: String(value))
            self.maxWidth = size.width
            self.maxHeight = size.height
          case "zm", "zoom":
            if let value = Double(value) {
              self.zoom = value
            }
          case "ua", "agent":
            if let value = Double(value) {
              self.userAgent = String(value)
            }
          case "vw":
            self.viewport = String(value)
          case "remove":
            self.removeSelectors = String(value)
          case "clear":
            self.clearSelectors = String(value)
          case "radius":
            if let value = Double(value) {
              self.radius = Double(value)
            }
          case "js":
            self.injectJS = String(value)
          case "css":
            self.injectCSS = String(value)
          case "icon":
            self.icon = String(value)
          default:
            break
          }
        }
      })
    }
    if let zoom = zoom { self.zoom = zoom }
  }
  
}

// MARK: Transient Props

extension Widget {
  @Transient
  var backColor: Color? {
    if let hex = backHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var foreColor: Color? {
    if let hex = foreHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var tintColor: Color? {
    if let hex = tintHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var displayName: String {
    if name.count > 0 {
      return name;
    }
    return title ?? hostName ?? "Untitled";
  }
  
  @Transient
  var hostName: String? {
    URLComponents(string: location!)?.host
  }
  
  @Transient
  var modelID: Data {
    let mid = try! JSONEncoder().encode(persistentModelID);
    return  mid;
  }
  
  func thumbnailChanged() {
    objectWillChange.send()
  }
  
  @Transient
  var thumbnailUIImage: UIImage? {
    if let file = thumbnailFile, let image = UIImage(contentsOfFile: file.path) {
      return image;
    }
    return nil;
  }
  
  @Transient
  var thumbnailImage: Image? {
    if let img = thumbnailUIImage {
      return Image(uiImage: img)
    }
    return nil
  }
  
  @Transient
  var thumbnailFile: URL? {
    if var path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      let filename = path
        .appendingPathComponent("thumbnails", isDirectory: true)
        .appendingPathComponent(self.id.uuidString + ".png")
      return filename
    }
    return nil
  }

  @Transient
  var sizeString: String {
    return ("\(width)x\(height)")
  }
  
  @Transient
  var safeShareURL:URL {
    return shareURL ?? URL(string:"about:blank")!
  }
  
  @Transient
  var shareURL: URL? {
    
    var items: [URLQueryItem] = []
    if (style == .transparent) {
      items.append(URLQueryItem(name: "style", value: "transparent")) }
    if name.count > 0  {
      items.append(URLQueryItem(name: "name", value: name)) }
    if backHex != nil { 
      items.append(URLQueryItem(name: "back", value: backHex)) }
    if foreHex != nil { 
      items.append(URLQueryItem(name: "fore", value: foreHex)) }
    if tintHex != nil { 
      items.append(URLQueryItem(name: "tint", value: tintHex)) }
    if zoom != 1.0 {
      items.append(URLQueryItem(name: "zoom", value: String(describing:zoom))) }
    if let value = viewport {
      items.append(URLQueryItem(name: "vw", value: value)) }
    if let string = injectJS, string.count > 0 {
      items.append(URLQueryItem(name: "js", value: string))}
    if let string = injectCSS, string.count > 0 {
      items.append(URLQueryItem(name: "css", value: string))}
    if (userAgent != "mobile") {
      items.append(URLQueryItem(name: "ua", value: userAgent)) }
    if let string = removeSelectors, string.count > 0 {
      items.append(URLQueryItem(name: "remove", value: string))
    }
    if let string = clearSelectors, string.count > 0 {
      items.append(URLQueryItem(name: "clear", value: string))
    }
    items.append(URLQueryItem(name: "size", value: sizeString))
    
    var components = URLComponents()
    components.queryItems = items;
    
    guard var suffix = components.string else { return nil }
    suffix.removeFirst()
    if (suffix.count > 0) { suffix = "?format=widget&" + suffix}
    
    guard let encodedURL = location?  //.replacingOccurrences(of: "https://", with: "")
      .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
    
    let urlString = "https://widget.vision/\(String(describing: encodedURL))\(suffix)"
    
    return URL(string: urlString)!
  }
  
  @Transient
  var description: String {
    return "Widget \(id) - \(location ?? "")"
  }
  
  static var preview: Widget {
    Widget(name: "Test", location: "https://example.com", style: .glass, options: "bg=0000&fg=ffff&tg=8aff&sz=360x360&zoom=1.0&icon=graduationcap")
  }
  @Transient
  var userAgentString: String {
    if (userAgent == "desktop") {
      return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
    } else if (userAgent == "mobile" || userAgent.count == 0) {
      return "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    } else {
      return userAgent;
    }
    
  }
  
}

private extension Color {
  static var random: Color {
    var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
    return random(using: &generator)
  }
  
  static func random(using generator: inout RandomNumberGenerator) -> Color {
    let red = Double.random(in: 0..<1, using: &generator)
    let green = Double.random(in: 0..<1, using: &generator)
    let blue = Double.random(in: 0..<1, using: &generator)
    return Color(red: red, green: green, blue: blue)
  }
}

enum ViewStyle: String, Equatable, CaseIterable, Codable {
  case glass = "Glass"
  case transparent  = "Transparent"
  //case toolbar  = "Toolbar"
  
  var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
  
  var displayName: String {
    switch self {
    case .transparent: return "Transparent"
    case .glass: return "Frosted Glass"
    //case .toolbar: return "Mini Browser"
    }
  }
  var iconName: String {
    switch self {
    case .transparent: return "square.dotted"
    case .glass: return "square.fill"
    //case .toolbar: return "macwindow"
    }
  }
}

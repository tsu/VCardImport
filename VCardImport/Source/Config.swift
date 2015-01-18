import UIKit

private func getBundleInfo()
  -> (executable: String, bundleId: String, version: String)
{
  var executable: String?
  var bundleId: String?
  var version: String?

  if let info = NSBundle.mainBundle().infoDictionary {
    if let data = info[kCFBundleExecutableKey] as? String {
      executable = data
    }
    if let data = info[kCFBundleIdentifierKey] as? String {
      bundleId = data
    }
    if let data = info[kCFBundleVersionKey] as? String {
      version = data
    }
  }

  return (
    executable ?? "Unknown",
    bundleId   ?? "org.tkareine.VCardImport",
    version    ?? "Unknown"
  )
}

private let BundleInfo = getBundleInfo()

struct Config {
  static let AppTitle = "vCard Import"

  static let Executable = BundleInfo.executable

  static let BundleIdentifier = BundleInfo.bundleId

  static let Version = BundleInfo.version

  static let OS = NSProcessInfo.processInfo().operatingSystemVersionString

  struct Net {
    /**
     * On failure, NSURLSession reports an NSError with description "The
     * operation couldn’t be completed". (NSURLErrorDomain error -1001.) It's
     * not helpful, so let's so a generic error description then.
     */
    static let GenericErrorDescription = "Cannot reach URL"

    static let VCardHTTPHeaders = [
      "Accept": "text/vcard,text/x-vcard,text/directory;profile=vCard;q=0.9,text/directory;q=0.8,*/*;q=0.7"
    ]
  }

  struct UI {
    static let AnimationDurationFadeMessage: NSTimeInterval = 0.5
    static let AnimationDelayFadeOutMessage: NSTimeInterval = 5
    static let SourcesCellReuseIdentifier = "SourcesCellReuseIdentifier"
    static let CellTextColorEnabled = UIColor.blackColor()
    static let CellTextColorDisabled = UIColor.grayColor()
    static let ValidationBorderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.6).CGColor
    static let ValidationBorderWidth: CGFloat = 2
    static let ValidationCornerRadius: CGFloat = 5
    static let ValidationThrottleInMS = 300
  }
}

import UIKit
import ImageIO

struct ImageHeaderData{
    static var PNG: [UInt8] = [0x89]
    static var JPEG: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47]
    static var TIFF_01: [UInt8] = [0x49]
    static var TIFF_02: [UInt8] = [0x4D]
}

public enum ImageFormat{
    case Unknown, PNG, JPEG, GIF, TIFF
    
    public var suffixName: String {
        switch self {
        case .PNG:
            return "png"
        case .JPEG:
            return "jpg"
        case .GIF:
            return "gif"
        case .TIFF:
            return "tiff"
        default:
            return "jpg"
        }
    }
}

extension NSData{
    
    /// 获取图片的原始格式
    public var imageFormat: ImageFormat{
        var buffer = [UInt8](repeating: 0, count: 1)
        self.getBytes(&buffer, range: NSRange(location: 0,length: 1))
        if buffer == ImageHeaderData.PNG {
            return .PNG
        } else if buffer == ImageHeaderData.JPEG {
            return .JPEG
        } else if buffer == ImageHeaderData.GIF {
            return .GIF
        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02 {
            return .TIFF
        } else{
            return .Unknown
        }
    }
}

import Foundation

/// Common data types for`MIME Type`
public enum TTDataMimeType: String {
    case JPEG = "image/jpeg"
    case PNG = "image/png"
    case GIF = "image/gif"
    case HEIC = "image/heic"
    case HEIF = "image/heif"
    case WEBP = "image/webp"
    case TIF = "image/tif"
    case JSON = "application/json"
    case FORM = "multipart/form-data"
}

/// TTMultipartData for upload datas, eg: images/photos
public class TTMultipartData {
    /// The data to be encoded and appended to the form data.
    let data: Data
    /// Name to associate with the `Data` in the `Content-Disposition` HTTP header.
    let name: String
    /// Filename to associate with the `Data` in the `Content-Disposition` HTTP header.
    let fileName: String
    /// The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types
    /// see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
    let mimeType: String

    /// Create TTMultipartData Model
    /// - Parameters:
    ///   - data: The data to be encoded and appended to the form data.
    ///   - name: The name to be associated with the specified data.
    ///   - fileName: The filename to be associated with the specified data.
    ///   - mimeType: The MIME type of the specified data. eg: image/jpeg
    public init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }

    /// Create TTMultipartData Model
    /// - Parameters:
    ///   - data: The data to be encoded and appended to the form data.
    ///   - name: The name to be associated with the specified data.
    ///   - fileName: The filename to be associated with the specified data.
    ///   - type: The MIME type of the specified data. eg: image/jpeg
    public convenience init(data: Data, name: String, fileName: String, type: TTDataMimeType) {
        self.init(data: data, name: name, fileName: fileName, mimeType: type.rawValue)
    }

    // mimeType --> image/jpeg, image/png, image/gif,
    // see: https://www.cnblogs.com/fuqiang88/p/4618652.html

    // 中文说明一下，增加理解：
    // 当提交一张图片或一个文件的时候 name 可以随便设置，服务端直接能拿到，如果服务端需要根据name去取不同文件的时候
    // 则appendPartWithFileData 方法中的 name 需要根据form的中的name一一对应
    // 所以name的值，是需要跟后台服务端商量好的.
}

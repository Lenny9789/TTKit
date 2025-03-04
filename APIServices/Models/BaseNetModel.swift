

class BaseNetModel: SexyJson {
    
    required init() {}
    
    func sexyMap(_ map: [String : Any]) {
        
    }
    
    var code: Int = 0
    var message: String?
    var ok: Bool = false
    var transactionId: String?
}
/// 资源载体类型
enum ResourcePayload {
    // 图片（watermarkSwitch：是否加水印）
    case image(image: UIImage)
    // 视频（watermarkSwitch：是否加水印；isCvtHls：是否转换成hls格式）
    case video(url: URL)
    // 语音
    case voice(url: URL)
    
    var payloadName: String {
        switch self {
        case .image(_): return "image"
        case .video(_): return "video"
        case .voice(_): return "voice"
        }
    }
}

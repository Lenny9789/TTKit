import Foundation


/// 实现协议，每个接口，都是一个`APIItem`
public struct APIItem: TTAPIProtocol {
    public var url: String { kAppDomain + URLPath }  //域名 + path
    public let description: String
    public let extra: String?
    public var method: TTHTTPMethod
    public var generalHeaders: [String: String]? //header通用参数

    private let URLPath: String  // URL的path

    init(_ path: String, d: String, e: String? = nil, m: TTHTTPMethod = .get) {
        URLPath = path
        description = d
        extra = e
        method = m
        generalHeaders = ["platform": "iOS",
                          "osversion": kSysVersion,
                          "version": "0.1",
                          "model": UIDevice.current.model,
                          "udid": tt_uniqueIdentifier
        ]
    }

    init(_ path: String, m: TTHTTPMethod) {
        self.init(path, d: "", e: nil, m: m)
    }
}

/// 分页信息
public struct APIPage {
    /// 分页页码
    enum Key: String {
        case pageNo     = "pageNo"
        case pageSize   = "pageSize"
    }
    
    /// 分页默认值
    enum DefValue: Int {
        case pageNo     = 1   //默认从1开始
        case pageSize   = 20  //默认20
    }
}

/// API接口地址
public struct API {

    // MARK: 公共分类
    public struct Common {
        static let shared = Common()
        public var uplaod: APIItem { APIItem("/api/general/upload", d: "上传", m: .post) }
        public var musics: APIItem { APIItem("/api/general/musics", d: "音乐列表", m: .get) }
        public var images: APIItem { APIItem("/api/general/images", d: "图片列表", m: .get) }
        public var ossPolicy: APIItem { APIItem("/api/general/get-oss-policy", d: "OSS-Policy") }
        public var banners: APIItem { APIItem("/api/general/banners", d: "首页轮播图") }
        public var configs: APIItem { APIItem("/api/general/configs", d: "全局配置") }
    }
    
    // MARK: 登录/注册
    public struct Account {
        static let shared = Account()

        public var loginPwd: APIItem { APIItem("/api/user/password-login", d: "账号密码登录", m: .post) }
        public var loginFetchCaptcha: APIItem { APIItem("/api/user/captcha", d: "获取验证码", m: .get) }
        public var loginCaptcha: APIItem { APIItem("/api/user/captcha-login", d: "验证码登录", m: .post) }
        public var loginOneClick: APIItem { APIItem("/api/user/phone-one-click-login", d: "一键登录", m: .post) }
        public var pwdReset: APIItem { APIItem("/api/user/password-reset", d: "验证码重置密码", m: .post) }
    }
    
}

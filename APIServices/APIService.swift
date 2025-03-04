
import UIKit

/// API接口请求
class APIService {
    static let shared = { APIService() }()
    
}

// MARK: 公共分类
extension APIService {

    //-MARK: 用户
//    func loginOneClick(token: String, completion: @escaping (TTGenericResult<OneClickDataModel>) -> Void) {
//        var parameter = [String: String]()
//        let headers: [String: String] = [:]
//        parameter["token"] = token
//        TTNET.fetch(API.Account.shared.loginOneClick, parameters: parameter, headers: headers).result { result in
//            let parsedRet = parseResponseToModel2(result: result, type: OneClickDataModel.self)
//            switch parsedRet {
//            case .success(let value):
//                completion(.success(value: value as! OneClickDataModel))
//            case .failure(let error):
//                completion(.failure(error: error))
//            }
//        }
//    }
//    
//    func loginFetchCaptcha(phone: String, completion: @escaping (TTBooleanResult) -> Void) {
//        let parameter: [String: Any] = ["phone": phone]
//        let headers: [String: String] = [:]
//        
//        TTNET.fetch(API.Account.shared.loginFetchCaptcha, parameters: parameter, headers: headers).result { result in
//            let parsedRet = parseResponseToModel2(result: result, type: String.self)
//            switch parsedRet {
//            case .success(_):
//                completion(.success)
//            case .failure(let error):
//                completion(.failure(error: error))
//            }
//        }
//    }
    
}

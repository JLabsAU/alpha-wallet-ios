//
//  DfnsManager.swift
//  Shiny
//
//  Created by leven on 2023/7/31.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON
import CryptoKit
import CommonCrypto
import AuthenticationServices
@available(iOS 15.0, *)
class DfnsManager {
    
    let request: Request
    let passKeys: Passkeys

    static let shared = DfnsManager()
    
    init() {
        self.request = Request()
        self.passKeys = Passkeys()
    }
    
    func register(username: String, password: String) -> Promise<JSON> {
        var temporaryAuthenticationToken: String = ""
        return request.request(path: "register/init", method: .post, params: ["username": username, "password": password]).then { json in
            temporaryAuthenticationToken = json["temporaryAuthenticationToken"].stringValue
            return Promise<ASAuthorizationPlatformPublicKeyCredentialRegistration> { resolver in
                self.passKeys.createPasskeys(json) { res, error in
                    if let error = error {
                        resolver.reject(error)
                    } else if let credentialRegistration = res as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
                        resolver.fulfill(credentialRegistration)
                    } else if let _ = res as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    } else {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    }
                }
            }
        }.then { credential in
            let rawClientDataJSON = credential.rawClientDataJSON.toBase64Url()
            let rawAttestationObject = credential.rawAttestationObject?.toBase64Url()
            let credentialID = credential.credentialID.toBase64Url()
            let p: [String: Any] = [
                "firstFactorCredential": [
                    "credentialKind": "Fido2",
                    "credentialInfo": [
                        "credId" : credentialID,
                        "clientData": rawClientDataJSON,
                        "attestationData": rawAttestationObject,
                    ],
                ] as [String : Any]
            ]
            return self.request.request(path: "register/complete", method: .post, params: ["signedChallenge": p, "temporaryAuthenticationToken" : temporaryAuthenticationToken])
        }
    }
    
    func signIn(username: String) -> Promise<JSON> {
        return request.request(path: "login", method: .post, params: ["username" : username])
    }
    
    func authSignIn(username: String) -> Promise<JSON> {
        var challengeIdentifier: String = ""

        return request.request(path: "auth/login/init", method: .post, params: ["username": username, "orgId": self.request.orgId, "authToken": self.request.authToken]).then { json in
            
            challengeIdentifier = json["challengeIdentifier"].stringValue

            return Promise<ASAuthorizationPlatformPublicKeyCredentialAssertion> { resolver in
                self.passKeys.signPassKeys(json) { res, error in
                    if let error = error {
                        resolver.reject(error)
                    } else if let credential = res as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                        resolver.fulfill(credential)
                    } else if let _ = res as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    } else {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    }
                }
            }
        }.then { credential in
            let authenticatorData = credential.rawAuthenticatorData.toBase64Url()
            let rawClientDataJSON = credential.rawClientDataJSON.toBase64Url()
            let credentialID = credential.credentialID.toBase64Url()
            let signature = credential.signature.toBase64Url()
            let userHandle = credential.userID.toBase64Url()
            
            let p: [String: Any] = [
                "username": username,
                "signedChallenge" : [
                    "challengeIdentifier" : challengeIdentifier,
                    "firstFactor" : [
                        "kind": "Fido2",
                        "credentialAssertion": [
                            "authenticatorData" :  authenticatorData,
                            "credId" : credentialID,
                            "clientData": rawClientDataJSON,
                            "signature": signature,
                            "userHandle" : userHandle
                        ],
                    ] as [String : Any]
                   
                ] as [String : Any],
                "authToken": self.request.authToken
            ]
            return self.request.request(path: "auth/login/complete", method: .post, params: p)
        }
    }
    
    
    func listWallets() -> Promise<JSON> {
        return request.request(path: "wallets/list", method: .get)
    }
    
    func createWallet(net: String) ->Promise<JSON> {
        
        var requestBody: [String: Any] = [:]
        var challengeIdentifier: String = ""
        return request.request(path: "wallets/new/init", method: .post, params: ["network": net]).then { json in
            requestBody = json["requestBody"].dictionaryObject ?? [:]
            challengeIdentifier = json["challenge"]["challengeIdentifier"].stringValue
            return Promise<ASAuthorizationPlatformPublicKeyCredentialAssertion> { resolver in
                self.passKeys.signPassKeys(json) {  res, error in
                    if let error = error {
                        resolver.reject(error)
                    } else if let _ = res as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    } else if let credential = res as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                        resolver.fulfill(credential)
                    } else {
                        resolver.reject(WebAuthnError.message("invalid passkeys type"))
                    }
                }
            }
        }.then { credential in
            let authenticatorData = credential.rawAuthenticatorData.toBase64Url()
            let rawClientDataJSON = credential.rawClientDataJSON.toBase64Url()
            let credentialID = credential.credentialID.toBase64Url()
            let signature = credential.signature.toBase64Url()
            let userHandle = credential.userID.toBase64Url()
            
            let p: [String: Any] = [
                "requestBody" : requestBody,
                "signedChallenge" : [
                    "challengeIdentifier" : challengeIdentifier,
                    "firstFactor" : [
                        "kind": "Fido2",
                        "credentialAssertion": [
                            "authenticatorData" :  authenticatorData,
                            "credId" : credentialID,
                            "clientData": rawClientDataJSON,
                            "signature": signature,
                            "userHandle" : userHandle
                        ],
                    ] as [String : Any]
                ] as [String : Any]
            ]
            return self.request.request(path: "wallets/new/complete", method: .post, params: p)
        }
    }
}

@available(iOS 15.0, *)
extension DfnsManager {
    class Request {
        private var headers: [String: Any] = [:]
        private var host: String = ""
        private let USERACTION_HEADER_KEY: String = "X-DFNS-USERACTION"

        private var applicationOrigin: String = ""
        private(set) var authToken: String = ""
        private(set) var orgId: String = ""

        private var appId: String = ""
        private var credentialPrivateKey: String = ""

        init() {
            if let url = Bundle.main.url(forResource: "dfns", withExtension: "json"), let data = try? Data(contentsOf: url), let json = try? JSON(data: data), let values = json["values"].array {
                if let authToken = values.first(where: {$0["key"].stringValue == "authToken"})?["value"].string {
                    self.authToken = authToken
                    headers["Authorization"] = "Bearer " + authToken
                }
                
                if let applicationId = values.first(where: {$0["key"].stringValue == "applicationId"})?["value"].string {
                    self.appId = applicationId
                    headers["X-DFNS-APPID"] = applicationId
                }
                
                if let orgId = values.first(where: {$0["key"].stringValue == "orgId"})?["value"].string {
                    self.orgId = orgId
                }
                
                if let host = values.first(where: {$0["key"].stringValue == "dfnsApiDomain"})?["value"].string {
                    self.host = host
                }
                
                if let applicationOrigin = values.first(where: {$0["key"].stringValue == "applicationOrigin"})?["value"].string {
                    self.applicationOrigin = applicationOrigin
                }
                
                
                if let credentialPrivateKey = values.first(where: {$0["key"].stringValue == "credentialPrivateKey"})?["value"].string {
                    self.credentialPrivateKey = credentialPrivateKey.replacingOccurrences(of: "\\n", with: "\n")
                }
            }
        }
        
        func generateNonce() -> String? {
            let uuid = UUID().uuidString
            let dateString = Date().ISO8601Format()
            if let data = try? JSONSerialization.data(withJSONObject: [
                "uuid" : uuid,
                "date" : dateString
            ]) {
                return data.base64EncodedString()
            }
            return nil
        }

        
        func resendEmail(email: String) -> Promise<JSON> {
            return request(path: "auth/manage/users/send-registration-email", method: .put ,params: ["username": email, "orgId": "or-1jrr0-ao48r-8dg8b63gst7upr9v"])
        }
        
        func createUser(email: String) -> Promise<JSON> {
            return request(path: "auth/users", method: .post ,params: ["email": email, "kind": "EndUser"], headers: [USERACTION_HEADER_KEY : ""])
        }
        
        func registerUser(json: JSON, code: String, email: String) -> Promise<JSON> {
//            if let name = json["username"].string, let orgId = json["orgId"].string {
                let p = ["username": email, "registrationCode": code, "orgId" : "or-1jrr0-ao48r-8dg8b63gst7upr9v"]
                return request(path: "auth/registration/init", method: .post ,params: p)
//            } else {
//                return Promise<JSON>.init(error: WebAuthnError.message("invalid params"))
//            }
        }
        
        func completeRegister(params: [String: Any], headers: [String: String]) -> Promise<JSON> {
            return request(path: "register/complete", method: .post ,params: ["signedChallenge": params, "temporaryAuthenticationToken" : headers["Authorization"]!], headers: [:])

//            return request(path: "auth/registration", method: .post ,params: params, headers: headers)
        }
        
        
        
        
        func request(path: String, method: HTTPMethod = .get, params: [String: Any] = [:], headers: [String: String] = [:]) -> Promise<JSON> {
            return signAction(headers[USERACTION_HEADER_KEY] == "", path: path, method: method, params: params).then { userAction in
//                let url = URL(string: "https://" + self.host + "/" + path)!
//                let url = URL(string: "http://" + "dfns-api.j-labs.xyz:8000" + "/" + path)!
                let url = URL(string: "http://" + "localhost:8000" + "/" + path)!

                var defaultHeader = self.getRequestHeaders()
                defaultHeader.merge(headers, uniquingKeysWith: { $1 })
                if userAction.isEmpty == false {
                    defaultHeader[self.USERACTION_HEADER_KEY] = userAction
                }
                let httpHeaders = HTTPHeaders(defaultHeader)
                return AF.request(url, method: method, parameters: params, encoding: method == .get ? URLEncoding.default : JSONEncoding.default, headers: httpHeaders).promiseResponse()
            }
        }
        
        func signAction(_ enable: Bool,path: String, method: HTTPMethod, params: [String: Any] = [:]) -> Promise<String> {
            if enable == false {
                return Promise.value("")
            }
            var challenge: JSON = JSON()
            var clientDataString: String = ""
            
            let content: [String: Any] = [
                "userActionPayload": JSON(params).rawString() ?? "",
                "userActionHttpPath": "/" + path,
                "userActionHttpMethod": method.rawValue,
                "userActionServerKind": "Api"
            ]

            return request(path: "auth/action/init", method: .post, params: content).then { [weak self] json -> Promise<String> in
                guard let self = self else {
                    return Promise<String>.init(error: WebAuthnError.message("self deinit"))
                }
                if let errorMessage = json["error"]["message"].string {
                    return Promise<String>.init(error: WebAuthnError.message(errorMessage))

                }
               challenge = json
                let clientData = [
                    "type": "key.get",
                    "challenge": challenge["challenge"].stringValue,
                    "origin": self.applicationOrigin
                ]
               
                if let data = try? JSONSerialization.data(withJSONObject: clientData), let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                    clientDataString = jsonString
                    return self.trySignPayload(dataString: jsonString)
                } else {
                    return Promise<String>.init(error: WebAuthnError.message("invalid challenge string"))
                }
           }.then { signature -> Promise<JSON> in
               
               let signedChallenge: [String: Any] = [
                "kind": "Key",
                "credentialAssertion": [
                    "credId": challenge["allowCredentials"]["key"].arrayValue.first?["id"].stringValue,
                    "clientData": clientDataString.decodeBase64Url()?.toBase64Url() ?? "",
                    "signature": signature
                    ]
               ]
               let parms: [String: Any] = [
                "challengeIdentifier": challenge["challengeIdentifier"].stringValue,
                "firstFactor": signedChallenge
               ]
               return self.request(path: "auth/action", method: .post, params: parms)

               
//               if let data = try? JSONSerialization.data(withJSONObject: parms), let jsonString = String(data: data, encoding: String.Encoding.utf8) {
//               } else {
//                   return Promise<JSON>.init(error: WebAuthnError.message("invalid signedChallenge"))
//               }
               
           }.then { json -> Promise<String> in
               return Promise.value(json["userAction"].stringValue)
           }
        }
        
        func trySignPayload(dataString: String) -> Promise<String> {
            return Promise { resolver in
                if let key = self.getBaseEncodePrivateKey() {
                    let signature = try self.signWithPrivateKey(dataString, key)
                    resolver.fulfill(signature ?? "")
                } else {
                    resolver.reject(WebAuthnError.message("invalid private key"))
                }
               
            }
        }
        
        private func signWithPrivateKey(_ text: String, _ key: SecKey) throws -> String? {
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            let data = text.data(using: .utf8)!

            let _ = digest.withUnsafeMutableBytes { digestBytes in
                data.withUnsafeBytes { dataBytes in
                    CC_SHA256(dataBytes, CC_LONG(data.count), digestBytes)
                }
            }

            var signature = Data(count: SecKeyGetBlockSize(key) * 4)
            var signatureLength = signature.count

            let result = signature.withUnsafeMutableBytes { signatureBytes in
                digest.withUnsafeBytes { digestBytes in
                    SecKeyRawSign(key,
                                  SecPadding.PKCS1SHA256,
                                  digestBytes,
                                  digest.count,
                                  signatureBytes,
                                  &signatureLength)
                }
            }

            let count = signature.count - signatureLength
            signature.removeLast(count)

            guard result == noErr else {
                throw WebAuthnError.message("Could not sign data: \(result)")
            }

            return signature.base64EncodedString()
        }
        
        func getApi(path: String) -> URL {
            return URL(string: "https://" + self.host + "/" + path)!
        }
        
        func getRequestHeaders() -> [String: String] {
            return [
                "Content-Type" : "application/json",
                "X-DFNS-APPID" : self.appId,
                "X-DFNS-NONCE" : self.generateNonce() ?? "",
                "Authorization": "Bearer " + self.authToken
            ]
        }

        
        /// https://stackoverflow.com/questions/75072057/pem-encoded-elliptic-curve-public-key-conversion-ios
        func createSecKeyWithPEMSecp256r1Private(_ pem: String) throws -> SecKey? {
            let privateKeyCK = try P256.Signing.PrivateKey(pemRepresentation: pem)
            let x963Data = privateKeyCK.x963Representation
            var errorQ: Unmanaged<CFError>? = nil
            let privateKeySF = try? SecKeyCreateWithData(x963Data as NSData, [
                kSecAttrKeyType: kSecAttrKeyTypeEC,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            ] as NSDictionary, &errorQ)
            return privateKeySF
        }

        
        func getBaseEncodePrivateKey() -> SecKey? {
            let key = try? self.createSecKeyWithPEMSecp256r1Private(self.credentialPrivateKey)
            return key
        }
    }
    
    
}

@available(iOS 15.0, *)
extension DfnsManager {

    class Passkeys: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate  {
        
        private var resultBlock: ((ASAuthorizationCredential?, Error?) -> Void)?
        private var isSign: Bool = false
    
        func signPassKeys(_ json: JSON, complete: @escaping (ASAuthorizationCredential?, Error?) -> Void) {
            self.resultBlock = complete
            let challenge = (json["challenge"]["challenge"].string ?? json["challenge"].string)?.data(using: .utf8) ?? Data()
            let domain = "j-labs.xyz"
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)

            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
            assertionRequest.userVerificationPreference = .required
            // you can pass in any mix of supported sign in request types here - we only use Passkeys
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return UIApplication.shared.keyWindow!
        }

        func createPasskeys(_ json: JSON, complete: @escaping (ASAuthorizationCredential?, Error?) -> Void) {
            self.resultBlock = complete
            let domain = "j-labs.xyz"
            let username = json["user"]["name"].stringValue
            let challenge = json["challenge"].stringValue.data(using: .utf8) ?? Data()
            let userID = json["user"]["id"].stringValue.data(using: .utf8) ?? Data()
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                                                      name: username, userID: userID)
            if let userVerification = json["authenticatorSelection"]["userVerification"].string, userVerification.isEmpty == false {
                registrationRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.init(rawValue: userVerification)
            }

            let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
            
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            self.resultBlock?(authorization.credential, nil)
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            self.resultBlock?(nil, error)
        }
    }
}

extension Data {
    func toBase64Url() -> String {
        return self.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}


extension String {
    
    func decodeBase64Url() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return Data(base64Encoded: self)
    }
    
    var hexData: Data? {
          var data = Data(capacity: count / 2)
          let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
          regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
              let byteString = (self as NSString).substring(with: match!.range)
              let num = UInt8(byteString, radix: 16)!
              data.append(num)
          }
          guard data.isEmpty == false else { return nil }
          return data
      }
    
}

extension DataRequest {
    
    func promiseResponse() -> Promise<JSON> {
        return Promise<JSON> { resover in
            let _ = self.response { res in
                if res.response?.statusCode == 401 {
                    resover.reject(NSError(domain: "", code: 401))

                } else {
                    switch res.result {
                    case .success(let data):
                        if let data = data, let json = try? JSON(data: data) {
                            resover.fulfill(json)
                        } else if (res.response?.statusCode ?? 0) >= 200 && (res.response?.statusCode ?? 0) < 300 {
                            resover.fulfill(JSON())
                        } else {
                            print(String(data: data ?? Data(), encoding: .utf8))
                            resover.reject(WebAuthnError.message("invalid response data"))
                        }
                    case .failure(let err):
                        resover.reject(err)
                    }
                }
            }
        }
    }

}

enum WebAuthnError: Error {
    case message(String)
}



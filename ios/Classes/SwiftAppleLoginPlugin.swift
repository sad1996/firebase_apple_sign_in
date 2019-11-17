import Flutter
import UIKit
import AuthenticationServices
import Foundation
import CommonCrypto
import CryptoKit
import Security
import FirebaseAuth

public class SwiftAppleLoginPlugin: NSObject, FlutterPlugin {

    let controller: FlutterViewController
    
    var flutterResult: FlutterResult?

    init(controller: FlutterViewController) {
        self.controller = controller
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "apple_login", binaryMessenger: registrar.messenger())
          let storyboard : UIStoryboard? = UIStoryboard.init(name: "Main", bundle: nil);
    
          let viewController: UIViewController? = storyboard!.instantiateViewController(withIdentifier: "FlutterViewController")
    let instance = SwiftAppleLoginPlugin(controller: viewController as! FlutterViewController)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.flutterResult = result
   if(call.method.elementsEqual("sign_in")){
//    let arguments = call.arguments as? Dictionary<String, Any>
    if #available(iOS 13, *) {
        startSignInWithAppleFlow()
    } else {
        self.flutterResult!(FlutterMethodNotImplemented)
    }
   } else{
    self.flutterResult!(FlutterMethodNotImplemented)
   }
  }

  // Unhashed nonce.
  var currentNonce: String?

  @available(iOS 13, *)
  func startSignInWithAppleFlow() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let authorizationController = ASAuthorizationController(authorizationRequests:[request])
    
    authorizationController.presentationContextProvider = controller as? ASAuthorizationControllerPresentationContextProviding
     authorizationController.performRequests()
  }

  @available(iOS 13, *)
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      return String(format: "%02x", $0)
    }.joined()

    return hashString
  }

  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        return random
      }

      randoms.forEach { random in
        if length == 0 {
          return
        }

        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }
}

@available(iOS 13.0, *)
extension SwiftAppleLoginPlugin: ASAuthorizationControllerDelegate {

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
      // Initialize a Firebase credential.
      let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                accessToken: nonce)
      // Sign in with Firebase.
      Auth.auth().signIn(with: credential) { (authResult, error) in
        if (error != nil) {
          // Error. If error.code == .MissingOrInvalidNonce, make sure
          // you're sending the SHA256-hashed nonce as a hex string with
          // your request to Apple.
            self.flutterResult!(error)
            print(error?.localizedDescription as Any)
          return
        }
        print("Sign in with Apple success: \(String(describing: authResult))")
        self.flutterResult!(authResult)
        // User is signed in to Firebase with Apple.
        // ...
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    self.flutterResult!(error)
    
    print("Sign in with Apple errored: \(error)")
  }

}

protocol ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
    
    
}


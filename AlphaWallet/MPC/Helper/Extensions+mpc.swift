//
//  View+mpc.swift
//  AlphaWallet
//
//  Created by leven on 2023/8/14.
//

import Foundation
import SVProgressHUD
import Toast_Swift
import SVGKit

public extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Converts String to Int
    func toInt() -> Int? {
        if let num = NumberFormatter().number(from: self) {
            return num.intValue
        } else {
            return nil
        }
    }
    
    /// Converts String to Double
    func toDouble() -> Double? {
        if let num = NumberFormatter().number(from: self) {
            return num.doubleValue
        } else {
            return nil
        }
    }
    
    /// Converts String to Float
    func toFloat() -> Float? {
        if let num = NumberFormatter().number(from: self) {
            return num.floatValue
        } else {
            return nil
        }
    }
    
    /// Converts String to Bool
    func toBool() -> Bool? {
        let trimmedString = self.trimmed().lowercased()
        if trimmedString == "true" || trimmedString == "false" {
            return (trimmedString as NSString).boolValue
        }
        return nil
    }
    
    func verifyUrl(urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    func docDir() -> String {
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        return (docPath as NSString).appendingPathComponent((self as NSString).pathComponents.last!)
    }
    
    static func uuid() -> String {
        var uuid = UserDefaults.standard.string(forKey: "UUID")
        if (uuid?.count ?? 0) > 0 {
            return uuid!
        } else {
            uuid = UUID().uuidString
            UserDefaults.standard.setValue(uuid, forKey: "UUID")
            UserDefaults.standard.synchronize()
            return uuid!
        }
    }
    
    static func randomUUID() -> String {
        return UUID().uuidString
    }
}
extension UIView {
    func toast(_ msg: String, duration: TimeInterval = 2) {
        self.makeToast(msg, duration: duration ,position: .center)
    }
    @discardableResult
    func addedOn(_ superView: UIView?) -> UIView {
        if let superView = superView {
            superView.addSubview(self)
        }
        return self
    }
    
    func addTap(_ callback: @escaping () -> Void) {
        self.isUserInteractionEnabled = true
        self.gestureRecognizers?.removeAll(where: { tap in
            tap is UITapGestureRecognizer
        })
        
        UITapGestureRecognizer(addToView: self) {
             callback()
        }
    }
}
extension UIWindow {
    static func toast(_ msg: String, duration: TimeInterval = 2) {
        UIApplication.shared.keyWindow?.toast(msg, duration: duration)
    }
    
    static func showLoading() {
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultAnimationType(.native)
        SVProgressHUD.setBackgroundColor(UIColor.black.withAlphaComponent(0.8))
        SVProgressHUD.setMinimumSize(CGSize(width: 150, height: 150))
        SVProgressHUD.setRingRadius(20)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show()
    }
    
    static func hideLoading() {
        SVProgressHUD.dismiss()
    }
    
}

extension UIImage {
    static func svg(_ name: String, color: UIColor? = nil, size: Any? = nil) -> UIImage? {
        let path = Bundle.main.path(forResource: name, ofType: "svg")
        return svg(path: path ?? "", color: color, size: size)
    }
    
    static func svg(path: String, emojiDetect: Bool = true, color: UIColor? = nil,  size: Any? = nil, direction: UIImage.Orientation? = nil) -> UIImage? {
        var imageResult: UIImage?
        if let image = SVGKImage(contentsOfFile: path) {
            if let size = size as? CGSize {
                image.size = size
            }
            if let size = size as? Double {
                image.size = CGSize(width: size, height: size)
            }

            imageResult = image.uiImage

            if let color = color {
                imageResult = imageResult?.fillColor(color)
            }

        }
        return imageResult        
    }
    func fillColor(_ color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let alphaInfo = self.cgImage!.alphaInfo
        let opaque = alphaInfo == .noneSkipLast || alphaInfo == .noneSkipFirst || alphaInfo == .none;
        UIGraphicsBeginImageContextWithOptions(self.size, opaque, self.scale);
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height);
        context?.scaleBy(x: 1.0, y: -1.0);
        context?.setBlendMode(.normal);
        context?.clip(to: rect, mask: self.cgImage!);
        context?.setFillColor(color.cgColor)
        context?.fill(rect);
        let imageOut = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return imageOut;
    }
    
}

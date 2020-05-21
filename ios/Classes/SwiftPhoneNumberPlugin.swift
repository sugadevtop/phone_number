import Flutter
import UIKit
import PhoneNumberKit

public class SwiftPhoneNumberPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.julienvignali/phone_number", binaryMessenger: registrar.messenger())
        let instance = SwiftPhoneNumberPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
            case "parse":
                parse(call, result)
            case "format":
                format(call, result)
            case "getRegions":
                var map: [String:Int] = [:]
                kit.allCountries().forEach {
                    if let countryCode = kit.countryCode(for: $0) {
                        map[$0] = Int(countryCode)
                    }
                }
                result(map)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private let kit = PhoneNumberKit()

    private func format(_ call: FlutterMethodCall, _ result: FlutterResult) {
        guard
            let arguments = call.arguments as? [String : Any],
            let number = arguments["string"] as? String,
            let region = arguments["region"] as? String
            else {
                let error = FlutterError(code:"InvalidArgument",
                                         message: "Input string and region can't be null",
                                         details: nil)
                result(error)
                return
        }

        let formatter = PartialFormatter(phoneNumberKit: kit, defaultRegion: region)
        let formatted = formatter.formatPartial(number)
        result(formatted)
    }

    private func parse(_ call: FlutterMethodCall, _ result: FlutterResult) {
        guard
            let arguments = call.arguments as? [String : Any],
            let string = arguments["string"] as? String
            else {
                let error = FlutterError(code: "InvalidArgument",
                                         message: "Input string can't be null",
                                         details: nil)
                result(error)
                return
        }

        let region = arguments["region"] as? String
        let ignoreType = arguments["ignoreType"] as! Bool

        guard let phoneNumber = parsePhoneNumber(string, region, ignoreType: ignoreType)
            else {
                let error = FlutterError(code: "InvalidNumber",
                                         message: "Failed to parse string '\(string).'",
                                         details: nil)
                result(error)
                return
        }

        result(buildMap(with:phoneNumber))
    }

    // MARK: Parsing
    
    /// Parses a number string.
    ///
    /// - Parameters:
    ///   - string: the raw number string.
    ///   - region: ISO 639 compliant region code.
    ///   - ignoreType: Avoids number type checking for faster performance.
    /// - Returns: PhoneNumber object or nil.

    private func parsePhoneNumber(_ string: String, _ region: String?, ignoreType: Bool = false) -> PhoneNumber? {
        if let region = region {
            return try? kit.parse(string, withRegion: region, ignoreType: ignoreType)
        } else {
            return try? kit.parse(string, ignoreType: ignoreType)
        }
    }

    private func buildMap(with phoneNumber: PhoneNumber) ->[String:Any] {
        return [
            "type": phoneNumber.type.normalized(),
            "e164": kit.format(phoneNumber, toType: .e164),
            "international": kit.format(phoneNumber, toType: .international, withPrefix: true),
            "national": kit.format(phoneNumber, toType: .national),
            "country_code": phoneNumber.countryCode,
            "number_string": phoneNumber.numberString,
        ];
    }
}

extension PhoneNumberType {
    func normalized() -> String {
        switch(self) {
            case .fixedLine: return "fixedLine"
            case .mobile: return "mobile"
            case .fixedOrMobile: return "fixedOrMobile"
            case .tollFree: return "tollFree"
            case .premiumRate: return "premiumRate"
            case .sharedCost: return "sharedCost"
            case .voip: return "voip"
            case .personalNumber: return "personalNumber"
            case .pager: return "pager"
            case .uan: return "uan"
            case .voicemail: return "voicemail"
            case .unknown: return "unknown"
            case .notParsed: return "notParsed"
        }
    }
}

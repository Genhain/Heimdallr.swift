import Argo

/// See: The OAuth 2.0 Authorization Framework, 5.2 Error Response
///      <https://tools.ietf.org/html/rfc6749#section-5.2>

public let OAuthErrorDomain = "OAuthErrorDomain"
public let OAuthErrorInvalidRequest = 1
public let OAuthErrorInvalidClient = 2
public let OAuthErrorInvalidGrant = 3
public let OAuthErrorUnauthorizedClient = 4
public let OAuthErrorUnsupportedGrantType = 5
public let OAuthErrorInvalidScope = 6

public let OAuthURIErrorKey = "OAuthURIErrorKey"
public let OAuthJSONErrorKey = "JSONErrorKey"

public enum OAuthErrorCode: String {
    case InvalidRequest = "invalid_request"
    case InvalidClient = "invalid_client"
    case InvalidGrant = "invalid_grant"
    case UnauthorizedClient = "unauthorized_client"
    case UnsupportedGrantType = "unsupported_grant_type"
    case InvalidScope = "invalid_scope"
}

public extension OAuthErrorCode {
    public var intValue: Int {
        switch self {
        case .InvalidRequest:
            return OAuthErrorInvalidRequest
        case .InvalidClient:
            return OAuthErrorInvalidClient
        case .InvalidGrant:
            return OAuthErrorInvalidGrant
        case .UnauthorizedClient:
            return OAuthErrorUnauthorizedClient
        case .UnsupportedGrantType:
            return OAuthErrorUnsupportedGrantType
        case .InvalidScope:
            return OAuthErrorInvalidScope
        }
    }
}

extension OAuthErrorCode: Decodable {
    public static func decode(json: JSON) -> Decoded<OAuthErrorCode> {
        return String.decode(json).flatMap { code in
            return .fromOptional(OAuthErrorCode(rawValue: code))
        }
    }
}

public class OAuthError {
    public let code: OAuthErrorCode
    public let description: String?
    public let uri: String?
	public let json: JSON?

	public init(code: OAuthErrorCode, description: String? = nil, uri: String? = nil, json: JSON? = nil) {
        self.code = code
        self.description = description
        self.uri = uri
		self.json = json
    }
}

public extension OAuthError {
    public var nsError: NSError {
        var userInfo = [String: AnyObject]()

        if let description = description {
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(description, comment: "")
        }

        if let uri = uri {
            userInfo[OAuthURIErrorKey] = uri
        }
		
		if let json = json {
			switch json {
			case .Object(let JSON):
				userInfo[OAuthJSONErrorKey] = JSON as? AnyObject
			default:
				break
			}
			
		}

        return NSError(domain: OAuthErrorDomain, code: code.intValue, userInfo: userInfo)
    }
}

extension OAuthError: Decodable {
	public class func create(code: OAuthErrorCode)(description: String?)(uri: String?)(json: JSON?) -> OAuthError {
        return OAuthError(code: code, description: description, uri: uri, json: json)
    }

    public class func decode(json: JSON) -> Decoded<OAuthError> {
        return create
            <^> json <| "error"
            <*> json <|? "error_description"
            <*> json <|? "error_uri"
			<*> json <|? "json"
    }

    public class func decode(data: NSData) -> Decoded<OAuthError> {
        let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
        return Decoded<AnyObject>.fromOptional(json).flatMap(Argo.decode)
    }
}

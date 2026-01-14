// Models/AnyCodable.swift
// MacLightController
//
// Type-erased Codable wrapper for dynamic parameter values

import Foundation

/// A type-erased Codable value that can hold any JSON-compatible type
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let float as Float:
            try container.encode(Double(float))
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable cannot encode value of type \(type(of: value))"
                )
            )
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [Any], rhs as [Any]):
            return lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { AnyCodable($0) == AnyCodable($1) }
        case let (lhs as [String: Any], rhs as [String: Any]):
            return lhs.count == rhs.count && lhs.keys.allSatisfy { key in
                guard let lhsValue = lhs[key], let rhsValue = rhs[key] else { return false }
                return AnyCodable(lhsValue) == AnyCodable(rhsValue)
            }
        default:
            return false
        }
    }

    // MARK: - Convenience Accessors

    var boolValue: Bool? { value as? Bool }
    var intValue: Int? { value as? Int }
    var doubleValue: Double? { value as? Double }
    var floatValue: Float? { (value as? Double).map { Float($0) } ?? (value as? Float) }
    var stringValue: String? { value as? String }
    var arrayValue: [Any]? { value as? [Any] }
    var dictionaryValue: [String: Any]? { value as? [String: Any] }
}

// MARK: - ExpressibleBy Protocols

extension AnyCodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self.value = NSNull()
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Any...) {
        self.value = elements
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, Any)...) {
        self.value = Dictionary(uniqueKeysWithValues: elements)
    }
}

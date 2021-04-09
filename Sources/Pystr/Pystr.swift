import Foundation

public protocol PyStrComapatible {
    associatedtype CompatibleType

    var py: CompatibleType { get }
}

public final class PyStrExtension<Base> {
    private let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public extension PyStrComapatible {
    var py: PyStrExtension<Self> {
        return PyStrExtension(self)
    }
}

extension String: PyStrComapatible { }

extension PyStrExtension where Base == String {
    enum Exception: Error {
        case ValueError(String)
        case IndexError(String)
        case TypeError(String)
    }

    private func substr(_ start: Int, _ end: Int) -> String {
        let lower = base.index(base.startIndex, offsetBy: start)
        let upper = base.index(base.startIndex, offsetBy: end)
        return String(base[lower..<upper])
    }

    private func get_offset(_ value: Int?, _ vdefault: Int, _ size: Int) -> Int {
        var valueInt = value.map({ $0 }) ?? vdefault
        if valueInt < 0 {
            valueInt += size
        }
        return min(max(valueInt, 0), size)
    }

    private func slice_onestep(_ start: Int?, _ end: Int?) -> String {
        let size = base.count

        if start.map({ $0 == 0 }) ?? true &&
            end.map({ $0 == size }) ?? true {
            return base
        }

        let startValue = get_offset(start, 0, size)
        let endValue = get_offset(end, size, size)
        if startValue < endValue {
            return substr(startValue, endValue)
        } else {
            return ""
        }
    }

    /**
     * str.__add__() of python
     */
    func add(_ value: String) -> String {
        return base + value
    }

    /**
     * str.__contains__() of python
     */
    func contains(_ key: String) -> Bool {
        if !key.isEmpty {
            return base.contains(key)
        } else {
            return true
        }
    }

    /**
     * str.__eq__() of python
     */
    func eq(_ value: String) -> Bool {
        return base == value
    }

    /**
     * str.__ge__() of python
     */
    func ge(_ value: String) -> Bool {
        return base >= value
    }

    /**
     * str.__getitem__() of python
     */
    func getitem(_ key: Int) throws -> String {
        let size = base.count
        let newKey = (key >= 0) ? key : key + size
        if !(0..<size).contains(newKey) {
            throw Exception.IndexError("string index out of range")
        }

        if newKey < size {
            return substr(newKey, newKey + 1)
        } else {
            return ""
        }
    }

    /**
     * str[start:end:step] of python
     * 
     * to call str[:end:], define first argument as nil like str.py.slice(nil, end)
     */
    func slice(_ start: Int?, _ end: Int? = nil, _ step: Int? = nil) throws -> String {
        let size = base.count

        if start.map({ $0 == 0 }) ?? true &&
            end.map({ $0 == size }) ?? true &&
            step.map({ $0 == 1 }) ?? true {
            return base
        }

        // set step
        let stepInt: Int = step.map({ $0 }) ?? 1
        if stepInt == 0 {
            throw Exception.ValueError("slice step cannot be zero")
        }

        // set start
        var startInt: Int
        if let value = start {
            startInt = (value >= 0) ? value : value + size
        } else {
            startInt = (stepInt > 0) ? 0 : size - 1
        }
        if !(0...size).contains(startInt) { // clamp if needed
            startInt = min(max(startInt, 0), size) + ((stepInt > 0) ? 0 : -1)
        }

        // set end
        var endInt: Int
        if let value = end {
            endInt = (value >= 0) ? value : value + size
        } else {
            endInt = (stepInt > 0) ? size : -1
        }
        if !(0...size).contains(endInt) { // clamp if needed
            endInt = min(max(endInt, 0), size) + ((stepInt > 0) ? 0 : -1)
        }

        if stepInt == 1 {
            if startInt <= endInt {
                return substr(startInt, endInt)
            } else {
                return ""
            }
        } else {
            var retval = ""
            var index = startInt
            while (stepInt > 1) ? (index < endInt) : (index > endInt) {
                retval += substr(index, index + 1)
                index += stepInt
            }
            return retval
        }
    }

    /**
     * str.__gt__() of python
     */
    func gt(_ value: String) -> Bool {
        return base > value
    }

    /**
     * str.__le__() of python
     */
    func le(_ value: String) -> Bool {
        return base <= value
    }

    /**
     * str.__len__() of python
     */
    func len() -> Int {
        if base.contains("\r\n") {
            return len0D0A(base)
        }

        return base.count
    }

    /**
     * str.__lt__() of python
     */
    func lt(_ value: String) -> Bool {
        return base < value
    }

    /**
     * str.__mul__() of python
     */
    func mul(_ value: Int) -> String {
        if value >= 0 {
            return String(repeating: base, count: value)
        } else {
            return ""
        }
    }

    /**
     * str.__ne__() of python
     */
    func ne(_ value: String) -> Bool {
        return base != value
    }

    /**
     * str.__repr__() of python
     * 
     * support only plain ascii
     */
    func repr() -> String {
        var retval = ""

        // escape characters
        let ESC: [String.Element: String] = [
            "\t": "\\t", "\n": "\\n", "\r": "\\r", "\\": "\\\\"
        ]
        for element in base {
            if let escaped = ESC[element] {
                retval += escaped
            } else {
                retval += String(element)
            }
        }

        // append quotations
        if retval.range(of: "'") == nil {
            retval = "'" + retval + "'"
        } else {
            if retval.range(of: "\"") == nil {
                retval = "\"" + retval + "\""
            } else {
                retval = "'" + retval.replacingOccurrences(of: "'", with: "\\'") + "'"
            }
        }

        return retval
    }

    /**
     * str.__rmul__() of python
     */
    func rmul(_ value: Int) -> String {
        return mul(value)
    }

    /**
     * str.capitalize() of python
     */
    func capitalize() -> String {
        let size = base.count
        if size == 0 {
            return ""
        } else if size == 1 {
            return base.uppercased()
        } else {
            return substr(0, 1).uppercased() + substr(1, size).lowercased()
        }
    }

    /**
     * str.casefold() of python
     */
    func casefold() -> String {
        return base.lowercased()
    }

    /**
     * str.center() of python
     *
     * the behavior of str.centor() is little bit strange.
     * see http://bugs.python.org/issue23624
     */
    func center(_ width: Int, _ fillchar: String = " ") throws -> String {
        if fillchar.count != 1 {
            throw Exception.TypeError("The fill character must be exactly one character long")
        }

        if base.count >= width {
            return base
        }

        var retval = fillchar.py.mul(width)
        let fillSize = width - base.count
        var offset = fillSize / 2
        if (fillSize % 2 != 0) && (base.count % 2 == 0) {
            // special adjustment
            offset = (fillSize + 1) / 2
        }
        let lower = retval.index(retval.startIndex, offsetBy: offset)
        let upper = retval.index(retval.startIndex, offsetBy: offset + base.count)
        retval.replaceSubrange(lower..<upper, with: base)
        return retval
    }

    /**
     * str.count() of python
     */
    func count(_ sub: String, _ start: Int? = nil, _ end: Int? = nil) -> Int {
        if sub.isEmpty {
            return slice_onestep(start, end).count + 1
        }

        var counter = 0
        var index = find(sub, start, end)
        while index != -1 {
            counter += 1
            index = find(sub, index + sub.count, end)
        }
        return counter
    }

    /**
     * str.endswith() of python
     */
    func endswith(_ prefix: String, _ start: Int? = nil, _ end: Int? = nil) -> Bool {
        return slice_onestep(start, end).hasSuffix(prefix)
    }

    /**
     * str.endswith() of python
     */
    func endswith(_ prefix: [String], _ start: Int? = nil, _ end: Int? = nil) -> Bool {
        return prefix.contains { endswith($0, start, end) }
    }

    /**
     * str.expandtabs() of python
     */
    func expandtabs(_ tabsize: Int = 8) -> String {
        if tabsize <= 0 {
            return base.replacingOccurrences(of: "\t", with: "")
        }

        var str = ""
        var currentSize = tabsize

        for element in base {
            if element == "\t" {
                str.append(String(repeating: " ", count: currentSize))
                currentSize = tabsize
            } else if element == "\r" || element == "\n" {
                str.append(element)
                currentSize = tabsize
            } else {
                str.append(element)
                currentSize = (currentSize > 1) ? currentSize - 1 : tabsize
            }
        }

        return str
    }

    /**
     * str.find() of python
     */
    func find(_ sub: String, _ start: Int? = nil, _ end: Int? = nil) -> Int {
        let startOffset = get_offset(start, 0, base.count)
        if sub.isEmpty {
            let valueStart = start.map({ $0 }) ?? 0
            if (-base.count...base.count).contains(valueStart) {
                return startOffset
            } else if valueStart < -base.count {
                return 0
            } else {
                return -1
            }
        } else {
            let str = slice_onestep(start, end)
            if let range = str.range(of: sub) {
                return str.distance(from: str.startIndex, to: range.lowerBound) + startOffset
            } else {
                return -1
            }
        }
    }

    /**
     * str.index() of python
     */
    func index(_ sub: String, _ start: Int? = nil, _ end: Int? = nil) throws -> Int {
        let found = find(sub, start, end)
        if found != -1 {
            return found
        } else {
            throw Exception.ValueError("substring not found")
        }
    }

    /**
     * str.isalnum() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isalnum() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isNumber || $0.isCased })
    }

    /**
     * str.isalpha() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isalpha() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isCased })
    }

    /**
     * str.isascii() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isascii() -> Bool {
        return base.allSatisfy({ $0.isASCII })
    }

    /**
     * str.isdecimal() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isdecimal() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isNumber })
    }

    /**
     * str.isdigit() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isdigit() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isNumber })
    }

    /**
     * str.islower() of python
     *
     * non-ascii characters are not tested enough.
     */
    func islower() -> Bool {
        return base.allSatisfy({ !$0.isUppercase }) &&
            base.contains(where: { $0.isLowercase })
    }

    /**
     * str.isnumeric() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isnumeric() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isNumber })
    }

    /**
     * str.isprintable() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isprintable() -> Bool {
        let range: Range<Character> = "\u{0020}"..<"\u{007f}"
        return base.allSatisfy({ range ~= $0 })
    }

    /**
     * str.isspace() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isspace() -> Bool {
        return !base.isEmpty && base.allSatisfy({ $0.isWhitespace })
    }

    /**
     * str.istitle() of python
     *
     * non-ascii characters are not tested enough.
     */
    func istitle() -> Bool {
        return !base.isEmpty &&
            zip(" " + base, base).allSatisfy({
                $0.isCased ? !$1.isUppercase: !$1.isLowercase
            })
    }

    /**
     * str.isupper() of python
     *
     * non-ascii characters are not tested enough.
     */
    func isupper() -> Bool {
        return base.allSatisfy({ !$0.isLowercase }) &&
            base.contains(where: { $0.isUppercase })
    }

    /**
     * str.join() of python
     */
    func join(_ strs: [String]) -> String {
        return strs.joined(separator: base)
    }

    /**
     * str.ljust() of python
     */
    func ljust(_ width: Int, _ fillchar: String = " ") throws -> String {
        if fillchar.count != 1 {
            throw Exception.TypeError("The fill character must be exactly one character long")
        }

        return base + fillchar.py.mul(width - base.count)
    }

    /**
     * str.lower() of python
     */
    func lower() -> String {
        return base.lowercased()
    }

    /**
     * str.lstrip() of python
     */
    func lstrip(_ chars: String? = nil) -> String {
        let chars = chars.map({ $0 }) ?? " "

        var start = 0
        for element in base {
            if chars.range(of: String(element)) != nil {
                start += 1
            } else {
                break
            }
        }
        return substr(start, base.count)
    }

    /**
     * str.partition() of python
     */
    func partition(_ sep: String) throws -> [String] {
        if sep.isEmpty {
            throw Exception.ValueError("empty separator")
        }

        let pos = find(sep)
        if pos != -1 {
            return [substr(0, pos),
                    substr(pos, pos + sep.count),
                    substr(pos + sep.count, base.count)]
        } else {
            return [base, "", ""]
        }
    }

    /**
     * str.replace() of python
     */
    func replace(_ old: String, _ new: String, _ count: Int = -1) -> String {
        if old.isEmpty {
            var retval = new
            for element in base {
                retval += String(element) + new
            }
            return retval
        }

        var pos = 0
        var times = 0
        var retval = ""
        while times < count || count < 0 {
            let prevPos = pos
            pos = find(old, pos)
            if pos >= 0 {
                retval += substr(prevPos, pos) + new
                pos += old.count
                times += 1
            } else {
                retval += substr(prevPos, base.count)
                break
            }
        }
        if times == count {
            retval += substr(pos, base.count)
        }
        return retval
    }

    /**
     * str.rfind() of python
     */
    func rfind(_ sub: String, _ start: Int? = nil, _ end: Int? = nil) -> Int {
        if sub.isEmpty {
            let valueEnd = end.map({ $0 }) ?? 0
            if (-base.count...base.count).contains(valueEnd) {
                return self.get_offset(end, base.count, base.count)
            } else if valueEnd < -base.count {
                return 0
            } else {
                return -1
            }
        } else {
            let str = self.slice_onestep(start, end)
            if let range = str.range(of: sub, options: String.CompareOptions.backwards) {
                let startOffset = self.get_offset(start, 0, base.count)
                return str.distance(from: str.startIndex, to: range.lowerBound) + startOffset
            } else {
                return -1
            }
        }
    }

    /**
     * str.rindex() of python
     */
    func rindex(_ sub: String, _ start: Int? = nil, _ end: Int? = nil) throws -> Int {
        let found = self.rfind(sub, start, end)
        if found != -1 {
            return found
        } else {
            throw Exception.ValueError("substring not found")
        }
    }

    /**
     * str.rjust() of python
     */
    func rjust(_ width: Int, _ fillchar: String = " ") throws -> String {
        if fillchar.count != 1 {
            throw Exception.TypeError("The fill character must be exactly one character long")
        }

        return fillchar.py.mul(width - base.count) + base
    }

    /**
     * str.rpartition() of python
     */
    func rpartition(_ sep: String) throws -> [String] {
        if sep.isEmpty {
            throw Exception.ValueError("empty separator")
        }

        let pos = rfind(sep)
        if pos != -1 {
            return [substr(0, pos),
                    substr(pos, pos + sep.count),
                    substr(pos + sep.count, base.count)]
        } else {
            return ["", "", base]
        }
    }

    /**
     * str.rsplit() of python
     */
    func rsplit(_ sep: String? = nil, _ maxsplit: Int = -1) throws -> [String] {
        let valSep = sep.map({ $0 }) ?? " "
        if valSep.isEmpty {
            throw Exception.ValueError("empty separator")
        }

        var ret: [String] = []
        var start = base.count
        var end = self.rfind(valSep, 0, start)
        var times = maxsplit >= 0 ? maxsplit : Int.max

        while end != -1 && times > 0 {
            let trim = substr(end + valSep.count, start)
            if sep != nil || trim != "" {
                ret.insert(trim, at: 0)
                times -= 1
            }
            start = end
            end = self.rfind(valSep, 0, start)
        }

        if sep != nil {
            ret.insert(substr(0, start), at: 0)
        } else {
            let trim = substr(0, start).py.rstrip(" ")
            if trim != "" {
                ret.insert(trim, at: 0)
            }
        }

        return ret
    }

    /**
     * str.rstrip() of python
     */
    func rstrip(_ chars: String? = nil) -> String {
        let chars = chars.map({ $0 }) ?? " "

        var end = base.count
        for element in base.reversed() {
            if chars.range(of: String(element)) != nil {
                end -= 1
            } else {
                break
            }
        }
        return substr(0, end)
    }

    /**
     * str.split() of python
     */
    func split(_ sep: String? = nil, _ maxsplit: Int = -1) throws -> [String] {
        let valSep = sep.map({ $0 }) ?? " "
        if valSep.isEmpty {
            throw Exception.ValueError("empty separator")
        }

        var ret: [String] = []
        var start = 0
        var end = self.find(valSep, start)
        var times = maxsplit >= 0 ? maxsplit : Int.max

        while end != -1 && times > 0 {
            let trim = substr(start, end)
            if sep != nil || trim != "" {
                ret.append(trim)
                times -= 1
            }
            start = end + valSep.count
            end = self.find(valSep, start)
        }

        if sep != nil {
            ret.append(substr(start, base.count))
        } else {
            let trim = substr(start, base.count).py.lstrip(" ")
            if trim != "" {
                ret.append(trim)
            }
        }

        return ret
    }

    /**
     * str.splitlines() of python
     */
    func splitlines(_ keepends: Bool = false) -> [String] {
        let returnCodes = ["\r\n", "\r", "\n"]

        var ret: [String] = []
        var tmp = ""
        for element in base {
            let char = String(element)
            let ends = returnCodes.contains(char)

            if !ends || (ends && keepends) {
                tmp += char
            }

            if ends {
                ret.append(tmp)
                tmp.removeAll()
            }
        }
        if tmp != "" {
            ret.append(tmp)
        }
        return ret
    }

    /**
     * str.startswith() of python
     */
    func startswith(_ prefix: String, _ start: Int? = nil, _ end: Int? = nil) -> Bool {
        return self.slice_onestep(start, end).hasPrefix(prefix)
    }

    /**
     * str.startswith() of python
     */
    func startswith(_ prefix: [String], _ start: Int? = nil, _ end: Int? = nil) -> Bool {
        return prefix.contains { self.startswith($0, start, end) }
    }

    /**
     * str.strip() of python
     */
    func strip(_ chars: String? = nil) -> String {
        return rstrip(chars).py.lstrip(chars)
    }

    /**
     * str.swapcase() of python
     */
    func swapcase() -> String {
        var retval = ""
        for element in base {
            if element.isLowercase {
                retval += String(element.uppercased())
            } else if element.isUppercase {
                retval += String(element.lowercased())
            } else {
                retval += String(element)
            }
        }
        return retval
    }

    /**
     * str.title() of python
     *
     * non-ascii characters are not tested enough.
     */
    func title() -> String {
        var retval = ""
        for (pre, cur) in zip(" " + base, base) {
            retval += String(pre.isCased ? cur.lowercased() : cur.uppercased())
        }
        return retval
    }

    /**
     * str.upper() of python
     */
    func upper() -> String {
        return base.uppercased()
    }

    /**
     * str.zfill() of python
     *
     */
    func zfill(_ width: Int) -> String {
        let middleIndex = startswith(["-", "+"]) ? 1 : 0
        return substr(0, middleIndex) +
               "0".py.mul(width - base.count) +
               substr(middleIndex, base.count)
    }

}

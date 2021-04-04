import Foundation

public func len0D0A(_ str: String) -> Int {
    var ret = 0
    for element in str {
        ret += (String(element) != "\r\n") ? 1 : 2
    }
    return ret
}

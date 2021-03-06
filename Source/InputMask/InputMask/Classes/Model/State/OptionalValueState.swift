//
//  InputMask
//
//  Created by Egor Taflanidi on 17.08.28.
//  Copyright © 28 Heisei Egor Taflanidi. All rights reserved.
//

import Foundation


/**
 ### OptionalValueState
 
 Represents optional characters in square brackets [].
 
 Accepts any characters, but puts into the result string only the characters of own type (see ```StateType```).
 
 Returns accepted characters of own type as an extracted value.
 
 - seealso: ```OptionalValueState.StateType```
 */
class OptionalValueState: State {
    
    /**
     ### StateType
     
     * ```Numeric``` stands for [9] characters
     * ```Literal``` stands for [a] characters
     * ```AlphaNumeric``` stands for [-] characters
     */
    enum StateType {
        case Numeric
        case Literal
        case AlphaNumeric
    }
    
    let type: StateType
    
    func accepts(character char: Character) -> Bool {
        switch self.type {
            case .Numeric:
                return CharacterSet.decimalDigits.isMember(character: char)
            case .Literal:
                return CharacterSet.letters.isMember(character: char)
            case .AlphaNumeric:
                return CharacterSet.alphanumerics.isMember(character: char) || char == "." || char == "@"
        }
    }
    
    override func accept(character char: Character) -> Next? {
        if self.accepts(character: char) {
            return Next(
                state: self.nextState(),
                insert: char,
                pass: true,
                value: char
            )
        } else {
            return Next(
                state: self.nextState(),
                insert: nil,
                pass: false,
                value: nil
            )
        }
    }
    
    /**
     Constructor.
     
     - parameter child: next ```State```
     - parameter type: type of the accepted characters
     
     - seealso: ```OptionalValueState.StateType```
     
     - returns: Initialized ```OptionalValueState``` instance.
     */
    init(
        child: State,
        type: StateType
        ) {
        self.type = type
        super.init(child: child)
    }
    
    override var debugDescription: String {
        get {
            switch self.type {
                case .Literal:
                    return "[a] -> " + (nil != self.child ? self.child!.debugDescription : "nil")
                case .Numeric:
                    return "[9] -> " + (nil != self.child ? self.child!.debugDescription : "nil")
                case .AlphaNumeric:
                    return "[-] -> " + (nil != self.child ? self.child!.debugDescription : "nil")
            }
        }
    }
    
}

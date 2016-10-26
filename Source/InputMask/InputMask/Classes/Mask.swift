//
//  InputMask
//
//  Created by Egor Taflanidi on 10.08.28.
//  Copyright © 28 Heisei Egor Taflanidi. All rights reserved.
//

import Foundation


/**
 ### Mask
 
 Iterates over user input. Creates formatted strings from it. Extracts value specified by mask format.
 
 Provided mask format string is translated by the ```Compiler``` class into a set of states, which define the formatting
 and value extraction.
 
 - seealso: ```Compiler```, ```State``` and ```CaretString``` classes.
 */
public class Mask {
    
    /**
     ### Result
     
     The end result of mask application to the user input string.
     */
    public struct Result {
        public let formattedText:  CaretString
        public let extractedValue: String
    }
    
    private let initialState: State
    private static var cache: [String : Mask] = [:]
    
    /**
     Constructor.
     
     - parameter format: mask format.
     
     - returns: Initialized ```Mask``` instance.
     
     - throws: ```CompilerError``` if format string is incorrect.
     */
    public required init(format: String) throws {
        self.initialState = try Compiler().compile(formatString: format)
    }
    
    /**
     Constructor.
     
     Operates over own ```Mask``` cache where initialized ```Mask``` objects are stored under corresponding format key:
     ```[format : mask]```
     
     - returns: Previously cached ```Mask``` object for requested format string. If such it doesn't exist in cache, the
     object is constructed, cached and returned.
     */
    public static func getOrCreate(withFormat format: String) throws -> Mask {
        if let cachedMask: Mask = cache[format] {
            return cachedMask
        } else {
            let mask: Mask = try Mask(format: format)
            cache[format] = mask
            return mask
        }
    }
    
    /**
     Apply mask to the user input string.
     
     - parameter toText: user input string with current cursor position
     
     - returns: Formatted text with extracted value an adjusted cursor position.
     */
    public func apply(toText text: CaretString, autocomplete: Bool = false) -> Result {
        let iterator: CaretStringIterator = CaretStringIterator(caretString: text)
        
        var extractedValue:         String  = ""
        var modifiedString:         String  = ""
        var modifiedCaretPosition:  Int     =
            text.string.distance(from: text.string.startIndex, to: text.caretPosition) 
        
        var state: State = self.initialState
        var beforeCaret: Bool = iterator.beforeCaret()
        var character: Character? = iterator.next()
        
        while let char: Character = character {
            if let next: Next = state.accept(character: char) {
                state = next.state
                modifiedString += nil != next.insert ? String(next.insert!) : ""
                extractedValue += nil != next.value  ? String(next.value!)  : ""
                if next.pass {
                    beforeCaret = iterator.beforeCaret()
                    character   = iterator.next()
                } else {
                    if beforeCaret && nil != next.insert {
                        modifiedCaretPosition += 1
                    }
                }
            } else {
                if beforeCaret {
                    modifiedCaretPosition -= 1
                }
                beforeCaret = iterator.beforeCaret()
                character   = iterator.next()
            }
        }
        
        while autocomplete && beforeCaret, let next: Next = state.autocomplete() {
            state = next.state
            modifiedString += nil != next.insert ? String(next.insert!) : ""
            extractedValue += nil != next.value  ? String(next.value!)  : ""
            if nil != next.insert {
                modifiedCaretPosition += 1
            }
        }
        
        return Result(
            formattedText: CaretString(
                string: modifiedString,
                caretPosition: modifiedString.index(modifiedString.startIndex, offsetBy: modifiedCaretPosition)
            ),
            extractedValue: extractedValue
        )
    }
    
    /**
     Generate placeholder.
     
     - returns: Placeholder string.
     */
    public func placeholder() -> String {
        return self.appendPlaceholder(withState: self.initialState, placeholder: "")
    }
    
    /**
     Minimal length of the text inside the field to fill all mandatory characters in the mask.
     
     - returns: Minimal satisfying count of characters inside the text field.
     */
    public func acceptableTextLength() -> Int {
        var state: State? = self.initialState
        var length: Int = 0
        while let s: State = state, !(state is EOLState) {
            if s is FixedState || s is FreeState || s is ValueState {
                length += 1
            }
            state = s.child
        }
        
        return length
    }
    
    /**
     Maximal length of the text inside the field.
     
     - returns: Total available count of mandatory and optional characters inside the text field.
     */
    public func totalTextLength() -> Int {
        var state: State? = self.initialState
        var length: Int = 0
        while let s: State = state, !(state is EOLState) {
            if s is FixedState || s is FreeState || s is ValueState || s is OptionalValueState {
                length += 1
            }
            state = s.child
        }
        
        return length
    }
    
    /**
     Minimal length of the extracted value with all mandatory characters filled.
     
     - returns: Minimal satisfying count of characters in extracted value.
     */
    public func acceptableValueLength() -> Int {
        var state: State? = self.initialState
        var length: Int = 0
        while let s: State = state, !(state is EOLState) {
            if s is FixedState || s is ValueState {
                length += 1
            }
            state = s.child
        }
        
        return length
    }
    
    /**
     Maximal length of the extracted value.
     
     - returns: Total available count of mandatory and optional characters for extracted value.
     */
    public func totalValueLength() -> Int {
        var state: State? = self.initialState
        var length: Int = 0
        while let s: State = state, !(state is EOLState) {
            if s is FixedState || s is ValueState || s is OptionalValueState {
                length += 1
            }
            state = s.child
        }
        
        return length
    }
    
}

private extension Mask {
    
    func appendPlaceholder(withState state: State?, placeholder: String) -> String {
        guard let state: State = state
        else { return placeholder }
        
        if state is EOLState {
            return placeholder
        }
        
        if let state = state as? FixedState {
            return self.appendPlaceholder(withState: state.child, placeholder: placeholder + String(state.ownCharacter))
        }
        
        if let state = state as? FreeState {
            return self.appendPlaceholder(withState: state.child, placeholder: placeholder + String(state.ownCharacter))
        }
        
        if let state = state as? OptionalValueState {
            switch state.type {
                case .AlphaNumeric:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "-")
                
                case .Literal:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "a")
                
                case .Numeric:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "0")
            }
        }
        
        if let state = state as? ValueState {
            switch state.type {
                case .AlphaNumeric:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "-")
                    
                case .Literal:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "a")
                    
                case .Numeric:
                    return self.appendPlaceholder(withState: state.child, placeholder: placeholder + "0")
            }
        }
        
        return placeholder
    }
    
}

// `Int16`, which is used in the VM, does not work with arrays. So we extend arrays to allow `Int16` simply by converting these to the larger `Int` type.

extension Array {
    
    subscript(_ i: T) -> Element {
        get {
            return self[Int(i) % Int(T.max)]
        } set {
            self[Int(i) % Int(T.max)] = newValue
        }
    }
    
}

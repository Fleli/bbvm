class BreadboardVM {
    
    
    var ir = 0
    var pc = 0
    
    var registers = [Int](repeating: 0, count: 8)
    
    var ram = [Int](repeating: 0, count: 1 << 15)
    
    
    func run(_ program: [Int]) {
        
        load(program)
        
        
        
    }
    
    
    private func load(_ program: [Int]) {
        
        for index in 0 ..< program.count {
            ram[index] = program[index]
        }
        
    }
    
    
}

class BreadboardVM {
    
    static let addressBound = 1 << 15   // Exclusive
    static let maximumNumberOfInstructions = 1_000_000
    
    var numberOfInstructions = 0
    
    var ir: T = 0
    var pc: T = 0
    
    var registers = [T](repeating: 0, count: 8)
    
    var ram = [T](repeating: 0, count: addressBound)
    
    
    func run(_ program: [T]) {
        
        load(program)
        
        while (self.numberOfInstructions < Self.maximumNumberOfInstructions) {
            numberOfInstructions += 1
            runInstruction()
        }
        
    }
    
    
    private func load(_ program: [T]) {
        
        for index in 0 ..< program.count {
            ram[index] = program[index]
        }
        
    }
    
    
    private func runInstruction() {
        
        let (opcode, srcA, srcB, dest, imm) = decodeInstruction()
        
        print("Decoded: \((opcode, srcA, srcB, dest, imm))")
        
        incrementPC()
        
        switch opcode {
        case 0x00:  // nop
            break
        case 0x01:  // mv %dst, %src
            registers[dest] = registers[srcA]
        case 0x02:  // li %dst, $imm
            registers[dest] = imm
            incrementPC()
        case 0x03:  // ldraw %dst, $imm
            registers[dest] = ram[imm]
            incrementPC()
        case 0x04:  // ldind %dst, %src
            registers[dest] = ram[registers[srcA]]
        case 0x05:  // ldio %dst, %base, $offs
            registers[dest] = ram[registers[srcA] &+ imm]
            incrementPC()
        case 0x06:  // stio %base, $offs, %val
            ram[registers[srcA] &+ imm] = registers[srcB]
            incrementPC()
        case 0x07:  // add %dst, %srcA, %srcB
            registers[dest] = registers[srcA] &+ registers[srcB]
        case 0x08:  // sub %dst, %srcA, %srcB
            registers[dest] = registers[srcA] &- registers[srcB]
        case 0x09:  // neg %dst, %src
            registers[dest] = ~registers[srcA] &+ 1
        case 0x0A:  // xor %dst, %srcA, %srcB
            registers[dest] = registers[srcA] ^ registers[srcB]
        case 0x0B:  // nand %dst, %srcA, %srcB
            registers[dest] = ~(registers[srcA] & registers[srcB])
        case 0x0C:  // and %dst, %srcA, %srcB
            registers[dest] = registers[srcA] & registers[srcB]
        case 0x0D:  // or %dst, %srcA, %srcB
            registers[dest] = registers[srcA] | registers[srcB]
        case 0x0E:  // not %dst, %src
            registers[dest] = ~registers[srcA]
        case 0x0F:  // j %src
            pc = registers[srcA]
        case 0x10:  // jnz %src, $imm
            let changeToImm = { self.pc = imm }
            let function = (registers[srcA] != 0) ? changeToImm : incrementPC
            function()
        case 0x11:  // jimm $imm
            pc = imm
        case 0x12:  // addi %dst, %src, $imm
            registers[dest] = registers[srcA] &+ imm
            incrementPC()
        default:
            fatalError("Unrecognized opcode \(opcode) yields undefined behaviour. Terminating execution after \(numberOfInstructions) completed instructions.")
        }
        
    }
    
    
    private func decodeInstruction() -> (T, T, T, T, T) {
        
        let rawInstruction = ram[pc]
        
        // Extract opcode
        let opcode = rawInstruction >> 9
        
        // Extract source (readable) registers
        let srcA = (rawInstruction & 0b0000_0001_1100_0000) >> 6
        let srcB = (rawInstruction & 0b0000_0000_0011_1000) >> 3
        
        // Extract destination (writable) register
        let dest = rawInstruction & 0b0000_0000_0000_0111
        
        // Find immediate
        let imm = ram[pc &+ 1]
        
        return (opcode, srcA, srcB, dest, imm)
        
    }
    
    
    private func incrementPC() {
        pc = pc &+ 1
    }
    
    
}

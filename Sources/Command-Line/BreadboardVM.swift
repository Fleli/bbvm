class BreadboardVM {
    
    static let addressBound: T = 1 << 15   // Exclusive
    static var maximumNumberOfInstructions = 10
    
    static let trapRequestAddress: T = 2000
    
    static let mapping: [String] = ["nop", "mv", "li", "ldraw", "ldind", "ldio", "stio", "add", "sub", "neg", "xor", "nand", "and", "or", "not", "j", "jnz", "jimm", "addi", "st"]
    
    var numberOfInstructions = 0
    
    var pc: T = 0
    
    var registers = [T](repeating: 0, count: 8)
    
    var ram = RAM()
    
    var notHalted = true
    
    func run(_ program: [T], _ viewVerbose: Bool, _ viewShort: Bool, _ viewSubrange: Subrange?, _ viewFinal: Bool, _ vga: Bool) {
        
        load(program)
        
        if viewVerbose || viewShort {
            print("Starting execution with \(ram)")
            print("\n-----\n")
        }
        
        while (self.numberOfInstructions < Self.maximumNumberOfInstructions) && notHalted {
            numberOfInstructions += 1
            runInstruction(viewVerbose, viewShort)
        }
        
        if viewVerbose || viewShort || viewFinal {
            print("Execution finished.")
            print("\tregisters: \(registers)")
            print("\tpc: \(pc)")
            print(ram)
            print("Terminated after \(numberOfInstructions) instructions (Ceiling was \(Self.maximumNumberOfInstructions))")
        }
        
        if let viewSubrange {
            print(ram.delimitedDescription(T(viewSubrange.start), T(viewSubrange.end)))
        }
        
        print("\n--------------------------------------\n\nReturned from main\t\t\(ram[2046])\n\n--------------------------------------\n")
        
        if (self.numberOfInstructions >= Self.maximumNumberOfInstructions) {
            print("\nTERMINATED DUE TO LONG EXECUTION: \(self.numberOfInstructions)\n")
        }
        
    }
    
    
    private func load(_ program: [T]) {
        
        for index in 0 ..< program.count {
            ram[T(index)] = program[index]
        }
        
    }
    
    
    private func runInstruction(_ viewVerbose: Bool, _ viewShort: Bool) {
        
        let (opcode, srcA, srcB, dest, imm) = decodeInstruction()
        
        if (viewVerbose || viewShort) && opcode <= 0x13 {
            print(opcode, srcA, srcB, dest, imm)
            print("opcode:", opcode, "\t\t; \(Self.mapping[opcode])", "\nsrcA:", srcA, "\nsrcB:", srcB, "\ndest:", dest, "\nimm?:", imm)
            print("PC = \(pc)")
            print("Regs: \(registers)\n")
        }
        
        if viewVerbose {
            print(ram, "\n-----")
        }
        
        incrementPC()
        
        switch opcode {
        case 0x00:  // nop
            notHalted = false
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
        case 0x13:  // st %addr, %val
            ram[registers[srcA]] = registers[srcB]
        default:
            fatalError("Unrecognized opcode \(opcode) yields undefined behaviour. Terminating execution after \(numberOfInstructions) completed instructions.")
        }
        
        handleTrapRequest()
        
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
    
    
    private func handleTrapRequest() {
        
        let trapRequest = ram[Self.trapRequestAddress]
        
        guard trapRequest != 0 else {
            return
        }
        
        switch trapRequest {
            
        // print(char*)
        case 1:
            
            func arg(_ i: T) -> T? {
                let val = ram[Self.trapRequestAddress + i]
                return (val == 0) ? nil : val
            }
            
            var i: T = 0
            
            while i < Self.addressBound, let val = arg(i), let unicodeScalar = Unicode.Scalar(val) {
                
                let char = Character(unicodeScalar)
                print(char, terminator: "")
                
                i += 1
                
            }
            
        default:
            
            break
            
        }
        
        // Delete trap request.
        ram[Self.trapRequestAddress] = 0
        
    }
    
    
}

struct RAM: CustomStringConvertible {
    
    private var data = [T](repeating: 0, count: Int(BreadboardVM.addressBound))
    
    subscript(i: T) -> T {
        get {
            return data[i % BreadboardVM.addressBound]
        } set {
            data[i % BreadboardVM.addressBound] = newValue
        }
    }
    
    var description: String {
        return delimitedDescription(0, BreadboardVM.addressBound - 1)
    }
    
    func delimitedDescription(_ min: T, _ max: T) -> String {
        
        var str = "\tram: [\n"
        
        var index = min
        while index <= max {
            
            str += "\t\t[\(index)] \(self[index])\n"
            
            index += 1
            
            while self[index - 1] == 0 && self[index] == 0 && index <= max {
                index += 1
            }
            
        }
        
        str += "\t]"
        
        return str
        
    }
    
}

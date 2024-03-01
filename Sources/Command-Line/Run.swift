
import ArgumentParser


struct Subrange: ExpressibleByArgument {
    
    let start: Int
    let end: Int
    
    init?(argument: String) {
        
        print("Argument {\(argument)}")
        
        let parts = argument.split(separator: " ")
        
        guard parts.count == 2, let start = Int(parts[0]), let end = Int(parts[1]) else {
            return nil
        }
        
        self.start = start
        self.end = end
        
    }
    
}


struct Run: ParsableCommand {
    
    
    @ArgumentParser.Argument(help: "The executable's ('.bbx') file path.")
    var exePath: String
    
    
    @ArgumentParser.Flag(help: "View verbose state (including RAM) at every step.")
    var viewVerbose = false
    
    @ArgumentParser.Flag(help: "View shortened state (excluding RAM) at every step.")
    var viewShort = false
    
    @ArgumentParser.Option(help: "View a specific subrange of RAM at every step.")
    var viewSubrange: Subrange?
    
    @ArgumentParser.Flag(help: "View the final state of RAM and registers when execution terminates.")
    var viewFinal = false
    
    @ArgumentParser.Option(help: "Specify the maximum number of instructions the VM is allowed to execute.")
    var maxInstructions: Int = 100_000
    
    @ArgumentParser.Flag(help: "Open a window with a 200x150 pixels display similar to the VGA display the breadboard computer will use.")
    var vga: Bool = false
    
    
    func run() throws {
        
        let program = try fetchProgram()
        
        BreadboardVM.maximumNumberOfInstructions = self.maxInstructions
        let virtualMachine = BreadboardVM()
        virtualMachine.run(program, viewVerbose, viewShort, viewSubrange, viewFinal, vga)
        
    }
    
    
    private func fetchProgram() throws -> [T] {
        
        let text = try String(contentsOfFile: exePath)
        
        var code: [T] = []
        
        for (n, line) in text.split(separator: "\n").enumerated() {
            
            guard let int = Int(line) else {
                fatalError("Incorrect file format on line \(n + 1)")
            }
            
            if int >= 0 {
                code.append(T(int))
                continue
            }
            
            let positiveInt = T(-int)
            let twosComplement = ~positiveInt &+ 1
            
            code.append(twosComplement)
            
        }
        
        return code
        
    }
    
}

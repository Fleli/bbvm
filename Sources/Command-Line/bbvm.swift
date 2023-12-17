
import Foundation
import ArgumentParser

typealias T = UInt16

@main
struct bbvm: ParsableCommand {
    
    
    @ArgumentParser.Argument(help: "The executable's ('.bbx') file path.")
    var exePath: String
    
    
    func run() throws {
        
        let program = try fetchProgram()
        
        let virtualMachine = BreadboardVM()
        virtualMachine.run(program)
        
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


import Foundation
import ArgumentParser

@main
struct bbvm: ParsableCommand {
    
    
    @ArgumentParser.Argument(help: "The executable's ('.bbx') file path.")
    var exePath: String
    
    
    func run() throws {
        
        print("Path to file: {\(exePath)}")
        
        let program = try fetchProgram()
        
        let virtualMachine = BreadboardVM()
        virtualMachine.run(program)
        
    }
    
    
    private func fetchProgram() throws -> [Int] {
        
        let text = try String(contentsOfFile: exePath)
        
        var code: [Int] = []
        
        for (n, line) in text.split(separator: "\n").enumerated() {
            
            guard let int = Int(line) else {
                fatalError("Incorrect file format on line \(n + 1)")
            }
            
            code.append(int)
            
        }
        
        for n in code {
            print(n)
        }
        
        return code
        
    }
    
    
}

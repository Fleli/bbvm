
import Foundation
import ArgumentParser

typealias T = UInt16

@main
struct bbvm: ParsableCommand {
    
    
    static let configuration = CommandConfiguration(
        abstract: "Breadboard Virtual Machine (BBVM)",
        subcommands: [Version.self, Run.self]
    )
    
    
}

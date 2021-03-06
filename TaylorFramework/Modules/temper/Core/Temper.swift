//
//  Temper.swift
//  Temper
//
//  Created by Mihai Seremet on 8/28/15.
//  Copyright © 2015 Yopeso. All rights reserved.
//

import Foundation

final class Temper {
    
    var rules : [Rule]
    private let outputPath : String
    private var violations : [Violation]
    private var output : OutputCoordinator
    private var currentPath : String?
    private var reporters : [Reporter]
    
    static  var totalFiles = 0
    static  var filesWithViolations = 0
    static  var violationsWithP1 = 0
    static  var violationsWithP2 = 0
    static  var violationsWithP3 = 0
    private var fileWasChecked = false
    
    var resultsOutput = [ResultOutput]()
    
    var path : String {
        return outputPath
    }
    
    /**
        Temper module initializer
        
        If the path is wrong, the current directory path will be used as output path
    
        For reporter customization, call setReporters([Reporter]) method with needed reporters
        For rule customization, call setLimits([String:Int]) method with needed limits
        For check the content for violations, call checkContent(FileContent) method
        For finish and generate the reporters, call finishTempering() method
    
        :param: outputPath The output path when will be created the reporters
    */
    
    init(outputPath: String) {
        if !NSFileManager.defaultManager().fileExistsAtPath(outputPath) {
            print("Temper: Wrong output path! The current directory path will be used as output path!")
            self.outputPath = NSFileManager.defaultManager().currentDirectoryPath
        } else {
            self.outputPath = outputPath
        }
        rules = RulesFactory().getRules()
        violations = [Violation]()
        output = OutputCoordinator(filePath: outputPath)
        reporters = [Reporter(PMDReporter())]
    }
    
    /**
        This method check the content of file for violations
        
        For finish and generate the reporters, call finishTempering() method
    
        :param: content The content of file parsed in components
    */
    
    func checkContent(content: FileContent) {
        Temper.totalFiles++
        fileWasChecked = false
        currentPath = content.path
        let initialViolations = violations.count
        startAnalazy(content.components)
        
        resultsForFile(currentPath, violations: violations.count - initialViolations)
    }
    
    func resultsForFile(currentPath: String?, violations: Int) {
        guard let path = currentPath where path.characters.count > outputPath.characters.count else { return }
        let relativePath: String = (path as NSString).substringFromIndex(outputPath.characters.count + 1)
        resultsOutput.append(ResultOutput(path: relativePath,
            warnings: violations))
    }
    
    /**
        This method set the reporters. If method is not called, PMD reporter will be used as default.
        
        :param: reporters An array of reporters:
        * PMD (xml file)
        * JSON (json file)
        * Xcode (Xcode IDE warnings/error)
        * Plain (text file)
    */
    
    func setReporters(reporters : [Reporter]) {
        self.reporters = reporters
    }
    
    /**
        This method is called when there are no more content for checking. It will create the reporters and write the violations.
    */
    
    func finishTempering() {
        output.writeTheOutput(violations, reporters: reporters)
    }
    
    /**
        This method set the limits of the rules. The limits should be greather than 0
        
        :param: limits A dictionary with the rule name as key and unsigned int as value(the limit)
    */
    
    func setLimits(limits: [String:Int]) {
        rules = rules.map({ (var rule: Rule) -> Rule in
            if let limit = limits[rule.rule] {
                rule.limit = limit
            }
            return rule
        })
    }
    
    // Private methods
    
    private func startAnalazy(components: [Component]) {
        for component in components {
            for rule in rules {
                checkPair(rule: rule, component: component)
            }
            if !component.components.isEmpty {
                startAnalazy(component.components)
            }
        }
    }
    
    private func checkPair(rule rule: Rule, component: Component) {
        guard let path = currentPath else {
            return
        }
        let result = rule.checkComponent(component)
        if !result.isOk {
            var message = String()
            var value = 0
            if let msg = result.message {
                message = msg
            }
            if let val = result.value {
                value = val
            }
            violations.append(Violation(component: component, rule: rule, message: message, path: path, value: value))
            if !fileWasChecked {
                fileWasChecked = true
                Temper.filesWithViolations++
            }
            if let last = violations.last {
                switch last.rule.priority {
                case 1: Temper.violationsWithP1++
                case 2: Temper.violationsWithP2++
                case 3: Temper.violationsWithP3++
                default: break
                }
            }
        }
    }
}

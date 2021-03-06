//
//  Scissors.swift
//  Scissors
//
//  Created by Alexandru Culeva on 9/3/15.
//  Copyright © 2015 com.yopeso.aculeva. All rights reserved.
//

import Foundation
import SourceKittenFramework

struct Scissors {    
    /**
    Tokenizes contents of file at a given path by converting it to a tree of components.
    
    - parameter path: Absolute path to the file to be tokenized.
    
    - returns: **FileContent** containing 'path' to file and the tree of components.
    */
    func tokenizeFileAtPath(path: String) -> FileContent {
        guard NSFileManager.defaultManager().fileExistsAtPath(path) else {
            return FileContent(path: "", components: [])
        }
        let tree = Tree(file: File(path: path)!)
        let root = tree.makeTree()
        return FileContent(path: path, components: root.components)
    }
}

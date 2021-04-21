//
//  ViewController.swift
//  TesteHex
//
//  Created by Diego Cruz on 07/04/21.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var txtIn: NSTextField!
    @IBOutlet weak var txtOut: NSTextField!
    var strOut = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func actionBtn(_ sender: NSButton) {
        
        txtIn.stringValue = NSPasteboard.general.string(forType: .string) ?? "00"
        
        var control = 0
        var control16 = 0
        let text = txtIn.stringValue
        var textArray: [Character] = []
        for str in text {
            textArray.append(str)
        }
        
        strOut = "int dataSize = \(text.count / 2); \nbyte data[] = {\n"
        while (control < text.count) {
            strOut += "0x\(textArray[control])\(textArray[control+1])"
            control = control + 2
            
            if control < text.count {
                strOut.append(", ")
            }
            
            control16 += 1
            
            if control16 == 16 {
                strOut.append("\n")
                control16 = 0
            }
            
        }
        
        strOut.append("\n};")
        
        txtOut.stringValue = strOut
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(strOut, forType: .string)
    }
    
}


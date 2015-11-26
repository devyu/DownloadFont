//
//  ViewController.swift
//  DownloadFont
//
//  Created by mac on 11/21/15.
//  Copyright © 2015 JY. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var activityIndeicator: UIActivityIndicatorView!
    
    
    var fontNames   = [String]()
    var fontSamples = [String]()
    var errorMessage: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fontNames = [
            "STXingkai-SC-Light",
            "DFWaWaSC-W5",
            "FZLTXHK--GBK1-0",
            "STLibian-SC-Regular",
            "LiHeiPro",
            "HiraginoSansGB-W3",
        ]
        fontSamples = [
            "没错，我就是行楷字体",
            "我是娃娃字体，是不是很可爱？😄😄😄",
            "支援服务升级资讯专业制",
            "作创意空间快速无线上网",
            "兙兛兞兝兡兣嗧瓩糎",
            "㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩",
        ]
        
        
        textView.editable    = false
        
        tableView.dataSource = self
        tableView.delegate   = self
    }
    
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellID = "cellID"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellID)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellID)
        }

        cell!.textLabel?.text = fontNames[indexPath.row]
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        asynchronousSetFontsName(fontNames[indexPath.row])
        
    }
    
    
    private func asynchronousSetFontsName(fontName: String) {
        
        let aFont = UIFont(name: fontName, size: 12.0)
        
        // If the font is already download
        if let font = aFont {
            if (font.fontName.compare(fontName) == .OrderedSame ||
                font.familyName.compare(fontName) == .OrderedSame) {
                    if let sampleIndex = fontNames.indexOf(fontName) {
                        textView.text = fontSamples[sampleIndex]
                        textView.font = UIFont(name: fontName, size: 24.0)
                    }
                    return
            }
        }
        
        // Creat a dictionary with the font's PostScript name.
        let attrs = NSDictionary(object: fontName, forKey: kCTFontNameAttribute as String)
        // Creat a new font descriptor reference from the attributtes dictionary
        let desc = CTFontDescriptorCreateWithAttributes(attrs as CFDictionaryRef)
        
        var descs = NSMutableArray()
        descs = NSMutableArray(capacity: 0)
        descs.addObject(desc)
        
        CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) {
            (state: CTFontDescriptorMatchingState, progressParameter: CFDictionary) -> Bool in
            
//            print(" state == \(state), progress =  \(progressParameter)")
            
            let parameter = progressParameter as NSDictionary
            let progressValue = parameter.objectForKey(kCTFontDescriptorMatchingPercentage)?.doubleValue
            
            switch state {
            case .DidBegin:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activityIndeicator.startAnimating()
                    self.textView.text = "Downloading \(fontName)"
                    self.textView.font = UIFont.systemFontOfSize(12.0)
                    
                    print("Begin Matching")
                })
                
            case .DidFinish:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activityIndeicator.stopAnimating()
                    self.activityIndeicator.hidden = true
                    
                    // display the sample text for the newly downloaded font
                    if let index = self.fontNames.indexOf(fontName) {
                        self.textView.text = self.fontSamples[index]
                        self.textView.font = UIFont(name: fontName, size: 24.0)
                        
                        
                        // Log the font URL in the console
                        let font = CTFontCreateWithName(fontName, 0.0, nil)
                        let fontURL = CTFontCopyAttribute(font, kCTFontURLAttribute) as! NSURL
                        
                        print("FontURL: \(fontURL)")
                    }
                })
                
                
            case .WillBeginDownloading:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progress.progress = 0.0
                    self.progress.hidden = false
                    
                    print("Begin Downloading")
                })
                
            case .DidFinishDownloading:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progress.hidden = true
                    self.activityIndeicator.hidden = true
                    print("Finish Downloading")
                })
                
                
            case .Downloading:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progress.setProgress(Float(progressValue! / 100.0), animated: true)
                    
                    print("Downliading \(progressValue!) complete")
                })
                
            case .DidFailWithError:
                if let error = parameter.objectForKey(kCTFontDescriptorMatchingError) {
                    self.errorMessage = error.description!
                } else {
                    self.errorMessage = "Error message is not avilable!"
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progress.hidden = true
                    print("Download Error, msg: \(self.errorMessage)")
                })
            default:
                break
            }
            
            return true
        }
    }
}
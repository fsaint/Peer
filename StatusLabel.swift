//
//  StatusLabel.swift
//  
//
//  Created by Felipe Saint-jean on 7/3/15.
//
//

import UIKit



private
struct QueueElement {
    let color:UIColor
    let text:String
}


private
extension CGRect {
    func moveUp() -> CGRect {
        var copy = self
        copy.origin.y = copy.origin.y - copy.size.height
        return copy
    }
    
    func moveDown()-> CGRect {
        var copy = self
        copy.origin.y = copy.origin.y + copy.size.height
        return copy
    }

}

class StatusLabel: UIView {
    var label:UILabel?
    var changing = false
    private var queue:[QueueElement] = []
    
    
    func runQueue(){
        if queue.count == 0 || self.changing {
            return
        }
        

        
        let top = queue.removeAtIndex(0)
        
        
        self.setStatus(top)
        
    }
    
    func setStatus(text:String, color:UIColor = UIColor.blackColor()){
    
        let new_element = QueueElement(color: color, text: text)
        
        self.queue.append(new_element)
        
        self.runQueue()
    }
    
    
    private
    func setStatus(element:QueueElement){
        
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            assert(!self.changing, "Should not animate while changing")
            self.changing = true
            var new_label = UILabel(frame:self.bounds.moveDown())
            new_label.text = element.text
            new_label.font = UIFont(name: "Mobile Font", size: 22.0)
            new_label.textColor = element.color
            new_label.alpha = 0.0
            new_label.textAlignment = NSTextAlignment.Center
            self.addSubview(new_label)
            
            UIView.animateWithDuration(0.3, animations: {() -> Void in
                if let old = self.label {
                    old.frame = old.frame.moveUp()
                    old.alpha = 0.0
                }
                new_label.frame = new_label.frame.moveUp()
                new_label.alpha = 1.0
                
                }) { (finished:Bool) -> Void in
                    if let old = self.label{
                        old.removeFromSuperview()
                    }
                    self.changing = false
                    self.runQueue()
                    self.label = new_label
            }

        })
        
    }
}

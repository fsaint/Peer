//
//  OptionViewController.swift
//  
//
//  Created by Felipe Saint-jean on 7/2/15.
//
//

import UIKit



class OptionViewController: UIViewController, Peer{
    
    @IBOutlet weak var status_label: StatusLabel!
    
    override func viewDidLoad() {
        self.status_label.setStatus("Loading ...")
    }
    func message(message: String) {
        self.status_label.setStatus(message)
    }
}



class TeacherViewController: OptionViewController, TeacherSessionDelegate {
    var peer:TeacherAdvertiser?
    
    
    @IBOutlet weak var sent_image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.peer = TeacherAdvertiser(delegate: self, session_delegate: self)
        
        
        self.title = "Teacher"

        // Do any additional setup after loading the view.
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func disconnect(sender: AnyObject) {
        if let peer = self.peer{
            peer.close()
        }
    }
    
    func studentConnected(student:String){
        self.message("Student Connected \(student)")
    }
    func studentConnecting(student:String){
        self.message("Student is Connecting \(student)")
    
    }
    func studentDisConnected(student:String){
        self.message("Student Dis-connected \(student)")
    
    }
    func receivedImage(image:UIImage){
        self.sent_image.image = image
        
    }
    @IBAction func requestScreenShot(sender: AnyObject) {
        if let peer = self.peer {
            peer.requestScreenShot()
        }
       
    }
}



class StudentViewController: OptionViewController,StudentRoomBrowserDelegate, StudentSessionDelegate {
    var peer:StudentRoomBrowser?
    var student_session: StudentSession?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.peer = StudentRoomBrowser(delegate: self)
        self.title = "Student"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func disconnect(sender: AnyObject) {
        if let peer = self.peer{
           // peer.session_peer?.disconnect()
        }
    }


    func roomAvailable(room:AvailableRoom){
        self.message("Room Available \(room.number)")
        
        if let ss = self.student_session{
            ss.disconnect()
            ss.session_delegate = nil
        }
        
        self.student_session = self.peer?.connect(room, session_delegate: self)
    }
    func roomUnAvailable(room:AvailableRoom){
         self.message("Room Gone \(room.number)")
    
    }
    
    func connectingToRoom(room:AvailableRoom){
        self.message("Connecting to \(room.number)")
        
    }
    func connectedToRoom(room:AvailableRoom){
        self.message("Connected to \(room.number)")
    
    }
    func disconnectedFromRoom(room:AvailableRoom){
        self.message("Disconnected to \(room.number)")
    
    }

    
}

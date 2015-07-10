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



func croppIngimage(imageToCrop:UIImage, toRect rect:CGRect) -> UIImage{
    
    var imageRef:CGImageRef = CGImageCreateWithImageInRect(imageToCrop.CGImage, rect)
    var cropped:UIImage = UIImage(CGImage:imageRef)!
    return cropped
}
class TeacherViewController: OptionViewController, TeacherSessionDelegate {
    var peer:TeacherAdvertiser?
    
    var students:[String:UIView] = [:]
    
    
    @IBOutlet weak var sent_image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peer = TeacherAdvertiser(delegate: self, session_delegate: self)
        
        self.title = "Teacher"

        // Do any additional setup after loading the view.
    }
    
    
    func receivedMessage(student:String, type:MessageTypes, additional:[String: AnyObject]?){
        
    
    }
    
    override
    func viewDidAppear(animated: Bool) {
        
        /*
        var images:[UIImage] = []
        if let image = UIImage(named: "ryu.png"){
        for i in 0...3{
        let fi:CGFloat = CGFloat(i)
        let r = CGRectMake(0.0, fi * image.size.width/4, image.size.width/4, image.size.height)
        let cr = croppIngimage(image, toRect: r)//image.imageWithAlignmentRectInsets(ei)
        images.append(cr)
        }
        }
        
        self.sent_image.animationImages = images
        self.sent_image.animationDuration=0.1
        self.sent_image.animationRepeatCount = Int.max
        self.sent_image.startAnimating()
        */
    
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tappedStudentView(recognizer: UIGestureRecognizer){
        if let view  = recognizer.view as? UILabel {
            view.backgroundColor = UIColor.lightGrayColor()
            if let peer = self.peer, stundent = view.text {
                peer.pingStudent(stundent)
            }
        }
    }
    
    func viewForStundent(name:String) -> UIView {
        let existing = self.students[name]
        
        if let existing = existing {
            return existing
        }
        
    
        let new = UILabel(frame: CGRectMake(200.0 * CGFloat(self.students.count), self.view.bounds.size.height-200.0, 200.0, 200.0))
        new.text = name
        new.layer.cornerRadius = 100.0
        new.clipsToBounds = true
        new.textAlignment = NSTextAlignment.Center
        new.textColor = UIColor.whiteColor()
        new.backgroundColor = UIColor.grayColor()
        let tap = UITapGestureRecognizer(target: self, action: "tappedStudentView:")
        tap.numberOfTapsRequired = 1
        new.addGestureRecognizer(tap)
        new.userInteractionEnabled = true

        self.view.addSubview(new)
        self.students[name] = new
        
        
        return new
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        if let peer = self.peer{
            peer.close()
        }
    }
    
    func studentConnected(student:String){
        self.message("Student Connected \(student)")
        
        let student = self.viewForStundent(student)
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            student.backgroundColor = UIColor.blueColor()
        })
        
    }
    func studentConnecting(student:String){
        self.message("Student is Connecting \(student)")
        
        let student = self.viewForStundent(student)
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            student.backgroundColor = UIColor.yellowColor()
        })

    
        
        
    }
    func studentDisConnected(student:String){
        self.message("Student Dis-connected \(student)")
        let student = self.viewForStundent(student)
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            student.backgroundColor = UIColor.redColor()
         })
    
    }
    func receivedImage(image:UIImage){
        self.sent_image.image = image
        
    }
    func receivedPingBack(stident: String) {
        
        let student = self.viewForStundent(stident)
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            student.backgroundColor = UIColor.blueColor()
        })
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
        self.peer?.peerDelegate = self
        self.title = "Student"

    }
    
    @IBAction func pingMaster(sender: UIButton) {
        
        if let ssession = self.student_session {
            ssession.pingMaster()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func disconnect(sender: AnyObject) {
        if let student_session = self.student_session{
            student_session.disconnect()
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
        self.message("Gonna Try and Reconnect")
        
        // reconnect
        
        self.peer = StudentRoomBrowser(delegate: self)
        self.peer?.peerDelegate = self
    
    }

    
}

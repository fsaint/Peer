    //
//  StudentPeer.swift
//  
//
//  Created by Felipe Saint-jean on 7/2/15.
//
//

import UIKit
import MultipeerConnectivity
import AssetsLibrary

enum MessagesKeys : String, Printable {
    case MessageType = "message_type"
    case MessageImage = "message_image"
    
    
    var description : String {
        get {
            return self.rawValue
        }
    }
}
    
enum MessageTypes : String, Printable {
    case SendTakenScreenshot = "send_taken_screenshot_image"
    case SendRequestedScreenshot = "send_requested_screenshot_image"
    case RequestScreenShot = "request_screenshot"
    var description : String {
        get {
            return self.rawValue
        }
    }
}

    
class BasicPeer: NSObject {
    weak var peerDelegate: Peer?
    var session:MCSession
    
    func sendData(data:[String:NSCoding], peers:[MCPeerID]){
        let binary = NSKeyedArchiver.archivedDataWithRootObject(data)
        self.session.sendData(binary, toPeers: peers, withMode: MCSessionSendDataMode.Reliable, error: nil)
    }

    
    func message(message:String){
        println(message)
        if let peerDelegate = self.peerDelegate {
            peerDelegate.message(message)
        }
    
    }
    
    init(peerid:MCPeerID) {
        self.session = MCSession(peer: peerid, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        super.init()
        if let delegate = self as? MCSessionDelegate {
            self.session.delegate = delegate
        }
    }
    
    
    
    
}


public protocol StudentRoomBrowserDelegate: class {
    func roomAvailable(room:AvailableRoom)
    func roomUnAvailable(room:AvailableRoom)
}

public protocol StudentSessionDelegate: class {
    
    func connectingToRoom(room:AvailableRoom)
    func connectedToRoom(room:AvailableRoom)
    func disconnectedFromRoom(room:AvailableRoom)
}

enum StudentRoomBrowsertState{
    case Inactive
    case Searching
    case Error

}
    

enum StudentSessionStatus {
    case Connecting
    case Connected
    case Disconnected
    case Reconnecting
    case Error
}


public struct AvailableRoom {
    let number: String
    let peer:  MCPeerID
    let info: [NSObject : AnyObject]
}




class StudentSession: BasicPeer ,MCSessionDelegate {
    
    var room: AvailableRoom?
    
    weak var session_delegate:StudentSessionDelegate?
    //var observers = []
    var asset_library: ALAssetsLibrary
    var last_count:Int? = nil
    
    override
    init(peerid:MCPeerID) {
        self.asset_library = ALAssetsLibrary()
        super.init(peerid:peerid)
        self.setupNotifications()
    }
    
    @objc private func didTakeScreenshotNotification(notification: NSNotification){
        println("A Notification Happened \(notification.name)")
        self.updateImageCount()
    }
    
    @objc private func willResignActiveNotification(notification: NSNotification){
        println("A Notification Happened \(notification.name)")
        self.session.disconnect()
    }

    
    @objc private func didEnterBackground(notification: NSNotification){
        println("A Notification Happened \(notification.name)")
    }
    
    @objc private func assetChanged(notification: NSNotification){
        println("A Notification Happened \(notification.name)")
        
        
        
        
        if self.last_count != nil {
            self.sendNewImageInCameraRoll()
        }
        
    }

    
    func setupNotifications(){
        
        
        // This will make the Image notifications work
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEnterBackground:" as Selector, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willResignActiveNotification:" as Selector, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didTakeScreenshotNotification:" as Selector, name: UIApplicationUserDidTakeScreenshotNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "assetChanged:" as Selector, name: ALAssetsLibraryChangedNotification
, object: nil)

    }
    
    func removeNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    func updateImageCount(){
        self.asset_library.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupSavedPhotos), usingBlock: { (group: ALAssetsGroup!, finish: UnsafeMutablePointer<ObjCBool>) -> Void in
            if group != nil {
                group.setAssetsFilter(ALAssetsFilter.allPhotos())
                self.last_count = group.numberOfAssets()
            }
            
            }) { (error: NSError!) -> Void in
                
        }
        
    }

    
    
    func sendNewImageInCameraRoll(){
        
        self.asset_library.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupSavedPhotos), usingBlock: { (group: ALAssetsGroup!, finish: UnsafeMutablePointer<ObjCBool>) -> Void in
            if group != nil {
                group.setAssetsFilter(ALAssetsFilter.allPhotos())
                
                if self.last_count != nil && self.last_count < group.numberOfAssets() {
                    
                    group.enumerateAssetsAtIndexes(NSIndexSet(index: group.numberOfAssets()-1), options: NSEnumerationOptions.allZeros, usingBlock: { (asset: ALAsset!, index: Int, inner_finish: UnsafeMutablePointer<ObjCBool>) -> Void in
                        if asset != nil && self.last_count != nil {
                            
                            let repo = asset.defaultRepresentation()
                            let cg = repo.fullScreenImage().takeUnretainedValue()
                            let image = UIImage(CGImage: cg)
                            
                            if let image = image {
                                if (self.last_count != nil){
                                    println("Sending image \(self.last_count)")
                                    inner_finish.memory = ObjCBool(true)
                                    self.last_count = nil
                                    self.sendImage(image)
                                }
                                
                            }
                        }
                    })
                }
            }
            
            }) { (error: NSError!) -> Void in
            
        }
        
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        
        if peerID != self.room?.peer{
            println("Not sure if this should happen. If it can I should ignore it")
            return
        }
        
        
        
        switch state{
            case .Connected:
                self.message("\(peerID.displayName) Connected")
                if let session_delegate = self.session_delegate {
                    if let room = self.room{
                        session_delegate.connectedToRoom(room)
                    }
                }
            case .Connecting:
                self.message("\(peerID.displayName) Connecting")
                if let session_delegate = self.session_delegate {
                    if let room = self.room{
                        session_delegate.connectingToRoom(room)
                    }
                }
            
            case .NotConnected:
                self.message("\(peerID.displayName) NotConnected")
                if let session_delegate = self.session_delegate {
                    if let room = self.room{
                        session_delegate.disconnectedFromRoom(room)
                    }
                }
        }
               
    }
    
    func sendImage(image:UIImage){
    
        let imgData = UIImageJPEGRepresentation(image, 0.5)
        
        if let master = self.room?.peer{
            self.sendData([MessagesKeys.MessageType.rawValue:MessageTypes.SendTakenScreenshot.rawValue,MessagesKeys.MessageImage.rawValue:imgData],peers: [master])
        }

    }
    
    func sendScreenShot(){
        let mainScreen = UIScreen.mainScreen()
        let root = UIApplication.sharedApplication().delegate?.window!?.rootViewController
        
        if let root = root{
            var size = mainScreen.nativeBounds.size
            
            if  UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation){
                size = CGSizeMake(size.height, size.width)
            }
            
            UIGraphicsBeginImageContext(size)
            root.view.layer.renderInContext(UIGraphicsGetCurrentContext())
            
            let image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            self.sendImage(image)
        }
        
        
        
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
      

        if let data = data, sd = self.session_delegate{
            //    let string_value = NSString(data: data, encoding: NSUTF8StringEncoding)
            if let r = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String:AnyObject] {
                println(r)
                if let message_type = r[MessagesKeys.MessageType.rawValue] as? String,  message = MessageTypes(rawValue: message_type) {
                    switch message {
                    case .SendTakenScreenshot:
                        println(message)
                    case .SendRequestedScreenshot:
                        println(message)
                    case .RequestScreenShot:
                        dispatch_async(dispatch_get_main_queue()){
                            self.sendScreenShot()
                        }
            
                        println(message)
                    }
                }
                
            }
            
        }

        
        self.message("Got Data")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        self.message("didFinishReceivingResourceWithName")
        
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        self.message("didStartReceivingResourceWithName")
        
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        self.message("Did Receive Stream")
    }
    
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        self.message("didReceiveCertificate")
        certificateHandler(true)
        
    }
    
    func disconnect(){
        session.disconnect()
        session.delegate = nil
    }
    
    deinit{
        session.disconnect()
        self.removeNotifications()
    }
    
}


class StudentRoomBrowser: BasicPeer, MCNearbyServiceBrowserDelegate {
    var browser:MCNearbyServiceBrowser
    var peerid:MCPeerID
    
    var state: StudentRoomBrowsertState = .Inactive
    var available_rooms:[String:AvailableRoom] = [:]
    
    
    weak var room_delegate:StudentRoomBrowserDelegate?
    
    init(delegate: StudentRoomBrowserDelegate?) {
        self.peerid = MCPeerID(displayName: "Student")
        self.browser = MCNearbyServiceBrowser(peer: self.peerid, serviceType: service)
        super.init(peerid: self.peerid)
        self.room_delegate = delegate
        self.browser.delegate = self
        self.browser.startBrowsingForPeers()
        self.message("Browsing ...")
        self.state =  .Searching
    }
    
    deinit{
        self.browser.stopBrowsingForPeers()
    }
    
    
    func connect(room:AvailableRoom, session_delegate:StudentSessionDelegate) -> StudentSession {
        self.message("Found Master Peer \(room.peer.displayName)")
        
        let student_session = StudentSession(peerid: self.peerid)
        student_session.room = room
        student_session.peerDelegate = self.peerDelegate
        student_session.session_delegate = session_delegate
        self.browser.invitePeer(room.peer, toSession: student_session.session, withContext: nil, timeout: 5.0)
        
        return student_session
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!){
        
        
        if let room_number = info["room"] as? String {
            let new_room = AvailableRoom (number: room_number, peer: peerID, info: info)
            self.available_rooms[room_number] = new_room
            
            if let room_dalegate = self.room_delegate {
                room_delegate?.roomAvailable(new_room)
            }
            
        }else{
            self.message("Found a weird peer Peer, going to ignore it")
        }
        
    }
    
    // A nearby peer has stopped advertising
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!){
        for (number,room) in self.available_rooms{
            if (room.peer == peerID){
                let gone = self.available_rooms.removeValueForKey(number)
                if let room_dalegate = self.room_delegate {
                    if let gone = gone{
                        room_delegate?.roomUnAvailable(gone)
                    }
                }

            }
        }
    }
    
    // Browsing did not start due to an error
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!){
        self.message("Student Peer Error")
    }
}

//
//  TeacherPeer.swift
//  
//
//  Created by Felipe Saint-jean on 7/2/15.
//
//

import UIKit
import MultipeerConnectivity


import UIKit
import MultipeerConnectivity

let service = "bcx-service"


public protocol Peer: class {
    //func didConnectTo(room: String)
    //func didDisconectFrom(room: String)
    //func gotMessageFrom(user: String, data:[String: AnyObject])
    func message(message: String)
}


enum TeacherSessionStatus {
    case Closed
    case Accepting
    case Error
    
}





public protocol TeacherSessionDelegate: class {
    func studentConnected(student:String)
    func studentConnecting(student:String)
    func studentDisConnected(student:String)
    func receivedImage(image:UIImage)
}



class TeacherSession: BasicPeer ,MCSessionDelegate {
    
    weak var session_delegate:TeacherSessionDelegate?
    
    init(peer_status:TeacherSessionDelegate?, peerid: MCPeerID){
        self.session_delegate = peer_status
        super.init(peerid: peerid)
        
    }
    
    
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        
        
        switch state{
        case .Connected:
            if let session_delegate = self.session_delegate {
                session_delegate.studentConnected(peerID.displayName)
            }
        case .Connecting:
            if let session_delegate = self.session_delegate {
                session_delegate.studentConnecting(peerID.displayName)
            }
        case .NotConnected:
            if let session_delegate = self.session_delegate {
                session_delegate.studentDisConnected(peerID.displayName)
            }
            
        }
        for p in session.connectedPeers{
            if let peer = p as? MCPeerID {
                println("Peer \(peer.displayName)")
            }
        }
        
    }
    
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        if let data = data, sd = self.session_delegate{
        //    let string_value = NSString(data: data, encoding: NSUTF8StringEncoding)
            if let r = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String:AnyObject] {
                println(r)
                if let image_data = r[MessagesKeys.MessageImage.rawValue] as? NSData{
                    let image = UIImage(data: image_data)
                    dispatch_async(dispatch_get_main_queue()){
                        if let sd = self.session_delegate, image = image {
                            sd.receivedImage(image)
                        }
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
    
    deinit{
       
        session.delegate = nil
        session.disconnect()

    }
    
}


class TeacherAdvertiser: BasicPeer, MCNearbyServiceAdvertiserDelegate {
    var advertiser: MCNearbyServiceAdvertiser
    var peerid:MCPeerID
   
    var session_peer:TeacherSession?
    weak var session_delegate: TeacherSessionDelegate?
    
    
    init(delegate: Peer?, session_delegate: TeacherSessionDelegate) {
        
        self.peerid = MCPeerID(displayName: "Teacher")
        self.session_delegate = session_delegate
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerid, discoveryInfo: ["room":"237"], serviceType: service)
        
        super.init(peerid: self.peerid)
        
        self.peerDelegate = delegate
        
        self.advertiser.delegate = self

        self.advertiser.startAdvertisingPeer()
        
        self.message("Advertising")
        
    }
    
    deinit{
        self.advertiser.delegate = nil
        self.advertiser.stopAdvertisingPeer()
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!){
        if self.session_peer == nil {
            self.session_peer = TeacherSession(peer_status: self.session_delegate, peerid: self.peerid)
            self.session_peer?.peerDelegate = self.peerDelegate
        }
        
        
        if let session = self.session_peer{
            invitationHandler(true, session.session)
        }
    }
       
        
    
    // Advertising did not start due to an error
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!){
        self.message("Advertising Failed")
       
    }
    
    func requestScreenShot(){
        //self.sendData([], peers: self.session.connectedPeers)
        if let session = self.session_peer {
            
            if let peers = session.session.connectedPeers as? [MCPeerID]{
                session.sendData([MessagesKeys.MessageType.rawValue:MessageTypes.RequestScreenShot.rawValue], peers:peers)
            }
            
        }
    }
    func close(){
    }
}

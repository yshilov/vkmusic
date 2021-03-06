//
//  ViewController.swift
//  VKMusic
//
//  Created by Yuriy Shilov on 29.10.15.
//  Copyright © 2015 Yuriy Shilov. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
//import VKSdkFramework
var logsArray = [String]()
class VKViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,VKSdkDelegate, UITextFieldDelegate {
    let appID = "5126219"
    let popularSongs = ["Молодые ветра remix"]
    
    var player = AVPlayer()
    var playlist = [Song]()
    var currentSongNumber : Int?
    var request: VKRequest?;
    var sdk: VKSdk?

    private struct Storyboard{
        static let CellReuseIdentifier = "Song"
    }
    var searchText: String?  {
        didSet{
            searchTextField?.text = searchText
            if let searchquery = searchText { loadPlaylistForQuery(searchquery) }
        }
        
    }
    @IBOutlet weak var searchTextField: UITextField!{
        didSet{
            searchTextField.delegate = self
            searchTextField.text = searchText
        }
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
            searchText = textField.text
        }
        return true
        
    }
    
    override func viewDidLoad() {
        NSLog("AppID = %@\n", appID)
        logsArray.append("AppID = \(appID)")
        sdk = VKSdk.initializeWithAppId(appID)
        sdk!.registerDelegate(self)
        saveToFile("")
        
        
        super.viewDidLoad()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        playlistTable.dataSource = self
        playlistTable.delegate = self
        connectToVK()
        
        request = VKRequest(method: "audio.get", parameters: nil)
        getPlaylistFromVK()
        
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {}
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "playNext",
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: player.currentItem
        )
        
    }
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        guard let event = event else {return}
        guard event.type == UIEventType.RemoteControl else {return}
        switch event.subtype{
        case .RemoteControlPause : player.pause()
        case .RemoteControlNextTrack : playNext()
        case .RemoteControlPlay : player.play()
        case .RemoteControlPreviousTrack : player.seekToTime(CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1)))
        case .RemoteControlTogglePlayPause : if (player.rate != 0 && player.error == nil){player.pause()} else {player.play()}
        default : break
        }
    }
    
    
    @IBAction func getInitialPlaylist(sender: AnyObject) {
        request = VKRequest(method: "audio.get", parameters: nil)
        getPlaylistFromVK()
        searchText = nil
    }
    
    @IBAction func play(sender: AnyObject) {
        player.play()
    }
    
    @IBAction func pause(sender: AnyObject) {
        player.pause()
    }
    
    @IBOutlet weak var playlistTable: UITableView!
   
    
    @IBAction func getPlaylist(sender: AnyObject) {
        searchText = popularSongs[0]
    }
    func loadPlaylistForQuery(q:String){
        request = VKRequest(method: "audio.search", parameters: ["q":q, "count":60])
        getPlaylistFromVK()
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier)!
        cell.textLabel?.text = playlist[indexPath.row].title ?? "VA"
        cell.detailTextLabel?.text = playlist[indexPath.row].artist ?? "VA"
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let i = indexPath.row
        playSongWithNumber(i)
    }
    func playSongWithNumber(i:Int){
        if i < playlist.count {
            if let url = NSURL(string: playlist[i].url ?? ""){
                player = AVPlayer(URL: url)
                player.play()
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist:playlist[i].artist ?? "", MPMediaItemPropertyTitle:playlist[i].title ?? ""]
                currentSongNumber = i
            }
        }
        
    }
    func playNext(){
        guard var i = currentSongNumber else {return}
        i = (i + 1) % playlist.count
        playSongWithNumber(i)
        playlistTable.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: true, scrollPosition: .None)
        
    }

    func saveToFile(name: String)
    {
    }

    func getPlaylistFromVK(){
        request!.executeWithResultBlock({
            [unowned self, weak playlistTable = self.playlistTable] AAA in
            if let response = (AAA.json.objectForKey("items")) as? [[String:AnyObject]] {
                self.playlist.removeAll()
                for item in response {
                    if let _ = NSURL(string: (item["url"] as? String ) ?? ""){
                        let song = Song(artist: item["artist"] as! String, title: item["title"] as! String, id: item["id"] as! NSNumber, url: item["url"] as! String)
                        self.playlist.append(song)
                        
                        NSLog("ID = %@\n", song.id)
                        logsArray.append("ID = \(song.id)")
                    }

                }
                playlistTable?.reloadData()
            }
        }, errorBlock: nil)

    }
    
    
    func connectToVK(){
        NSLog("Connect begin");
        logsArray.append("Connect begin")
        VKSdk.wakeUpSession(
            [VK_PER_AUDIO],

            completeBlock: {
                if( $0 == .Authorized)
                {
                    NSLog("wakeUpSession: authorized")
                    logsArray.append("wakeUpSession: authorized")
                }else if( $0 == .Initialized)
                {
                    NSLog("wakeUpSession: initialized")
                    logsArray.append("wakeUpSession: initialized")
                    VKSdk.authorize([VK_PER_AUDIO])
                }else
                {
                    NSLog("wakeUpSession: status code %ld\n", CLong($0.rawValue))
                    logsArray.append("wakeUpSession: status code \($0.rawValue)")
                }

                if ($1 != nil) {
                    NSLog("Error")
                    logsArray.append("Error")
                }
            }
        )
    }



    func vkSdkAccessAuthorizationFinishedWithResult(result: VKAuthorizationResult)
    {
        NSLog("vkSdkAccessAuthorizationFinishedWithResult")
        logsArray.append("vkSdkAccessAuthorizationFinishedWithResult")
    }
    
    func vkSdkUserAuthorizationFailed()
    {
        NSLog("vkSdkUserAuthorizationFailed")
        logsArray.append("vkSdkUserAuthorizationFailed")
    }
    //VK DELEGATE ENDS

}

struct Song{
    var artist : String
    var  title : String
    var     id : NSNumber
    var    url : String
    
}

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
class VKViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,VKSdkDelegate, UITextFieldDelegate {
    let appID = "5126219"
    let popularSongs = ["Молодые ветра remix"]
    var player = AVPlayer()
    var playlist = [Song]()
    var currentSongNumber : Int?
    var request = VKRequest(method: "audio.get", andParameters: nil, andHttpMethod: "GET")
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
        super.viewDidLoad()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        playlistTable.dataSource = self
        playlistTable.delegate = self
        connectToVK()
        getPlaylistFromVK()
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {}
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playNext", name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)
        
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
        request = VKRequest(method: "audio.get", andParameters: nil, andHttpMethod: "GET")
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
        request = VKRequest(method: "audio.search", andParameters: ["q":q, "count":60], andHttpMethod: "GET")
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
    
    func getPlaylistFromVK(){
        request.executeWithResultBlock({
            [unowned self, weak playlistTable = self.playlistTable] in
            if let response = $0.json.objectForKey("items") as? [[String:AnyObject]] {
                self.playlist.removeAll()
                for item in response {
                    if let _ = NSURL(string: (item["url"] as? String ) ?? ""){
                        let song = Song(artist: item["artist"] as? String, title: item["title"] as? String, url: item["url"] as! String)
                        self.playlist.append(song)
                    }

                }
                playlistTable?.reloadData()
            }
        }, errorBlock: nil)

    }
    func connectToVK(){
        VKSdk.initializeWithDelegate(self, andAppId: appID)
        if VKSdk.wakeUpSession() {
        }else{
            VKSdk.authorize([VK_PER_FRIENDS, VK_PER_EMAIL, VK_PER_AUDIO])
        }
    }
   
   

    
    //MARK: VK DELEGATE FUNCS
    func vkSdkNeedCaptchaEnter(captchaError: VKError) {}
    func vkSdkTokenHasExpired(expiredToken: VKAccessToken) {}
    func vkSdkUserDeniedAccess(authorizationError: VKError) {}
    func vkSdkShouldPresentViewController(controller: UIViewController) {}
    func vkSdkReceivedNewToken(newToken: VKAccessToken) {}
    //VK DELEGATE ENDS

}

struct Song{
    var artist : String?
    var title : String?
    var url : String
    
}

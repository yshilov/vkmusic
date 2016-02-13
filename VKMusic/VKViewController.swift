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
    let appID = "5292683"
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
        NSLog("AppID = %@\n", appID)
        saveToFile("")
        
        
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

    func saveToFile(name: String)
    {
        let ass = NSFileManager()
        if let url = ass.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first {
            let filepath =  url.URLByAppendingPathComponent("test.txt")
            NSLog("(((%@)))\n", filepath)
            let result = NSData(contentsOfURL: NSURL(string: "https://psv4.vk.me/c4693/u61905946/audios/3bb013bfcf32.mp3")!)
            NSLog("DONE!\n")
        }
    }

    func getPlaylistFromVK(){
        request.executeWithResultBlock({
            [unowned self, weak playlistTable = self.playlistTable] AAA in
            if let response = (AAA.json.objectForKey("items")) as? [[String:AnyObject]] {
                self.playlist.removeAll()
                for item in response {
                    if let _ = NSURL(string: (item["url"] as? String ) ?? ""){
                        let song = Song(artist: item["artist"] as? String, title: item["title"] as? String, url: item["url"] as! String)
                        self.playlist.append(song)
                        
                        NSLog("<%@>\n\n", song.url)
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
    func vkSdkNeedCaptchaEnter(captchaError: VKError)
    {
        NSLog(
            "!!! vkSdkNeedCaptchaEnter errorCode = %ld, errorMessage = %@, errorReason = %@, errorText = %@\n",
            CLong(captchaError.errorCode),
            captchaError.errorMessage,
            captchaError.errorReason,
            captchaError.errorText
        );
    }

    func vkSdkTokenHasExpired(expiredToken: VKAccessToken)
    {
        NSLog(
            "!!! vkSdkTokenHasExpired: isExpired = %ld, email = %@\n",
            CLong(expiredToken.isExpired),
            expiredToken.email
        );
    }

    func vkSdkUserDeniedAccess(authorizationError: VKError)
    {
        NSLog(
            "!!! vkSdkUserDeniedAccess errorCode = %ld, errorMessage = %@, errorReason = %@, errorText = %@\n",
            CLong(authorizationError.errorCode),
            authorizationError.errorMessage,
            authorizationError.errorReason,
            authorizationError.errorText
        );
    }

    func vkSdkShouldPresentViewController(controller: UIViewController)
    {
        NSLog("vkSdkShouldPresentViewController\n");
    }

    func vkSdkReceivedNewToken(newToken: VKAccessToken)
    {
        NSLog(
            "!!! vkSdkReceivedNewToken: isExpired = %ld, email = %@\n",
            CLong(newToken.isExpired),
            newToken.email
        );
    }
    //VK DELEGATE ENDS

}

struct Song{
    var artist : String?
    var title : String?
    var url : String
    
}

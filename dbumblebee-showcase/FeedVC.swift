//
//  FeedVC.swift
//  dbumblebee-showcase
//
//  Created by Brian Bresen on 11/22/16.
//  Copyright © 2016 BeeHive Productions. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postField: MaterialTextField!
    @IBOutlet weak var imageSelectorImage: UIImageView!
    
    var posts = [Post]()
    
    var imagePicker: UIImagePickerController!
    
    static var imageCache = NSCache<AnyObject, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 353
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { snapshot in

            self.posts = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshots {
//                    print("SNAP:\(snap)")
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

// Here we could add check for a viewing option between newest or oldest first
// let i { if oldestFirst {return indexPath.row} else {return posts.count-1-indexPath.row}
// let post = posts[i]
//        Firebase is storing oldest post first
//        let post = posts[indexPath.row]
//      using the below to show newtest post first in table
        let post = posts[(posts.count - 1 - indexPath.row)]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            cell.request?.cancel()

            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.object(forKey: url as AnyObject) as? UIImage
            }
            
            cell.configureCell(post: post, img: img)
            return cell
        } else {
            return PostCell()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
// Here we could add check for a viewing option between newest or oldest first
//        let post = posts[indexPath.row]
//      Using the below to show newest post first in the table
        let post = posts[(posts.count - 1 - indexPath.row)]
        
        if post.imageUrl == nil {
            return 150
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageSelectorImage.image = image
            imageSelectorImage.tag = 1
        }
    }
    
    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func makePost(_ sender: Any) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        
        if let txt = postField.text, txt != "" {
            if let img = imageSelectorImage.image, imageSelectorImage.tag == 1 {
                
                let imageData = UIImageJPEGRepresentation(img, 0.8)
                let imagePath = "\(uid!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let storageUrl = FIRApp.defaultApp()?.options.storageBucket
                let fullImageUrl = "gs://" + storageUrl! + "/" + imagePath
            print("Stroring image to firebase: \(fullImageUrl)")
                //Store the image to Firebase Storage
                FIRStorage.storage().reference(forURL: "gs://" + storageUrl!).child(imagePath).put(imageData!, metadata: metadata) { [weak self] (metadata, error) in
                        if let error = error {
                            print("Error uploading: \(error)")
                            return
                        }
                }
                //Store the post to Firebase Database
                self.postToFirebase(imgUrl: fullImageUrl)
            } else {
                self.postToFirebase(imgUrl: nil)
            }
        }
    }
    
    func postToFirebase(imgUrl: String?) {
        print("saving post to firebase")
        //Set dictionary value to save to firebase
        var post: Dictionary<String, Any> = [
            "description": postField.text!,
            "likes": 0
        ]
        //Add image field if present
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
        }
        
        //Get a new post reference and set it's value
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        postField.text = ""
        imageSelectorImage.image = UIImage(named: "camera")
        imageSelectorImage.tag = 0
        
        tableView.reloadData()
    }
}

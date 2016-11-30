//
//  PostCell.swift
//  dbumblebee-showcase
//
//  Created by Brian Bresen on 11/22/16.
//  Copyright © 2016 BeeHive Productions. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import FirebaseStorage

class PostCell: UITableViewCell {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var showcaseImg: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    
    var post: Post!
    var request: Request?
    var likeRef: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped(_:)))
        tap.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tap)
        likeImage.isUserInteractionEnabled = true
        
    }
    
    override func draw(_ rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        
        showcaseImg.clipsToBounds = true
    }
    
    func configureCell(post: Post, img: UIImage?) {
        self.post = post
        
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"
        
        //Image setup
        if let imgUrl = post.imageUrl {
            if img != nil {
                //print("configureCell got an image \(img)")
                self.showcaseImg.image = img
                self.showcaseImg.isHidden = false
            } else {
                print(imgUrl)
                if imgUrl.hasPrefix("gs://") {
                
                    FIRStorage.storage().reference(forURL: imgUrl).data(withMaxSize: INT64_MAX){ (data, error) in
                        if let error = error {
                            print("Error downloading: \(error)")
                            return
                        }
                        let img = UIImage.init(data: data!)!
                        self.showcaseImg.image = img
                        self.showcaseImg.isHidden = false
                        FeedVC.imageCache.setObject(img, forKey: imgUrl as AnyObject)
                    }
                } else {
                    request = Alamofire.request(imgUrl).validate(contentType: ["image/*"]).responseData { response in
                        
                        switch response.result {
                        case .success:
                            let img = UIImage(data: response.data!)!
                            self.showcaseImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: imgUrl as AnyObject)
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            }
        } else {
            self.showcaseImg.isHidden = true
        }
        
        //Likes setup
        likeRef = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            if let doesNotExist = snapshot.value as? NSNull {
                //This means we have not liked this specific post
                self.likeImage.image = UIImage(named: "heart-empty")
            } else {
                self.likeImage.image = UIImage(named: "heart-full")
            }
        })
    }
    
    func likeTapped(_ sender: UITapGestureRecognizer) {
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            if let doesNotExist = snapshot.value as? NSNull {
                //This means we have not liked this specific post
                self.likeImage.image = UIImage(named: "heart-full")
                self.post.adjustLikes(addLike: true)
                self.likeRef.setValue(true)
            } else {
                self.likeImage.image = UIImage(named: "heart-empty")
                self.post.adjustLikes(addLike: false)
                self.likeRef.removeValue()
            }
        })
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  riderTableViewCell.swift
//  ToolMan
//
//  Created by 呂明聲 on 2018/11/18.
//  Copyright © 2018 MingShengLyu. All rights reserved.
//

import UIKit

class riderTableViewCell: UITableViewCell {

    @IBOutlet weak var mIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var user_name: UILabel!
    @IBOutlet weak var user_email: UILabel!
    @IBOutlet weak var user_description: UILabel!
    
    
    func congfigureCell(profileImg:String, name:String, email:String, detail:String){
        
        
        DispatchQueue.main.async {
            
            self.mIndicator.startAnimating()
            let imgData = NSData(contentsOf: URL(string: profileImg)!)
            let userImage = UIImage(data: imgData! as Data)
            self.userImg.image = userImage
            self.mIndicator.stopAnimating()
        }
        //self.userImg.image = profileImg
        self.user_name.text = name
        self.user_email.text = email
        self.user_description.text = detail
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

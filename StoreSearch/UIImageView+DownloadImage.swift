//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by Buck Rozelle on 5/3/20.
//  Copyright © 2020 buckrozelledotcomLLC. All rights reserved.
//

import UIKit

extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        
        //create a download task
        let downloadTask = session.downloadTask(with: url,
                                                 completionHandler: {[weak self] url, response, error in
        
        //create an image of the loaded file
        if error == nil, let url = url,
            let data = try? Data(contentsOf: url),  //load the file into a data object
            let image = UIImage(data: data) {
            
            //put the image into the UIImageView's image property
            DispatchQueue.main.async {
                if let weakSelf = self {
                    weakSelf.image = image
                }
            }
        }
        
        })
    //call resume to start the download task.
    downloadTask.resume()
    return downloadTask
}
}

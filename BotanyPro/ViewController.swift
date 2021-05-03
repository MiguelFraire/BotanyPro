//
//  ViewController.swift
//  BotanyPro
//
//  Created by Miguel Fraire on 4/14/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"




    @IBOutlet weak var imageViewSelected: UIImageView!
    @IBOutlet weak var informativeLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            guard let ciImage = CIImage(image: userImage) else{
                fatalError("Could not convert to CIImage")
            }
            detect(image: ciImage)
            
            //imageViewSelected.image = userImage
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else{
            fatalError("Cannot import model")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else{
                fatalError("Could not classify")
            }
            //print(request.results)
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
    }
    func requestInfo(flowerName:String){
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "720",
        ]
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if case .success(let value) = response.result {
                let flowerJSON: JSON = JSON(value)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageViewSelected.sd_setImage(with: URL(string: flowerImageURL))
                self.informativeLabel.text = flowerDescription
            }
            
        }
    }
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
}


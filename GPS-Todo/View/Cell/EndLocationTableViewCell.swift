//
//  EndLocationTableViewCell.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/03.
//

import UIKit
import MapKit

protocol EndLocationTVCellDelegate: AnyObject {
    func didDeleteButtonClicked(_ cell: EndLocationTableViewCell)
}

class EndLocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var btnIcon: UIButton!
    @IBOutlet weak var lblCoordinate: UILabel!
    
    private(set) var annotation: MKAnnotation!
    
    enum ButtonMode {
        case delete, placeIcon
        
        var image: UIImage {
            switch self {
            case .delete:
                return UIImage(systemName: "xmark.circle.fill")!
            case .placeIcon:
                return UIImage(systemName: "photo.fill")!
            }
        }
    }
    var buttonMode: ButtonMode = .delete {
        didSet {
            self.btnIcon.setImage(buttonMode.image, for: .normal)
        }
    }
    
    weak var delegate: EndLocationTVCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(text: String) {
        lblCoordinate.text = text
    }
    
    func configure(annotation: MKAnnotation) {
        self.annotation = annotation
        
        // TODO: 좌표 소수점 표시 > extension으로 빼기
        let coordinate = annotation.coordinate
        let lat = String(format: "%.5f", coordinate.latitude)
        let lon = String(format: "%.5f", coordinate.longitude)
        let title = annotation.title ?? "Unknown place"
        let text = "\(title ?? "Unknown place"): \(lat), \(lon)"
        
        lblCoordinate.text = text
    }
    
    @IBAction func btnIconDoAct(_ sender: Any) {
        switch buttonMode {
        case .delete:
            delegate?.didDeleteButtonClicked(self)
        case .placeIcon:
            break
        }
    }
}

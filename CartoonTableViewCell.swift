//
//  CartoonTableViewCell
//  LiveScore
//
//  Created by 학철 on 2018. 7. 16..
//

import UIKit

@objc
class CartoonTableViewCell: UITableViewCell {
    @IBOutlet var ivThumbnail: UIImageView!
    @IBOutlet var lbTitle: UILabel!
    var cartoonNo: String?
    var categoryNo: String?
    var dataDic: [AnyHashable : Any]?
    weak var datasource: CartoonTableViewCellDataSource?

    override func awakeFromNib() {
        super.awakeFromNib()

        let hilightView = UIView()
        hilightView.backgroundColor = RGB(0xff, 0xc6, 0x00)
        selectedBackgroundView = hilightView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // 백그라운드 색상을 통해 읽은 내역이 있는지 없는지 표시
    @objc
    func configurationData(_ dataDic: [AnyHashable : Any]?, cartoonNo: String?) {
        self.dataDic = dataDic
        self.cartoonNo = cartoonNo
        categoryNo = self.dataDic?["categoryNo"] as? String
        //    NSString *title = [_dataDic objectForKey:@"title"];
        let photoUrl = self.dataDic?["photoUrl"] as? String
        //    NSString *imgFileCnt = [_dataDic objectForKey:@"imgFileCnt"];

        // 흰색 백그라운드로 표시(초기화)
        defaultReuseSetting()

        var readPage: String? = nil
        if datasource?.responds(to: #selector(CartoonTableViewCellDataSource.fetchingReadPage(fromCache:))) ?? false {
            let key = String(format: "%@|%03ld", self.cartoonNo ?? "", Int(categoryNo ?? "") ?? 0)
            readPage = datasource?.fetchingReadPage(fromCache: key)
        }
        
        // 읽은 이력이 있는 경우 회색 백그라운드 표시
        if (readPage?.count ?? 0) > 0 {
            //    if ([readPage isEqualToString:[_dataDic objectForKey:@"imgFileCnt"]]) {
            contentView.backgroundColor = RGB(0xed, 0xed, 0xed)
        }
        ivThumbnail.clipsToBounds = true
        let defaultImgName = ""

        if (photoUrl?.count ?? 0) > 0 {

            let decryptKey = SharedData.sharedInstance()?.objectForkey(kUSER_CARTOON_CERTIFICATE) as? String
            LSImageCache.getInstance()?.loadImage(
                from: URL(string: photoUrl ?? ""),
                secondsToCache: 0,
                userInfo: nil,
                seedKey: decryptKey,
                cachePath: DOWNLOAD_CACHE_PATH_CARTOON,
                callback: { image, userInfo in
                    if let image = image {
                        self.ivThumbnail.image = image as? UIImage
                    } else {
                        self.ivThumbnail.image = UIImage(named: "cartoon_basics_image")
                    }
                })
        }
        lbTitle.text = self.dataDic?["title"] as? String
    }

    func defaultReuseSetting() {
        contentView.backgroundColor = .white
        ivThumbnail.image = nil
        ivThumbnail.accessibilityValue = nil
        lbTitle.text = ""
    }

    deinit {

        dataDic = nil
        cartoonNo = nil
        categoryNo = nil
    }
}

@objc protocol CartoonTableViewCellDataSource: NSObjectProtocol {
    func fetchingReadPage(fromCache key: String?) -> String?
}

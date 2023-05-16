//
//  CartoonDetailListViewController.h
//  LiveScore
//
//  Created by 학철 on 2018. 7. 16..
//

import UIKit


let HEIGHT_FOOTER = 100

private let kReuseCellID = "CartoonTableViewCell"

@objc
class CartoonDetailListViewController: DefaultViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, CartoonTableViewCellDataSource, CartoonReaderViewControllerDataSource, CartoonReaderViewControllerDelegate {
    @IBOutlet private var tblView: UITableView! // 단행본 리스트
    @IBOutlet private var topView: UIView!  // 띠 배너
    @IBOutlet private var btnClose: UIButton!   // 닫기 버튼
    @IBOutlet private var lbHeaderTitle: UILabel!   // 만화책 제목
    @IBOutlet private var footerView: UIView!
    @IBOutlet private var lbFooterEmpty: UILabel!
    @IBOutlet private var btnMore: UIButton!
    private var arrData: [Any]?
    private var initData: [AnyHashable : Any]?
    private var pageKey: String?
    private var canRequestData = false
    @IBOutlet private var lbViewCnt: UILabel!   // 조회수
    private var dicCartoonInfo: [AnyHashable : Any]?
    private var cartoonNo: String?
    private var arrOffCategoryNo: [Any]?
        
    @objc
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, withData initData: [String : Any]?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initData = initData
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tblView.tableHeaderView = UIView()
        tblView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: tblView.frame.size.width, height: 0.3)
        tblView.tableHeaderView?.backgroundColor = RGB(0xc0, 0xc0, 0xc0)
        lbFooterEmpty.text = ""
        tblView.tableFooterView = footerView
        tblView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: tblView.frame.size.width, height: CGFloat(HEIGHT_FOOTER))
        tblView.bounces = false
        lbViewCnt.text = ""
        cartoonNo = initData?["cartoonNo"] as? String
        lbHeaderTitle.text = initData?["title"] as? String

        tblView.delegate = self
        tblView.dataSource = self
        tblView.estimatedRowHeight = 60

        btnMore.isUserInteractionEnabled = false
        btnMore.isHidden = true

        arrData = []

        dataReset()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func requestBookData() {

        if pageKey == "end" {
            return
        }
        LiveScoreAppDelegate.shared().startLoadingAnimation();
        DataRequestManager.sharedInstance().requestCartoonBookList(withUserNo: (UserDefaults.standard.object(forKey: kUSER_NO)) as? String, cartoonNo: cartoonNo, pageKey: pageKey) { [self] targetCode, dataDic in
            LiveScoreAppDelegate.shared().stopLoadingAnimation()

            let arrCartoon = dataDic?["list"] as? [Any]
            let tmpPagekey = pageKey
            pageKey = dataDic?["pageKey"] as? String

            if (arrCartoon?.count ?? 0) > 0 {
                if (tmpPagekey?.count ?? 0) == 0 {
                    if let arrCartoon {
                        arrData = arrCartoon
                    }
                    tblView.contentOffset = CGPoint.zero
                } else {
                    if let arrCartoon {
                        arrData?.append(contentsOf: arrCartoon)
                    }
                }

                lbFooterEmpty.text = dataDic?["comment"] as? String

                let hitCnt = dataDic?["hitCnt"] as? String

                if (hitCnt?.count ?? 0) > 0 {
                    lbViewCnt.text = Utility.getNumberFormatString(
                        withNumberStryle: NumberFormatter.Style.decimal,
                        with: hitCnt)
                }
            }

            arrOffCategoryNo = dataDic?["offCategoryNo"] as? [Any]

            if (arrData?.count ?? 0) == 0 {
                lbFooterEmpty.text = "준비 중입니다."
                pageKey = "end"
                tblView.isScrollEnabled = false
            }

            tblView.reloadData()
            tblView.layoutIfNeeded()
            //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //            [self visibleBtnMore];
            //        });
        }
    }

    func addData() {
        if pageKey != "end" {
            requestBookData()
        }
    }

    func dataReset() {
        pageKey = ""
        requestBookData()
    }

    // MARK: -- UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrData?.count ?? 0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (arrData?.count ?? 0) - 1 == indexPath.row {
            addData()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellID) as? CartoonTableViewCell
        if cell == nil {
            cell = Bundle.main.loadNibNamed("CartoonTableViewCell", owner: self, options: nil)?.first as? CartoonTableViewCell
            cell!.datasource = self
        }

        let dicItem = arrData?[indexPath.row] as? [AnyHashable : Any]
        cell?.configurationData(dicItem, cartoonNo: cartoonNo)

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let dicItem = arrData?[indexPath.row] as? [AnyHashable : Any]

        let vc = CartoonReaderViewController(nibName: "CartoonReaderViewController", bundle: nil, cartoonNo: cartoonNo, categoryCnt: initData?["categoryCnt"] as? String, withData: dicItem)
        vc.arrOffCategoryNo = arrOffCategoryNo
        vc.arrData = arrData
        vc.datasource = self
        vc.delegate = self
        LiveScoreAppDelegate.shared().getRootNavigationController().pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // 닫기 버튼 터치 시 띠 배너만 숨김
    @IBAction func onClickBtnTouchUpinside(_ sender: UIButton) {
        if sender == btnClose {
            navigationController?.popViewController(animated: false)
        }
    }

    // MARK: -- ScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if canRequestData {
            dataReset()
            canRequestData = false
        }

    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        if velocity > 0 && scrollView.contentOffset.y <= 0 {
            //땡겼을대 리프레쉬
            canRequestData = true
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //    CGFloat contentoffset = ceil(scrollView.contentOffset.y);
        //    CGFloat contentHeight = ceil(scrollView.contentSize.height);
        //    if (contentoffset + scrollView.frame.size.height >= contentHeight) {
        //        _btnMore.hidden = YES;
        //    }
        //    else {
        //         [self visibleBtnMore];
        //    }
    }

    func visibleBtnMore() {
        //    if (_tblView.contentSize.height /*- HEIGHT_FOOTER*/ >= _tblView.frame.size.height) {
        //        _btnMore.hidden = NO;
        //    }
    }

    // MARK: - CartoonTableViewCellDataSource
    //key: cartoonNo|categoryNo, EX)key: 062|001 value:001  3자리로
    func fetchingReadPage(fromCache key: String?) -> String? {
        if (key?.count ?? 0) == 0 {
            return nil
        }
        let dic = (UserDefaults.standard.object(forKey: kUSER_CARTOON_INFO) as? [String?:String?])
        return dic?[key] as? String
    }

    // MARK: - CartoonReaderViewControllerDataSource

    func getCategoryInfo(byKey categoryNo: String?) -> [AnyHashable : Any]? {
        for dicItem in arrData ?? [] {
            guard let dicItem = dicItem as? [AnyHashable : Any] else {
                continue
            }
            if dicItem["categoryNo"] as? String == categoryNo {
                return dicItem
            }
        }
        return nil
    }

    func readerContentViewPopBackAction() {
        tblView.reloadData()
    }

    deinit {

        arrData = nil
        initData = nil
        pageKey = nil

        cartoonNo = nil
        arrOffCategoryNo = nil
        dicCartoonInfo = nil
    }
}

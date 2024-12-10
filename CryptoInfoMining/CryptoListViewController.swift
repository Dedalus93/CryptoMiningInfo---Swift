//
//  CryptoListViewController.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 07/12/24.
//

import UIKit
import RxSwift

struct CryptoInfo : Codable {
    let name: String
    let image: Data
    let price: Double
}

protocol CryptoView: AnyObject  {
    var cryptoInfo: [CryptoInfo] { get set }
    func dataLoading()
    func dataLoaded()
}

class CryptoListViewController: UIViewController {
    
    var viewModel: CryptoListViewModel?
    var cryptoInfo: [CryptoInfo] = []
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = "Crypto List"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ProgressHUD.show()
    }
    @IBAction func rightButtonPressed(_ sender: Any) {
        viewModel?.testButton()
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

extension CryptoListViewController: CryptoView {
    func dataLoading() {
        DispatchQueue.main.async {
            ProgressHUD.show()
        }
    }
    
    func dataLoaded() {
        DispatchQueue.main.async {
            ProgressHUD.dismiss()
        }
    }
}

extension CryptoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
}


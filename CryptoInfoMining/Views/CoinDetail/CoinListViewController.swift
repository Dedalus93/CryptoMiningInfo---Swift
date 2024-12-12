//
//  CoinListViewController.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 07/12/24.
//

import UIKit
import RxSwift
import RxCocoa


/// Protocol for the CoinList view. Only this elements are visibile by the viewmodel.
protocol CoinListView: AnyObject  {
    var viewObjects: [(rank: String, image: UIImage?, name: String, price: Double)] { get set }
    var viewIsReadySubject: PublishSubject<Void> { get }
    var userSelectionSubject: PublishSubject<String> { get }
    
    func dataLoading()
    func dataLoaded()
}

class CoinListViewController: UIViewController {
    
    var viewModel: CoinListViewModel?
    
    var viewObjects: [(rank: String, image: UIImage?, name: String, price: Double)] = []
    var viewIsReadySubject = PublishSubject<Void>()
    var userSelectionSubject = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = CoinListViewModel(view: self)
        setupBindings()

        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = "Coin Market Cap Ranking"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ProgressHUD.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewIsReadySubject.onNext(())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? LineChartViewController {
            if let viewObject = sender as? (name: String, description: String, link: String, values: [Double]) {
                viewController.title = viewObject.name + " Info"
                viewController.coinDescription = viewObject.description
                viewController.linkString = viewObject.link
                viewController.chartData = viewObject.values
            }
        }
    }
    
    /// This function made the binding beetwen the viewModel and view of this specific view.
    func setupBindings() {
        guard let viewModel = self.viewModel else { return }
        /// Bind button tap to ViewModel's observer
        rightBarButton.rx.tap
            .bind(to: viewModel.userActionObserver)
            .disposed(by: disposeBag)
        
        /// Show an alert for any type of error.
        viewModel.error
            .observe(on: MainScheduler.instance) // Assicurati di aggiornare la UI sul main thread
            .subscribe(onNext: { [weak self] errorTitle, errorMessage in
                self?.showErrorAlert(title: errorTitle, message: errorMessage)
            })
            .disposed(by: disposeBag)
        
        /// Show a progressHUD in the UX when viewmodel is performing actions.
        viewModel.startLoadingDataSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { status in
                ProgressHUD.show(status: status)
            })
            .disposed(by: disposeBag)
        /// Viewmodel has finished its tasks and the progressHUD is dismissed.
        viewModel.finishedLoadingDataSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
                ProgressHUD.dismiss()
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.loadedNextViewDataSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { name, description, link, values  in
                self.performSegue(withIdentifier: "CoinInfo", sender: (name, description, link, values))
            })
            .disposed(by: disposeBag)
    }

    
    /// Method for showing the user information about any type of error.
    /// - Parameters:
    ///   - title: The title indicating what is generating the error.
    ///   - message: The message underlying the error (e.g. code, localized description).
    func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: CoinList View method implementation
extension CoinListViewController: CoinListView {
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

// MARK: UITableViewDelegate and UITableViewDataSource
extension CoinListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CoinInfoTableViewCell
        cell.rankLabel.text = (viewObjects[indexPath.row].rank)
        cell.coinImage.image = viewObjects[indexPath.row].image
        cell.nameLabel.text = viewObjects[indexPath.row].name
        cell.priceLabel.text = "\(viewObjects[indexPath.row].price) €"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        userSelectionSubject.onNext((viewObjects[indexPath.row].name))
    }
}


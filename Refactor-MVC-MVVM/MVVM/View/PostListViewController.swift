//
//  PostListViewController.swift
//  Refactor-MVC-MVVM
//
//  Created by Victor Roldan on 27/07/22.
//

import UIKit
import Combine

class PostListViewController: UIViewController{
    @IBOutlet weak var tableView: UITableView!

    private var viewModel = PostViewModel()
    private var anyCancellable = Set<AnyCancellable>()
    
    lazy var loading : UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .large)
        loading.startAnimating()
        loading.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44.0)
        return loading
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        subscriptions()
        Task{
            await self.viewModel.getPosts()
        }
    }
    
    private func configTableView(){
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func subscriptions(){
        viewModel.postObservable.sink { error in
            print("erro: ", error)
        } receiveValue: {[weak self] in
            self?.tableView.reloadData()
        }.store(in: &anyCancellable)
        
        viewModel.wasRemovedObservable.sink {[weak self] (wasRemoved, indexPath) in
            if wasRemoved{
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }.store(in: &anyCancellable)
    }

}

extension PostListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.postList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.postList[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = viewModel.formatTitle(item)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.numberOfLines = 0
        
        cell.detailTextLabel?.text = item.body
        cell.detailTextLabel?.numberOfLines = 0
        
        if viewModel.postList.count == (indexPath.row+1){
            Task{
                await viewModel.getPosts()
            }
            self.tableView.tableFooterView = loading
            self.tableView.tableFooterView?.isHidden = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = viewModel.postList[indexPath.row]
        let vc = DetailViewController(post: post)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let postId = viewModel.postList[indexPath.row].id
        viewModel.deletePost(postId: postId, indexPath: indexPath)
    }
}

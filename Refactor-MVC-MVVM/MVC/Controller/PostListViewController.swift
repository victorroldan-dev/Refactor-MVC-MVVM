//
//  PostListViewController.swift
//  Refactor-MVC-MVVM
//
//  Created by Victor Roldan on 27/07/22.
//

import UIKit

class PostListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var postList = [PostModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        navigationController?.navigationBar.prefersLargeTitles = true
        
        Task{
            await self.getPosts()
        }
    }
    
    private func getPosts(moreResults : Bool = false) async{
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response1 = try decoder.decode([PostModel].self, from: data)
            let response = Array(response1.prefix(10))
            DispatchQueue.main.async {
                if moreResults{
                    self.postList += response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.tableView.reloadData()
                        self.tableView.tableFooterView?.isHidden = true
                    }
                }else{
                    self.postList = response
                    self.tableView.reloadData()
                }
            }
        } catch {
            print("Invalid data: ", error)
        }
    }
    
    private func deletePostClosure(postId : Int, completion : @escaping (Bool)->Void){
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(postId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let service = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion((error == nil))
            }
        }
        service.resume()
    }
    
    private func deleteRowFromList(_ indexPath : IndexPath){
        postList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func formatTitle(_ item : PostModel) -> String{
        let title = item.title.capitalized
        return title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = postList[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = formatTitle(item)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.numberOfLines = 0
        
        cell.detailTextLabel?.text = item.body
        cell.detailTextLabel?.numberOfLines = 0
        
        if postList.count == (indexPath.row+1){
            Task{
                await getPosts(moreResults: true)
            }
            
            let loading = UIActivityIndicatorView(style: .large)
            loading.startAnimating()
            loading.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44.0)
            
            self.tableView.tableFooterView = loading
            self.tableView.tableFooterView?.isHidden = false
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postList[indexPath.row]
        let vc = DetailViewController(post: post)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let postId = postList[indexPath.row].id
        deletePostClosure(postId: postId) { [weak self] wasRemoved in
            if wasRemoved{
                self?.deleteRowFromList(indexPath)
            }else{
                print("error removing")
            }
        }
    }
}


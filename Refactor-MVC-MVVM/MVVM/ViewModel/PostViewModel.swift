//
//  PostViewModel.swift
//  Refactor-MVC-MVVM
//
//  Created by Victor Roldan on 31/07/22.
//

import Foundation
import Combine
enum CustomError : Error{
    case generic
}

class PostViewModel{
    var provider : PostProviderProtocol
    var postList = [PostModel]()
    var postObservable = PassthroughSubject<Void, Error>()
    var wasRemovedObservable = PassthroughSubject<(Bool,IndexPath), Never>()
    
    init(provider : PostProviderProtocol = PostProvider()){
        self.provider = provider
    }
    
    @MainActor func getPosts() async{
        guard let result = await provider.getPosts() else{
            //logic
            postObservable.send(completion: .failure(CustomError.generic))
            return
        }
        if postList.count > 0{
            postList += result
        }else{
            postList = result
        }
        postObservable.send()
    }
    
    func deletePost(postId : Int, indexPath : IndexPath){
        provider.deletePostClosure(postId: postId) {[weak self] wasRemoved in
            guard let self = self else {return}
            self.postList.remove(at: indexPath.row)
            DispatchQueue.main.async {
                self.wasRemovedObservable.send((wasRemoved, indexPath))
            }
        }
    }
    
    func formatTitle(_ item : PostModel) -> String{
        let title = item.title.capitalized
        return title
    }
}

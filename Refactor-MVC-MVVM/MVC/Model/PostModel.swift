//
//  PostModel.swift
//  Refactor-MVC-MVVM
//
//  Created by Victor Roldan on 28/07/22.
//

import Foundation

struct PostModel : Codable{
    let userId : Int
    let id : Int
    let title : String
    let body : String
}

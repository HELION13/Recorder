//
//  MainRouter.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import UIKit

protocol Router {
    func set(controllers: [UIViewController], animated: Bool)
    func show(controller: UIViewController, animated: Bool)
}

class MainRouter: Router {
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func set(controllers: [UIViewController], animated: Bool) {
        navigationController.setViewControllers(controllers, animated: animated)
    }
    
    func show(controller: UIViewController, animated: Bool) {
        navigationController.pushViewController(controller, animated: animated)
    }
}

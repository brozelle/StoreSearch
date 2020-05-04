//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Buck Rozelle on 5/4/20.
//  Copyright © 2020 buckrozelledotcomLLC. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    /*
 creates the object, makes it as big as the containerView and inserts
     it behind everything else in the container view.
 */
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView?.insertSubview(dimmingView, at: 0)
        
        //animate background
        dimmingView.alpha = 0
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
}
        
    }

    override var shouldRemovePresentersView: Bool {
        return false
    }
    
}

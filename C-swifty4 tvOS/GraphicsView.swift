//
//  GraphicsView.swift
//  C-swifty4 tvOS
//
//  Created by Fabio on 22/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import Foundation

#if (arch(i386) || arch(x86_64)) && os(tvOS)
    class GraphicsView: ContextBackedView {}
#else
    class GraphicsView: MetalView {}
#endif

//
//  PropertyWrapper.swift
//  NCEngine
//
//  Created by 四熊泰之 on R 2/01/03.
//  Copyright © Reiwa 2 四熊 泰之. All rights reserved.
//

import Foundation

/// 排他的な読み書きを提供する
@propertyWrapper public struct DMSynchronized<T> {
    private var value: T
    private var mutext: pthread_mutex_t = pthread_mutex_t()

    public init(wrappedValue: T) {
        pthread_mutex_init(&mutext, nil)
        self.value = wrappedValue
    }
    
    public var wrappedValue: T {
        mutating get {
            pthread_mutex_lock(&mutext)
            defer { pthread_mutex_unlock(&mutext) }
            return value
        }
        set {
            pthread_mutex_lock(&mutext)
            self.value = newValue
            pthread_mutex_unlock(&mutext)
        }
    }
}

//
//  ErrorType.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 22/05/2024.
//

import Foundation

enum ErrorType: Error {
    case sessionError
    case engineError
    case noPitchDetected
    case noMicPermission
    case unknown
}

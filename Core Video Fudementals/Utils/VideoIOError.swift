//
//  VideoIOError.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//


import CoreVideo
import CoreImage

enum VideoIOError: Error {
    case noVideoTrack
    case writerSetup
    case noPixelBufferPool
    case unknown
}

extension Optional {
    func orThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else { throw error() }
        return value
    }
}

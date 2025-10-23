//
//  PhotoAssetWriter.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import UIKit
import Photos

protocol PhotoAssetWriter {
    func enqueue(_ image: UIImage)
    func enqueue(_ images: [UIImage])
}

struct PhotoAssetWriterImpl: PhotoAssetWriter {
    func enqueue(_ image: UIImage) {
        _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
    }
    func enqueue(_ images: [UIImage]) {
        for img in images {
            _ = PHAssetChangeRequest.creationRequestForAsset(from: img)
        }
    }
}

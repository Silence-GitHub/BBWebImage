# BBWebImage

BBWebImage is a Swift library for downloading, caching and editing web images asynchronously.

## Features

- [x] View extensions for `UIImageView`, `UIButton`, `MKAnnotationView` and `CALayer` to set image from URL
- [x] Asynchronous image downloader
- [x] Asynchronous memory + file + SQLite image cache with least recently used algorithm
- [x] Asynchronous image decompressing
- [x] Asynchronous image editing without modifying original image disk data
- [x] Independent image cache, downloader, coder and editor for separate use
- [x] Customized image cache, downloader and coder

## Requirements

- iOS 8.0+
- Swift 4.0+

## How To Use

Set image for `UIImageView` with `URL`

```swift
imageView.bb_setImage(with: url)
```

The code below:

1. Downloads a high-resolution image
2. Downsamples it to match an expected maximum resolution and image view size
3. Draws it with round corner, border and background color
4. Displays edited image after downloading and editing
5. Displays a placeholder image before downloading
6. Decodes image incrementally and displays it while downloading
7. Caches original image data to disk and caches edited image to memory
8. Do something when loading is finished

```swift
let editor = BBWebImageEditor.editorForScaleAspectFillContentMode(with: imageView.frame.size,
                                                                  maxResolution: 1024 * 1024,
                                                                  corner: .allCorners,
                                                                  cornerRadius: 5,
                                                                  borderWidth: 1,
                                                                  borderColor: .yellow,
                                                                  backgroundColor: .gray)
imageView.bb_setImage(with: url,
                      placeholder: UIImage(named: "placeholder"),
                      options: .progressiveDownload,
                      editor: editor)
{ (image: UIImage?, data: Data?, error: Error?, cacheType: BBImageCacheType) in
    // Do something when finish loading
}
```

## License

BBWebImage is released under the MIT license. See LICENSE for details.


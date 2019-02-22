# BBWebImage

BBWebImage is a Swift library for downloading, caching and editing web images asynchronously.

## Examples

Simplely download, display and cache images.

![](README_resources/original_image.gif)

Download images. Decode, edit and display images while downloading. After downloading, cache edited images in memory and cache original image data in disk.

**Add filter**

![](README_resources/edit_filter.gif)

**Draw rounded corner and border**

![](README_resources/edit_common.gif)

## Features

- [x] View extensions for `UIImageView`, `UIButton`, `MKAnnotationView` and `CALayer` to set image from URL
- [x] Asynchronous image downloader
- [x] Asynchronous memory + file + SQLite image cache with least recently used algorithm
- [x] Asynchronous image decompressing
- [x] Asynchronous image editing without modifying original image disk data
- [x] Animated image smart decoding, decompressing, editing and caching
- [x] Independent image cache, downloader, coder and editor for separate use
- [x] Customized image cache, downloader and coder

## Why to use

### Solve the problems of SDWebImage

SDWebImage is a powerful library for downloading and caching web images. When BBWebImage first version (0.1.0) is released, the latest version of SDWebImage is 4.4.3 which dose not contain powerful image editing function. If we download an image with SDWebImage 4.4.3 and edit the image, the problems will happen:

1. The edited image is cached, but the original image data is lost. We need to download the original image again if we want to display it.
2. The original image data is cached to disk. If we do not cache the edited image, we need to edit image to display the edited image every time. If we cache the edited image to both memory and disk, we need to write more code and manage the cache key. If we cache the edited image to memory only, when we get the cached image, we need to know whether it is edited by checking where it is cached.
3. If we use `Core Graphics` to edit image, we should disable SDWebImage image decompressing (because decompressing is unnecessary. Both editing and decompressing have similar steps: create `CGContext`, draw image, create new image) and enable it later.

BBWebImage is born to solve the problems.

1. The original image data is cached to disk, and the original or edited image is cached to memory. The `UIImage` is associated with edit key which is a String identifying how the image is edited. Edit key is nil for original image. When we load image from the network or cache, we can pass `BBWebImageEditor` to get edited image. BBWebImageEditor specifies how to edit image, and contains the edit key which will be associated to the edited image. If the edit key of the memory cached image is the same as the edit key of BBWebImageEditor, then the memory cached image is what we need; Or BBWebImage will load and edit the original image and cache the edited image to memory. If we want the original image, do not pass BBWebImageEditor. We will not download an image more than once. We do not need to write more code to cache edited image or check whether the image is edited.
2. If we load original image, BBWebImage will decompress image by default. If we load image with BBWebImageEditor, BBWebImage will use editor to edit image without decompressing. We do not need to write more code to enable or disable image decompressing.

### Edit animated image and cache smartly

To display animated image, we need to decode image frames, change frame according to frame duration. We use `BBAnimatedImage` to manage animated image data, and use `BBAnimatedImageView` to play the animation. BBAnimatedImageView decides which frame to display or to decode. BBAnimatedImage decodes and caches image frames in the background. The max cache size is calculated dynamically and the cache is cleared automatically.

BBAnimatedImage uses BBWebImageEditor to edit image frames. BBAnimatedImage has a property `bb_editor` which is an optional BBWebImageEditor type. Set an editor to the property to display edited image frames, or set nil to display original image frames.

## Requirements

- iOS 8.0+
- Swift 4.2

## Installation

Install with CocoaPods:

1. Add `pod 'BBWebImage'` to your Podfile. Add `pod 'BBWebImage/MapKit'` for MKAnnotationView extension. Add `pod 'BBWebImage/Filter'` for image filter.
2. Run `pod install` or `pod update`.
3. Add `import BBWebImage` to the Swift source file.

## How To Use

The simplest way to use is setting image for `UIImageView` with `URL`

```swift
imageView.bb_setImage(with: url)
```

The code below:

1. Downloads a high-resolution image
2. Downsamples and crops it to match an expected maximum resolution and image view size
3. Draws it with rounded corner, border and background color
4. Displays edited image after downloading and editing
5. Displays a placeholder image before downloading
6. Decodes image incrementally and displays it while downloading
7. Caches original image data to disk and caches edited image to memory
8. Do something when loading is finished

```swift
let editor = bb_imageEditorCommon(with: imageView.frame.size,
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

To support GIF, replace `UIImageView` by `BBAnimatedImageView`. BBAnimatedImageView is a subclass of UIImageView. BBAnimatedImageView supports both static image and animated image.

## Supported image formats

- [x] JPEG
- [x] PNG
- [x] GIF

To support other image format or change default encode/decode behaivor, customize image coder. Implement new coder conforming to `BBImageCoder` protocol. Get old coders and change.

```swift
if let coderManager = BBWebImageManager.shared.imageCoder as? BBImageCoderManager {
	let oldCoders = coderManager.coders
	let newCoders = ...
	coderManager.coders = newCoders
}
```

## License

BBWebImage is released under the MIT license. See LICENSE for details.


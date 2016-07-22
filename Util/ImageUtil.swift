import Foundation

class ImageUtil {

    static func resizeImageS3(image: UIImage) -> UIImage {
        let newSize: CGSize = CGSizeMake(IMAGE_AMAZON_S3_WIDTH, IMAGE_AMAZON_S3_HEIGHT);
        UIGraphicsBeginImageContext(newSize)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    static func cropSquareResize(image: UIImage, size: CGSize, pct: Double = 1.0) -> UIImage? {
        return self.resizeImage(self.zoomCrop(self.cropImageToSquare(image)!, pct: pct), targetSize: size)
    }

    static func cropImageToSquare(image: UIImage) -> UIImage? {
        var imageHeight = image.size.height
        var imageWidth = image.size.width

        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }

        let size = CGSize(width: imageWidth, height: imageHeight)

        let refWidth : CGFloat = CGFloat(CGImageGetWidth(image.CGImage))
        let refHeight : CGFloat = CGFloat(CGImageGetHeight(image.CGImage))

        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2

        let cropRect = CGRectMake(x, y, size.height, size.width)
        if let imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect) {
            let newImage = UIImage(CGImage: imageRef, scale: 0, orientation: image.imageOrientation)
            return newImage
        }

        return nil
    }

    static func zoomCrop(image: UIImage, pct: Double) -> UIImage? {
        let height = Double(image.size.height)
        let width = Double(image.size.width)

        let reducedHeight = height * pct / 100
        let reducedWidth = width * pct / 100

        let newX = (width - reducedWidth) / 2
        let newY = (height - reducedHeight) / 2

        let cropRect = CGRectMake(CGFloat(newX), CGFloat(newY), CGFloat(reducedHeight), CGFloat(reducedWidth))
        if let imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect) {
            let newImage = UIImage(CGImage: imageRef, scale: 0, orientation: image.imageOrientation)
            return newImage
        }

        return nil
    }

    static func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        if let image = image {
            let size = image.size

            let widthRatio  = targetSize.width  / image.size.width
            let heightRatio = targetSize.height / image.size.height

            // Figure out what our orientation is, and use that to form the rectangle
            var newSize: CGSize
            if(widthRatio > heightRatio) {
                newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
            } else {
                newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
            }

            // This is the rect that we've calculated out and this is what is actually used below
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)

            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            image.drawInRect(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        } else {
            return nil
        }
    }

    static func scaleUIImageToSize(let image: UIImage, let size: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

}

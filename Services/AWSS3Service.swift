import Foundation
import AWSCore
import AWSS3
import AssetsLibrary

class AWSS3Service {

    static func uploadPostImage(image: UIImage, withCompletionBlock: ((AWSTask, AWSS3TransferManagerUploadRequest) -> Void)!) {
        self.uploadImage(image, group: AWS_S3_BUCKET_POSTS, withCompletionBlock: {
            (task, request) in
            withCompletionBlock(task, request)
        })
    }

    static func uploadUserImage(image: UIImage, withCompletionBlock: ((AWSTask, AWSS3TransferManagerUploadRequest) -> Void)!) {
        self.uploadImage(image, group: AWS_S3_BUCKET_USERS, withCompletionBlock: {
            (task, request) in
            withCompletionBlock(task, request)
        })
    }

    static func writeImageToFilePath(image: UIImage, filePath: String) -> Bool {
        let imageData = UIImageJPEGRepresentation(ImageUtil.resizeImageS3(image), IMAGE_AMAZON_S3_COMPRESSION)
        return imageData!.writeToFile(filePath, atomically: true)
    }

    static func uploadImage(image: UIImage, group: String, withCompletionBlock: ((AWSTask, AWSS3TransferManagerUploadRequest) -> Void)!) {
        // Upload image to Amazon S3
        let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(AWS_S3_UPLOAD_TEMP_JPEG_EXT)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(AWS_S3_UPLOAD_TEMP_FOLDER).URLByAppendingPathComponent(fileName)
        let filePath = fileURL.path!

        if self.writeImageToFilePath(image, filePath: filePath) {
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest.body = fileURL
            uploadRequest.key = "\(AWS_S3_BUCKET_PREFIX)/\(group)/\(fileName)"
            uploadRequest.bucket = AWS_S3_BUCKET_NAME
            uploadRequest.contentType = AWS_S3_CONTENT_TYPE_JPEG
            uploadRequest.ACL = AWSS3ObjectCannedACL.PublicRead

            AWSS3TransferManager.defaultS3TransferManager().upload(uploadRequest).continueWithBlock({
                (task) -> AnyObject? in
                withCompletionBlock(task, uploadRequest)
                return nil
            })
        }
    }

    static func deletePostImage(imageURL: String, withCompletionBlock: ((Bool) -> Void)!) {
        let prefix = "\(AWS_S3_WEB_URL)/\(AWS_S3_BUCKET_NAME)/"
        if let _ = imageURL.rangeOfString(prefix, options: .LiteralSearch, range: nil, locale: nil)?.startIndex {
            let startIndex = imageURL.startIndex.advancedBy(prefix.characters.count)
            let key = imageURL.substringFromIndex(startIndex)

            let deleteRequest = AWSS3DeleteObjectRequest()
            deleteRequest.bucket = AWS_S3_BUCKET_NAME
            deleteRequest.key = key

            AWSS3.defaultS3().deleteObject(deleteRequest, completionHandler: {
                (output, error) in
                if error == nil {
                    withCompletionBlock(true)
                } else {
                    withCompletionBlock(false)
                }
            })
        } else {
            withCompletionBlock(false)
        }
    }

}

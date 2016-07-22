import UIKit
import MapKit
import imglyKit

class PhotoViewController: CommonViewController {

    // MARK: @IBOutlet

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!

    // MARK: Local Variables

    var parentView: HomeViewController!
    var cameraManager: CameraManager!
    var current_lat: CLLocationDegrees!
    var current_lon: CLLocationDegrees!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Set initial hide
        self.acceptButton.hidden = true

        // Configure camera
        self.cameraManager = CameraManager()
        self.cameraManager.cameraDevice = .Back
        self.cameraManager.cameraOutputMode = .StillImage
        self.cameraManager.cameraOutputQuality = .High
        self.cameraManager.flashMode = .Off
        self.cameraManager.showCropMasking = true
        self.cameraManager.writeFilesToPhoneLibrary = false
        self.cameraManager.showAccessPermissionPopupAutomatically = true

        // Load camera only when it is ready
        let currentCameraState = self.cameraManager.currentCameraStatus()
        if currentCameraState == .Ready {
            self.cameraManager.addPreviewLayerToView(self.cameraView)
            self.cameraManager.showErrorBlock = {
                (error, message) in
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: message)
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Dismiss if camera not ready
        let currentCameraState = self.cameraManager.currentCameraStatus()
        if currentCameraState != .Ready {
            self.dismissViewControllerAnimated(true, completion: nil)
        }

        // Set current location
        self.current_lat = self.parentView.current_lat
        self.current_lon = self.parentView.current_lon

        // Resume camera
        self.cameraManager.resumeCaptureSession()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        // Stop camera
        self.cameraManager.stopCaptureSession()
    }

    // MARK: @IBAction

    @IBAction func cancelButtonPressed(sender: UIButton) {
        if sender.currentTitle == BUTTON_LABEL_CANCEL {
            // Stop camera and dismiss
            self.cameraManager.stopCaptureSession()
            self.dismissViewControllerAnimated(true, completion: nil)
        } else if sender.currentTitle == BUTTON_LABEL_RETAKE {
            // Restart camera
            self.cameraManager.resumeCaptureSession()
            self.cameraManager.clearCropImage()

            self.setCameraToCapture(true)
        }
    }

    @IBAction func acceptButtonPressed(sender: UIButton) {
        if let image = self.cameraManager.getCropImage() {
            // Stop camera
            self.cameraManager.stopCaptureSession()

            // Load image into editor
            let editorView = IMGLYMainEditorViewController()
            editorView.completionBlock = editorCompletionBlock as IMGLYEditorCompletionBlock
            editorView.highResolutionImage = image

            // Remove crop from options
            // let actionButtons = editorView.actionButtons as [IMGLYActionButton]

            // Load editor in new navigation view
            let navView = IMGLYNavigationController(rootViewController: editorView)
            navView.navigationBar.barStyle = .Black
            navView.navigationBar.translucent = false
            navView.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]

            self.dismissViewControllerAnimated(true, completion: {
                self.parentView.presentViewController(navView, animated: true, completion: nil)
            })
        }
    }

    @IBAction func cameraButtonPressed(sender: UIButton) {
        // Crop, resize and show preview
        self.cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
            if error == nil {
                // Stop camera
                self.cameraManager.stopCaptureSession()

                // Set button configuration
                self.setCameraToCapture(false)

                // Crop square and resize
                let formattedImage = ImageUtil.cropSquareResize(image!, size: CGSize(width: 800.0, height: 800.0), pct: 75.3)
                self.cameraManager.setCropImage(formattedImage!)
            }
        })
    }

    @IBAction func flashButtonPressed(sender: UIButton) {
        self.cameraManager.changeFlashMode()
        switch self.cameraManager.flashMode {
        case .Off:
            sender.setBackgroundImage(UIImage(named: "Icon-FlashOff.png"), forState: UIControlState.Normal)
        case .On:
            sender.setBackgroundImage(UIImage(named: "Icon-FlashOn.png"), forState: UIControlState.Normal)
        case .Auto:
            // Forward to off
            self.cameraManager.changeFlashMode()
            sender.setBackgroundImage(UIImage(named: "Icon-FlashOff.png"), forState: UIControlState.Normal)
        }
    }

    @IBAction func toggleButtonPressed(sender: UIButton) {
        // Reverse front/back camera
        self.cameraManager.cameraDevice = self.cameraManager.cameraDevice == CameraDevice.Front ? CameraDevice.Back : CameraDevice.Front
    }

    // MARK: Helpers

    func saveToAlbum(image: UIImage) -> Void {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(PhotoViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    func editorCompletionBlock(result: IMGLYEditorResult, image: UIImage?) {
        if let pickedImage = image {
            // Activate spinner
            SpinnerView.show(ALERT_MESSAGE_SAVING_IMAGE)

            // Save to device album
            self.saveToAlbum(pickedImage)

            // Make sure current post location is valid
            let location = CLLocation(latitude: self.current_lat, longitude: self.current_lon)
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                // Upload to AWS
                AWSS3Service.uploadPostImage(pickedImage, withCompletionBlock: {
                    (task, request) in
                    if let _ = task.error {
                        // Failed
                        SpinnerView.hide()
                        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_IMAGE_UPLOAD_FAILED)
                        self.parentView.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        // Build image URL
                        let imageURL = "\(AWS_S3_WEB_URL)/\(request.bucket!)/\(request.key!)"

                        // Add post to firebase and location to geofire
                        FbaseDataService.ds.createPost(self.user.uid, imageURL: imageURL, withCompletionBlock: {
                            (error, key) in
                            if error == nil {
                                GfireDataService.ds.addPostLocation(location, forKey: key, withCompletionBlock: {
                                    (error) in
                                    if error == nil {
                                        // Get current post count for user
                                        FbaseDataService.ds.getUserPostCount(self.user.uid, withCompletionBlock: {
                                            (count) in
                                            // Update count in stats
                                            FbaseDataService.ds.updateUserPostCount(self.user.uid, count: count, withCompletionBlock: {
                                                (error, ref) in
                                                // Dismiss editor and load timeline for new photo
                                                self.parentView.dismissImageEditorAndLoadTimeline(location)
                                            })
                                        })
                                    } else {
                                        // Post failed
                                        SpinnerView.hide()
                                        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SAVE_LOCATION_FAILED)
                                        self.parentView.dismissViewControllerAnimated(true, completion: nil)
                                    }
                                })
                            } else {
                                // Post failed
                                SpinnerView.hide()
                                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_POST_FAILED)
                                self.parentView.dismissViewControllerAnimated(true, completion: nil)
                            }
                        })
                    }
                })
            } else {
                // Upload failed
                SpinnerView.hide()
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_INVALID_LOCATION)
                self.parentView.dismissViewControllerAnimated(true, completion: nil)
            }
        } else {
            self.parentView.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
        if error != nil {
            // Report error to user
        }
    }

    func setCameraToCapture(enable: Bool) {
        // Disable camera button
        self.cameraButton.enabled = enable

        // Disable toggle button
        self.toggleButton.enabled = enable

        // Disable flash button
        self.flashButton.enabled = enable

        // Show accept button
        self.acceptButton.hidden = enable

        if enable {
            self.cancelButton.setTitle(BUTTON_LABEL_CANCEL, forState: UIControlState.Normal)
        } else {
            self.cancelButton.setTitle(BUTTON_LABEL_RETAKE, forState: UIControlState.Normal)
        }
    }

}

//
//  ViewController.swift
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 12/29/19.
//  Copyright © 2019 Andrew Li. All rights reserved.
//

import UIKit
import AVFoundation

let DP_EPSILON_FACTOR = 0.015;
let MINIMUM_SIZE = 25000;
let QUADRATURE_TOLERANCE = 0.4;

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var boxLayer: CALayer?
    var rectangleDetector = RectangleDetector(epsilon: DP_EPSILON_FACTOR, maximumSize: Int32(MINIMUM_SIZE), quadratureTolerance: QUADRATURE_TOLERANCE)
    lazy var throttledProcessImage = throttle(delay: 0.5, action: processImage)

    override func viewDidLoad() {
        super.viewDidLoad()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                  if granted {
                      self.setupCaptureSession()
                  }
                }
            default:
                return
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession?.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        captureSession?.stopRunning()
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession!.beginConfiguration()

        let videoOutput = AVCaptureVideoDataOutput()
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let deviceInput = try? AVCaptureDeviceInput(device: device),
            captureSession!.canAddInput(deviceInput),
            captureSession!.canAddOutput(videoOutput)
        else {
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.li357.cvrd.Video"))
        captureSession!.addInput(deviceInput)
        captureSession!.addOutput(videoOutput)
        captureSession!.sessionPreset = .high
        captureSession!.commitConfiguration()

        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.session = captureSession!
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.frame
        view.layer.addSublayer(previewLayer)

        boxLayer = CALayer()
        previewLayer.addSublayer(boxLayer!)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        throttledProcessImage(sampleBuffer)
    }

    func convertFromCamera(_ point: CGPoint, widthScale: CGFloat, heightScale: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * widthScale, y: point.y * heightScale)
    }

    func processImage(_ sampleBuffer: CMSampleBuffer) {
        guard
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let uiImage = imageBuffer.toUIImage()
        else {
            return
        }

        boxLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        let rectangles = rectangleDetector?.findRectangles(in: uiImage)

        // Buffer is height x width, not width x height
        let bufferWidth = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let bufferHeight = CGFloat(CVPixelBufferGetWidth(imageBuffer))

        let widthScale = view.bounds.width / bufferWidth
        let heightScale = view.bounds.height / bufferHeight

        DispatchQueue.main.async {
            rectangles?
                .compactMap { $0 as? Rectangle }
                .forEach { rectangle in
                    let box = CAShapeLayer()
                    box.strokeColor = UIColor.systemGreen.cgColor
                    box.lineWidth = 3
                    box.lineJoin = .miter
                    box.opacity = 0.5

                    let path = UIBezierPath()
                    path.move(to: self.convertFromCamera(rectangle.topLeft, widthScale: widthScale, heightScale: heightScale))
                    path.addLine(to: self.convertFromCamera(rectangle.topRight, widthScale: widthScale, heightScale: heightScale))
                    path.addLine(to: self.convertFromCamera(rectangle.bottomRight, widthScale: widthScale, heightScale: heightScale))
                    path.addLine(to: self.convertFromCamera(rectangle.bottomLeft, widthScale: widthScale, heightScale: heightScale))
                    path.close()
                    box.path = path.cgPath
                    self.boxLayer?.addSublayer(box)
                }
        }
    }
}

extension CVImageBuffer {
    func toUIImage() -> UIImage? {
        let ciImage = CIImage(cvImageBuffer: self).oriented(.right)
        let context = CIContext.init(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage.init(cgImage: cgImage)
    }
}

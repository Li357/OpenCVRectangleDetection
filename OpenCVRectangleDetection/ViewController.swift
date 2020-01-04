//
//  ViewController.swift
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 12/29/19.
//  Copyright © 2019 Andrew Li. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupImageView()
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

    func setupImageView() {
        imageView.frame = view.layer.bounds
        imageView.contentMode = .scaleAspectFill
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
        captureSession!.sessionPreset = .photo
        captureSession!.commitConfiguration()
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let uiImage = sampleBuffer.toUIImage() else {
            return
        }

        let withContours = RectangleDetection.drawContours(uiImage)
        DispatchQueue.main.async {
            self.imageView.image = withContours
        }
    }
}

extension CMSampleBuffer {
    func toUIImage() -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
          return nil
        }

        let ciImage = CIImage(cvImageBuffer: imageBuffer).oriented(.right)
        let context = CIContext.init(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage.init(cgImage: cgImage)
    }
}

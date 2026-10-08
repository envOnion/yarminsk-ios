import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public struct QRCodeView: View {
    public let data: String
    public let size: CGFloat
    public let padding: CGFloat
    public let cornerRadius: CGFloat
    public let boxColor: Color

    private let context = CIContext()

    public init(
        data: String,
        size: CGFloat = 200,
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        boxColor: Color = .white
    ) {
        self.data = data
        self.size = size
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.boxColor = boxColor
    }

    public var body: some View {
        Group {
            if let qrImage = generateQRCode(from: data) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.yarSubject40)
            }
        }
        .frame(width: size, height: size)
        .padding(padding)
        .background(boxColor)
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty, let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        let messageData = string.data(using: .utf8)
        filter.setValue(messageData, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputCIImage = filter.outputImage else {
            return nil
        }

        // Scale up using nearest-neighbor transform to keep pixel-sharp borders
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = outputCIImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        QRCodeView(data: "A1B2C3", size: 180)
    }
}

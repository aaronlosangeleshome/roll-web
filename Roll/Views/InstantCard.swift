import SwiftUI

enum CardMetrics {
    static let margin: CGFloat = 0.06        // side + top border, fraction of width
    static let bottom: CGFloat = 0.22        // chin, fraction of width
    static var heightRatio: CGFloat { margin + (1 - 2 * margin) + bottom }
    static var aspect: CGFloat { 1 / heightRatio }
}

/// The instant print. Same view is used on screen and for export (via ImageRenderer).
struct InstantCard: View {
    let image: UIImage
    var frame: FrameStyle = .classic
    var caption: String = ""
    var stickers: [StickerPlacement] = []
    var progress: Double = 1
    var showsShadow = true
    var onStickersChange: (([StickerPlacement]) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let m = w * CardMetrics.margin
            let photo = w - 2 * m
            let corner = w * 0.012

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(frame.paper)
                    .shadow(color: showsShadow ? .black.opacity(0.28) : .clear, radius: w * 0.03, x: 0, y: w * 0.015)

                // Photo window with the chemical develop effect
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: photo, height: photo)
                    .saturation(0.1 + 0.9 * progress)
                    .blur(radius: (1 - progress) * w * 0.05, opaque: true)
                    .overlay(
                        Color(red: 0.10, green: 0.15, blue: 0.17)
                            .opacity(max(0, 1 - progress * 1.3))
                    )
                    .clipShape(Rectangle())
                    .overlay(
                        Rectangle().strokeBorder(Color.black.opacity(0.12), lineWidth: max(0.5, w * 0.002))
                    )
                    .offset(x: m, y: m)

                // Handwritten caption
                if !caption.isEmpty {
                    Text(caption)
                        .font(.custom("Noteworthy-Bold", size: w * 0.07))
                        .foregroundStyle(frame.ink.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: photo, height: w * CardMetrics.bottom, alignment: .center)
                        .offset(x: m, y: m + photo)
                        .opacity(progress)
                }

                // Stickers
                ForEach(stickers) { sticker in
                    StickerView(
                        placement: sticker,
                        cardSize: CGSize(width: w, height: h),
                        editable: onStickersChange != nil,
                        onChange: { updated in
                            guard let onStickersChange else { return }
                            var list = stickers
                            if let i = list.firstIndex(where: { $0.id == updated.id }) { list[i] = updated }
                            onStickersChange(list)
                        },
                        onDelete: {
                            guard let onStickersChange else { return }
                            onStickersChange(stickers.filter { $0.id != sticker.id })
                        }
                    )
                    .opacity(progress)
                }
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(CardMetrics.aspect, contentMode: .fit)
    }
}

struct StickerView: View {
    let placement: StickerPlacement
    let cardSize: CGSize
    let editable: Bool
    let onChange: (StickerPlacement) -> Void
    let onDelete: () -> Void

    @GestureState private var drag: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        let base = cardSize.width * 0.17
        let size = base * placement.scale * pinch
        let image = Image(systemName: placement.symbol)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(StickerAsset.color(for: placement.symbol))
            .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1)
            .rotationEffect(.degrees(placement.rotation))
            .position(x: placement.x * cardSize.width + drag.width,
                      y: placement.y * cardSize.height + drag.height)

        if editable {
            image
                .gesture(
                    DragGesture()
                        .updating($drag) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            var p = placement
                            p.x = min(1, max(0, (placement.x * cardSize.width + value.translation.width) / cardSize.width))
                            p.y = min(1, max(0, (placement.y * cardSize.height + value.translation.height) / cardSize.height))
                            onChange(p)
                        }
                        .simultaneously(with:
                            MagnifyGesture()
                                .updating($pinch) { value, state, _ in state = value.magnification }
                                .onEnded { value in
                                    var p = placement
                                    p.scale = min(3, max(0.4, placement.scale * value.magnification))
                                    onChange(p)
                                }
                        )
                )
                .onTapGesture(count: 2, perform: onDelete)
                .accessibilityLabel("Sticker")
                .accessibilityHint("Drag to move. Double tap to remove.")
        } else {
            image.allowsHitTesting(false)
        }
    }
}

@MainActor
enum CardRenderer {
    /// Flattens a finished card to a 1080 pt wide UIImage for Save / Share.
    static func render(shot: Shot, image: UIImage) -> UIImage? {
        let width: CGFloat = 1080
        let view = InstantCard(image: image, frame: shot.frame, caption: shot.caption,
                                stickers: shot.stickers, progress: 1, showsShadow: false)
            .frame(width: width, height: width * CardMetrics.heightRatio)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

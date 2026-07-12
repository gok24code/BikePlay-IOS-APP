import SwiftUI
import MediaPlayer

struct VolumeSliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        
    
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = .systemGreen
            slider.maximumTrackTintColor = .darkGray
            slider.thumbTintColor = .systemGreen
        }
        
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

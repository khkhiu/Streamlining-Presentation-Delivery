// utils/video.js
export class VideoProcessor {
    static makeBackgroundTransparent(timestamp, previousTimestamp, video, canvas, tmpCanvas) {
        if (timestamp - previousTimestamp <= 30) return previousTimestamp;
        
        const tmpCanvasContext = tmpCanvas.getContext('2d', { willReadFrequently: true });
        const canvasContext = canvas.getContext('2d');
        
        tmpCanvasContext.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
        
        if (video.videoWidth > 0) {
            const frame = tmpCanvasContext.getImageData(0, 0, video.videoWidth, video.videoHeight);
            this.processFrameData(frame);
            canvasContext.putImageData(frame, 0, 0);
        }
        
        return timestamp;
    }
    
    static processFrameData(frame) {
        for (let i = 0; i < frame.data.length / 4; i++) {
            let r = frame.data[i * 4 + 0];
            let g = frame.data[i * 4 + 1];
            let b = frame.data[i * 4 + 2];
            
            if (g - 150 > r + b) {
                frame.data[i * 4 + 3] = 0;
            } else if (g + g > r + b) {
                const adjustment = (g - (r + b) / 2) / 3;
                frame.data[i * 4 + 0] = r + adjustment;
                frame.data[i * 4 + 1] = g - adjustment * 2;
                frame.data[i * 4 + 2] = b + adjustment;
                frame.data[i * 4 + 3] = Math.max(0, 255 - adjustment * 4);
            }
        }
    }
}
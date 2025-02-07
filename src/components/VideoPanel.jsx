// src/components/VideoPanel.jsx
import { useEffect, useRef } from 'react';
import { VideoProcessor } from '../utils/video';

function VideoPanel({ isSessionActive }) {
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const tmpCanvasRef = useRef(null);
  const animationFrameRef = useRef(null);
  const previousTimestampRef = useRef(0);

  useEffect(() => {
    if (isSessionActive) {
      const processFrame = (timestamp) => {
        previousTimestampRef.current = VideoProcessor.makeBackgroundTransparent(
          timestamp,
          previousTimestampRef.current,
          videoRef.current,
          canvasRef.current,
          tmpCanvasRef.current
        );
        animationFrameRef.current = requestAnimationFrame(processFrame);
      };

      animationFrameRef.current = requestAnimationFrame(processFrame);
    }

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [isSessionActive]);

  return (
    <div className="video-panel">
      <div id="remoteVideo">
        <video ref={videoRef} id="video" />
        <audio id="audio" />
      </div>
      <canvas ref={canvasRef} id="canvas" hidden />
      <canvas ref={tmpCanvasRef} id="tmpCanvas" hidden />
    </div>
  );
}

export default VideoPanel;
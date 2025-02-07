// main.js
import { AvatarService } from './services/AvatarService.js';
import { UIController } from './ui/UIController.js';
import { VideoProcessor } from './utils/video.js';

class App {
    constructor() {
        this.avatarService = new AvatarService();
        this.uiController = new UIController(this.avatarService);
    }
    
    initialize() {
        this.uiController.setupListeners();
        
        // Set up animation frame for video processing
        if (document.getElementById('transparentBackground').checked) {
            window.requestAnimationFrame((timestamp) => {
                const video = document.getElementById('video');
                const canvas = document.getElementById('canvas');
                const tmpCanvas = document.getElementById('tmpCanvas');
                
                this.previousAnimationFrameTimestamp = VideoProcessor.makeBackgroundTransparent(
                    timestamp,
                    this.previousAnimationFrameTimestamp,
                    video,
                    canvas,
                    tmpCanvas
                );
                
                window.requestAnimationFrame(this.processFrame.bind(this));
            });
        }
    }
}

// Initialize the application
const app = new App();
app.initialize();